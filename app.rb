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
    @recruits = Recruit.all
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
        profile: img_url
        )
        
    if user.persisted?
        session[:user] = user.id
        user.login = false
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
    erb :home
end

get '/post/board' do
    erb :recruit
end

post '/post/board' do
    
    Model.create(
        platform: params[:platform]
        )
        
    Category.create(
        purpose: params[:purpose]
        )
    
    Game.create(
        gamename: params[:gamename],
        model_id: Model.find_by(platform: params[:platform]).id, #機種テーブルから今追加したレコードのid取得
        category_id: Category.find_by(purpose: params[:purpose]).id #カテゴリーテーブルから今追加したレコードのid取得
        )
    
    Recruit.create(
        model_id: Model.find_by(platform: params[:platform]).id, #機種テーブルから今追加したレコードのid取得
        game_id: Game.find_by(gamename: params[:gamename]).id, #ゲームタイトルテーブルから今追加したレコードのid取得
        category_id: Category.find_by(purpose: params[:purpose]).id, #カテゴリーテーブルから今追加したレコードのid取得
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
    Model.find_by(id: editpost.model_id).platform = params[:platform]
    Game.find_by(id: editpost.game_id).gamename = params[:gamename]
    Category.find_by(id: editpost.category_id).purpose = params[:purpose]
    editpost.article = params[:article]
    Model.find_by(id: editpost.model_id).save
    p params[:platform]
    p Model.find_by(id: editpost.model_id).platform
    Game.find_by(id: editpost.game_id).save
    Category.find_by(id: editpost.category_id).save
    editpost.save
    
    redirect '/home'
end
get '/delete/:id' do
    recruit = Recruit.find(params[:id])
    recruit.destroy
    redirect '/home'
end

get '/talkroom' do
    erb :talkroom
end

post '/search' do #ゲームタイトルで絞り検索
    game = Game.find_by(gamename: params[:gamename]).id
    @recruits = Recruit.where(game_id: game)
    erb :index
end