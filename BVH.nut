
::min <- function(a, b){
	return a > b ? b : a;
};
::max <- function(a, b){
	return a < b ? b : a;
};

::clamp <- function(a, lower, upper){
	if(lower > a)return lower;
	if(upper < a)return upper;
	return a;
};

::inRange <- function(a, lower, upper){
	return lower <= a && a <= upper;
};

::swap <- function(arr, i, j){
	local o = arr[i];
	arr[i] = arr[j];
	arr[j] = o;
}

::BVH <- class{
	nodes = null;
	nodesUsed = 1;
	_objs = null; //actual object
	objs = null; //_objs index
	colors = null;
	data = {
		nodeIntersected = 0,
	
	};
	static Node = class{
		bbox = null;
		leftNode = null; //index to leftNode or first object idx (if objCount != 0)
		objCount = null;
		constructor(){}
		function isLeaf(){
			return objCount > 0;
		}
	}
	constructor(_objs){
		nodes = [];
		colors = [];
		this._objs = _objs;
		this.objs = [];
		for(local i = 0; i < this._objs.len(); i++){
			this.objs.push(i);
		}
		nodes.push(Node());
		local root = nodes[0];
		root.leftNode = 0; 
		root.objCount = this.objs.len();
		
		updateNodeBounds();
		subdivide();
		
		printl("Finished Generating BVH. # of Nodes: " + nodesUsed);
	}
	//fit the aabb to the objects inside the node
	function updateNodeBounds(nodeIdx = 0){
		local node = nodes[nodeIdx];
		local mins = Vector(99999, 99999, 99999);
		local maxs = Vector(-99999, -99999, -99999);
		//printl("updateNodeBounds for Node #" + nodeIdx);
		//printl("Creating bound for objects between index " + node.leftNode + " and " + node.objCount);
		//for each object
		for(local i = node.leftNode; i < node.leftNode + node.objCount; i++){
			local obj = _objs[objs[i]].bbox();
			local oMins = obj.mins();
			local oMaxs = obj.maxs();
			//for aabb type
			//x
			mins.x = min(mins.x, oMins.x);
			mins.y = min(mins.y, oMins.y);
			mins.z = min(mins.z, oMins.z);
			
			maxs.x = max(maxs.x, oMaxs.x);
			maxs.y = max(maxs.y, oMaxs.y);
			maxs.z = max(maxs.z, oMaxs.z);
		}
		local center = (maxs + mins) * 0.5;
		node.bbox = AABB(center, maxs - center);
		local size = node.bbox.size();
		//printl(format("Bound size: %f x %f x %f", size.x, size.y, size.z));
	}
	function subdivide(nodeIdx = 0, layer = 0){
		local node = nodes[nodeIdx];
		//printl("subdividing node #" + nodeIdx);
		if(colors.len() < layer + 1){
			colors.push(Vector(RandomInt(0, 255), RandomInt(0, 255), RandomInt(0, 255)));
		}
		if(node.objCount <= 2){
			//printl("returned node.objCount <= 2");
			return;
		}
		//split longest axis
		local axisLength = node.bbox.size();
		local axis = "x";
		if(axisLength.y > axisLength.x){
			axis = "y";
		}
		if(axisLength.z > axisLength[axis]){
			axis = "z";
		}
		//printl("pos splited on axis " + axis);
		//printl("axisLength: " + axisLength[axis]);
		local splitPos = node.bbox.getCenter()[axis];
		//printl("splitPos: " + splitPos);
		//printl("node.bbox.center(): " + node.bbox.center());
		
		//swap obj on the left side of the splitPos to the left of array
		local i = node.leftNode;
		local j = i + node.objCount - 1;
		while(i <= j){
			if(this._objs[this.objs[i]].getCenter()[axis] < splitPos){
				//printl("to left");
				i++
			}else{
				//printl("to right");
				swap(this.objs, i, j);
				j--;
			}
		}
		
		//obj on the splitpos - first obj idx
		//number of objs on the left side of the splitPos
		local leftCount = i - node.leftNode;
		if (leftCount == 0 || leftCount == node.objCount){
			//printl("returned leftCount == 0");
			//printl("i: " + i);
			//printl("node.leftNode: " + node.leftNode);
			return;
		}
		//printl("nodes splitted at index " + i);
		local leftChildIdx = nodesUsed++;
		local rightChildIdx = nodesUsed++;
		nodes.push(Node());
		nodes.push(Node());
		nodes[leftChildIdx].leftNode = node.leftNode; //first object idx
		//printl("Node #" + (nodesUsed - 2) + " has " + leftCount + " objs");
		nodes[leftChildIdx].objCount = leftCount;
		nodes[rightChildIdx].leftNode = i; //first object idx
		//printl("Node #" + (nodesUsed - 1) + " has " + (node.objCount - leftCount) + " objs");
		nodes[rightChildIdx].objCount = node.objCount - leftCount;
		
		node.leftNode = leftChildIdx; //index to leftNode
		node.objCount = 0;
		
		updateNodeBounds(leftChildIdx);
		updateNodeBounds(rightChildIdx);
		
		subdivide(leftChildIdx, layer + 1);
		subdivide(rightChildIdx, layer + 1);
	}
    function draw(nodeIdx, layer, alpha, duration) {
		local node = nodes[nodeIdx];
		node.bbox.draw(colors[layer], alpha, duration);
		if(!node.isLeaf()){
			draw(node.leftNode, layer + 1, alpha, duration);
			draw(node.leftNode + 1, layer + 1, alpha, duration);
		}
    }   
	function drawNode(nodeIdx, color, alpha, duration){
		local node = nodes[nodeIdx];
		node.bbox.draw(color, alpha, duration);
	}
	function drawLayer(layer, alpha, duration){
		_drawLayer(layer, 0, 0, alpha, duration);
	}
	function _drawLayer(level, nodeIdx, layer, alpha, duration){
		if(nodeIdx > nodes.len() || layer > level){
			return;
		}
		local node = nodes[nodeIdx];
		if(layer == level){
			node.bbox.draw(Vector(0,255,0), alpha, duration);
		}
		if(!node.isLeaf()){
			_drawLayer(level, node.leftNode, layer + 1, alpha, duration);
			_drawLayer(level, node.leftNode + 1, layer + 1, alpha, duration);
		}
    }
	function intersect(object, arr){
		_intersect(object, 0, arr);
		return arr;
	}
	function _intersect(object, nodeIdx, arr){
		local node = nodes[nodeIdx];
		if(Collision.intersect(object, node.bbox)){
			if(node.isLeaf()){
				//node.bbox.draw(Vector(0,255,0), 50, 0);
				for(local i = node.leftNode; i < node.leftNode + node.objCount; i++){
					arr.push(objs[i]);
				}
				return;
			}
			_intersect(object, node.leftNode, arr);
			_intersect(object, node.leftNode + 1, arr);
		}
	}
	function resetData(){
		data.nodeIntersected = 0;
	}
	//generate a n*n*n 
	static function buildTest(origin, gap, length, n){
		local gapAndLength = gap + length;
		local halfLength = length/2.0;
		local arr = [];
		local halfTotalLength = (n * length + (n - 1) * gap)/2;
		for(local i1 = 0; i1 < n; i1++){
			local x = i1 * gapAndLength - halfTotalLength;
			for(local i2 = 0; i2 < n; i2++){
				local y = i2 * gapAndLength - halfTotalLength;
				for(local i3 = 0; i3 < n; i3++){
					local z = i3 * gapAndLength - halfTotalLength;
					local cubeOrigin = origin + Vector(x + RandomInt(-10, 10), y+ RandomInt(-10, 10), z+ RandomInt(-10, 10));
					local halfSize = Vector(halfLength, halfLength, halfLength);
					arr.push(AABB(cubeOrigin-halfSize, cubeOrigin+halfSize));
				}
			}
		}
		return BVH(arr);
	}
}
::Collision <- {
	function pointVPoint(p1, p2){
		return !(p1.x != p2.x || p1.y != p2.y || p1.z != p2.z);
	},
	function pointVLine(p, line){
		return (line.start - line.end).LengthSqr() == (p - line.start).LengthSqr() + (p - line.end).LengthSqr();
	},
	function pointVAABB(p, aabb){
		local min = aabb.mins();
		local max = aabb.maxs();
		//printl("x");
		if(p.x < min.x || p.x > max.x) return false;
		//printl("y");
		if(p.y < min.y || p.y > max.y) return false;
		//printl("z");
		if(p.z < min.z || p.z > max.z) return false;
		//printl("done");
		return true;
	},
	function pointVPlane(p, plane){
		//if displacement is perpendicular to normal
		return inRange(plane.normal.Dot(plane.point - p), -0.01, 0.01);
	},
	function pointVSphere(p, sphere){
		return (sphere.center - p).LengthSqr() < sphere.radiusSqr;
	},
	function pointVOBB(vec, obb){
		//DebugDrawBox((obb.aabb.center + obb.toLocal(vec)), Vector(-1,-1,-1), Vector(1,1,1), 255, 0, 0, 255, 0);
		//obb.aabb.draw(Vector(255,255,255), 10, 0);
		return pointVAABB(obb.aabb.center + obb.toLocal(vec), obb.aabb);
	},
	function lineVPoint(line, point){
		return pointVLine(point, line);
	},
	function lineVLine(line1, line2){
		return _doIntersect(line1.start, line1.end, line2.start, line2.end);
	},
	function lineVPlane(line, plane){
		return inRange((plane.point - line.start).Dot(plane.normal)/(line.end - line.start).Dot(plane.normal), 0, 1);
	},
	function lineVAABB(line, aabb){
		local min = aabb.mins();
		local max = aabb.maxs();
		
		local lineLength = 1 / (line.end.x - line.start.x);

		local xtmin = (min.x - line.end.x) * lineLength;
		local xtmax = (max.x - line.end.x) * lineLength;
		
		if(xtmax < xtmin){
			local t = xtmax;
			xtmax = xtmin;
			xtmin = t;
		}

		lineLength = 1 / (line.end.y - line.start.y);
		local ytmin = (min.y - line.end.y) * lineLength;
		local ytmax = (max.y - line.end.y) * lineLength;
		
		if(ytmax < ytmin){
			local t = ytmax;
			ytmax = ytmin;
			ytmin = t;
		}

		if(ytmin > xtmax || ytmax < xtmin) {
			return null;
		} else {
			ytmin = ytmin > xtmin ? ytmin : xtmin;
			ytmax = ytmax > xtmax ? xtmax : ytmax;
		}

		lineLength = 1 / (line.end.z - line.start.z);
		xtmin = (min.z - line.end.z) * lineLength;
		xtmax = (max.z - line.end.z) * lineLength;
		
		if(xtmax < xtmin){
			local t = xtmax;
			xtmax = xtmin;
			xtmin = t;
		}
		if(ytmin > xtmax || ytmax < xtmin) {
			return null;
		} else {
			xtmin = ytmin > xtmin ? ytmin : xtmin;
			xtmax = ytmax > xtmax ? xtmax : ytmax;
		}
		return (xtmin < 0 || xtmax > 1);
	},
	function lineVOBB(line, obb){
		return lineVAABB(Line(obb.aabb.center + obb.toLocal(line.start), obb.aabb.center + obb.toLocal(line.end)), obb.aabb);
	},
	function lineVSphere(line, sphere){
		return pointVSphere(line.closestPoint(sphere.center), sphere);
	},
	function planeVPoint(plane, p){
		return pointVPlane(p, plane);
	},
	function planeVLine(plane, line){
		return lineVPlane(line, plane);
	},
	function planeVPlane(plane1, plane2){
		return inRange(fabs(plane1.normal.Dot(plane2.normal)), 0.99, 1.01);
	},
	function planeVAABB(plane, aabb){
		local e = aabb.extent;
		local n = plane.normal;

		// Compute the projection interval radius of b onto L(t) = b.c + t * p.n
		local r = e.x*abs(n.x) + e.y*abs(n.y) + e.z*abs(n.z);

		// Compute distance of box center from plane
		local s = n.Dot(aabb.center - plane.point);

		// Intersection occurs when distance s falls within [-r,+r] interval
		return abs(s) <= r;
	},
	function planeVOBB(plane, obb){
		return planeVAABB(Plane(obb.aabb.center + obb.toLocal(plane.point), obb.toLocal(obb.aabb.center + plane.normal)), obb.aabb);
	},
	function planeVSphere(plane, sphere){
		return pointVSphere(plane.closestPoint(sphere.center), sphere);
	},
	function AABBVPoint(aabb, vec){
		return pointVAABB(vec, aabb);
	},
	function AABBVLine(aabb, line){
		return lineVAABB(line, aabb);
	},
	function AABBVPlane(aabb, plane){
		return planeVAABB(plane, aabb);
	},
	function AABBVAABB(aabb1, aabb2){
		local mins = aabb1.mins();
		local maxs = aabb1.maxs();
		local _mins = aabb2.mins();
		local _maxs = aabb2.maxs();
		if(maxs.x < _mins.x || _maxs.x < mins.x) return false;
		if(maxs.y < _mins.y || _maxs.y < mins.y) return false;
		if(maxs.z < _mins.z || _maxs.z < mins.z) return false;
		return true
	},
	function AABBVOBB(aabb, obb){
		//obb against aabb
		local obbPoints = obb.absPoints();
		local aabbPoints = aabb.absPoints();
		
		foreach(v in aabb.worldVectors){
			if(_axisGapExist(v, obbPoints, aabbPoints)) {
				//printl(v);
				return false;
			}
		}		
		foreach(v in obb.worldVectors){
			if(_axisGapExist(v, obbPoints, aabbPoints)) {
				//printl(v);
				return false;
			}
		}		
		foreach(v1 in aabb.worldVectors){
			foreach(v2 in obb.worldVectors){
				if(_axisGapExist(v1.Cross(v2), obbPoints, aabbPoints)) {
					//printl(v1.Cross(v2));
					return false;
				}
			}	
		}	
		return true;
	},
	function _axisGapExist(axis, points1, points2){
		local min1 = 99999;
		local max1 = -99999;
		local min2 = 99999;
		local max2 = -99999;
		
		foreach(v in points1){
			local dot = axis.Dot(v);
			min1 = min(min1, dot);
			max1 = max(max1, dot);
		}		
		foreach(v in points2){
			local dot = axis.Dot(v);
			min2 = min(min2, dot);
			max2 = max(max2, dot);
		}
		// printl(min1);
		// printl(max1);
		// printl(min2);
		// printl(max2);
		return (min1 > max2 || min2 > max1);
	}
	function AABBVSphere(aabb, sphere){
		return pointVSphere(aabb.closestPoint(sphere.center), sphere);
	},
	function OBBVPoint(obb, point){
		return pointVOBB(point, obb);
	},
	function OBBVLine(obb, line){
		return lineVOBB(line, obb);
	},
	function OBBVPlane(obb, plane){
		return planeVOBB(plane, obb);
	},
	function OBBVAABB(obb, aabb){
		return AABBVOBB(aabb, obb);
	},
	function OBBVOBB(obb1, obb2){
		local obbPoints = obb1.absPoints();
		local aabbPoints = obb2.aabb.absPoints();
		foreach(k, v in obbPoints){
			obbPoints[k] = obb2.aabb.toWorld(obb2.toLocal(v));
		}
		local newAxis = [
			OBB.Ax(obb2.localVectors, obb1.worldVectors[0]),
			OBB.Ax(obb2.localVectors, obb1.worldVectors[1]),
			OBB.Ax(obb2.localVectors, obb1.worldVectors[2])
		];
		foreach(v in obb2.aabb.worldVectors){
			if(_axisGapExist(v, obbPoints, aabbPoints)) {
				//print("aabb: ");
				//printl(v);
				return false;
			}
		}		
		foreach(v in newAxis){
			if(_axisGapExist(v, obbPoints, aabbPoints)) {
				//printl(v);
				return false;
			}
		}		
		foreach(v1 in obb2.aabb.worldVectors){
			foreach(v2 in newAxis){
				if(_axisGapExist(v1.Cross(v2), obbPoints, aabbPoints)) {
					//printl(v1.Cross(v2));
					return false;
				}
			}	
		}	
		return true;
	},
	function OBBVSphere(obb, sphere){
		return pointVSphere(obb.closestPoint(sphere.center), sphere);
	},
	function sphereVPoint(sphere, point){
		return pointVSphere(point, sphere);
	},
	function sphereVLine(sphere, line){
		return lineVSphere(line, sphere);
	},
	function sphereVPlane(sphere, plane){
		return planeVSphere(plane, sphere);
	},
	function sphereVAABB(sphere, aabb){
		return AABBVSphere(aabb, sphere);
	},
	function sphereVOBB(sphere, obb){
		return OBBVSphere(obb, sphere);
	},
	function sphereVSphere(sphere1, sphere2){
		return (sphere1.center - sphere2.center).LengthSqr() < pow(sphere1.radius + sphere2.radius, 2);
	},
	// Given three collinear points p, q, r, the function checks if
	// point q lies on line segment 'pr'
	function _onSegment(p, q, r){
		return (q.x <= min(p.x, r.x) && q.x >= min(p.x, r.x) && q.y <= min(p.y, r.y) && q.y >= min(p.y, r.y));
	},
	function _doIntersect(p1, q1, p2, q2){
		// Find the four orientations needed for general and
		// special cases
		local o1 = _orientation(p1, q1, p2);
		local o2 = _orientation(p1, q1, q2);
		local o3 = _orientation(p2, q2, p1);
		local o4 = _orientation(p2, q2, q1);
	  
		// General case
		if (o1 != o2 && o3 != o4)
			return true;
	  
		// Special Cases
		// p1, q1 and p2 are collinear and p2 lies on segment p1q1
		if (o1 == 0 && _onSegment(p1, p2, q1)) return true;
	  
		// p1, q1 and q2 are collinear and q2 lies on segment p1q1
		if (o2 == 0 && _onSegment(p1, q2, q1)) return true;
	  
		// p2, q2 and p1 are collinear and p1 lies on segment p2q2
		if (o3 == 0 && _onSegment(p2, p1, q2)) return true;
	  
		// p2, q2 and q1 are collinear and q1 lies on segment p2q2
		if (o4 == 0 && _onSegment(p2, q1, q2)) return true;
	  
		return false; // Doesn't fall in any of the above cases
	},
	// To find orientation of ordered triplet (p, q, r).
	// The function returns following values
	// 0 --> p, q and r are collinear
	// 1 --> Clockwise
	// 2 --> Counterclockwise
	function _orientation (p, q, r){
		// See https://www.geeksforgeeks.org/orientation-3-ordered-points/
		// for details of below formula.
		local val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
	  
		if (val == 0) return 0; // collinear
	  
		return (val > 0) ? 1 : 2; // clock or counterclock wise
	},

}
::Collision.obj <- {
		[Vector] = 	{
						[Vector] = Collision.pointVPoint,
						[Line] = Collision.pointVLine,
						[Plane] = Collision.pointVPlane,
						[AABB] = Collision.pointVAABB,
						[OBB] = Collision.pointVOBB,
						[Sphere] = Collision.pointVSphere
					},
		[Line] = 	{
						[Vector] = Collision.lineVPoint,
						[Line] = Collision.lineVLine,
						[Plane] = Collision.lineVPlane,
						[AABB] = Collision.lineVAABB,
						[OBB] = Collision.lineVOBB,
						[Sphere] = Collision.lineVSphere
					},
		[Plane] = 	{
						[Vector] = Collision.planeVPoint,
						[Line] = Collision.planeVLine,
						[Plane] = Collision.planeVPlane,
						[AABB] = Collision.planeVAABB,
						[OBB] = Collision.planeVOBB,
						[Sphere] = Collision.planeVSphere
					},
		[AABB] = 	{
						[Vector] = Collision.AABBVPoint,
						[Line] = Collision.AABBVLine,
						[Plane] = Collision.AABBVPlane,
						[AABB] = Collision.AABBVAABB,
						[OBB] = Collision.AABBVOBB,
						[Sphere] = Collision.AABBVSphere
					},
		[OBB] = 	{
						[Vector] = Collision.OBBVPoint,
						[Line] = Collision.OBBVLine,
						[Plane] = Collision.OBBVPlane,
						[AABB] = Collision.OBBVAABB,
						[OBB] = Collision.OBBVOBB,
						[Sphere] = Collision.OBBVSphere
					},
		[Sphere] = 	{
						[Vector] = Collision.sphereVPoint,
						[Line] = Collision.sphereVLine,
						[Plane] = Collision.sphereVPlane,
						[AABB] = Collision.sphereVAABB,
						[OBB] = Collision.sphereVOBB,
						[Sphere] = Collision.sphereVSphere
					},
};
::Collision.intersect <- function(obj1, obj2){
	return obj[obj1.getclass()][obj2.getclass()].call(Collision, obj1, obj2);
};