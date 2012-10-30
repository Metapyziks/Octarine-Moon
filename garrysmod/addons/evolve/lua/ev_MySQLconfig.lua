MsgN("-----> Starting Evolve MySQL Plugin <-----\n")
Evolve_SQLConf = {} 
DB = {}


/*
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Evolve MySQL Config<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
>>						 Please enter the correct data here if you want to use MySQL 								  <<
>>						  REMEMBER: EVOLVE ONLY USES MYSQLOO FOR MYSQL CONNECTIONS! 								  <<
>>									 Otherwise Evolve will use SQLite... 											  <<
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*/

Evolve_SQLConf.EnableMySQL = true 
Evolve_SQLConf.Host = "127.0.0.1" 
Evolve_SQLConf.Username = "changeme" 			
Evolve_SQLConf.Password = "changeme" 	
Evolve_SQLConf.Database_name = "evolve" 
Evolve_SQLConf.Database_port = 3306



if file.Exists("includes/modules/gmsv_mysqloo.dll", "LUA") or file.Exists("includes/modules/gmsv_mysqloo_i486.so", "LUA") or file.Exists("includes/modules/gmsv_mysqloo_i486.dll", "LUA") then
	MsgN("MySqlOO files found, trying to include them!\n")
	require("mysqloo")
end

local CONNECTED_TO_MYSQL = false
DB.MySQLDB = nil

function DB.Begin()
	if not CONNECTED_TO_MYSQL then sql.Begin() end
end
function DB.Commit()
	if not CONNECTED_TO_MYSQL then sql.Commit() end
end

function DB.Query(query, callback)
	if CONNECTED_TO_MYSQL then 
		if DB.MySQLDB and DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED then
			DB.ConnectToMySQL(Evolve_SQLConf.Host, Evolve_SQLConf.Username, Evolve_SQLConf.Password, Evolve_SQLConf.Database_name, Evolve_SQLConf.Database_port)
		end
		
		local query = DB.MySQLDB:query(query)
		local data
		query.onData = function(Q, D)
			data = data or {}
			data[#data + 1] = D
		end
		
		query.onError = function(Q, E) Error(E) callback()  end
		query.onSuccess = function()
			if callback then callback(data) end 
		end
		query:start()
		return
	end
	sql.Begin()
	local Result = sql.Query(query)
	sql.Commit()
	if callback then callback(Result) end
	return Result
end

function DB.QueryValue(query, callback)
	if CONNECTED_TO_MYSQL then
		if DB.MySQLDB and DB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED then
			DB.ConnectToMySQL(Evolve_SQLConf.Host, Evolve_SQLConf.Username, Evolve_SQLConf.Password, Evolve_SQLConf.Database_name, Evolve_SQLConf.Database_port)
		end
		
		local query = DB.MySQLDB:query(query)
		local data
		query.onData = function(Q, D)
			data = D
		end
		query.onSuccess = function()
			for k,v in pairs(data or {}) do
				callback(v)
				return
			end
			callback()
		end
		query.onError = function(Q, E) Error(E) callback() end
		--DB.Log("MySQL Error: ".. E)
		query:start()
		return
	end
	callback(sql.QueryValue(query))
end
function DB.Init()
	DB.Begin()
		DB.Query("CREATE TABLE IF NOT EXISTS `evolve_bans` (`uid` bigint(255) NOT NULL,`steamid` varchar(255) NOT NULL,`ip` varchar(255),`lenght` bigint(255),`banend` bigint(255),`reason` varchar(255) NOT NULL,`admin` bigint(255) NOT NULL,`nick` varchar(255) NOT NULL);")
		/* Disabled because of some failures
		DB.Query("CREATE TABLE IF NOT EXISTS `evolve_Ranks` (`rank` varchar(255),`usergroup` varchar(255),`title` varchar(255),`Privileges` varchar(10000),`colorr` int(11),`colorg` int(11),`colorb` int(11),`immunity` int(11),`icon` varchar(255),`readonly` varchar(255),`notremoveable` varchar(255))")
		DB.Query("CREATE TABLE IF NOT EXISTS `evolve_players` (`SteamID` varchar(255) NOT NULL,`playtime` bigint(30),`lastjoin` bigint(30),`ip` varchar(255) NOT NULL,`rank` varchar(255) NOT NULL);")*/
	DB.Commit()
end
function DB.ConnectToMySQL(host, username, password, database_name, database_port)
	if not mysqloo then
		MsgN("MySQL modules aren't installed properly!\n")
		MsgN("Continuing with SQlite...\n")
		CONNECTED_TO_MYSQL = false
		DB.Init()
	else
		MsgN("----->Establishing connection to Database "..host.."\n")
		local databaseObject = mysqloo.connect(host, username, password, database_name, database_port)
		
		databaseObject.onConnectionFailed = function(msg)
			MsgN("MySQL Error: Connection failed! "..tostring(msg).."\n")
			MsgN("Continuing with SQlite...\n")
		end
		
		databaseObject.onConnected = function()
			CONNECTED_TO_MYSQL = true
			MsgN("-----> Evolve MySQL Plugin Initialized! <-----")
			DB.Init() 
		end
		databaseObject:connect() 
		DB.MySQLDB = databaseObject
	end
end
DB.ConnectToMySQL(Evolve_SQLConf.Host, Evolve_SQLConf.Username, Evolve_SQLConf.Password, Evolve_SQLConf.Database_name, Evolve_SQLConf.Database_port)