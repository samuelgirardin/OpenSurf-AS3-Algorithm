package surf
{
	import flash.geom.Point;
	
	/**
	 * @author Samuel Girardin
	 */

	public class SurfDescriptor
	{
		private var gauss25:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(7) ; 
		private var  img:IntegralImage ;
		private var pi:Number = Math.PI ;
		
		public function SurfDescriptor(ipts:Vector.<IPoint> , upright:Boolean , extended:Boolean , img:IntegralImage)
		{
			//ini de gauss25 ;
			gauss25[0] = Vector.<Number>([0.02350693969273,0.01849121369071,0.01239503121241,0.00708015417522,0.00344628101733,0.00142945847484,0.00050524879060]);
			gauss25[1] = Vector.<Number>([0.02169964028389,0.01706954162243,0.01144205592615,0.00653580605408,0.00318131834134,0.00131955648461,0.00046640341759]);
			gauss25[2] = Vector.<Number>([0.01706954162243,0.01342737701584,0.00900063997939,0.00514124713667,0.00250251364222,0.00103799989504,0.00036688592278]);
			gauss25[3] = Vector.<Number>([0.01144205592615,0.00900063997939,0.00603330940534,0.00344628101733,0.00167748505986,0.00069579213743,0.00024593098864]);
			gauss25[4] = Vector.<Number>([0.00653580605408,0.00514124713667,0.00344628101733,0.00196854695367,0.00095819467066,0.00039744277546,0.00014047800980]);
			gauss25[5] = Vector.<Number>([0.00318131834134,0.00250251364222,0.00167748505986,0.00095819467066,0.00046640341759,0.00019345616757,0.00006837798818]);
			gauss25[6] = Vector.<Number>([0.00131955648461,0.00103799989504,0.00069579213743,0.00039744277546,0.00019345616757,0.00008024231247,0.00002836202103]);
			
		
			
			DescribeInterestPoints(ipts, upright, extended, img);
			
		}
		
		public function DescribeInterestPoints(ipts:Vector.<IPoint> , upright:Boolean , extended:Boolean , img:IntegralImage):void {
			
			if(ipts.length==0) {
				trace("ipts is empty, return") ;
				return ;
			}
			
			this.img = img ;
			
			for each(var ip:IPoint in ipts){
				
				// determine descriptor size
				if (extended) ip.descriptorLength = 128;
				else ip.descriptorLength = 64;
				// if we want rotation invariance get the orientation
				if (!upright) GetOrientation(ip);
				
				// Extract SURF descriptor
				GetDescriptor(ip, upright, extended);
			}
			
		}
		
		private function GetOrientation(ip:IPoint):void {
			
			const Responses:int = 109 ;
			var resX:Vector.<Number> = new Vector.<Number>(Responses) ; 
			var resY:Vector.<Number> = new Vector.<Number>(Responses) ; 
			var Ang:Vector.<Number> = new Vector.<Number>(Responses) ; 
			
			var idx:int = 0 ; 
			var id:Vector.<int> = Vector.<int>([6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6 ]) ; 
			
			// Get rounded InterestPoint data
			var X:int = int(Math.round(ip.x)) ;
			var Y:int = int(Math.round(ip.y)) ;
			var S:int = int(Math.round(ip.scale)) ;
			// calculate haar responses for points within radius of 6*scale
			 
			
			for (var i:int = -6; i <= 6; ++i)
			{
				for (var j:int = -6; j <= 6; ++j)
				{
					if (i * i + j * j < 36)
					{
						
						
						var gauss:Number ;
						
						var a1:int = id[i+6] ; var a2:int = id[j+6] ;
						
						gauss= gauss25[a1][ a2];
						resX[idx] = gauss * img.HaarX(Y + j * S, X + i * S, 4 * S);
						resY[idx] = gauss * img.HaarY(Y + j * S, X + i * S, 4 * S);
						Ang[idx] = Number(GetAngle(resX[idx], resY[idx]));
						++idx;
					}
				}
			}
			
			// calculate the dominant direction 
			
			var sumX:Number ; 
			var sumY:Number ;
			var max:Number =0 ;
			var orientation:Number =0 ;
			var ang1:Number ;
			var ang2:Number ;
			
			
			for (ang1 = 0; ang1 < 2 * pi; ang1 += 0.15)
			{
				ang2 = (ang1 + pi / 3 > 2 * pi ? ang1 - 5 * pi / 3 : ang1 + pi / 3);
				sumX = sumY = 0;
				
				for (var k:int = 0; k < Responses; ++k)
				{
					// determine whether the point is within the window
					if (ang1 < ang2 && ang1 < Ang[k] && Ang[k] < ang2)
					{
						sumX += resX[k];
						sumY += resY[k];
					}
					else if (ang2 < ang1 &&
						((Ang[k] > 0 && Ang[k] < ang2) || (Ang[k] > ang1 && Ang[k] < pi)))
					{
						sumX += resX[k];
						sumY += resY[k];
					}
				}
				
				// if the vector produced from this window is longer than all 
				// previous vectors then this forms the new dominant direction
				if (sumX * sumX + sumY * sumY > max)
				{
					// store largest orientation
					max = sumX * sumX + sumY * sumY;
					orientation = GetAngle(sumX, sumY);
				}
			}
			
			ip.orientation = orientation ;			
			
			
		}
		
		private function GetDescriptor(ip:IPoint , bUpright:Boolean , bExtended:Boolean):void {
			
			var sample_x:int = 0 ; 
			var sample_y:int = 0 ;
			var count:int = 0 ; 
			var i:int =0 ;
			var ix:int = 0 ;
			var j:int = 0 ; 
			var jx:int = 0 ;
			var xs:int = 0 ; 
			var ys:int = 0 ; 
			var dx:Number
			var dy :Number
			var mdx:Number
			var mdy:Number
			var co :Number
			var si:Number
			var dx_yn:Number
			var mdx_yn:Number
			var dy_xn:Number
			var mdy_xn:Number
			var gauss_s1:Number =0 ;
			var gauss_s2 :Number = 0 ;
			var rx:Number= 0 ;
			var ry:Number= 0 ;
			var rrx:Number= 0 ;
			var rry:Number= 0 ;
			var len :Number= 0 ;
			var cx:Number = -0.5 ;
			var cy:Number =0 ; 
			
			var X:int = int(Math.round(ip.x)) ; 
			var Y:int = int(Math.round(ip.y)) ; 
			var S:int = int(Math.round(ip.scale)) ; 
			
			// Allocate descriptor memory
			ip.SetDescriptorLength(64) ; 
			
			if (bUpright)
			{
				co = 1;
				si = 0;
			}
			else
			{
				co = Math.cos(ip.orientation);
				si = Math.sin(ip.orientation);
			}
			
			//Calculate descriptor for this interest point
			i = -8;
			while (i < 12)
			{
				j = -8;
				i = i - 4;
				
				cx += 1;
				cy = -0.5;
				
				while (j < 12)
				{
					cy += 1;
					
					j = j - 4;
					
					ix = i + 5;
					jx = j + 5;
					
					dx = dy = mdx = mdy = 0;
					dx_yn = mdx_yn = dy_xn = mdy_xn = 0;
					
					xs = int(Math.round(X + (-jx * S * si + ix * S * co)));
					ys = int(Math.round(Y + ( jx * S * co + ix * S * si)));
					
					// zero the responses
					dx = dy = mdx = mdy = 0;
					dx_yn = mdx_yn = dy_xn = mdy_xn = 0;
					
					for (var k:int = i; k < i + 9; ++k)
					{
						for (var l:int = j; l < j + 9; ++l)
						{
							//Get coords of sample point on the rotated axis
							sample_x = int(Math.round(X + (-l * S * si + k * S * co)));
							sample_y = int(Math.round(Y + (l * S * co + k * S * si)));
							
							//Get the gaussian weighted x and y responses
							gauss_s1 = GaussianInt(xs - sample_x, ys - sample_y, 2.5 * S);
							rx = img.HaarX(sample_y, sample_x, 2 * S);
							ry = img.HaarY(sample_y, sample_x, 2 * S);
							
							//Get the gaussian weighted x and y responses on rotated axis
							rrx = gauss_s1 * (-rx * si + ry * co);
							rry = gauss_s1 * (rx * co + ry * si);
							
							
							if (bExtended)
							{
								// split x responses for different signs of y
								if (rry >= 0)
								{
									dx += rrx;
									mdx += Math.abs(rrx);
								}
								else
								{
									dx_yn += rrx;
									mdx_yn += Math.abs(rrx);
								}
								
								// split y responses for different signs of x
								if (rrx >= 0)
								{
									dy += rry;
									mdy += Math.abs(rry);
								}
								else
								{
									dy_xn += rry;
									mdy_xn += Math.abs(rry);
								}
							}
							else
							{
								dx += rrx;
								dy += rry;
								mdx += Math.abs(rrx);
								mdy += Math.abs(rry);
							}
						}
					}
					//Add the values to the descriptor vector
					gauss_s2 = GaussianNumber(cx - 2, cy - 2, 1.5);
					
					ip.descriptor[count++] = dx * gauss_s2;
					ip.descriptor[count++] = dy * gauss_s2;
					ip.descriptor[count++] = mdx * gauss_s2;
					ip.descriptor[count++] = mdy * gauss_s2;
					
					// add the extended components
					if (bExtended)
					{
						ip.descriptor[count++] = dx_yn * gauss_s2;
						ip.descriptor[count++] = dy_xn * gauss_s2;
						ip.descriptor[count++] = mdx_yn * gauss_s2;
						ip.descriptor[count++] = mdy_xn * gauss_s2;
					}
					
					len += (dx * dx + dy * dy + mdx * mdx + mdy * mdy
						+ dx_yn + dy_xn + mdx_yn + mdy_xn) * gauss_s2 * gauss_s2;
					
					j += 9;
				}
				i += 9;
			}
			
			//Convert to Unit Vector
			len =  Math.sqrt(len) ;
			if (len > 0)
			{
				for (var d:int = 0; d < ip.descriptorLength; ++d)
				{
					ip.descriptor[d] /= len;
				}
			}
					
			
			
		}
			
		
		
		private function GetAngle(X:Number , Y:Number):Number {
		
			var v:Number ; 
			
			if (X >= 0 && Y >= 0)
				v= Math.atan(Y / X);
			else if (X < 0 && Y >= 0)
				v= pi - Math.atan(-Y / X);
			else if (X < 0 && Y < 0)
				v= pi + Math.atan(Y / X);
			else if (X >= 0 && Y < 0)
				v= 2 * pi - Math.atan(-Y / X);
		
			return v ;
		}
		
		private function GaussianInt(x:int, y:int, sig:Number):Number {
			
			
			return (1 / (6.2831 * sig * sig)) * Math.exp(-(x * x + y * y) / (2.0 * sig * sig));
			
		}
		
		private function GaussianNumber(x:Number, y:Number, sig:Number):Number {
			
			
			return 1 / (6.2831 * sig * sig) * Math.exp(-(x * x + y * y) / (2.0* sig * sig));
			
		}
		
	}
}