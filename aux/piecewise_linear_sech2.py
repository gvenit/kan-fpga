import sys
import numpy as np
import matplotlib.pyplot as plt
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('-p', "--plot", action='store_true', dest='has_plot')
parser.add_argument('--dtype', default="float32")
parser.add_argument('--fr-bits',type=int,dest='fr_bits', nargs='*')

args = parser.parse_args()

try:
    args.dtype = np.dtype(args.dtype)
except Exception as e:
    raise ValueError('Invalid value for argument "dtype" : {dtype}', args.dtype) from e

num_bits = args.dtype.name.split('int')[-1]

if  num_bits.isnumeric() :
    num_bits = int(num_bits)

    if args.fr_bits in [None, []] :
        args.fr_bits = [num_bits // 2, num_bits // 2]
        print('Setting fractional bits to',args.fr_bits,'.')
    elif len(args.fr_bits) > 2 :
        raise ValueError('Invalid value for argument "fr-bits" : {fr_bits}', args.fr_bits)
    elif args.fr_bits[0] >= num_bits or args.fr_bits[0] < 0 or args.fr_bits[-1] >= num_bits or args.fr_bits[-1] < 0 :
        raise ValueError('Invalid value for argument "fr-bits" : {fr_bits}', args.fr_bits)
    
else :
    num_bits = 0

# Constants
dtype = 'float16' if num_bits else args.dtype   # Calculate curves using floats
# x = np.linspace(-10,10,10**6, dtype=dtype)
x = np.linspace(-10,10,10**2+1, dtype=dtype)
f = lambda x: 1 - np.tanh(x)**2

#Breakpoints
xcurve = np.dtype(dtype).type(np.log((np.sqrt(6)+np.sqrt(5))/(np.sqrt(6)-np.sqrt(5))) / 2)
xcurve2= np.dtype(dtype).type(np.log((np.sqrt(64)+np.sqrt(63))/(np.sqrt(64)-np.sqrt(63))) / 2)

# print(xcurve, xcurve2)

bp = []     # Breakpoints
sl = []     # Slopes
yi = []     # Y-intercepts

# For |x| < x0 -> 1 + a0 |x|^2
bp.append( np.log((np.sqrt(3)+1)/(np.sqrt(3)-1)) / 2 )
sl.append( -1 / bp[0]**2 / 3 )
yi.append( 1 )

# For x0 <= |x| < x1 -> a1 |x| + b1
bp.append( (3*xcurve + bp[-1])/4 )
sl.append( - 2 / 3 / (xcurve - bp[0]) )
yi.append( - sl[-1] * xcurve )

# For x1 <= |x| < x2 -> a2 |x| + b2
bp.append( xcurve2 )
sl.append( -(sl[-1] * bp[-2] + yi[-1]) / (xcurve2 - bp[-2]) )
yi.append( - sl[-1] * xcurve2 )

bp = np.array(bp, dtype=dtype)
sl = np.array(sl, dtype=dtype)
yi = np.array(yi, dtype=dtype)

if num_bits:
    bp = (bp  * args.dtype.type(2**args.fr_bits[-1])).astype(args.dtype)
    sl = (sl  * args.dtype.type(2**args.fr_bits[-1])).astype(args.dtype)
    yi = (yi  * args.dtype.type(2**args.fr_bits[-1])).astype(args.dtype)

    x_scale = 2**args.fr_bits[ 0]
    y_scale = 2**args.fr_bits[-1]

    x  = x[abs(x) < np.dtype(args.dtype).type(2<<(num_bits-args.fr_bits[0]))]
    x  = (x   * x_scale).astype(args.dtype)
    y  = (f(x)* y_scale).astype(args.dtype)
else :
    y = f(x)
    x_scale = y_scale = 1.

if num_bits :
    cast_to = np.uint64

    def mult(op_0, op_1, bit_shift, cast_to=cast_to):
        return cast_to(
            (cast_to(op_0) * cast_to(op_1)) >> cast_to(bit_shift)
        )

    lambda_func = [
        lambda y: mult( 
                sl[0],
                mult(
                    y,
                    y,
                    args.fr_bits[-1]
                ),
                args.fr_bits[-1]
            ) + yi[0],
        *[
            lambda y, i=i: mult(sl[i], y, args.fr_bits[-1]) + yi[i]
                for i in range(1,len(bp))
        ], 0
    ]
else :
    lambda_func = [
        lambda y: sl[0] * y**2 + yi[0],
        *[
            lambda y, i=i: sl[i] * y + yi[i]
                for i in range(1,len(bp))
        ], 0
    ]

f_hat = lambda x: np.piecewise(
    abs(x), [
        abs(x) <= bp[0],
        *[
        np.logical_and(abs(x) > bp[i], abs(x) <= bp[i+1])
            for i in range(len(bp)-1)
    ]], lambda_func
)

y_hat = f_hat(x)
diff = y - y_hat

if num_bits:
    err = np.sqrt(np.mean( mult(diff,diff,args.fr_bits[-1]), dtype='float64') / y_scale)
else :
    err = np.sqrt(np.mean(diff**2))


print('Error :')
print('\t', err)
print('Breakpoints :')
print('\t', bp)
print('Slopes :')
print('\t',sl)
print('Y-intercept :')
print('\t',yi)

print(max(y), min(y), max(y_hat), min(y_hat),)

print(x / x_scale)
print(y / y_scale)
print(y_hat / y_scale)

if args.has_plot:
    if num_bits:
        x = (x.astype('float64') / x_scale)
        y = (y.astype('float64') / y_scale)
        y_hat= (y_hat.astype('float64') / y_scale)
    
    plt.plot(x,y,'.')
    plt.plot(x,y_hat,'.')
    plt.show()