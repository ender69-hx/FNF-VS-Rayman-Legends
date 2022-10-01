package external;

#if desktop
import Sys.sleep;
import discord_rpc.DiscordRpc;
#end

import grafex.system.log.GrfxLogger;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

using StringTools;

class DiscordClient
{
    #if desktop
        public static var isInitialized:Bool = false;
	    public function new()
	    {
	    	DiscordRpc.start({
	    		clientID: "885223855327698985",
	    		onReady: onReady,
	    		onError: onError,
	    		onDisconnected: onDisconnected
	    	});
    
	    	while (true)
	    	{
	    		DiscordRpc.process();
	    		sleep(2);
	    	}
    
	    	DiscordRpc.shutdown();
	    }
	    
	    public static function shutdown()
	    {
	    	DiscordRpc.shutdown();
	    }
	    
	    static function onReady()
	    {
	    	DiscordRpc.presence({
	    		details: "The Menu",
	    		state: null,
	    		largeImageKey: 'discordlogo',
	    		largeImageText: "Grafex Engine"
	    	});
	    }
    
	    static function onError(_code:Int, _message:String)
	    {
	    	GrfxLogger.log('Warning', '$_message');
	    }
    
	    static function onDisconnected(_code:Int, _message:String)
	    {
	    	GrfxLogger.log('warning', '$_code : $_message');
	    }
    
	    public static function initialize()
	    {
	    	var DiscordDaemon = sys.thread.Thread.create(() ->
	    	{
	    		new DiscordClient();
	    	});
	    	GrfxLogger.log('info', "Discord Client initialized");
            isInitialized = true;
	    }
    
	    public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?smallImageText:String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	    {
	    	var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;
    
	    	if (endTimestamp > 0)
	    	{
	    		endTimestamp = startTimestamp + endTimestamp;
	    	}
    
	    	DiscordRpc.presence({
	    		details: details,
	    		state: state,
	    		largeImageKey: 'discordlogo',
	    		largeImageText: "Grafex v " + grafex.data.EngineData.grafexEngineVersion,
	    		smallImageKey : smallImageKey,
                smallImageText : smallImageText,
	    		// Obtained times are in milliseconds so they are divided so Discord can use it
	    		startTimestamp : Std.int(startTimestamp / 1000),
                endTimestamp : Std.int(endTimestamp / 1000)
	    	});
	    }
    
	    #if LUA_ALLOWED
	    public static function addLuaCallbacks(lua:State) {
	    	Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?smallImageText:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
	    		changePresence(details, state, smallImageKey, smallImageText, hasStartTimestamp, endTimestamp);
	    	});
	    }
	    #end
    #end
}
