require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

$db = SQLite3::Database.open("test.db")
$db.execute("CREATE TABLE IF NOT EXISTS Users(Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT, Salt TEXT, Hash TEXT, Bucks INTEGER)")

$bucks_min = 50

$bets = [0,0]
$odds = [1,2]
$playerstats = {}

$players = ["", "Player 1", "Player 2"]

get '/' do
	if session[:username]
		erb :index
	else
		redirect "/login"
	end
end

post '/' do
	puts params
	session[:lastbet] = params[:wager]
	session[:lastpick] = params[:player1]=="" ? 1 : 2
	erb :index
end

get '/login' do
	if session[:username]
		redirect "/"
	end
	erb :login
end

post '/login' do
	if session[:username]
		redirect "/"
	end
	a = $db.execute("SELECT * FROM Users WHERE Name IS \"#{params[:username]}\"")
	if a[0]
		salt = a[0][2]
		if a[0][3] == BCrypt::Engine.hash_secret(params[:password], salt)
			session[:username] = params[:username]
		end
	else
		salt = BCrypt::Engine.generate_salt
		hash = BCrypt::Engine.hash_secret(params[:password], salt)

		$db.execute("INSERT INTO Users VALUES(NULL, \"#{params[:username]}\", \"#{salt}\", \"#{hash}\", #{$bucks_min})")
	
		session[:username] = params[:username]
	end

	redirect "/"
end

get '/logout' do
	session[:username] = nil
	redirect "/"
end
