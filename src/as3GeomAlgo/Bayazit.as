/**
 * Bayazit polygon decomposition implementation.
 * NOTE: Should work only for SIMPLE polygons (not self-intersecting, without holes).
 * 
 * Based on:
 * 
 * @see http://mnbayazit.com/406/bayazit							(C - by Mark Bayazit)
 * @see http://mnbayazit.com/406/credit
 * 
 * Other credits should go to papers/work of: 
 * 
 * @see http://mnbayazit.com/406/files/PolygonDecomp-Keil.pdf		(Keil)
 * @see http://mnbayazit.com/406/files/OnTheTimeBound-Snoeyink.pdf	(Snoeyink & Keil)
 * @see http://www.cs.sfu.ca/~binay/								(Dr. Bhattacharya)
 * 
 * @author azrafe7
 */

package as3GeomAlgo
{

	import flash.geom.Point;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import as3GeomAlgo.PolyTools;


	public class Bayazit
	{
		
		static public var reflexVertices:Vector.<Point> = new Vector.<Point>();
		static public var steinerPoints:Vector.<Point> = new Vector.<Point>();

		/** Decomposes `poly` into a near-minimum number of convex polygons. */
		static public function decomposePoly(poly:Vector.<Point>):Vector.<Vector.<Point>> {
			var res:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();
			
			PolyTools.makeCCW(poly);	// in place
			
			reflexVertices.length = 0;
			steinerPoints.length = 0;
			
			_decomposePoly(poly, res);
			
			return res;
		}
		
		/** Used internally by decomposePoly(). */
		static private function _decomposePoly(poly:Vector.<Point>, polys:Vector.<Vector.<Point>>):void {
			var _:* = getDefinitionByName(getQualifiedClassName(PolyTools));	// shortcut for PolyTools
			
			var upperInt:Point = new Point(), lowerInt:Point = new Point(), 
				p:Point = new Point(), closestVert:Point = new Point();
			var upperDist:Number = 0, lowerDist:Number = 0, d:Number = 0, closestDist:Number = 0;
			var upperIdx:int = 0, lowerIdx:int = 0, closestIdx:int = 0;
			var upperPoly:Vector.<Point> = new Vector.<Point>(), lowerPoly:Vector.<Point> = new Vector.<Point>();
			var j:int = 0, k:int = 0;
			
			for (var i:int = 0; i < poly.length; i++) {
				if (PolyTools.isReflex(poly, i)) {
					reflexVertices.push(poly[i]);
					upperDist = lowerDist = Number.POSITIVE_INFINITY;
					for (j = 0; j < poly.length; j++) {
						if (_.isLeft(_.at(poly, j), _.at(poly, i - 1), _.at(poly, i)) &&
							_.isRightOrOn(_.at(poly, j - 1), _.at(poly, i - 1), _.at(poly, i))) // if line intersects with an edge
						{
							p = PolyTools.intersection(_.at(poly, i - 1), _.at(poly, i), _.at(poly, j), _.at(poly, j - 1)); // find the point of intersection
							if (_.isRight(p, _.at(poly, i + 1), _.at(poly, i))) { // make sure it's inside the poly
								d = PolyTools.distanceSquared(poly[i], p);
								if (d < lowerDist) { // keep only the closest intersection
									lowerDist = d;
									lowerInt = p;
									lowerIdx = j;
								}
							}
						}
						
						if (_.isLeft(_.at(poly, j + 1), _.at(poly, i + 1), _.at(poly, i))
								&& _.isRightOrOn(_.at(poly, j), _.at(poly, i + 1), _.at(poly, i))) 
						{			
							p = PolyTools.intersection(_.at(poly, i + 1), _.at(poly, i), _.at(poly, j), _.at(poly, j + 1));
							if (_.isLeft(p, _.at(poly, i - 1), _.at(poly, i))) {
								d = PolyTools.distanceSquared(poly[i], p);
								if (d < upperDist) {
									upperDist = d;
									upperInt = p;
									upperIdx = j;
								}
							}
						}
					}
					
					// if there are no vertices to connect to, choose a point in the middle
					if (lowerIdx == (upperIdx + 1) % poly.length) {

						//trace('Case 1: Vertex($i), lowerIdx($lowerIdx), upperIdx($upperIdx), poly.length(${poly.length})');
						
						p.x = (lowerInt.x + upperInt.x) / 2;
						p.y = (lowerInt.y + upperInt.y) / 2;
						steinerPoints.push(p);
						
						if (i < upperIdx) {
							for (k = i; k < upperIdx + 1; k++) lowerPoly.push(poly[k]);
							lowerPoly.push(p);
							upperPoly.push(p);
							if (lowerIdx != 0) for (k = lowerIdx; k < poly.length; k++) upperPoly.push(poly[k]);
							for (k = 0; k < i + 1; k++) upperPoly.push(poly[k]);
						} else {
							if (i != 0) for (k = i; k < poly.length; k++) lowerPoly.push(poly[k]);
							for (k = 0; k < upperIdx + 1; k++) lowerPoly.push(poly[k]);
							lowerPoly.push(p);
							upperPoly.push(p);
							for (k = lowerIdx; k < i + 1; k++) upperPoly.push(poly[k]);
						}
						
					} else {
						
						// connect to the closest point within the triangle
						//trace('Case 2: Vertex($i), closestIdx($closestIdx), poly.length(${poly.length})');

						if (lowerIdx > upperIdx) {
							upperIdx += poly.length;
						}
						closestDist = Number.POSITIVE_INFINITY;
						for (j = lowerIdx; j < upperIdx + 1; j++) {
							if (_.isLeftOrOn(_.at(poly, j), _.at(poly, i - 1), _.at(poly, i))
									&& _.isRightOrOn(_.at(poly, j), _.at(poly, i + 1), _.at(poly, i))) 
							{
								d = PolyTools.distanceSquared(_.at(poly, i), _.at(poly, j));
								if (d < closestDist) {
									closestDist = d;
									closestVert = _.at(poly, j);
									closestIdx = j % poly.length;
								}
							}
						}

						if (i < closestIdx) {
							for (k = i; k < closestIdx + 1; k++) lowerPoly.push(poly[k]);
							if (closestIdx != 0) for (k = closestIdx; k < poly.length; k++) upperPoly.push(poly[k]);
							for (k = 0; k < i + 1; k++) upperPoly.push(poly[k]);
						} else {
							if (i != 0) for (k = i; k < poly.length; k++) lowerPoly.push(poly[k]);
							for (k = 0; k < closestIdx + 1; k++) lowerPoly.push(poly[k]);
							for (k = closestIdx; k < i + 1; k++) upperPoly.push(poly[k]);
						}
					}

					// solve smallest poly first
					if (lowerPoly.length < upperPoly.length) {
						_decomposePoly(lowerPoly, polys);
						_decomposePoly(upperPoly, polys);
					} else {
						_decomposePoly(upperPoly, polys);
						_decomposePoly(lowerPoly, polys);
					}
					return;
				}
			}
			polys.push(poly);
		}	
	}
}