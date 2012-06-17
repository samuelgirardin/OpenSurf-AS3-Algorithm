package surf
{
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.net.Responder;
	import flash.utils.getTimer;
	
	/**
	 * @author Samuel Girardin
	 */
	
	public class FastHessian 
	{
		private var  thresh:Number;
		private var octaves:int;
		private var init_sample:int;
		private var img:IntegralImage ; 
		
		private var ipts:Vector.<IPoint> ;
		private var responseMap:Vector.<ResponseLayer> ; 
		
		public static var elapsedTimeRoadMap:Number ;
		public static var elapsedTimeInterpolate:Number ;
		
		
		public function FastHessian(_thresh:Number , _octaves:int , _init_sample:int , _img:IntegralImage)
		{
			thresh = _thresh;
			octaves = _octaves;
			init_sample = _init_sample;
			img = _img ; 			
		}
		
		
		public function getIpoints():Vector.<IPoint> {
			
			var filter_map:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(5) ; 
			filter_map[0] =  Vector.<int>([0,1,2,3]); //, [1,3,4,5], [3,5,6,7], [5,7,8,9], [7,9,10,11]];
			filter_map[1] =  Vector.<int>([1,3,4,5]);
			filter_map[2] =  Vector.<int>([3,5,6,7]);
			filter_map[3] =  Vector.<int>([5,7,8,9]);
			filter_map[4] =  Vector.<int>([7,9,10,11]);
			
			// Clear the vector of exisiting ipts -> Sam on le crer on verra apres...			
			//if (ipts == null) ipts = new List<IPoint>();
			//else ipts.Clear();
			ipts = new Vector.<IPoint> ;
			
			// Build the response map
			var ti:Number = getTimer();
			buildResponseMap();
			elapsedTimeRoadMap = getTimer() - ti ; 
			
			var b:ResponseLayer ; 
			var m:ResponseLayer ; 
			var t:ResponseLayer ; 
			
			var tii:Number = getTimer() ;
			
			for (var o:int = 0; o < octaves; ++o)
			{
				for (var i:int = 0; i <= 1; ++i)
				{					
					b = responseMap[filter_map[o][i]];
					m = responseMap[filter_map[o][i+1]];
					t = responseMap[filter_map[o][i+2]];
					
					// loop over middle response layer at density of the most 
					// sparse layer (always top), to find maxima across scale and space
					for (var r:int = 0; r < t.height; ++r)
					{
						for (var  c:int = 0; c < t.width; ++c)
						{
							
							
							if (isExtremum(r, c, t, m, b))
							{	
								interpolateExtremum(r, c, t, m, b);						
							}
						}
					}
				}
			}
			
			elapsedTimeInterpolate = getTimer()-tii ;
			
			// Get the response layers			
			return ipts ; 
			
		}
		
		
		private function  buildResponseMap():void {			
			
			// Calculate responses for the first 4 octaves:
			// Oct1: 9,  15, 21, 27
			// Oct2: 15, 27, 39, 51
			// Oct3: 27, 51, 75, 99
			// Oct4: 51, 99, 147,195
			// Oct5: 99, 195,291,387
			
			// Deallocate memory and clear any existing response layers -> Sam on le creer seulement
			//if (responseMap == null) responseMap = new List<ResponseLayer>();
			//else responseMap.Clear();
			responseMap = new Vector.<ResponseLayer> ;			
			
			var  w:int = (img.Width / init_sample);
			var  h:int = (img.Height / init_sample);
			var  s:int = (init_sample);
			
			//trace(w+" "+h+" "+s) ; 
						
			/*
		    if (octaves >= 1)
			{
				responseMap.push(new ResponseLayer(w,   h,   s,   9));
				responseMap.push(new ResponseLayer(w, h, s, 15));
				responseMap.push(new ResponseLayer(w, h, s, 21));
				responseMap.push(new ResponseLayer(w, h, s, 27));
			}
			
			if (octaves >= 2)
			{
				responseMap.push(new ResponseLayer(w >>1 , h>>1, s <<1, 39));
				responseMap.push(new ResponseLayer(w >>1,  h>>1, s <<1, 51));
			}
			
			if (octaves >= 3)
			{
				responseMap.push(new ResponseLayer(w >> 2, h>> 2, s << 2, 75));
				responseMap.push(new ResponseLayer(w >> 2, h >> 2, s <<2, 99));
			}
			
			if (octaves >= 4)
			{
				responseMap.push(new ResponseLayer(w >>3, h>>3, s << 3, 147));
				responseMap.push(new ResponseLayer(w >>3, h>>3, s <<3, 195));
			}
			
			if (octaves >= 5)
			{
				responseMap.push(new ResponseLayer(w >>4, h>>4, s <<4, 291));
				responseMap.push(new ResponseLayer(w >>4, h>>4, s <<4, 387));
			}
			*/
			
			
			if (octaves >= 1)
			{
				responseMap.push(new ResponseLayer(w,   h,   s,   9));
				responseMap.push(new ResponseLayer(w, h, s, 15));
				responseMap.push(new ResponseLayer(w, h, s, 21));
				responseMap.push(new ResponseLayer(w, h, s, 27));
			}
			
			if (octaves >= 2)
			{
				responseMap.push(new ResponseLayer(w / 2, h / 2, s * 2, 39));
				responseMap.push(new ResponseLayer(w / 2, h / 2, s * 2, 51));
			}
			
			if (octaves >= 3)
			{
				responseMap.push(new ResponseLayer(w / 4, h / 4, s * 4, 75));
				responseMap.push(new ResponseLayer(w / 4, h / 4, s * 4, 99));
			}
			
			if (octaves >= 4)
			{
				responseMap.push(new ResponseLayer(w / 8, h / 8, s * 8, 147));
				responseMap.push(new ResponseLayer(w / 8, h / 8, s * 8, 195));
			}
			
			if (octaves >= 5)
			{
				responseMap.push(new ResponseLayer(w / 16, h / 16, s * 16, 291));
				responseMap.push(new ResponseLayer(w / 16, h / 16, s * 16, 387));
			}			
			
			for (var i:int = 0; i < responseMap.length; ++i)
			{
				buildResponseLayer(responseMap[i]);
			}
		}	
		
		private function buildResponseLayer(rl:ResponseLayer):void {			
			
						
			
			var step:int = rl.step;  // step size for this filter
			var b:int = (rl.filter - 1) >>1;             // border for this filter
			var l:int = rl.filter / 3;                   // lobe for this filter (filter size / 3)
			var w:int = rl.filter;                       // filter size
			var inverse_area:Number = 1 / (w * w);       // normalisation factor
			var Dxx:Number ; 
			var Dyy:Number ; 
			var Dxy:Number ;
			
			var r:int = 0 ; 
			var c:int = 0 ; 
			var ar:int = 0 ; 
			var index:int = 0 ; 
			var ac:int = 0 ;
			
						
			
			for(ar = 0 ; ar<rl.height ; ++ar) {
				for(ac = 0 ; ac <rl.width ; ++ac,index++) {					
					
					r = ar * step;
					c = ac * step;				
					
					
					/*Dxx = img.BoxIntegral(r - l + 1, c - b, (l<<1) - 1, w)
						- img.BoxIntegral(r - l + 1, c - (l >>1), (l<<1) - 1, l) * 3;
					Dyy = img.BoxIntegral(r - b, c - l + 1, w, (l<<1) - 1)
						- img.BoxIntegral(r - (l >> 1), c - l + 1, l, (l<<1) - 1) * 3;
					Dxy = + img.BoxIntegral(r - l, c + 1, l, l)
						+ img.BoxIntegral(r + 1, c - l, l, l)
						- img.BoxIntegral(r - l, c - l, l, l)
						- img.BoxIntegral(r + 1, c + 1, l, l);
					
					// Normalise the filter responses with respect to their size
					Dxx *= inverse_area;
					Dyy *= inverse_area;
					Dxy *= inverse_area;
					
					rl.responses[index] = (Dxx * Dyy - 0.81 * Dxy * Dxy);
					rl.laplacian[index] = (Dxx + Dyy >= 0 ? 1 : 0);*/
					
					Dxx = img.BoxIntegral(r - l + 1, c - b, 2 * l - 1, w)
						- img.BoxIntegral(r - l + 1, c - l / 2, 2 * l - 1, l) * 3;
					Dyy = img.BoxIntegral(r - b, c - l + 1, w, 2 * l - 1)
						- img.BoxIntegral(r - l / 2, c - l + 1, l, 2 * l - 1) * 3;
					Dxy = + img.BoxIntegral(r - l, c + 1, l, l)
						+ img.BoxIntegral(r + 1, c - l, l, l)
						- img.BoxIntegral(r - l, c - l, l, l)
						- img.BoxIntegral(r + 1, c + 1, l, l);
					
					// Normalise the filter responses with respect to their size
					Dxx *= inverse_area;
					Dyy *= inverse_area;
					Dxy *= inverse_area;
					
					rl.responses[index] = (Dxx * Dyy - 0.81 * Dxy * Dxy);
					rl.laplacian[index] = (Dxx + Dyy >= 0 ? 1 : 0);
					
					
				
					
				}				
			}			
		}
		
		
		private function isExtremum(r:int, c:int, t:ResponseLayer , m:ResponseLayer , b:ResponseLayer):Boolean{
			
			// bounds check
			var layerBorder:int = (t.filter + 1) / (2 * t.step);
			if (r <= layerBorder || r >= t.height - layerBorder || c <= layerBorder || c >= t.width - layerBorder)
			{
				return false;
			}
			
			// check the candidate point in the middle layer is above thresh 
			var candidate:Number = m.getResponsesR(r, c, t);
			if (candidate < thresh)
			{
				return false;
			}
			//trace("false  areps 1") ; 
			for (var rr:int = -1; rr <= 1; ++rr)
			{
				for (var  cc:int = -1; cc <= 1; ++cc)
				{
					// if any response in 3x3x3 is greater candidate not maximum
					if (    t.getResponse(r + rr, c + cc) >= candidate ||
						((rr != 0 || cc != 0) && m.getResponsesR(r + rr, c + cc, t) >= candidate) ||
						b.getResponsesR(r + rr, c + cc, t) >= candidate)
					
					{   
						return false;
					}
				}
			}				
			
			return true ;			
		}
		
		private function interpolateExtremum(r:int, c:int, t:ResponseLayer , m:ResponseLayer , b:ResponseLayer):void {
			
			
			var v1:Vector.<Number> = buildDerivative(r, c, t, m, b)
			
			var v2:Vector.<Vector.<Number>> = buildHessian(r, c, t, m, b) ;
			
			var H:matrix = new matrix(3,3) ;
		    H.setElement(0, 0, v2[0][ 0]); 
			H.setElement(0, 1, v2[0][ 1]);
			H.setElement(0, 2, v2[0][ 2]);
			H.setElement(1, 0, v2[1][ 0]);
			H.setElement(1, 1, v2[1][ 1]);
			H.setElement(1, 2, v2[1][ 2]);
			H.setElement(2, 0, v2[2][ 0]);
			H.setElement(2, 1, v2[2][ 1]);
			H.setElement(2, 2, v2[2][ 2]);
			
			var Hi:matrix = H.inverse() ;
			
			var aa:Number =Hi.getElement(0, 0);
			var bb:Number =Hi.getElement(0, 1);
			var cc:Number =Hi.getElement(0, 2);
			var dd:Number =Hi.getElement(1, 0);
			var ee:Number =Hi.getElement(1, 1);
			var ff:Number =Hi.getElement(1, 2);
			var gg:Number =Hi.getElement(2, 0);
			var hh:Number =Hi.getElement(2, 1);
			var ii:Number =Hi.getElement(2, 2);	
			
			
			var a1:Number =-( v1[0]* aa +		v1[1] * bb   +    v1[2]*cc)     ;
			var b1:Number =-( v1[0]* dd +		v1[1]  *ee   +    v1[2]*ff)     ; 
			var c1:Number =-( v1[0]* gg +		v1[1] * hh   +    v1[2]*ii)     ; 
			
			
			
			
			/*var a2:Number ;
			var b2:Number ;
			var c2:Number ;
			
			var a3:Number ;
			var b3:Number ;
			var c3:Number ;
			
			var a4:Number ;
			var b4:Number ;
			var c4:Number ;
			
			a2 = v1[0]* aa +		v1[1] * dd   +    v1[2]*gg     ;
			b2 = v1[0]* bb +		v1[1]  *ee   +    v1[2]*hh     ; 
			c2 = v1[0]* cc +		v1[1] * ff   +    v1[2]*ii     ;
			
			a3 = v1[0]* aa +		v1[0] * dd   +    v1[0]*gg     ;
			b3 = v1[1]* bb +		v1[1]  *ee   +    v1[1]*hh     ; 
			c3 = v1[2]* cc +		v1[2] * ff   +    v1[2]*ii     ;
			
			a4 = v1[0]* aa +		v1[0] * bb   +    v1[0]*cc     ;
			b4 = v1[1]* dd +		v1[1]  *ee   +    v1[1]*ff     ; 
			c4 = v1[2]* gg +		v1[2] * hh   +    v1[2]*ii     ;*/
			
			
			
			//trace("dam"+a1+"  "+b1+"  "+c1) ;
			//trace("hjx"+a2+"  "+b2+"  "+c2) ;
			//trace("DDD"+a3+"  "+b3+"  "+c3) ;
			//trace("EEE"+a4+"  "+b4+"  "+c4) ;
			
			
			//trace("ok") ; 
			
			//var Of:matrix = Hi.mulMatrix(D) ;
			
			
			
			//trace(Hi.getElement(0,0)) ; 
			//trace(Of.getElement(0,0)) ; 
			
			var filterStep:int = (m.filter - b.filter);
			if (Math.abs(a1) < 0.5 && Math.abs(b1) < 0.5 && Math.abs(c1) < 0.5) {
				
				var ipt:IPoint = new IPoint() ;
				ipt.x = (c+a1)*t.step ;
				ipt.y = (r+b1)*t.step ;
				
				ipt.scale = 0.1333 * (m.filter + c1 * filterStep);
				ipt.laplacian = (int)(m.getLaplacianR(r,c,t));
				ipts.push(ipt) ;
				
				var x1:Number =(c+a1)*t.step ;
				var y1:Number =(r+b1)*t.step ;
			    var z1:Number =ipt.scale;
				//trace("x1 :"+x1+"    y1 :"+y1 +"   z :"+z1) ; 
				
			}
			
			
		}
		
		private function buildDerivative(r:int, c:int, t:ResponseLayer , m:ResponseLayer , b:ResponseLayer):Vector.<Number> {			
			
			//trace("dans build derivative") ; 
			
			var dx:Number = 0  ; 
			var dy:Number = 0  ; 
			var ds:Number = 0  ;					
			
			dx = (m.getResponsesR(r, c + 1, t) - m.getResponsesR(r, c - 1, t)) *.5;
			dy = (m.getResponsesR(r + 1, c, t) - m.getResponsesR(r - 1, c, t)) *.5;
			ds = (t.getResponse(r, c) - b.getResponsesR(r, c, t)) *.5;
			
			var D:Vector.<Number> = new Vector.<Number>(3) ;
						
			D[0] = dx ;
			D[1] = dy ; 
			D[2] = ds ;			
			
				
			return D ;
		}
		
		private function buildHessian(r:int, c:int, t:ResponseLayer , m:ResponseLayer , b:ResponseLayer):Vector.<Vector.<Number>>
		{
			var v:Number   = 0 ; 
			var dxx:Number = 0  ; 
			var dyy:Number = 0  ; 
			var dss:Number = 0  ;	
			var dxy:Number = 0  ; 
			var dxs:Number = 0  ; 
			var dys:Number = 0  ;	
			
			v = m.getResponsesR(r,c,t) ; 
			
			
			dxx = m.getResponsesR(r, c + 1, t) + m.getResponsesR(r, c - 1, t) - 2 * v;
			dyy = m.getResponsesR(r + 1, c, t) + m.getResponsesR(r - 1, c, t) - 2 * v;
			dss = t.getResponse(r, c) + b.getResponsesR(r, c, t) - 2 * v;
			dxy = (m.getResponsesR(r + 1, c + 1, t) - m.getResponsesR(r + 1, c - 1, t) -
				m.getResponsesR(r - 1, c + 1, t) + m.getResponsesR(r - 1, c - 1, t)) *.25;
			dxs = (t.getResponse(r, c + 1) - t.getResponse(r, c - 1) -
				b.getResponsesR(r, c + 1, t) + b.getResponsesR(r, c - 1, t)) *.25;
			dys = (t.getResponse(r + 1, c) - t.getResponse(r - 1, c) -
				b.getResponsesR(r + 1, c, t) + b.getResponsesR(r - 1, c, t)) *.25;
			
			var H:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(9) ;
			
			for (var x:int = 0; x < H.length ;  x++)
			{
				H[x] = new Vector.<Number>(2) ;
				
			}	
			
			H[0][ 0] = dxx;
			H[0][ 1] = dxy;
			H[0][ 2] = dxs;
			H[1][ 0] = dxy;
			H[1][ 1] = dyy;
			H[1][ 2] = dys;
			H[2][ 0] = dxs;
			H[2][ 1] = dys;
			H[2][ 2] = dss;
		
			
			return H ; 
			
		}
		
		
		
		
	}
}