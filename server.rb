require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

$db = SQLite3::Database.open("test.db")
$db.execute("CREATE TABLE IF NOT EXISTS Users(Id INTEGER PRIMARY KEY, Name TEXT, Salt TEXT, Hash TEXT, Bucks INTEGER)")

get '/' do
	erb :index
end

post '/' do
	puts params
	erb :index
end

get '/login' do
	erb :login
end

post '/login' do
	salt = BCrypt::Engine.generate_salt
	hash = BCrypt::Engine.hash_secret(params[:password], salt)

	$db.execute("INSERT INTO Users VALUES(0, #{params[:username]}, #{salt}, #{hash}, 50)")

	session[:username] = params[:username]
	redirect "/"
	puts params
end

get '/logout' do
	session[:username] = nil
	redirect "/"
end
