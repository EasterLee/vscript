/*
	LinkedQueue: first in first out
*/
if("LinkedQueue" in getroottable()){
	return;
}

::LinkedQueue <- class{    
	static Node = class{
        item = null;
        next = null;
        constructor(){}
    };
    first = null;
    last = null;
	n = 0;
    constructor() {}
    function isEmpty() {
        return this.n == 0;
    }
    function size() {
        return this.n;
    }
    function enqueue(item) {
        local oldlast = this.last;
        this.last = Node();
        this.last.item = item;
        this.last.next = null;
        if (this.isEmpty()) {
            this.first = this.last;
        } else {
            oldlast.next = this.last;
        }

        ++this.n;
    }
	//return the item at the front of this queue
    function peek() {
        Assert(!this.isEmpty(), "Queue is empty");
        return this.first.item;
    }
	//remove and return the item at the front of this queue
    function dequeue() {
        Assert(!this.isEmpty(), "Queue is empty");
		local item = this.first.item;
		this.first = this.first.next;
		--this.n;
		if (this.isEmpty()) {
			this.last = null;
		}
		return item;
    }
    function _tostring() {
        local sb = "";
        foreach(v in this.iterator()) {
            sb += v.item;
            sb += ", ";
        }

        return this.n > 0 ? "[" + sb.slice(0, sb.length() - 2) + "]" : "[]";
    }
	function iterator(){
		local node = first;
		while(node != null){
			yield node.item;
			node = node.next;
		}
	}
}