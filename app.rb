require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require 'dotenv/load'
require 'date' #DateTimeを使うために必要なライブラリ

enable :sessions

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
end

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
end

get '/' do
    @models = Model.all
    @categories = Category.all
    
    if params[:model].nil? && params[:category].nil? #条件検索なし
        @recruits = Recruit.all
    elsif !params[:category].nil? #目的で条件検索
        @recruits = Category.find(params[:category]).recruits
    else                                                       #機種で条件検索
        @recruits = Model.find(params[:model]).recruits
    end
    
    erb :index
end

get '/sign_in' do #ログイン画面に飛ぶ
    erb :sign_in
end

get '/sign_up' do #新規登録画面に飛ぶ
    erb :sign_up
end

post '/sign_in' do #ログイン
    user = User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user] = user.id
        user.login = true
        user.save
        redirect '/'
    else
        redirect '/'
    end
end

post '/sign_up' do #新規登録
    
    img_url = '' #ファイルのアップロード
    if params[:profile]
        img = params[:profile]
        tempfile = img[:tempfile]
        upload = Cloudinary::Uploader.upload(tempfile.path)
        img_url = upload['url']
    end
    
    user = User.create(
        name: params[:name],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        profile: img_url,
        login: false
        )
        
    if user.persisted?
        session[:user] = user.id
        redirect '/'
    else
        redirect '/'
    end
end

get '/sign_out' do #ログアウト
    session[:user] = nil
    redirect '/'
end

get '/home' do #ホーム画面に飛ぶ
    @posts = Recruit.where(user_id: session[:user]) #ログインしているユーザーの投稿情報だけ取り出す
    @userjoins = Join.where(user_id: session[:user]) #ログインしているユーザーのJoin情報だけを取り出
    @talkrooms = Talkroom.all
    @joiner = Join.all
    erb :home
end

get '/post/board' do #投稿ページに飛ぶ
    erb :recruit
end

post '/post/board' do #投稿する
    
    model = Model.find(params[:platform])
    category = Category.find(params[:purpose])
    
    Game.create(
        gamename: params[:gamename],
        model_id: model.id, #機種テーブルから今追加したレコードのid取得
        category_id: category.id #カテゴリーテーブルから今追加したレコードのid取得
        )
    
    Recruit.create(
        model_id: model.id, #機種テーブルから今追加したレコードのid取得
        game_id: Game.find_by(gamename: params[:gamename]).id, #ゲームタイトルテーブルから今追加したレコードのid取得
        category_id: category.id, #カテゴリーテーブルから今追加したレコードのid取得
        article: params[:article],
        user_id: session[:user],
        articletime: DateTime.now + Rational("9/24"),#現在時刻を取得
        status: false
        )
    
    redirect '/'
end

get '/edit/:id' do #編集ページ
    @edit = Recruit.find(params[:id])
    erb :edit
end

post '/edit/:id' do #編集する
    editpost = Recruit.find(params[:id])
    model = Model.find(params[:platform])
    category = Category.find(params[:purpose])
    
    Game.find_by(id: editpost.game_id).gamename = params[:gamename]
    editpost.article = params[:article]
    editpost.model_id = model.id
    editpost.category_id = category.id
    
    Game.find_by(id: editpost.game_id).save
    editpost.save
    
    redirect '/home'
end

get '/delete/:id' do
    recruit = Recruit.find(params[:id])
    recruit.destroy
    redirect '/home'
end

get '/talkroom/:id' do #トークルームに飛ぶ
    @joinrecruit = Recruit.find(params[:id])
    @joiner = Join.all
    @talkrooms = Talkroom.find_by(recruit_id: params[:id])
    @chats = Chat.where(talkroom_id: Talkroom.find_by(recruit_id: params[:id]).id) #そのトークルームのチャットレコードを取り出す
    erb :talkroom
end
    
post '/talkroom/:id' do #トークルーム作成
    @joinrecruit = Recruit.find(params[:id])
    #Joinボタンを押したら(初回だけ)
    if Join.find_by(user_id: session[:user], talkroom_id: Talkroom.find_by(recruit_id: params[:id])) == nil
        #トークルームのレコードは重複なし
        if Talkroom.find_by(recruit_id: params[:id]) == nil
            Talkroom.create( #トークルームの作成
                recruit_id: params[:id]
                )
            p "a"
        end
        
        if Join.find_by(user_id: session[:user], talkroom_id: Talkroom.find_by(recruit_id: params[:id]).id) == nil
            Join.create( #参加者
            user_id: session[:user],
            talkroom_id: Talkroom.find_by(recruit_id: params[:id]).id
            )
        p "b"
        end
        
        if Join.find_by(user_id: User.find_by(id: @joinrecruit.user_id), talkroom_id: Talkroom.find_by(recruit_id: params[:id])) == nil 
            Join.create( #投稿者
                user_id: User.find_by(id: @joinrecruit.user_id).id,
                talkroom_id: Talkroom.find_by(recruit_id: params[:id]).id
                )
        p "c"
        end
    end
   
    @joiner = Join.all
    @talkrooms = Talkroom.find_by(recruit_id: params[:id])
    @chats = Chat.where(talkroom_id: Talkroom.find_by(recruit_id: params[:id])) #そのトークルームのチャットレコードを取り出す
   
    erb :talkroom
end


post '/search' do #ゲームタイトルで絞り検索
    game = Game.find_by(gamename: params[:gamename]).id
    @recruits = Recruit.where(game_id: game)
    @models = Model.all
    @categories = Category.all
    erb :index
end

post '/exit/:id' do #トークルーム退出
    @joinrecruit = Recruit.find(params[:id])
    #終了ボタン押したら
    if session[:user] == User.find(@joinrecruit.user_id).id
        destroyjoin = Join.find_by(talkroom_id: Talkroom.find_by(recruit_id: params[:id]))
        destroyjoin.destroy #joinレコード消す
        destroyroom = Talkroom.find_by(recruit_id: params[:id])
        destroyroom.destroy #talkroomレコード消す
        #@joinrecruit.destroy #投稿消す
        @joinrecruit.status = true
        @joinrecruit.save
        p "o"
    #退出するボタン押したら
    else
        exitroom = Join.find_by(talkroom_id: Talkroom.find_by(recruit_id: params[:id]), user_id: session[:user])
        exitroom.destroy
        p "d"
    
        #誰も参加者いなくなったら自動的にトークルーム削除
        countjoiner = Join.where(talkroom_id: Talkroom.find_by(recruit_id: params[:id])).count
        if countjoiner == 1
            destroyroom = Talkroom.find_by(recruit_id: params[:id])
            destroyroom.destroy
            p "f"
        end
    
    end
    
    redirect '/'
end

post '/chat/:id' do #チャット
    Chat.create(
        comment: params[:comment],
        talkroom_id: params[:id],
        user_id: session[:user]
        )
    
    @chats = Chat.where(talkroom_id: params[:id]) #このトークルームだけのチャットレコードを取り出す
    @joiner = Join.all
    @joinrecruit = Recruit.find(Talkroom.find(params[:id]).recruit_id)
    @talkrooms = Talkroom.find(params[:id])
    
    erb :talkroom
end