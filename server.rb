require 'sinatra'
require 'pg'
require 'bcrypt'

set server: 'thin'
enable :sessions

$db = PGconn.open("ec2-54-204-43-138.compute-1.amazonaws.com", 5432, "", "", "deia47rhsmpbi8", "gxhlypbwsapuqu", "MlcweE_dk0Zn2TOXyU5aBhmwml")
$db.exec('CREATE TABLE IF NOT EXISTS Users(Name TEXT PRIMARY KEY, Salt TEXT, Hash TEXT, Bucks INTEGER)')

$bucks_min = 50

$playerbets = {}
$bets = [0,0]
$odds = [1,1]
$playerstats = {}

$players = ["Player 1", "Player 2"]
$betting = false

connections = []

get '/' do
	$locked = true
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
		salt = a.getvalue(0,1)
		if a.getvalue(0,2) == BCrypt::Engine.hash_secret(params[:password], salt)
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
	session[:lastbet] = 0
	redirect "/"
end

get '/admin' do
	erb :admin
end

post '/admin' do
	if params[:winner] == "1" or params[:winner] == "2"
		for bet in $playerbets
			if bet[1][0].to_i == params[:winner].to_i-1
				$db.exec("UPDATE Users SET Bucks = Bucks + #{(($bets[0]+$bets[1]).to_f / $bets[bet[1][0].to_i] * bet[1][1].to_i).truncate} WHERE Name = \'#{bet[0]}\'")
			else
				$db.exec("UPDATE Users SET Bucks = Bucks - #{bet[1][1]} WHERE Name = \'#{bet[0]}\'")
			end
		end

		$odds = [1,1]
		$bets = [0,0]
	end

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
	connections.each { |out| out << "data: {\"refresh\":1}\n\n"}
	erb :admin
end

get '/refresh', provides: 'text/event-stream' do
	stream :keep_open do |out|
		connections << out

		out.callback {
    	connections.delete(out)
    }
	end
end
