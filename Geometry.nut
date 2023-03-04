::AABB <- class{ 
	static type = "AABB";
	worldVectors = [
		Vector(1,0,0),
		Vector(0,1,0),
		Vector(0,0,1),
	];
	extent = null;
	center = null;
    constructor(center, extent) {
        this.center = center;
        this.extent = extent;
    }
    function xLength() {
		return this.extent.x * 2;
    }
    function yLength() {
		return this.extent.y * 2;
    }
	function zLength(){
		return this.extent.z * 2;
	}
	function size(){
		return this.extent * 2;
	}
	//absolute mins and maxs
	function mins(){
		return center - extent;
	}
	function maxs(){
		return center + extent;
	}
	function volume(){
		local s = size();
		return s.x * s.y * s.z;
	}
	function surfaceArea(){
		local x = xLength();
		local y = yLength();
		local z = zLength();
		return 2 * (x * y + z * y + z * x);
	}
	function absPoints(){
		local mins = mins();
		local maxs = maxs();
		
		return [maxs, Vector(mins.x, maxs.y, maxs.z), Vector(maxs.x, mins.y, maxs.z), Vector(mins.x, mins.y, maxs.z),
				mins, Vector(mins.x, maxs.y, mins.z), Vector(maxs.x, mins.y, mins.z), Vector(maxs.x, maxs.y, mins.z)];
	}
	function points(){
		return [extent, Vector(-extent.x, extent.y, extent.z), Vector(extent.x, -extent.y, extent.z), Vector(-extent.x, -extent.y, extent.z),
				extent * -1, Vector(-extent.x, extent.y, -extent.z), Vector(extent.x, -extent.y, -extent.z), Vector(extent.x, extent.y, -extent.z)];
	}
	function closestPoint(vec){
		local min = mins();
		local max = maxs();
		return Vector(
			clamp(vec.x, min.x, max.x), 
			clamp(vec.y, min.y, max.y), 
			clamp(vec.z, min.z, max.z)
		);
	}
	function toLocal(p){
		return p - center;
	}
	function toWorld(p){
		return center + p;
	}
	function draw(color, alpha, duration){
		DebugDrawBox(center, extent * -1, extent, color.x, color.y, color.z, alpha, duration);
	} 	
	function bbox(){
		return AABB(center, extent);
	}	
	function getCenter(){
		return center;
	}
};

::OBB <- class{
	static type = "OBB";
	aabb = null;
	angles = null;
	
	localVectors = null;
	worldVectors = null;
	//thanks https://en.wikipedia.org/wiki/Euler_angles
	static getWorld = function(angles){ //local to world
		local rad = angles * 0.0174533;
		local s2 = sin(rad.x);
		local c2 = cos(rad.x);

		local s1 = sin(rad.y);
		local c1 = cos(rad.y);

		local s3 = sin(rad.z);
		local c3 = cos(rad.z);
		return [
			Vector(c1 * c2, c2 * s1, -s2), // forward vector
			Vector(c1 * s2 * s3 - c3 * s1, c1 * c3 + s1 * s2 * s3, c2 * s3), // left vector
			Vector(s1 * s3 + c1 * c3 * s2, c3 * s1 * s2 - c1 * s3, c2 * c3) // up vector
		];
	}
	static getLocal = function(angles){ // world to local
		local rad = angles * 0.0174533;
		local s2 = sin(rad.x);
		local c2 = cos(rad.x);

		local s1 = sin(rad.y);
		local c1 = cos(rad.y);

		local s3 = sin(rad.z); 
		local c3 = cos(rad.z); 
		return [
			Vector(c1 * c2, c1 * s2 * s3 - c3 * s1, s1 * s3 + c1 * c3 * s2), // forward vector
			Vector(c2 * s1, c1 * c3 + s1 * s2 * s3, c3 * s1 * s2 - c1 * s3), // left vector
			Vector(-s2, c2 * s3, c2 * c3) // up vector
		];
	}
	function getCenter(){
		return aabb.center;
	}
	static Ax = function(a, x){
		local nullVec = Vector(0,0,0);
		nullVec += a[0] * x.x;
		nullVec += a[1] * x.y;
		nullVec += a[2] * x.z;
		return nullVec;
	}
	constructor(aabb, angles){
		this.aabb = aabb;
		this.angles = angles;
		localVectors = getLocal(angles);
		worldVectors = getWorld(angles);
	}
	function absPoints(){
		local obbPoints = [];
		foreach(v in aabb.points()){
			obbPoints.push(toWorld(v));
		}
		return obbPoints;
	}
	function points(){
		return aabb.points();
	}
	function closestPoint(point){
		return toWorld(aabb.toLocal(aabb.closestPoint(aabb.toWorld(toLocal(point)))));
	}
	function toLocal(p){
		//translate to origin then rotate
		return Ax(localVectors, aabb.toLocal(p));
	}
	function toWorld(p){
		//rotate around the origin then translate away
		return aabb.toWorld(Ax(worldVectors, p));
	}
	function draw(color, alpha, duration){
		DebugDrawBoxAngles(aabb.center, aabb.extent * -1, aabb.extent, angles, color.x, color.y, color.z, alpha, duration);
	}
	function bbox(){
		local points = absPoints();
		local mins = Vector(99999,99999,99999);
		local maxs = Vector(-99999, -99999, -99999);
		foreach(vec in points){
			mins.x = min(mins.x, vec.x);
			mins.y = min(mins.y, vec.y);
			mins.z = min(mins.z, vec.z);
			
			maxs.x = max(maxs.x, vec.x);
			maxs.y = max(maxs.y, vec.y);
			maxs.z = max(maxs.z, vec.z);
		}		
		local center = (maxs + mins) * 0.5;
		return AABB(center, maxs - center);
	}
};

::Line <- class{
	static type = "Line";
	start = null;
	end = null;
	constructor(start, end){
		this.start = start;
		this.end = end;
	}
	function f(t){
		return start + (end - start) * t;
	}
	function length(){
		return (end - start).Length();
	}	
	function lengthSqr(){
		return (end - start).LengthSqr();
	}
	function getCenter(){
		return (start + end) * 0.5;
	}
	function max(){
		return Vector(max(start.x, end.x), max(start.y, end.y), max(start.z, end.z));
	}
	function min(){
		return Vector(min(start.x, end.x), min(start.y, end.y), min(start.z, end.z));
	}
	function draw(color, noDepth, duration){
		DebugDrawLine(start, end, color.x, color.y, color.z, noDepth, duration);
	}
	function closestPoint(vec){
		local b = end - start;
		return start + b * clamp(b.Dot(vec - start)/b.Dot(b), 0, 1);
	}
	function bbox(){
		local mins = Vector(99999,99999,99999);
		local maxs = Vector(-99999, -99999, -99999);
		
		mins.x = min(start.x, end.x);
		mins.y = min(start.y, end.y);
		mins.z = min(start.z, end.z);
		
		maxs.x = max(start.x, end.x);
		maxs.y = max(start.y, end.y);
		maxs.z = max(start.z, end.z);
		
		local center = (maxs + mins) * 0.5;
		return AABB(center, maxs - center);
	}
};

::Plane <- class{
	static type = "Plane";
	normal = null;
	point = null;
	constructor(point, normal){
		this.point = point;
		this.normal = normal;
	}
	function closestPoint(vec){
		local distance = normal.Dot(vec-point);
		return vec - (normal * distance);
	}
	function draw(point, color, alpha, duration){
		local p = closestPoint(point);
		local ang = Vector(asin(normal.z) * 57.295779513, atan2(normal.y, normal.x) * 57.295779513, 0);
		
		DebugDrawBoxAngles(p, Vector(0, -500, -500), Vector(0, 500, 500), ang, color.x, color.y, color.z, alpha, duration);
	}
}

::Sphere <- class{
	static type = "Sphere";
	radius = null;
	radiusSqr = null;
	center = null;
	constructor(center, radius){
		this.center = center;
		this.radius = radius;
		radiusSqr = radius * radius;
	}
	function closestPoint(vec, norm = Vector(0,0,0)){
		norm = vec - center;
		norm.Norm();
		return center + norm * radius;
	}
	function draw(n, m, color, noDepth, duration){
		local lastDot = null;
		for(local i = 0; i < m; i++){
			for(local i1 = 0; i1 < n; i1++){
				local newDot = center + Vector(sin(PI * i/m) * cos(2 * PI * i1/n), sin(PI * i/m) * sin(2 * PI * i1/n), cos(PI * i/m)) * radius;
				if(lastDot)DebugDrawLine(lastDot, newDot, color.x, color.y, color.z, noDepth, duration);
				lastDot = newDot;
			}
		}
	}
	function bbox(){
		return AABB(center, Vector(radius, radius, radius));
	}
	function getCenter(){
		return center;
	}
};
//BezierCurveCubic
::BCC <- class{
	cp = null; //control points
	length = null;
	timeToLength = null;
	static align = function(ctrl1, pivot, ctrl2):(VectorManipulation){ //align ctrl1 along line made by pivot and ctrl2
		local dis1 = ctrl2 - pivot; //displacement from pivot to ctrl2
		local dis2 = ctrl1 - pivot; //displacement from pivot to ctrl1
		// local temp = pivot + VectorManipulation.projectToLine(dis2, dis1);
		local temp = pivot - dis1;
		ctrl1.x = temp.x;
		ctrl1.y = temp.y;
		ctrl1.z = temp.z;
	};
	constructor(start, ctrl1, ctrl2, end){
		cp = [start, ctrl1, ctrl2, end];
	}
	function f(t){ //return a point at t of the curve
		return 	cp[0] * (1-t) * (1-t) * (1-t) + 
				cp[1] * (3 * t * (1-t) * (1-t)) + 
				cp[2] * (3 * (1-t) * t * t) + 
				cp[3] * t * t * t;
	}
	function d1(t){//return first derivative
		local v1 = (cp[1] - cp[0]) * (3 * (1-t) * (1-t));
		local v2 = (cp[2] - cp[1]) * (6 * (1-t) * t);
		local v3 = (cp[3] - cp[2]) * (3 * t * t);
		return v1 + v2 + v3;
	}
	function getLength(recalculate = false){
		if(length && !recalculate) return length;
		return _getLength(10);
	}
	function _getLength(steps){
		local inv = 1.0/steps;
		timeToLength = [0];
		length = 0;
		for(local i = 0; i < steps; i++){
			local p1 = f(i * inv);
			local p2 = f((i + 1) * inv);
			length += (p2 - p1).Length();
			timeToLength.push(length);
		}
		return length;
	}
	function lengthAtTime(t){
		local idx = (timeToLength.len() - 1) * t;
		local remainder = idx - floor(idx);
		local upper = timeToLength[ceil(idx)];
		local lower = timeToLength[floor(idx)];
		return (upper - lower) * remainder + lower;
	}
	function timeAtLength(d){
		
	}
	function draw(steps, color, noDepth, duration){
		local inv = 1.0/steps;
		for(local i = 0; i < steps; i++){
			local p1 = f(i * inv);
			local p2 = f((i + 1) * inv);
			DebugDrawLine(p1, p2, color.x, color.y, color.z, noDepth, duration);
		}
	}
    function closestPoint(vec, slices, iterations) {
        return _closestPoint(iterations, vec, 0, 1, slices);
    }
    function _closestPoint(iterations, vec, start, end, slices) {
        if (iterations <= 0) {
			return (start + end) / 2;
		}
        local tick = (end - start) / slices;
        local best = 0;
        local bestDistance = 99999;
        local t = start;
        while (t <= end) {
			
			local vec1 = f(t);
			
            local currentDistance = (vec1 - vec).LengthSqr();
            if (currentDistance < bestDistance) {
                bestDistance = currentDistance;
                best = t;
            }
            t += tick;
        }
        return _closestPoint(iterations - 1, vec, (best - tick) > 0 ?  (best - tick) : 0, (best + tick) < 1 ? (best + tick) : 1, slices);
    }
	function half(){ //divide into two curves
		local a1 = (start + ctrl1) * 0.5;
		local a2 = (ctrl1 + ctrl2) * 0.5;
		local a3 = (ctrl2 + end) * 0.5;
		
		local b1 = (a1 + a2) * 0.5;
		local b2 = (a2 + a3) * 0.5;
		
		local c1 = (b1 + b2) * 0.5;
		return [getclass()(start, a1, b1, c1), getclass()(c1, b2, a3, end)];
	}
	function center(){
		return (cp[0] + cp[1] + cp[2] + cp[3]) * 0.25;
	}
};