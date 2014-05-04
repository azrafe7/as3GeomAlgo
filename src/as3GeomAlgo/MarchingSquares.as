/**
 * Marching Squares implementation (Counterclockwise).
 * 
 * Based on:
 * 
 * @see http://devblog.phillipspiess.com/2010/02/23/better-know-an-algorithm-1-marching-squares/	(C# - by Phil Spiess)
 * @see http://www.tomgibara.com/computer-vision/marching-squares									(Java - by Tom Gibara)
 * 
 * @author azrafe7
 */

package as3GeomAlgo
{

	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;


	public class MarchingSquares
	{
		static public const NONE:int = -1;
		static public const UP:int = 0;
		static public const LEFT:int = 1;
		static public const DOWN:int = 2;
		static public const RIGHT:int = 3;

		/** Minimum alpha value to consider a pixel opaque. */
		public var alphaThreshold:int = 1;

		private var prevStep:int = NONE;
		private var nextStep:int = NONE;
		
		private var bmd:BitmapData;
		private var clipRect:Rectangle;
		private var width:int;
		private var height:int;
		private var byteArray:ByteArray;
		
		private var point:Point = new Point();


		/**
		 * Constructor.
		 * 
		 * @param	bmd				BitmapData to use as source.
		 * @param	alphaThreshold  Minimum alpha value to consider a pixel opaque.
		 * @param	clipRect		The region of bmd to process (defaults to the entire image)
		 */
		public function MarchingSquares(bmd:BitmapData, alphaThreshold:int = 1, clipRect:Rectangle = null)
		{
			setSource(bmd, clipRect);
			
			this.alphaThreshold = alphaThreshold;
		}
		
		/** 
		 * Updates the BitmapData to use as source and its clipRect. 
		 * 
		 * NOTE: If you modifiy your bitmapData between calls to march()/walkPerimeter you may 
		 * also want to re-set the source so that the byteArray gets updated too.
		 */
		public function setSource(bmd:BitmapData, clipRect:Rectangle = null):void
		{
			this.bmd = bmd;
			this.clipRect = clipRect != null ? clipRect : bmd.rect;
			byteArray = bmd.getPixels(this.clipRect);
			width = int(this.clipRect.width);
			height = int(this.clipRect.height);
		}
		
		/** 
		 * Finds the perimeter.
		 * 
		 * @param	startPoint	Start from this point (if null it will be calculated automatically).
		 * @return	An array containing the points on the perimeter, or an empty array if no perimeter is found.
		 */
		public function march(startPoint:Point = null):Vector.<Point> 
		{
			if (startPoint == null) {
				if (findStartPoint() == null) return new <Point>[];
			}
			else point.setTo(startPoint.x, startPoint.y);
			
			return walkPerimeter(int(point.x), int(point.y));
		}
		
		/** 
		 * Finds the first opaque pixel location (starting from top-left corner, or from the specified line). 
		 * 
		 * @return The first opaque pixel location, or null if not found.
		 */
		public function findStartPoint(line:int = 0):Point {
			byteArray.position = 0;
			point.setTo(-1, -1);
			
			var alphaIdx:int = line * width << 2;
			var len:int = byteArray.length;
			var i:int = 0;
			while (alphaIdx < len) {
				if (byteArray[alphaIdx] >= alphaThreshold) {
					point.setTo((alphaIdx >> 2) % width, int((alphaIdx >> 2) / width));
					break;
				}
				alphaIdx += 4;
			}
			
			return point.x != -1 ? point.clone() : null;
		}
		
		/** Finds points belonging to the perimeter starting from `startX`, `startY`. */
		private function walkPerimeter(startX:int, startY:int):Vector.<Point> 
		{
			// clamp to source boundaries
			if (startX < 0) startX = 0;
			if (startX > width) startX = width;
			if (startY < 0) startY = 0;
			if (startY > height) startY = height;

			var pointList:Vector.<Point> = new Vector.<Point>();

			var x:int = startX;
			var y:int = startY;

			// loop until we return to the starting point
			var done:Boolean = false;
			while (!done) {
				step(x, y);

				// add perimeter point to return list (ensuring it's not out of boundaries)
				pointList.push(new Point(x < width ? x : width - 1, y < height ? y : height - 1));

				switch (nextStep)
				{
					case UP:    y--; break;
					case LEFT:  x--; break;
					case DOWN:  y++; break;
					case RIGHT: x++; break;
					default: throw "Illegal state at point (x: " + x + ", y: " + y + ").";
				}
				
				done = (x == startX && y == startY);
			}

			return pointList;
		}
		
		/** Calculates the next state for pixel at `x`, `y`. */
		public function step(x:int, y:int):void 
		{
			var upLeft:Boolean = isPixelSolid(x - 1, y - 1);
			var upRight:Boolean = isPixelSolid(x, y - 1);
			var downLeft:Boolean = isPixelSolid(x - 1, y);
			var downRight:Boolean = isPixelSolid(x, y);
			
			// save previous step
			prevStep = nextStep;

			// calc current state
			var state:int = 0;

			if (upLeft) state |= 1;
			if (upRight) state |= 2;
			if (downLeft) state |= 4;
			if (downRight) state |= 8;

			if (state == 0 || state == 15) throw "Error: point (x: " + x + ", y: " + y + ") doesn't lie on perimeter.";
			
			switch (state)
			{
				case 1:
				case 5:
				case 13: 
					nextStep = UP;
					break;
				case 2:
				case 3:
				case 7: 
					nextStep = RIGHT;
					break;
				case 4:
				case 12:
				case 14: 
					nextStep = LEFT;
					break;
				case 6:
					nextStep = (prevStep == UP ? LEFT : RIGHT);
					break;
				case 8:
				case 10:
				case 11: 
					nextStep = DOWN;
					break;
				case 9:
					nextStep = (prevStep == RIGHT ? UP : DOWN);
					break;
				default: 
					throw "Illegal state at point (x: " + x + ", y: " + y + ").";
			}
		}
		
		/** Returns true if the pixel at `x`, `y` is opaque (according to `alphaThreshold`). */
		public function isPixelSolid(x:int, y:int):Boolean {
			return (x >= 0 && y >= 0 && x < width && y < height && (byteArray[(y * width + x) << 2] >= alphaThreshold));
		}
	}
}