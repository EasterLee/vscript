/*

	Listening for game event

	EventListener.initialize(listenerTemplateName, listenerName);
	
	unhook if callback returned false;
*/


if("EventListener" in getroottable()){
	return;
}

::EventListener <- {
	//UserId getter
	players = {},
	info = null,
	target = null,
	generator = null,
	
	PlayerInfo = class{
		handle = null;
		name = null;
		networkid = null;
	},
	function generateGameEvent(){
		//retrieve player from loop
		local ply = resume generator;
		if(ply == null){
			//restart the loop
			generator = getGenerator();
			EntFireByHandle(info, "RunScriptCode", "generateGameEvent();", 5.0, null, null);
			return;
		}
		target = ply;
		EntFireByHandle(info, "GenerateGameEvent", "", 0.0, ply, ply);
		/*
			onEventGenerated is fired between these two
		*/
		EntFireByHandle(info, "RunScriptCode", "generateGameEvent();", 0.0, null, null);
	}
	//loop through players
	function getGenerator(){
		for(local ply = null; ply = Entities.FindByClassname(ply, "player");){
			ply.ValidateScriptScope();
			
			//ignore player who already have userid
			if("userid" in ply.GetScriptScope()){
				continue;
			}
			yield ply;
		}
		return null;
	}
	function onEventGenerated(e){
		//event is generated after connection(before or after map change)
		if(target){
			target.GetScriptScope().userid <- e.userid;
			
			//connected before event is generated
			if(!players.rawin(e.userid)){
				players[e.userid] <- PlayerInfo();
			}
			players[e.userid].handle = target;
			printl("userid generated for: " + target);
			target = null;
			return;
		}
		//connected before event is generated
		local info = PlayerInfo();
		info.name = e.name;
		info.networkid = e.networkid;
		players[e.userid] <- info;
		
	}
	function getPlayerInfoByUserId(uid){
		if(players.rawin(uid)){
			return players[uid];
		}
		return null
	}
	function getUserIdByHandle(handle){
		//just in case
		handle.ValidateScriptScope();
		local ss = handle.GetScriptScope();
		if(ss.rawin("userid")){
			return ss.userid;
		}
		return null
	}
	
	//Event Listener
	listenerTemplateName = null,
	listenerName = null,
	listeners = {},
	player_connect = null,
	Listener = class{
		static kv = {
			Targetname = null,
			EventName = null,
			FetchEventData = 1,
			IsEnabled = 1,
			TeamNum = -1
		};
		ent = null;
		callbacks = null;
		scallbacks = null;
		eventDatas = null;
		constructor(event){		
			this.callbacks = [];
			this.scallbacks = [];
			this.eventDatas = LinkedQueue();
			kv.EventName = event;
			kv.Targetname = event;
			local keyvalue = {};
			keyvalue[EventListener.listenerName] <- kv;
			this.ent = EntitiesMaker.spawnEntity(EventListener.listenerTemplateName, keyvalue)[event];
			this.ent.ValidateScriptScope();
			local ss = ent.GetScriptScope();
			ent.__KeyValueFromString("OnEventFired", event + ",CallScriptFunction,OnEventFired,0,-1");
			ss.OnEventFired <- OnEventFired.bindenv(this);
			
			local delegation = {_newslot = newslot.bindenv(this)};
			//delete from roottable instead upon VSquirrel_OnReleaseScope
			delegate {_delslot = function(key){getroottable().rawdelete(key)}} : delegation;
			delegate delegation: ss;
		}
		function OnEventFired(){
			local data = eventDatas.dequeue();
			for(local i = callbacks.len() - 1; i >= 0; i--){
				try{
					//if callback returned false
					if(!callbacks[i](data)){
						//replace and pop
						callbacks[i] = callbacks[callbacks.len() - 1];
						callbacks.pop();
						printl("callback removed")
					}
				}catch(e){
					printl(e);
				}
			}
		}
		function newslot(k, v){
			eventDatas.enqueue(v);
			for(local i = scallbacks.len() - 1; i >= 0; i--){
				try{
					//if callback returned false
					if(!scallbacks[i](v)){
						scallbacks[i] = scallbacks[scallbacks.len() - 1];
						scallbacks.pop();
					}
				}catch(e){
					printl(e);
				}
			}
		}
	}
	function hook(event, func, sync = false){
		if(!listeners.rawin(event)){
			printl("Created logic_eventlistener for the first time: " + event);
			listeners[event] <- Listener(event);
		}
		local c =  sync ? listeners[event].scallbacks : listeners[event].callbacks;
		printl(event + " callback pushed to " + (sync ? "sync" : "async"));
		c.push(func);
	}
	function unhook(event, func, sync){
		local c =  sync ? listeners[event].scallbacks : listeners[event].callbacks;
		for(local i = c.len() - 1; i >= 0; i--){
			if(c[i] == func){
				//replace and pop
				c[i] = c[c.len() - 1];
				c.pop();
				return;
			}
		}
	}
	function unhookAll(event){
		listeners[event].callbacks.clear()
		listeners[event].scallbacks.clear()
	}
	function initialize(temp, name){
		listenerTemplateName = temp;
		listenerName = name;
		
		listeners.clear();
		
		if(!info){
			info = Entities.CreateByClassname("info_game_event_proxy").weakref();
			info.__KeyValueFromString("event_name", "player_connect");
			info.__KeyValueFromString("targetname", "info_game_event_proxy");
			info.__KeyValueFromString("classname", "func_brush");
			info.ValidateScriptScope();
			info.GetScriptScope().generateGameEvent <- generateGameEvent.bindenv(this);
		}
		//dedicate a permanent player_connect listener for getting steam id
		if(!player_connect){
			player_connect <- Listener("player_connect");
			player_connect.ent.__KeyValueFromString("classname", "func_brush");
			//hook("player_connect", onEventGenerated.bindenv(this), true);
			player_connect.scallbacks.push(onEventGenerated.bindenv(this));
		}
		generator = getGenerator();
		EntFireByHandle(info, "RunScriptCode", "generateGameEvent();", 0.0, null, null);
	}
};