package surf
{
	
	/**
	 * @author Samuel Girardin
	 */
	public class IPoint
	{
		
		public var x:Number ; 
		public var y:Number ; 
		public var scale:Number ; 
		public var response:Number ; 
		public var orientation:Number ; 
		public var laplacian:int ;
		public var descriptorLength:int  ; 
		public var descriptor:Vector.<Number> ;
		
		
		public function IPoint()
		{
			
		}
						
		public function  SetDescriptorLength(Size:int):void {
			
			descriptorLength = Size;
			descriptor = new Vector.<Number>(Size) ; 
		
			
		}
		
		
	}
}