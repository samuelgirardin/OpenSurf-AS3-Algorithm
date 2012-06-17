package
{
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.getTimer;
	import surf.FastHessian;
	import surf.IPoint;
	import surf.IntegralImage;
	import surf.SurfDescriptor;
	
	/**
	 * @author Samuel Girardin __1
	 */
	
	[SWF(width='800',height='900',frameRate='60',backgroundColor='0xFFFFFF')]
	public class SurfAS extends Sprite
	{
		[Embed(source="assets/0.jpg")]
		private  static var picClass:Class;
		public static  var image:Bitmap = new picClass ; 
		
		[Embed(source="assets/1.jpg")]
		private  static var picClass1:Class;
		public static  var image1:Bitmap = new picClass1 ; 
		
		private var integral:IntegralImage ;
		private var integral1:IntegralImage ;
		private var ipts1:Vector.<IPoint> = new Vector.<IPoint>() ;
		private var ipts2:Vector.<IPoint> = new Vector.<IPoint>() ;
		
		private var afin:Number = 0.001 ;
		
		
		public function SurfAS()
		{
			addChild(image) ;
			addChild(image1) ;				
			
			integral = new IntegralImage(image) ; 			
			var f:FastHessian = new FastHessian(afin, 5, 3, integral) ;
			ipts1 = f.getIpoints() ;
			var surf:SurfDescriptor = new SurfDescriptor(ipts1, false, false, integral) ;  				
			
			for each (var ip:IPoint in ipts1)
			{
				var S:int = (2.5 * ip.scale);
				var R:int = (S* .5);
				var C:uint ;
				
				var AX:int = R * Math.cos(ip.orientation) ; 
				var AY:int = R * Math.sin(ip.orientation) ;  
				
				ip.laplacian > 0 ? C=0x0000ff : C=0xff0000 ; 				
				draw(ip.x,ip.y,S,R,C,AX,AY) ;
			}
			
			
			
			integral1 = new IntegralImage(image1) ; 
			var ff:FastHessian = new FastHessian(afin, 5, 3, integral1) ;
			ipts2 = ff.getIpoints() ;
			var surf1:SurfDescriptor = new SurfDescriptor(ipts2, false, false, integral1) ;
			
			image1.y = image1.height*2 ; 
			
			for each (ip in ipts2)
			{
				S = (2.5 * ip.scale);
				R = (S* .5);
				 
				
				 AX = R * Math.cos(ip.orientation) ; 
				 AY = R * Math.sin(ip.orientation) ;  
				
				ip.laplacian > 0 ? C=0x0000ff : C=0xff0000 ; 				
				draw(ip.x,ip.y+image1.height*2,S,R,C,AX,AY) ;
			}
			
			
			// compare !
			
			var dist:Number = 0;
			var d1:Number = 0 ;
			var d2:Number= 0 ;
			var match:IPoint ;
			var matches:Vector.<IPoint> = new Vector.<IPoint>() ;		
			
			
			
			for(var i:int = 0 ; i<ipts1.length ; i++) {
				d1 = d2 = Number.MAX_VALUE ;
				
				for(var j:int = 0 ; j<ipts2.length ; j++) {
					
					dist = soustract(ipts1[i],ipts2[j]) ;
					
					//trace("distance = "+dist) ; 
					
					if(dist<d1) // if this feature matches better than current best
					{						
						
						d2 = d1;
						d1 = dist;
						match = ipts2[j];
					}
					else if(dist<d2) // this feature matches better than second best
					{
						d2 = dist;
					}
				}
				
				
				//trace("d1/d2 " +d1/d2) ;
				
				if(d1/d2 < 0.65) 
				{ 
					
					// Store the change in position
					match.x - ipts1[i].x; 
					match.y - ipts1[i].y;
					matches.push(ipts1[i]);
					matches.push(match);
					
					var a:Point = new Point(ipts1[i].x,ipts1[i].y) ;
					var b:Point = new Point(match.x , match.y) ; 
					drawconnect(a,b) ; 
				}				
			}						
		}
		
		private function soustract(thi:IPoint,rhs:IPoint):Number {
			
			var sum:Number = 0  ;
			
			for(var i:int =0; i < 64; ++i) 		
				sum += (thi.descriptor[i] - rhs.descriptor[i])*(thi.descriptor[i] - rhs.descriptor[i]);		
			
			return Math.sqrt(sum);
			
		}
		
		
		private function drawconnect(a:Point , b:Point):void {			
		
			var s:Sprite = new Sprite(); 
			s.graphics.lineStyle(1,0xFF0000 * Math.random()*256) ; 
			s.graphics.moveTo(a.x,a.y) ; 
			s.graphics.lineTo(b.x,b.y+image1.height*2) ; 
			
			addChild(s) ; 
			
		}
		
		
		
		private function draw(X:int,Y:int,S:int,R:int,C:uint,AX:int,AY:int):void {
			
			var circle:Sprite = new Sprite() ;
			circle.graphics.beginFill(C,.05) ; 
			circle.graphics.lineStyle(.5,C) ; 
			circle.graphics.drawCircle(X,Y,S) ;
			circle.graphics.endFill() ;
			addChild(circle) ;
			
			var lin:Sprite = new Sprite(); 
			lin.graphics.lineStyle(1,0x00FF00) ;
			lin.graphics.moveTo(X,Y) ;
			lin.graphics.lineTo(X+AX,Y+AY) ;
			addChild(lin)  ;
			
		}
		
		
		
	}
}