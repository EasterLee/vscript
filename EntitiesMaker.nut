/*

	Entities Maker that returns its product in a table {string targetname = handle entity}
	EntitiesMaker.
		spawnEntity(string templateName, table KeyValues = null);
		spawnEntityAtEntityOrigin(string templateName, handle entity, table KeyValues = null);
		spawnEntityAtLocationFV(string templateName, vector location, vector direction, table KeyValues = null);
		spawnEntityAtLocation(string templateName, vector location, vector angles, table KeyValues = null);
		spawnEntityAtNamedEntityOrigin(string templateName, string targetname, table KeyValues = null);
		
	Replace ::GameStrings.enqueuePointer(temp); inside _initialize with temp.ValidateScriptScope(); if GameString.nut is not included.
*/
if("EntitiesMaker" in getroottable()){
	::EntitiesMaker.init();
	return;
}

::EntitiesMaker <- {
	templates = {},
	maker = null,
	entities = null,
	keyvalue = null,
	function _initialize(templateName){
		if(templates.rawin(templateName)){
			::Assert(templates[templateName].IsValid(), templateName + " Not Valid");
			return;
		}
		local temp = ::Entities.FindByName(null, templateName);
		::Assert(temp, templateName + " doesn't exist. FindByName returned NULL");
		templates[templateName] <- temp;
		::GameStrings.enqueuePointer(temp);
		//already validated inside GameStrings.enqueuePointer
		local ss = temp.GetScriptScope();
		ss.PostSpawn <- _PostSpawn.bindenv(this);
		ss.PreSpawnInstance <- _PreSpawn.bindenv(this);
	}
	function _PostSpawn(e){
		entities = e;
	}
	function _PreSpawn(c, n){
		if(keyvalue == null){
			return;
		}
		local sliceIndex = n.find("&");
		local preTemplateName = n.slice(0, sliceIndex != null ? sliceIndex : n.len());
		//printl(preTemplateName);
		if(preTemplateName in keyvalue){
			return keyvalue[preTemplateName];
		}
	}
	function _setKey(temp,k){
		_initialize(temp)
		keyvalue = k;
		maker.__KeyValueFromString("EntityTemplate", temp);
	}
	
	function getEntities(){
		return entities;
	}
	
	function spawnEntity(temp, k = null){ //optional keyvalue {targetname, {key, value}}
		_setKey(temp, k);
		
		maker.SpawnEntity();
		return getEntities();
	}
	function spawnEntityAtEntityOrigin(temp, e, k = null){
		_setKey(temp, k);
		
		maker.SpawnEntityAtEntityOrigin(e);
		return getEntities();
	}
	function spawnEntityAtLocationFV(temp, origin, orientation, k = null){
		_setKey(temp, k);
		
		maker.SetForwardVector(orientation);
		maker.SetOrigin(origin);
		
		maker.SpawnEntity();
		return getEntities();
	}
	function spawnEntityAtLocation(temp, origin, orientation, k = null){
		_setKey(temp, k);
		
		maker.SpawnEntityAtLocation(origin, orientation);
		return getEntities();
	}
	function spawnEntityAtNamedEntityOrigin(temp, targetname, k = null){
		_setKey(temp, k);
		
		maker.SpawnEntityAtNamedEntityOrigin(targetname);
		return getEntities();
	}
	function init(){
		if(!maker){
			maker = Entities.CreateByClassname("env_entity_maker").weakref();
			maker.__KeyValueFromString("classname", "func_brush"); //stay in between rounds
		}
		templates.clear();
	}
};
::EntitiesMaker.init();