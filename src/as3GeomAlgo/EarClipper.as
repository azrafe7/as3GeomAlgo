/**
 * Ear clipping implementation - concave to convex polygon decomposition (Counterclockwise).
 * NOTE: Should work only for SIMPLE polygons (not self-intersecting, without holes).
 * 
 * Based on:
 * 
 * @see http://www.box2d.org/forum/viewtopic.php?f=8&t=463&start=0										(JSFL - by mayobutter)
 * @see http://www.ewjordan.com/earClip/																(Processing - by Eric Jordan)
 * @see http://en.nicoptere.net/?p=16																	(AS3 - by Nicolas Barradeau)
 * @see http://blog.touchmypixel.com/2008/06/making-convex-polygons-from-concave-ones-ear-clipping/		(AS3 - by Tarwin Stroh-Spijer)
 * @see http://headsoft.com.au/																			(C# - by Ben Baker)
 * 
 * @author azrafe7
 */

package as3GeomAlgo
{

	import flash.geom.Point;
	import as3GeomAlgo.PolyTools;


	public class EarClipper
	{
		/**
		 * Triangulates a polygon.
		 * 
		 * @param	v	Array of points defining the polygon.
		 * @return	An array of Triangles resulting from the triangulation.
		 */
		public static function triangulate(v:Vector.<Point>):Vector.<Vector.<Point>>
		{
			if (v.length < 3)
				return null;

			var remList:Vector.<Point> = new Vector.<Point>().concat(v);
			
			var resultList:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();

			while (remList.length > 3)
			{
				var earIndex:int = -1;

				for (var i:int = 0; i < remList.length; i++)
				{
					if (isEar(remList, i))
					{
						earIndex = i;
						break;
					}
				}

				if (earIndex == -1)
					return null;

				var newList:Vector.<Point> = new Vector.<Point>().concat(remList);

				newList.splice(earIndex, 1);

				var under:int = (earIndex == 0 ? remList.length - 1 : earIndex - 1);
				var over:int = (earIndex == remList.length - 1 ? 0 : earIndex + 1);

				resultList.push(createCCWTri(remList[earIndex], remList[over], remList[under]));

				remList = newList;
			}

			resultList.push(createCCWTri(remList[1], remList[2], remList[0]));

			return resultList;
		}

		/**
		 * Merges triangles (defining a triangulated concave polygon) into a set of convex polygons.
		 * 
		 * @param	triangulation	An array of triangles defining the concave polygon.
		 * @return	An array of convex polygons being a decomposition of the original concave polygon.
		 */
		public static function polygonizeTriangles(triangulation:Vector.<Vector.<Point>>):Vector.<Vector.<Point>> 
		{
			var polys:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();

			if (triangulation == null)
			{
				return null;
			}
			else
			{
				var covered:Vector.<Boolean> = new Vector.<Boolean>();
				var i:int = 0;
				for (i = 0; i < triangulation.length; i++) covered[i] = false;

				var notDone:Boolean = true;
				while (notDone)
				{
					var poly:Vector.<Point> = null;

					var currTri:int = -1;
					for (i = 0; i < triangulation.length; i++)
					{
						if (covered[i]) continue;
						currTri = i;
						break;
					}
					if (currTri == -1)
					{
						notDone = false;
					}
					else
					{
						/* mmh */
						poly = triangulation[currTri];
						covered[currTri] = true;
						for (i = 0; i < triangulation.length; i++)
						{
							if (covered[i]) continue;
							var newPoly:Vector.<Point> = addTriangle(poly, triangulation[i]);
							if (newPoly == null) continue;
							if (isConvex(newPoly))
							{
								poly = newPoly;
								covered[i] = true;
							}
						}

						polys.push(poly);
					}
				}
			}

			return polys;
		}

		/** Checks if vertex `i` is the tip of an ear. */
		private static function isEar(v:Vector.<Point>, i:int):Boolean
		{
			var dx0:Number = 0., dy0:Number = 0., dx1:Number = 0., dy1:Number = 0.;

			if (i >= v.length || i < 0 || v.length < 3)
				return false;

			var upper:int = i + 1;
			var lower:int = i - 1;

			if (i == 0)
			{
				dx0 = v[0].x - v[v.length - 1].x;
				dy0 = v[0].y - v[v.length - 1].y;
				dx1 = v[1].x - v[0].x;
				dy1 = v[1].y - v[0].y;
				lower = v.length - 1;
			}
			else if (i == v.length - 1)
			{
				dx0 = v[i].x - v[i - 1].x;
				dy0 = v[i].y - v[i - 1].y;
				dx1 = v[0].x - v[i].x;
				dy1 = v[0].y - v[i].y;
				upper = 0;
			}
			else
			{
				dx0 = v[i].x - v[i - 1].x;
				dy0 = v[i].y - v[i - 1].y;
				dx1 = v[i + 1].x - v[i].x;
				dy1 = v[i + 1].y - v[i].y;
			}

			var cross:Number = (dx0 * dy1) - (dx1 * dy0);

			if (cross > 0) return false;

			var tri:Vector.<Point> = createCCWTri(v[i], v[upper], v[lower]);

			for (var j:int = 0; j < v.length; j++)
			{
				if (!(j == i || j == lower || j == upper))
				{
					if (isPointInsideTri(v[j], tri))
						return false;
				}
			}
			
			return true;
		}
		
		/** Checks if `point` is inside the triangle. */
		static public function isPointInsideTri(point:Point, tri:Vector.<Point>):Boolean
		{
			var vx2:Number = point.x - tri[0].x;
			var vy2:Number = point.y - tri[0].y;
			var vx1:Number = tri[1].x - tri[0].x;
			var vy1:Number = tri[1].y - tri[0].y;
			var vx0:Number = tri[2].x - tri[0].x;
			var vy0:Number = tri[2].y - tri[0].y;

			var dot00:Number = vx0 * vx0 + vy0 * vy0;
			var dot01:Number = vx0 * vx1 + vy0 * vy1;
			var dot02:Number = vx0 * vx2 + vy0 * vy2;
			var dot11:Number = vx1 * vx1 + vy1 * vy1;
			var dot12:Number = vx1 * vx2 + vy1 * vy2;
			var invDenom:Number = 1.0 / (dot00 * dot11 - dot01 * dot01);
			var u:Number = (dot11 * dot02 - dot01 * dot12) * invDenom;
			var v:Number = (dot00 * dot12 - dot01 * dot02) * invDenom;

			return ((u > 0) && (v > 0) && (u + v < 1));
		}
		
		static public function createCCWTri(point1:Point, point2:Point, point3:Point):Vector.<Point>
		{
			var points:Vector.<Point> = new <Point>[point1, point2, point3];
			PolyTools.makeCCW(points);
			return points;
		}
		
		/** Assuming the polygon is simple, checks if it is convex. */
		static public function isConvex(poly:Vector.<Point>):Boolean
		{
			var isPositive:Boolean = false;

			for (var i:int = 0; i < poly.length; i++)
			{
				var lower:int = (i == 0 ? poly.length - 1 : i - 1);
				var middle:int = i;
				var upper:int = (i == poly.length - 1 ? 0 : i + 1);
				var dx0:Number = poly[middle].x - poly[lower].x;
				var dy0:Number = poly[middle].y - poly[lower].y;
				var dx1:Number = poly[upper].x - poly[middle].x;
				var dy1:Number = poly[upper].y - poly[middle].y;
				var cross:Number = dx0 * dy1 - dx1 * dy0;
				
				// cross product should have same sign
				// for each vertex if poly is convex.
				var newIsP:Boolean = (cross > 0 ? true : false);

				if (i == 0)
					isPositive = newIsP;
				else if (isPositive != newIsP)
					return false;
			}

			return true;
		}

		/** 
		 * Tries to add a triangle to the polygon.
		 * Assumes bitwise equality of join vertices.
		 * 
		 * @return null if it can't connect properly.
		 */
		static public function addTriangle(poly:Vector.<Point>, t:Vector.<Point>):Vector.<Point>
		{
			// first, find vertices that connect
			var firstP:int = -1;
			var firstT:int = -1;
			var secondP:int = -1;
			var secondT:int = -1;
			var i:int = 0;
			
			for (i = 0; i < poly.length; i++)
			{
				if (t[0].x == poly[i].x && t[0].y == poly[i].y)
				{
					if (firstP == -1)
					{
						firstP = i; firstT = 0;
					}
					else
					{
						secondP = i; secondT = 0;
					}
				}
				else if (t[1].x == poly[i].x && t[1].y == poly[i].y)
				{
					if (firstP == -1)
					{
						firstP = i; firstT = 1;
					}
					else
					{
						secondP = i; secondT = 1;
					}
				}
				else if (t[2].x == poly[i].x && t[2].y == poly[i].y)
				{
					if (firstP == -1)
					{
						firstP = i; firstT = 2;
					}
					else
					{
						secondP = i; secondT = 2;
					}
				}
				else
				{
					//trace(t);
					//trace(firstP, firstT, secondP, secondT);
				}
			}

			// fix ordering if first should be last vertex of poly
			if (firstP == 0 && secondP == poly.length - 1)
			{
				firstP = poly.length - 1;
				secondP = 0;
			}

			// didn't find it
			if (secondP == -1)
				return null;

			// find tip index on triangle
			var tipT:int = 0;
			if (tipT == firstT || tipT == secondT) tipT = 1;
			if (tipT == firstT || tipT == secondT) tipT = 2;

			var newPoints:Vector.<Point> = new Vector.<Point>();

			for (i = 0; i < poly.length; i++)
			{
				newPoints.push(poly[i]);

				if (i == firstP)
					newPoints.push(t[tipT]);
			}

			return newPoints;
		}
	}
}