require 'sinatra'
require 'pg'
require 'bcrypt'

enable :sessions

$db = PGconn.open("ec2-54-204-43-138.compute-1.amazonaws.com", 5432, "", "", "deia47rhsmpbi8", "gxhlypbwsapuqu", "MlcweE_dk0Zn2TOXyU5aBhmwml")
$db.exec('CREATE TABLE IF NOT EXISTS Users(Name TEXT PRIMARY KEY, Salt TEXT, Hash TEXT, Bucks INTEGER)')

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
	while $bets[0] == 0
		erb :index
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
	a = $db.exec("SELECT * FROM Users WHERE Name = \'#{params[:username]}\'")
	if !a.to_a.empty?
		salt = a.getvalue(0,2)
		if a.getvalue(0,3) == BCrypt::Engine.hash_secret(params[:password], salt)
			session[:username] = params[:username]
		end
	else
		salt = BCrypt::Engine.generate_salt
		hash = BCrypt::Engine.hash_secret(params[:password], salt)

		$db.exec("INSERT INTO Users VALUES(\'#{params[:username]}\', \'#{salt}\', \'#{hash}\', #{$bucks_min})")
	
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
		$players[0] = params[:p1name]
		$players[1] = params[:p2name]
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
