package 
{

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import net.azrafe7.geomAlgo.EarClipper;
	import net.azrafe7.geomAlgo.MarchingSquares;
	import net.azrafe7.geomAlgo.RamerDouglasPeucker;
	import net.azrafe7.geomAlgo.Bayazit;


	[SWF(width="800", height="340", backgroundColor="#222222")]
	public class Test extends Sprite {

		private var g:Graphics;

		//[Embed(source="../assets/super_mario.png")]	// from here http://www.newgrounds.com/art/view/petelavadigger/super-mario-pixel
		[Embed(source = "../assets/pirate_small.png")]
		private var ASSET:Class;

		private var COLOR:int = 0xFF0000;
		private var ALPHA:Number = 1.;
		private var X_GAP:int = 10;

		private var TEXT_COLOR:int = 0xFFFFFFFF;
		private var TEXT_FONT:String = "_typewriter";
		private var TEXT_SIZE:Number = 12;
		private var TEXT_OFFSET:Number = -50;
		private var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 4, 4, 6);

		private var START_POINT:Point = new Point(30, 80);

		private var originalBMD:BitmapData;
		private var originalBitmap:Bitmap;
		private var originalText:TextField;

		private var marchingSquares:MarchingSquares;
		private var clipRect:Rectangle;
		private var perimeter:Vector.<Point>;
		private var marchingText:TextField;

		private var simplifiedPoly:Vector.<Point>;
		private var simplifiedText:TextField;

		private var triangulation:Vector.<Vector.<Point>>;
		private var triangulationText:TextField;

		private var decomposition:Vector.<Vector.<Point>>;
		private var decompositionText:TextField;

		private var decompositionBayazit:Vector.<Vector.<Point>>;
		private var decompositionBayazitText:TextField;


		public function Test() {
			super ();

			g = graphics;
			g.lineStyle(1, COLOR, ALPHA);
			originalBMD = Bitmap(new ASSET()).bitmapData;

			var x:Number = START_POINT.x;
			var y:Number = START_POINT.y;
			var width:int = originalBMD.width;

			// ORIGINAL IMAGE
			addChild(originalBitmap = new Bitmap(originalBMD));
			originalBitmap.x = x;
			originalBitmap.y = y;
			addChild(originalText = getTextField("Original\n" + originalBMD.width + "x" + originalBMD.height, x, y));

			// MARCHING SQUARES
			x += width + X_GAP;
			//clipRect = new Rectangle(10, 20, 90, 65);
			clipRect = originalBMD.rect;
			marchingSquares = new MarchingSquares(originalBMD, 1, clipRect);
			perimeter = marchingSquares.march();
			drawPerimeter(perimeter, x + clipRect.x, y + clipRect.y);
			addChild(marchingText = getTextField("MarchSqrs\n" + perimeter.length + " pts", x, y));

			// RAMER-DOUGLAS-PEUCKER
			x += width + X_GAP;
			simplifiedPoly = RamerDouglasPeucker.simplify(perimeter, 1.5);
			drawSimplifiedPoly(simplifiedPoly, x + clipRect.x, y + clipRect.y);
			addChild(simplifiedText = getTextField("Doug-Peuck\n" + simplifiedPoly.length + " pts", x, y));

			// EARCLIPPER TRIANGULATION
			x += width + X_GAP;
			triangulation = EarClipper.triangulate(simplifiedPoly);
			drawTriangulation(triangulation, x + clipRect.x, y + clipRect.y);
			addChild(triangulationText = getTextField("EC-Triang\n" + triangulation.length + " tris", x, y));

			// EARCLIPPER DECOMPOSITION
			x += width + X_GAP;
			decomposition = EarClipper.polygonizeTriangles(triangulation);
			drawDecomposition(decomposition, x + clipRect.x, y + clipRect.y);
			addChild(decompositionText = getTextField("EC-Decomp\n" + decomposition.length + " polys", x, y));

			// BAYAZIT DECOMPOSITION
			x += width + X_GAP;
			decompositionBayazit = Bayazit.decomposePoly(simplifiedPoly);
			drawDecompositionBayazit(decompositionBayazit, x + clipRect.x, y + clipRect.y);
			addChild(decompositionBayazitText = getTextField("Bayaz-Decomp\n" + decompositionBayazit.length + " polys", x, y));

			//stage.addChild(new FPS(5, 5, 0xFFFFFF));
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}


		public function drawPerimeter(points:Vector.<Point>, x:Number, y:Number):void 
		{
			// draw clipRect
			g.drawRect(originalBitmap.x + clipRect.x, originalBitmap.y + clipRect.y, clipRect.width, clipRect.height);

			g.moveTo(x + points[0].x, y + points[0].y);
			for (var i:int = 1; i < points.length; i++) {
				var p:Point = points[i];
				g.lineTo(x + p.x, y + p.y);
			}
		}

		public function drawSimplifiedPoly(points:Vector.<Point>, x:Number, y:Number):void 
		{
			var i:int = 0;
			var p:Point;
			// points
			for (i = 1; i < points.length; i++) {
				p = points[i];
				g.drawCircle(x + p.x, y + p.y, 2);
			}
			// lines
			g.moveTo(x + points[0].x, y + points[0].y);
			for (i = 1; i < points.length; i++) {
				p = points[i];
				g.lineTo(x + p.x, y + p.y);
			}
		}

		public function drawTriangulation(tris:Vector.<Vector.<Point>>, x:Number, y:Number):void 
		{
			for each (var tri:Vector.<Point> in tris) {
				var points:Vector.<Point> = tri;
				g.moveTo(x + points[0].x, y + points[0].y);

				for (var i:int = 1; i < points.length + 1; i++) {
					var p:Point = points[i % points.length];
					g.lineTo(x + p.x, y + p.y);
				}
			}
		}

		public function drawDecomposition(polys:Vector.<Vector.<Point>>, x:Number, y:Number):void 
		{
			for each (var poly:Vector.<Point> in polys) {
				var points:Vector.<Point> = poly;
				g.moveTo(x + points[0].x, y + points[0].y);

				for (var i:int = 1; i < points.length + 1; i++) {
					var p:Point = points[i % points.length];
					g.lineTo(x + p.x, y + p.y);
				}
			}
		}

		public function drawDecompositionBayazit(polys:Vector.<Vector.<Point>>, x:Number, y:Number):void 
		{
			var str:String = "";
			for each (var poly:Vector.<Point> in polys) {
				var points:Vector.<Point> = poly;
				g.moveTo(x + points[0].x, y + points[0].y);
				str += "[";
				for (var i:int = 1; i < points.length + 1; i++) {
					var p:Point = points[i % points.length];
					g.lineTo(x + p.x, y + p.y);
					str += p.x + "," + p.y + ",";
				}
				str += points[0].x + "," + points[0].y + "],\n";
			}
			trace(str);
			// draw Reflex and Steiner points
			/*
			g.lineStyle(1, (COLOR >> 1) | COLOR, ALPHA);
			for (p in Bayazit.reflexVertices) g.drawCircle(x + p.x, y + p.y, 2);
			g.lineStyle(1, (COLOR >> 2) | COLOR, ALPHA);
			for (p in Bayazit.steinerPoints) g.drawCircle(x + p.x, y + p.y, 2);
			g.lineStyle(1, COLOR, ALPHA);
			*/
		}

		public function getTextField(text:String = "", x:Number = 0, y:Number = 0):TextField
		{
			var tf:TextField = new TextField();
			var fmt:TextFormat = new TextFormat(TEXT_FONT, null, TEXT_COLOR);
			fmt.align = TextFormatAlign.CENTER;
			fmt.size = TEXT_SIZE;
			tf.defaultTextFormat = fmt;
			tf.selectable = false;
			tf.x = x;
			tf.y = y + TEXT_OFFSET;
			tf.filters = [TEXT_OUTLINE];
			tf.text = text;
			return tf;
		}

		public function onKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == 27) {
				System.exit(1);
			}
		}
	}
}