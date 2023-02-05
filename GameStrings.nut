/*
	Artifically dismember string from the gamestringtable
	double check with dumpgamestringtable command
	
	Require 
	point_template: 
		targetname: stringTemp
		spawnflags: "Preserve entity names" off
		template entity: something like a logic_relay
	
	GameStrings.enqueue(string str, bool low = false);
	GameStrings.enqueuePointer(entity);
*/
if("GameStrings" in getroottable()){
	GameStrings.init();
	return;
}
::GameStrings <-{
	stringTemplate = null,
	strings = [],
	stringsLowPriority = [],
	interval = 0.01,
	thinking = false,
	function init(){
		while(stringsLowPriority.len() != 0){
			strings.push(stringsLowPriority.pop());
		}
		stringTemplate = Entities.FindByName(null, "stringTemp");
		stringTemplate.ValidateScriptScope();
		stringTemplate.GetScriptScope().__ExecutePreSpawn <- __ExecutePreSpawn.bindenv(this);
		stringTemplate.GetScriptScope().PreSpawnInstance <- true;
		stringTemplate.GetScriptScope().PostSpawn <- true;

		if(strings.len()){
			EntFireByHandle(stringTemplate, "ForceSpawn", "", interval, null, null);
		}
		enqueuePointer(stringTemplate);
	}
	function __ExecutePreSpawn(ent){
		local str;
		if(strings.len()){
			str = strings.pop();
		}else{
			return false;
		}
		ent.__KeyValueFromString( "targetname", str);		
		if(strings.len()){
			EntFireByHandle(stringTemplate, "ForceSpawn", "", interval, null, null);
		}
		return false; //kill the entity
	}
	function enqueue(str, low = false){
		if(low){
			stringsLowPriority.push(str);
			return;
		}
		if(!strings.len()){
			EntFireByHandle(stringTemplate, "ForceSpawn", "", interval, null, null);
		}
		strings.push(str);
	}
	function enqueuePointer(entity){
		entity.ValidateScriptScope();
		enqueue(entity.GetScriptScope().__vname, true);
	}
	function fill(i){
		for(;i--;){
			local unique = "z " + UniqueString();
			EntFireByHandle(stringTemplate, "addoutput", unique, 0.00, null, null);
			enqueue(unique);
		}
	}
	function dump(){
		foreach(v in strings){
			printl(v);
		}
	}
}
::GameStrings.init();