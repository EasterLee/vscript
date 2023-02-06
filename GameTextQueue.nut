/*
	Same as HurtQueue
	
	GameTextQueue.enqueue(String message, Template FadeTemplate/ScanTemplate);
*/
if("GameTextQueue" in getroottable()){
	::GameTextQueue.init();
	return;
}
::GameTextQueue <- {
	gameText = null, //entity handle
	queue = null, //queue
	last = null, //last node in the queue
	n = 0, //size of the queue
	textNode = class{
		next = null;
		message = null;
		template = null;
		constructor(message, template){
			this.message = message;
			this.template = template;
		}
	},
	FadeTemplate = class{		
		x = -1;
		y = -1;
		color = null;
		fadein = null;
		fadeout = null;
		holdtime = null;
		channel = null;	
		constructor(x, y, color, fadein, fadeout, holdtime, channel){
			this.x = x;
			this.y = y;
			this.color = color;
			this.channel = channel;
			
			this.fadein = fadein;
			this.fadeout = fadeout;
			this.holdtime = holdtime;
		}
		function setKeyValues(ent){
			ent.__KeyValueFromFloat("effect", 0);
			
			ent.__KeyValueFromFloat("x", x);
			ent.__KeyValueFromFloat("y", y);
			ent.__KeyValueFromVector("color", color);
			ent.__KeyValueFromInt("channel", channel);
			
			ent.__KeyValueFromFloat("fadein", fadein);
			ent.__KeyValueFromFloat("fadeout", fadeout);
			ent.__KeyValueFromFloat("holdtime", fadeout);
		}
	},	
	ScanTemplate = class{
		x = -1;
		y = -1;
		color = null;
		color2 = null;
		fxtime = null;
		channel = null;
		constructor(x, y, color, color2, fxtime, channel){
			this.x = x;
			this.y = y;
			this.color = color;
			this.channel = channel;
			
			this.color2 = color2;
			this.fxtime = fxtime;
		}
		function setKeyValues(ent){
			ent.__KeyValueFromFloat("effect", 2);
			
			ent.__KeyValueFromFloat("x", x);
			ent.__KeyValueFromFloat("y", y);
			ent.__KeyValueFromVector("color", color);
			ent.__KeyValueFromInt("channel", channel);
			
			ent.__KeyValueFromFloat("color2", fadein);
			ent.__KeyValueFromFloat("fxtime", fadeout);
		}
	},
	function enqueue(player, message, template){
		local node = textNode(message, template);
		if(queue == null){
			queue = node;
			last = node;
		}else{
			last.next = node;
			last = node;
		}
		n++;
		//printl("Enqueued. Current size: " + size());
		//change keyvalues right before the text is displayed
		EntFireByHandle(gameText, "RunScriptCode", "setKeyValues();", 0.00, null, null);
		EntFireByHandle(gameText, "Display", "", 0.00, player, null);
	}
	function setKeyValues(){
		local node = dequeue();
		gameText.__KeyValueFromString("message", node.message);  
		node.template.setKeyValues(gameText);
	}
	function dequeue(){
		local q = queue;
		queue = queue.next;
		if(!queue){
			last = null;
		}
		n--;
		//printl("Dequeued. Current size: " + size());
		return q;
	}
	function size(){
		return n;
	}
	function init(){
		if(gameText){
			return;
		}
		gameText = Entities.CreateByClassname("game_text").weakref();
		gameText.__KeyValueFromString("classname", "func_brush");
		gameText.ValidateScriptScope();
	}
};
::GameTextQueue.init();
