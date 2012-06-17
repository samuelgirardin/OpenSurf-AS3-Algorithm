package surf 
{
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	
	public final class matrix extends Object
	{
		
		public static const opMul:String = "Multiplication";
		public static const opAdd:String = "Addition";
		public static const opSub:String = "Subtract";
		public static const opInv:String = "Inverse";
		public static const opFMX:String = "ToFlashMatrix";
		public static const opFM3:String = "ToFlashMatrix3D";
		
		private var data:Vector.<Number>;
		private var W:uint;
		private var H:uint;
		
		public var newLine:Boolean = true;
		
		//Constructor. Takes in width, height, and an array of data. You do not have to fill the matrix early, but you can't over-flow it.
		public function matrix ( width:uint, height:uint, ... dat )
		{
			
			data = new Vector.<Number> ( width * height, true );
			
			W = width;
			H = height;
			
			if ( dat.length > W * H )
				throw new Error ( "More data provided than fits in matrix.", 0 );
			
			for ( var n:uint = 0; n < dat.length; n ++ )
				data [ n ] = dat [ n ];
			
		};
		
		//Set a specific element to a value, in X-Y form, top left being the origin, going down and to the right.
		public function setElement ( x:uint, y:uint, value:Number ) : void
		{
			
			if ( x >= W || y >= H )
				throw new Error ( "The coordinance ( " + x + ", " + y + " ) is out of the matrix bounds.", 1 );
			
			data [ x + y * W ] = value;
			
		};
		
		//Add similar matrices.
		public function add ( mat:matrix ) : matrix
		{
			
			if ( mat.width != W || mat.height != H )
				throw new Error ( "Mismatched dimensions for adding.", 2 );
			
			var ret:matrix = new matrix ( W, H );
			
			for ( var x:uint = 0; x < W; x ++ )
			{
				
				for ( var y:uint = 0; y < H; y ++ )
				{
					
					ret.setElement ( x, y, data [ x + y * H ] + mat.getElement ( x, y ) );
					
				}
				
			}
			
			return ret;
			
		};
		
		//Subtract similar matrices
		public function sub ( mat:matrix ) : matrix
		{
			
			if ( mat.width != W || mat.height != H )
				throw new Error ( "Mismatched dimensions for adding.", 3 );
			
			var ret:matrix = new matrix ( W, H );
			
			for ( var x:uint = 0; x < W; x ++ )
			{
				
				for ( var y:uint = 0; y < H; y ++ )
				{
					
					ret.setElement ( x, y, data [ x + y * H ] - mat.getElement ( x, y ) );
					
				}
				
			}
			
			return ret;
			
		};
		
		//Multiply all the elements of an array my a value.
		public function mulUniform ( val:Number ):matrix
		{
			
			var ret:matrix = new matrix ( W, H );
			
			for ( var n:uint = 0; n < W * H; n ++ )
			{
				
				ret.setElement ( n % W, ( n - n % W ) / W, val * data [ n ] );
				
			}
			
			return ret;
			
		};
		
		//Multiply two matrices.
		public function mulMatrix ( mat:matrix ) : matrix
		{
			
			if ( W != mat.height )
				throw new Error ( "Mismatched dimensions for multiplication.", 4 );
			
			var ret:matrix = new matrix ( mat.width, H );
			var curr:Number;
			
			for ( var x:uint = 0; x < mat.width; x ++ )
				for ( var y:uint = 0; y < H; y ++ )
				{
					
					curr = 0;
					
					for ( var n:uint = 0; n < W; n ++ )
						curr += mat.getElement ( x, n ) * data [ n * W + y ];
					
					ret.setElement ( x, y, curr );
					
				}
			
			return ret;
			
		};
		
		//Get the inverse of the matrix. ( Only works with 1x1, 2x2, or 3x3 matrices.
		public function inverse () : matrix
		{
			
			if ( !operationSupported ( opInv ) )
				throw new Error ( "inversion is not possible on this matrix.", 5 );
			
			var ret:matrix = new matrix ( W, H );
			var mul:Number;
			
			if ( W == 1 )
				ret.setElement ( 0, 0, 1 / data [ 0 ] );
			
			if ( W == 2 )
			{
				
				mul = 1 / ( data [ 0 ] * data [ 3 ] - data [ 1 ] * data [ 2 ] );
				
				ret.setElement ( 0, 0, data [ 3 ] * mul );
				ret.setElement ( 1, 0, -data [ 1 ] * mul );
				
				ret.setElement ( 0, 1, -data [ 2 ] * mul );
				ret.setElement ( 1, 1, data [ 0 ] * mul );
				
			}
			
			if ( W == 3 )
			{
				
				mul = 1 / ( data [ 0 ] * ( ( data [ 4 ] * data [ 8 ] ) - ( data [ 5 ] * data [ 7 ] ) ) + data [ 1 ] * ( ( data [ 5 ] * data [ 6 ] ) - ( data [ 8 ] * data [ 3 ] ) ) + data [ 2 ] * ( ( data [ 3 ] * data [ 7 ] ) - ( data [ 4 ] * data [ 6 ] ) ) );
				
				ret.setElement ( 0, 0, ( data [ 4 ] * data [ 8 ] - data [ 5 ] * data [ 7 ] ) );
				ret.setElement ( 0, 1, ( data [ 2 ] * data [ 7 ] - data [ 1 ] * data [ 8 ] ) );
				ret.setElement ( 0, 2, ( data [ 1 ] * data [ 5 ] - data [ 2 ] * data [ 4 ] ) );
				
				ret.setElement ( 1, 0, ( data [ 5 ] * data [ 6 ] - data [ 3 ] * data [ 8 ] ) );
				ret.setElement ( 1, 1, ( data [ 0 ] * data [ 8 ] - data [ 2 ] * data [ 6 ] ) );
				ret.setElement ( 1, 2, ( data [ 2 ] * data [ 3 ] - data [ 0 ] * data [ 5 ] ) );
				
				ret.setElement ( 2, 0, ( data [ 3 ] * data [ 7 ] - data [ 4 ] * data [ 6 ] ) );
				ret.setElement ( 2, 1, ( data [ 6 ] * data [ 1 ] - data [ 0 ] * data [ 7 ] ) );
				ret.setElement ( 2, 2, ( data [ 0 ] * data [ 4 ] - data [ 1 ] * data [ 3 ] ) );
				
				ret = ret.mulUniform ( mul );
				
			}
			
			return ret;
			
		}
		
		//Get the value of a specific element, similarly to setElement.
		public function getElement ( x:uint, y:uint ) : Number
		{
			
			return data [ x + y * W ];
			
		};
		
		//Width getter
		public function get width () : uint
		{
			
			return W;
			
		};
		
		//Height getter
		public function get height () : uint
		{
			
			return H;
			
		};
		
		//Returns the raw number data in an array.
		public function getRawData () : Vector.<Number>
		{
			
			return data;
			
		};
		
		/*Test if a matrix can have a certain operation 
		preformed on it. This includes multiplication, 
		addition and subtraction with other matricies,
		getting the inverse, and converting to flash 
		display transform matrices.
		*/
		public function operationSupported ( operation:String, second:matrix = null ) : Boolean
		{
			
			if ( !( operation == opFMX || operation == opFM3 || operation == opInv || second != null ) )
				throw new Error ( "Second matrix not provided to test for operability.", 6 );
			
			switch ( operation )
			{
				
				case opInv:
					if ( ( W == 3 && H == 3 ) || ( W == 2 && H == 2 ) || ( W == 1 && H == 1 ) )
						return true;
					else
						return false;
					break;
				
				case opAdd:
					if ( W == second.width && H == second.height )
						return true;
					else
						return false;
					break;
				
				case opSub:
					if ( W == second.width && H == second.height )
						return true;
					else
						return false;
					break;
				
				case opMul:
					
					if ( W == second.height )
						return true;
					else
						return false;
					
				case opFMX:
					
					if ( W == 3 && H == 3 || W == 3 && H == 2 )
						return true;
					else
						return false;
					break;
				
				case opFM3:
					
					if ( W == 4 && H == 4 )
						return true;
					else
						return false;
					
					break;
				
				default:
					
					throw new Error ( operation + " is not an operation you can test for.", 7 );
					
					break;
				
			}
			
			return false;
			
		};
		
		public function toString () : String
		{
			
			var out:String = ( newLine ) ? '' : '[ ';
			var maxL:Vector.<uint> = new Vector.<uint> ( W, true );
			
			var qx:uint;
			var sp:String;
			var sa:String;
			
			for ( var n:uint = 0; n < W * H; n ++ )
			{
				
				qx = n % W;
				maxL [ qx ] = Math.max ( maxL [ qx ], data [ n ].toString ().length );
				
			}
			
			for ( var y:uint = 0; y < H; y ++ )
				for ( var x:uint = 0; x < W; x ++ )
				{
					
					sp = '';
					sa = data [ x + y * W ].toString ( 10 );
					
					while ( sa.length < maxL [ x ] && newLine )
						sa = ' ' + sa;
					
					if ( x == 0 )
						out += '[ ';
					
					out += sa;
					
					if ( x < W - 1 )
						out += ', ';
					else
					{
						
						out += ' ]';
						if ( y < H - 1 )
							out += ( newLine ) ? '\n' : ' ';
						
					}
					
				}
			
			out += ( newLine ) ? '' : ' ]';
			
			var t:String = '';
			
			if ( out.indexOf ( "\n" ) != 0 )
			{
				
				var u:uint = 0;
				while ( u ++ < out.indexOf ( "\n" ) )
					t += '-';
				
			}
			else
			{
				
				var g:uint = 0;
				while ( g ++ < out.length )
					t += '-';
				
			}
			
			if ( newLine )
				out = "Matrix:\n" + t + '\n' + out + '\n' + t;
			
			return out;
			
		};
		
		//Makes the matrix into a flash transform matrix.
		public function toFlashMatrix () : flash.geom.Matrix
		{
			
			if ( ! operationSupported ( opFMX ) )
				throw new Error ( "Cannot convert to flash matrix. ( wrond dimentions )", 8 );
			
			var ret:flash.geom.Matrix = new flash.geom.Matrix ( data [ 0 ], data [ 1 ], data [ 3 ], data [ 4 ], data [ 2 ], data [ 5 ] );
			return ret;
			
		}
		
		//Makes the matrix a Flash 3D transform matrix.
		public function toFlashMatrix3D () : flash.geom.Matrix3D
		{
			
			if ( ! operationSupported ( opFM3 ) )
				throw new Error ( "Cannot convert to flash matrix. ( wrond dimentions )", 9 );
			
			var ret:flash.geom.Matrix3D = new flash.geom.Matrix3D ( data );
			return ret;
			
		}
		
		//Generates an identity matrix of a specific size.
		public static function generateIdentity ( size:uint ) : matrix
		{
			
			var ret:matrix = new matrix ( size, size );
			var i:uint = 0;
			
			while ( i ++ < size )
				ret.setElement ( i - 1, i - 1, 1 );
			
			return ret;
			
		};
		
		//Creates a matrix from a flash transform matrix.
		public static function fromFlashMatrix ( mat:flash.geom.Matrix ) : matrix
		{
			
			return new matrix ( 3, 3, mat.a, mat.b, mat.tx, mat.c, mat.d, mat.ty, 0, 0, 1 );
			
		}
		
		//Creates a matrix from a flash 3D transform matrix.
		public static function fromFlashMatrix3D ( mat:flash.geom.Matrix3D ) : matrix
		{
			
			return new matrix ( 4, 4, mat.rawData );
			
		}
		
	};
	
};