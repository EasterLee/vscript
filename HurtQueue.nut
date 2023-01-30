/*
	Hoping to achieve the use of point_hurt multiple times on the same frame
	without needing or create additional point_hurts
	
	HurtQueue.enqueue(handle[] victims, int damageAmount, int damageType, handle attacker = null, string weapon = null);
*/

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
HurtQueue <- {
	pointHurt = null,
	hurtName = "hurt_player",
	defaultName = "player",
	queue = null,
	last = null,
	hurtNode = class{
		next = null;
		
		victims = null;
		
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
		if(queue == null){
			queue = node;
			last = node;
		}else{
			last.next = node;
			last = node;
		}
		//printl("Enqueued. Current size: " + size());
		EntFireByHandle(pointHurt, "Hurt", "", 0.00, attacker, null);
		EntFireByHandle(pointHurt, "RunScriptCode", "resetName()", 0.00, null, null);
	}
	function resetName(){
		local prev = dequeue();
		foreach(v in prev.victims){
			v.__KeyValueFromString("targetname", defaultName);
			//printl("name reset for: " + v);
		}
	}
	function dequeue(){
		local q = queue;
		queue = queue.next;
		if(!queue){
			last = null;
		}
		//printl("Dequeued. Current size: " + size());
		return q;
	}
	function size(){
		if(!queue){
			return 0;
		}
		local i = 0;
		local node = queue;
		while(node){
			i++;
			node = node.next;
		}
		return i;
	}
	function InputHurt(){
		foreach(v in queue.victims){
			if(v){
				v.__KeyValueFromString("targetname", hurtName);
				//printl("victims: " + v);
			}
		}
		pointHurt.__KeyValueFromInt("Damage", queue.damageAmount);
		pointHurt.__KeyValueFromInt("DamageType", queue.damageType);
		pointHurt.__KeyValueFromString("classname", queue.weapon != null ? queue.weapon : "point_hurt");
		return true;
	}
}
HurtQueue.pointHurt = Entities.CreateByClassname("point_hurt");
HurtQueue.pointHurt.__KeyValueFromString("DamageTarget", HurtQueue.hurtName);
HurtQueue.pointHurt.ValidateScriptScope();
HurtQueue.pointHurt.GetScriptScope().InputHurt <- HurtQueue.InputHurt.bindenv(HurtQueue);
HurtQueue.pointHurt.GetScriptScope().resetName <- HurtQueue.resetName.bindenv(HurtQueue);
