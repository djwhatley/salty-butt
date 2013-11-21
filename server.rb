require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

$db = SQLite3::Database.open("test.db")
$db.execute("CREATE TABLE IF NOT EXISTS Users(Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT, Salt TEXT, Hash TEXT, Bucks INTEGER)")

$bucks_min = 50

$playerbets = {}
$bets = [0,0]
$odds = [1,2]
$playerstats = {}

$players = ["Player 1", "Player 2"]
$betting = true

get '/' do
	if session[:username]
		if session[:lastbet].to_i > 0 and $bets[session[:lastpick]].to_i > 0
			session[:payout] = (($bets[0]+$bets[1]).to_f / $bets[session[:lastpick]].to_i * session[:lastbet].to_i).truncate
		end
		erb :index
	else
		redirect "/login"
	end
end

post '/' do
	puts params
	session[:lastbet] = params[:wager]
	session[:lastpick] = params[:player1]=="" ? 0 : 1
	if $betting
		$playerbets[session[:username]] = [session[:lastpick], session[:lastbet]]
	end
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

get '/admin' do
	erb :admin
end

post '/admin' do
	if params[:betting] == "start"
		$odds = [1,1]
		$bets = [0,0]
		$playerbets = {}
		$betting = true
	else
		for bet in $playerbets
			$bets[bet[1][0].to_i] += bet[1][1].to_i
		end
		if $bets[0] > $bets[1]
			$odds[0] = ($bets[0].to_f / $bets[1]).round(1)
			$odds[1] = 1
		else
			$odds[1] = ($bets[1].to_f / $bets[0]).round(1)
			$odds[0] = 1
		end
		$betting = false
	end
	erb :admin
end
