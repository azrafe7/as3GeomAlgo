/**
 * Ramer-Douglas-Peucker implementation.
 * 
 * Based on:
 * 
 * @see http://karthaus.nl/rdp/																				(JS - by Marius Karthaus)
 * @see http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment		(JS - Grumdrig)
 * 
 * @author azrafe7
 */

package as3GeomAlgo
{

	import flash.geom.Point;
	import as3GeomAlgo.PolyTools;

	public class RamerDouglasPeucker
	{
		/**
		 * Simplify polyline.
		 * 
		 * @param	points		Array of points defining the polyline.
		 * @param	epsilon		Perpendicular distance threshold (typically in the range [1..2]).
		 * @return	An array of points defining the simplified polyline.
		 */
		static public function simplify(points:Vector.<Point>, epsilon:Number = 1):Vector.<Point> 
		{
			var firstPoint:Point = points[0];
			var lastPoint:Point = points[points.length - 1];
			
			if (points.length < 3) {
				return points;
			}
			
			var index:int = -1;
			var dist:Number = 0.;
			for (var i:int = 1; i < points.length - 1; i++) {
				var currDist:Number = PolyTools.distanceToSegment(points[i], firstPoint, lastPoint);
				if (currDist > dist){
					dist = currDist;
					index = i;
				}
			}
			
			if (dist > epsilon){
				// recurse
				var l1:Vector.<Point> = points.slice(0, index + 1);
				var l2:Vector.<Point> = points.slice(index);
				var r1:Vector.<Point> = simplify(l1, epsilon);
				var r2:Vector.<Point> = simplify(l2, epsilon);
				// concat r2 to r1 minus the end/startpoint that will be the same
				var rs:Vector.<Point> = r1.slice(0, r1.length - 1).concat(r2);
				return rs;
			} else {
				return new <Point>[firstPoint, lastPoint];
			}
		}
	}
}