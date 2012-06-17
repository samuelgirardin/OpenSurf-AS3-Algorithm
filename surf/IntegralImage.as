package surf
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;	
	import flashx.textLayout.formats.WhiteSpaceCollapse;
	import flashx.undo.IUndoManager;
	
	/**
	 * @author Samuel Girardin
	 */
	
	public class IntegralImage extends EventDispatcher 
	{
		
		private const cR:Number = .2989;
		private const cG:Number = .5870;
		private const cB:Number = .1140;
		
		public var pic:Vector.<Vector.<Number>> ;	
		
		public var Width:int ;
		public var Height:int ;		
		
		
		public function IntegralImage(_img:Bitmap)
		{
			trace("InegralImage()") ; 
			fromImage(_img) ;
			
		}		
		
		
		private function _integralImage(width:int,height:int):Vector.<Vector.<Number>>
		{
			
			
			Width = width;
			Height = height;
			
			var grid:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(Height) ; 			
			
			for (var x:int = 0; x < Height ;  x++)			
				grid[x] = new Vector.<Number>(Width) ;
			
			
			return grid ; 
		}
		
		private function fromImage(img:Bitmap):void  {
			
			
			var rgb:uint;
			var red:uint ;
			var green:uint ;
			var blue:uint ;
			
			//var pixels:ByteArray ;
			//var bounds:Rectangle=new Rectangle(0,0,img.width,img.height);
			//pixels = img.bitmapData.getPixels(bounds) ; 
			//pixels.position = 0 ; 
			
		    //var vec:Vector.<uint> = new Vector.<uint>(img.width*img.height) ; 
			//vec =img.bitmapData.getVector(bounds) ;
			
			
			pic = _integralImage(img.width , img.height) ;			
			var bmpData:BitmapData = img.bitmapData ; 	
			
			var rowsum:Number = 0;
		
			for (var x:int = 0; x < img.width; x++)
			{
				rgb = bmpData.getPixel(x, 0);	
				//rgb = pixels.readByte();
				//rgb = vec[x] ; 
				red =  (rgb >> 16 & 0xFF);			
			    green =  (rgb >>>8  & 0xFF);				
				blue =  (rgb & 0xFF);
				rowsum += (cR * red + cG * green + cB * blue) / 255;
				pic[0][ x] = rowsum;
				
			}
			
			
			//pixels.position = 0 ; 			
			for (var y:int = 1; y < img.height; y++)
			{
				rowsum = 0;
				for (x = 0; x < img.width; x++)
				{
					rgb   =  bmpData.getPixel(x, y);					
					
					//pixels.position = (y*img.width+x)*4 ;
					//rgb = pixels.readInt() ; 
					//rgb = vec[y*img.width+x] ;
					red   =  (rgb >> 16 & 0xff);
					green =  (rgb >> 8 & 0xff);
					blue  =  (rgb & 0xff);
					rowsum += (cR * red + cG * green + cB * blue) / 255;
					
					// integral image is rowsum + value above        
					pic[y][ x] = rowsum + pic[y - 1][x];
				}
			}
			
		}
		
		
		
		
		
		public function BoxIntegral( row:int,  col:int,  rows:int,  cols:int):Number
		{
			// The subtraction by one for row/col is because row/col is inclusive.
			// var r1:int = Math.min(row, Height) - 1;
			// var c1:int = Math.min(col, Width) - 1;
			// var r2:int = Math.min(row + rows, Height) - 1;
			// var c2:int = Math.min(col + cols, Width) - 1;
			 
			 
			//var x:int = Math.min(a,b)	 into	var x:int = (a<b) ? a : b; better perf
			 var r1:int = (row<Height)?row-1:Height-1 ; 
			 var c1:int = (col<Width)?col-1:Width-1 ;			 
			 var r2:int = (row+rows<Height)?row+rows-1:Height-1 ;
			 var c2:int =(col+cols<Width)?col+cols-1:Width-1 ;
			 
			 var A:Number=0 ; 
			 var B:Number=0 ; 
			 var C:Number=0 ; 
			 var D:Number=0 ; 
			
			if (r1 >= 0 && c1 >= 0) A = pic[r1][c1];
			if (r1 >= 0 && c2 >= 0) B = pic[r1][c2];
			if (r2 >= 0 && c1 >= 0) C = pic[r2][c1];
			if (r2 >= 0 && c2 >= 0) D = pic[r2][c2];
			
			var R1:Number = A - B - C + D ;
			var R2:Number = (0>R1)?0:R1 ;
			
			return R2 ; 
		}
		
		public function HaarX(row:int, column:int, size:int):Number
		{
			// bitwise v>>1   =  v/2
			
			return BoxIntegral(row - size >> 1, column, size, size >> 1)- 1 * BoxIntegral(row - size >> 1, column - size >> 1, size, size >>1);
		}
		
		public function HaarY(row:int, column:int, size:int):Number
		{
			return BoxIntegral(row, column - size >> 1, size >> 1, size)- 1 * BoxIntegral(row - size >> 1, column - size >> 1, size >> 1, size);
		}
		
		
		
	}
}