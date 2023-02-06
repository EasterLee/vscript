/*
	Better Player Angles
*/


if ("PlayerAngles" in getroottable()){
	return;
}
::PlayerAngles <- {	
	eyeTable = {},
	//Angles
	function eyeAngles(ply){
		return eyeTable[ply].GetAngles();
	}
	//ForwardVector
	function eyeFV(ply){ //same as getEye(ph).getForwardVector();
		return eyeTable[ply].GetForwardVector();
	}
	//Whether a player has a measure movement attached
	function hasEye(ply){
		if (!eyeTable.rawin(ply)){
			return false;
		}
		return eyeTable[ply] != null;
	}
	//Spawn measure movement for a player
	function makeEye(ply){			
		local handle = Entities.CreateByClassname("logic_measure_movement");
		handle.ValidateScriptScope();
		local name = handle.GetScriptScope().__vname;
		
		ply.ValidateScriptScope();
		local plyName = ply.GetScriptScope().__vname;
		ply.__KeyValueFromString( "targetname", plyName);
		
		handle.__KeyValueFromString( "targetname", name);
		handle.__KeyValueFromString( "classname", "func_brush");
		handle.__KeyValueFromString( "MeasureReference", name);
		handle.__KeyValueFromString( "MeasureTarget", name);
		handle.__KeyValueFromInt( "MeasureType", 1);
		handle.__KeyValueFromString( "Target", name);
		handle.__KeyValueFromString( "TargetReference", name);
		handle.__KeyValueFromInt( "TargetScale", 1);
		
		EntFireByHandle(handle, "SetMeasureTarget", plyName, 0.00, null, null);
		EntFireByHandle(handle, "SetTarget", name, 0.00, null, null);
		EntFireByHandle(handle, "SetMeasureReference", name, 0.00, null, null);
		EntFireByHandle(handle, "Enable", "", 0.00, null, null);
		eyeTable[ply] <- handle.weakref();
	}
	//Entity handle of measure movement
	function getEye(ply){
		return eyeTable[ply];
	}
	//Destroy
	function delEye(ply){
		::GameStrings.enqueuePointer(eyeTable[ply]);
		eyeTable[ply].destroy();
		delete eyeTable[ply];
	}
};