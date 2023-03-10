/*
	Hoping to achieve the use of point_hurt multiple times on the same frame
	without needing or creating additional point_hurts
	
	HurtQueue.enqueue(handle[] victims, int damageAmount, int damageType, handle attacker = null, string weapon = null);
*/
if("HurtQueue" in getroottable()){
	::HurtQueue.init();
	return;
}

enum DMG_TYPE {
	GENERIC = 0 
	CRUSH = 1
	BULLET = 2
	SLASH = 4
	BURN = 8
	VEHICLE = 16
	FALL = 32
	BLAST = 64
	CLUB = 128
	SHOCK = 256
	SONIC = 512
	ENERGYBEAM = 1024
	DROWN = 16384
	PARALYSE = 32768
	NERVEGAS = 65536
	POISON = 131072
	RADIATION = 262144
	DROWNRECOVER = 524288
	ACID = 1048576
	SLOWBURN = 2097152
	REMOVENORAGDOLL = 4194304
}
::HurtQueue <- {
	pointHurt = null, //entity handle
	hurtName = "hurt_player", //set victims targetname to this before hurt
	defaultName = "player", //set victims targetname to this after hurt
	queue = [],
	hurtNode = class{ //should have used LinkedQueue.nut
		next = null;
		
		victims = null; //array of player handle
		
		damageAmount = null;
		damageType = null;
		
		weapon = null;
		constructor(v, da, dt, i){
			this.victims = v;
			this.damageAmount = da;
			this.damageType = dt;
			this.weapon = i;
		}
	},
	function enqueue(victims, damageAmount, damageType, attacker = null, weapon = null){
		local node = hurtNode(victims, damageAmount, damageType, weapon);
		queue.push(node);
		//printl("Enqueued. Current size: " + size());
		EntFireByHandle(pointHurt, "Hurt", "", 0.00, attacker, null);
		EntFireByHandle(pointHurt, "RunScriptCode", "resetName()", 0.00, null, null);
	}
	//execute right after hurt
	function resetName(){
		local prev = queue.remove(0); //should be fine as long queue size doesn't exceed 10k.
		foreach(v in prev.victims){
			v.__KeyValueFromString("targetname", defaultName);
			//printl("name reset for: " + v);
		}
	}
	function size(){
		return n;
	}
	//execute right before hurt
	function InputHurt(){
		local node = queue[0];
		foreach(v in node.victims){
			if(v){
				v.__KeyValueFromString("targetname", hurtName);
				//printl("victims: " + v);
			}
		}
		pointHurt.__KeyValueFromInt("Damage", node.damageAmount);
		pointHurt.__KeyValueFromInt("DamageType", node.damageType);
		pointHurt.__KeyValueFromString("classname", node.weapon != null ? node.weapon : "point_hurt");
		return true;
	}
	function init(){
		if(pointHurt){
			return;
		}
		pointHurt = Entities.CreateByClassname("point_hurt").weakref();
		pointHurt.__KeyValueFromString("DamageTarget", HurtQueue.hurtName);
		pointHurt.__KeyValueFromString("classname", "func_brush");
		pointHurt.ValidateScriptScope();
		pointHurt.GetScriptScope().InputHurt <- HurtQueue.InputHurt.bindenv(HurtQueue);
		pointHurt.GetScriptScope().resetName <- HurtQueue.resetName.bindenv(HurtQueue);
		
		queue = [];
	}
}
::HurtQueue.init();
