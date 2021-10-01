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
    else #ログイン失敗したら
        @miss = "ユーザー名、またはパスワードが違います。"
        erb :sign_in
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
    if User.find_by(name: params[:name]) == nil #まだ、そのユーザー名が使われていなかったら作成
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
            @miss = "パスワードと確認パスワードが一致しません"
            erb :sign_up
        end
        
    else #すでにユーザー名使われていたら
        @miss = params[:name] + "は使用されています"
        erb :sign_up
    end
end

get '/sign_out' do #ログアウト
    session[:user] = nil
    redirect '/'
end

get '/edit/profile' do #プロフィール変更ページ
    @user = User.find(session[:user])
    erb :edit_profile
end

post '/edit/profile' do #プロフィール変更
    if User.find_by(name: params[:name]) == nil || params[:name] == current_user.name #まだ、そのユーザー名が他のユーザーに使われていなかったら作成
        img_url = '' #ファイルのアップロード
        if params[:profile]
            img = params[:profile]
            tempfile = img[:tempfile]
            upload = Cloudinary::Uploader.upload(tempfile.path)
            img_url = upload['url']
        else 
            img_url = current_user.profile
        end
        
        p "q"
        if params[:password] == params[:password_confirmation] && params[:name] != "" #パスワードと確認パスワードが一緒でユーザー名が何か入力されてる時
            user = User.find(session[:user])
            user.name = params[:name]
            user.password = params[:password]
            user.password_confirmation = params[:password_confirmation]
            user.profile = img_url

            if params[:password] == "" && params[:name] != current_user.name && params[:profile] == nil #ユーザー名だけ変更
                @message = "ユーザー名を変更しました"
            elsif params[:password] != "" && params[:name] == current_user.name && params[:profile] == nil #パスワードだけ変更
                @message = "パスワードを変更しました"
            elsif params[:password] == "" && params[:name] == current_user.name && params[:profile] != nil #プロフィール画像だけ変更
                @message = "プロフィール画像を変更しました"
            elsif params[:password] != "" && params[:name] != current_user.name && params[:profile] == nil #ユーザー名、パスワード変更
                @message = "ユーザー名、パスワードを変更しました"
            elsif params[:password] != "" && params[:name] == current_user.name && params[:profile] != nil #パスワード、プロフィール画像変更
                @message = "パスワード、プロフィール画像を変更しました"
            elsif params[:password] == "" && params[:name] != current_user.name && params[:profile] != nil #ユーザー名、プロフィール画像変更
                @message = "ユーザー名、プロフィール画像を変更しました"
            elsif params[:password] != "" && params[:name] != current_user.name && params[:profile] != nil#全部変更
                @message = "プロフィール全て変更しました" 
            end
            p "l"
            user.save
            
            @posts = Recruit.where(user_id: session[:user]) #ログインしているユーザーの投稿情報だけ取り出す
            @joinscount = Join.where(user_id: session[:user]).count
            @userjoins = Join.where(user_id: session[:user])
            @talkrooms = Talkroom.all
            @joiner = Join.all
            @reviewcounts = Review.where(reviewed_id: session[:user]).count #そのユーザーを評価した数
    
            reviewstars = Review.where(reviewed_id: session[:user])
            star = 0
            if @reviewcounts != 0
                reviewstars.each do |reviewstar| #全評価の星の数を数える
                    star = star + reviewstar.star
                end
                @userstar = star / @reviewcounts #全評価の平均を出す
            else 
                @userstar = 0.0
    
            end
            p @userjoins
            p @joinscount
            erb :home
            
        elsif  params[:password] != params[:password_confirmation] &&  params[:name] != ""#パスワードと確認パスワードが一致しなければ
            @message = "パスワードと確認パスワードが一致しません"
            
            @user = User.find(session[:user])
            p "r"
            erb :edit_profile
        else #何も入力されてなければ
            redirect '/home'
            p "y"
        end
        
    elsif User.find_by(name: params[:name]) != nil && params[:name] != current_user.name#すでにユーザー名使われていたら
        @message = params[:name] + "は使用されています"
        @user = User.find(session[:user])
        p "x"
        erb :edit_profile
    
    #else #何も入力されてなければ
        #redirect '/home'
       # p "y"
    end
end

get '/home' do #ホーム画面に飛ぶ
    @posts = Recruit.where(user_id: session[:user]) #ログインしているユーザーの投稿情報だけ取り出す
    
    @joinscount = Join.where(user_id: session[:user]).count
    @userjoins = Join.where(user_id: session[:user])#.where.not(talkroom_id: Talkroom.find_by(id: Recruit.find_by(user_id: session[:user]))) #ログインしているユーザーのJoin情報だけを取り出す
    @talkrooms = Talkroom.all
    @joiner = Join.all
    @reviewcounts = Review.where(reviewed_id: session[:user]).count #そのユーザーを評価した数
    
    reviewstars = Review.where(reviewed_id: session[:user])
    star = 0
    if @reviewcounts != 0
        reviewstars.each do |reviewstar| #全評価の星の数を数える
            star = star + reviewstar.star
        end
        @userstar = star / @reviewcounts #全評価の平均を出す
    else 
        @userstar = 0.0
    
    end
    p @userjoins
    p @joinscount
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
        applicant: params[:applicant],
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
    
    #すでにトークルームがあったら
    if !Join.where(talkroom_id: Talkroom.find_by(recruit_id: params[:id])).empty?
        Join.destroy_by(talkroom_id: Talkroom.find_by(recruit_id: params[:id]))#joinレコード消す
        #destroyjoin.destroy #joinレコード消す
        destroyroom = Talkroom.find_by(recruit_id: params[:id]) #その投稿のトークルームを消す
        destroyroom.destroy
    end
    
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
    game = Game.find_by(gamename: params[:gamename])
    @recruits = Recruit.where(game_id: game)
    @models = Model.all
    @categories = Category.all
    erb :index
end

post '/exit/:id' do #トークルーム退出
    @joinrecruit = Recruit.find(params[:id])
    #終了ボタン押したら
    if session[:user] == User.find(@joinrecruit.user_id).id
        Join.destroy_by(talkroom_id: Talkroom.find_by(recruit_id: params[:id]))
        #destroyjoin.destroy #joinレコード消す
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

post '/chat/:id' do #メッセージ送信
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

get '/otherpage/:id' do
    @otheruser = User.find(params[:id]) #飛んだユーザー情報
    @otherposts = Recruit.where(user_id: params[:id]) #飛んだユーザーの投稿情報
    @reviewcounts = Review.where(reviewed_id: params[:id]).count #そのユーザーを評価した数
    
    reviewstars = Review.where(reviewed_id: params[:id])
    star = 0
    p @reviewcounts
    if @reviewcounts != 0
        reviewstars.each do |reviewstar| #全評価の星の数を数える
            star = star + reviewstar.star
        end
        @userstar = star / @reviewcounts #全評価の平均を出す
    else 
        @userstar = 0.0
    end
    
    if 0.0 <= @userstar && @userstar < 0.5
        @userstar = 0.0
    elsif 0.5 <= @userstar && @userstar < 1.0
        @userstar = 0.5
    elsif 1.0 <= @userstar && @userstar < 1.5
        @userstar = 1.0
    elsif 1.5 <= @userstar && @userstar < 2.0
        @userstar = 1.5
    elsif 2.0 <= @userstar && @userstar < 2.5
        @userstar = 2.0
    elsif 2.5 <= @userstar && @userstar < 3.0
        @userstar = 2.5
    elsif 3.0 <= @userstar && @userstar < 3.5
        @userstar = 3.0
    elsif 3.5 <= @userstar && @userstar < 4.0
        @userstar = 3.5
    elsif 4.0 <= @userstar && @userstar < 4.5
        @userstar = 4.0
    elsif 4.5 <= @userstar && @userstar < 5.0
        @userstar = 4.5
    else
        @userstar = 5.0
    end
    
    p @userstar
    erb :home_other
end

get '/review/:id' do
    @reviewed = User.find(params[:id])
    @reviews = Review.where(reviewed_id: params[:id])
    
    erb :reviewlist
end

get '/write/review/:id' do
    @reviewed = User.find(params[:id])
    
    erb :writereview
end

post '/write/review/:id' do #評価する
    #reviewer.create(reviewed_id: params[:id]) #ユーザを評価する
    if Review.find_by(evaluation: params[:evaluation], star: params[:star], reviewer_id: session[:user], reviewed_id: params[:id]) == nil
        if params[:star] == nil
            params[:star] = 0
        end
        
        Review.create(
            evaluation: params[:evaluation],
            star: params[:star],
            reviewer_id: session[:user],
            reviewed_id: params[:id]#reviewer.find_by(reviewed_id: params[:id])
            )
        p "g"
        
        @reviewed = User.find(params[:id])
        @reviews = Review.where(reviewed_id: params[:id])
    
        erb :reviewlist
        
    else 
        @message = "同じユーザーのレビュー内容の重複はできません。"
        @reviewed = User.find(params[:id])
        p "$"
        erb :writereview
    end
    
end

get '/how_to_use' do
    erb :howtouse
end