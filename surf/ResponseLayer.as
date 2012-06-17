package surf
{
	import flash.display.Sprite;
	
	/**
	 * @author Samuel Girardin
	 */
	
	public class ResponseLayer 
	{
		
		public var width:int ;
		public var height:int ;
		public var step:int ;
		public var filter:int ;
		
		public var responses:Vector.<Number> ; 
		public var laplacian:Vector.<int> ; 
		
		public function ResponseLayer(_width:int, _height:int, _step:int , _filter:int)
		{
			super() ;
			
			width = _width;
			height = _height;
			step = _step;
			filter = _filter;
			
			responses = new Vector.<Number>(width*height) ; 
			laplacian = new Vector.<int>(width*height) ; 
		}
		
		public function getLaplacian(row:int, column:int):int {
			
			return laplacian[row * width + column];
		}
		
		public function getLaplacianR(row:int, column:int , src:ResponseLayer):int {
			
			var scale:int = width /src.width;;
			return laplacian[(scale * row) * width + (scale * column)];
		}
		
		public function getResponse(row:int, column:int):Number {
			
			return responses[row * width + column];
		}
		
		public function getResponsesR(row:int, column:int ,  src:ResponseLayer):Number {
			var scale:int = width / src.width;
			return responses[(scale * row) * width + (scale * column)];
		}
			
	
			
	}
}