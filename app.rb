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
    erb :home
end

get '/post/board' do
    erb :recruit
end

post '/post/board' do
    
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
        articletime: DateTime.now + Rational("9/24")#現在時刻を取得
        #statusはnil
        )
    
    redirect '/'
end

get '/edit/:id' do
    @edit = Recruit.find(params[:id])
    erb :edit
end

post '/edit/:id' do
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

get '/talkroom/:id' do
    @joinrecruit = Recruit.find(params[:id])
    #Joinボタンを押したら
    if Join.find_by(user_id: session[:user], talkroom_id: params[:id]) == nil
        Talkroom.create( #トークルームの作成
            recruit_id: params[:id]
            )
        Join.create(
            user_id: session[:user],
            talkroom_id: Talkroom.find_by(recruit_id: params[:id]).id
            )
    end
   
    @joiner = Join.all
    @talkrooms = Talkroom.find(params[:id])
    erb :talkroom
end

post '/search' do #ゲームタイトルで絞り検索
    game = Game.find_by(gamename: params[:gamename]).id
    @recruits = Recruit.where(game_id: game)
    @models = Model.all
    @categories = Category.all
    erb :index
end