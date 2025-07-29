import numpy as np
import matplotlib.pyplot as plt
import argparse
import sys, os

parser = argparse.ArgumentParser()

parser.add_argument('-p',"--plot", action='store_true', dest='has_plot')
parser.add_argument('-s','--stats', action='store_true')
parser.add_argument('-d','--dryrun', action='store_false')
parser.add_argument('-I','--dtype-in', default="int16",dest='dtype_in')
parser.add_argument('-O','--dtype-out', default="uint16",dest='dtype_out')
parser.add_argument('-i','--fr-bits-in', type=int, dest='fr_bits_in')
parser.add_argument('-o','--fr-bits-out', type=int, dest='fr_bits_out')
parser.add_argument('-N','--natural', action='store_true', dest='natural')

args = parser.parse_args()
num_bits_in = None

### Check dtype of input data validity
try:
    if str(args.dtype_in).isnumeric():
        num_bits_in = int(args.dtype_in)
        args.dtype_in = 2 ** int(np.ceil(np.log2(num_bits_in)))
        if args.natural :
            args.dtype_in = f'uint{args.dtype_in}'
        else:
            args.dtype_in = f'int{args.dtype_in}'
    args.dtype_in = np.dtype(args.dtype_in)
except Exception as e:
    raise ValueError('Invalid value for argument "dtype_in" : {dtype}', args.dtype_in) from e

### Check dtype of output data validity
try:
    args.dtype_out = np.dtype(args.dtype_out)
except Exception as e:
    raise ValueError('Invalid value for argument "dtype_out" : {dtype}', args.dtype_out) from e

### Check number of fractional bits of input data validity
if num_bits_in is None:
    num_bits_in = args.dtype_in.name.split('int')[-1]

if  str(num_bits_in).isnumeric() :
    num_bits_in = int(num_bits_in)

    if args.fr_bits_in is None :
        args.fr_bits_in = num_bits_in // 2
        print('Setting input fractional bits to',args.fr_bits_in,'.')
    elif args.fr_bits_in >= num_bits_in or args.fr_bits_in < 0 :
        raise ValueError('Invalid value for argument "fr-bits-in" : {fr_bits}', args.fr_bits_in)
    
else :
    raise ValueError('Invalid value for argument "dtype" : {dtype}', args.dtype_in)

if args.natural :
    if 'int' in str(args.dtype_in) and 'uint' not in str(args.dtype_in):
        args.dtype_in = np.dtype('u' + str(args.dtype_in))

### Check number of fractional bits of input data validity
num_bits_out = args.dtype_out.name.split('int')[-1]

if  num_bits_out.isnumeric() :
    num_bits_out = int(num_bits_out)

    if args.fr_bits_out is None :
        args.fr_bits_out = num_bits_out // 2
        print('Setting output fractional bits to',args.fr_bits_out,'.')
    elif args.fr_bits_out > num_bits_out or args.fr_bits_out < 0 :
        raise ValueError('Invalid value for argument "fr-bits-out" : {fr_bits}', args.fr_bits_out)
    
else :
    raise ValueError('Invalid value for argument "dtype" : {dtype}', args.dtype_out)

# Constants
if args.natural:
    x = np.arange(2**(num_bits_in), dtype=args.dtype_in)
else:
    x = np.arange(-2**(num_bits_in-1),2**(num_bits_in-1), step=1, dtype=args.dtype_in)
f = lambda x, dtype='float128', nbits=args.fr_bits_in : 1 - np.tanh(x.astype(dtype) / 2**nbits)**2

y     = f(x) 
y_int = y * (2**args.fr_bits_out)
# y_int = (y * (2**num_bits_out-1)).round()
# y_int = y_int.astype(args.dtype_out)
if (num_bits_out == args.fr_bits_out):
    y_int = np.where(
        y_int > 2**num_bits_out-1,
        2**num_bits_out-1,
        y_int.astype(args.dtype_out)
    )
else :
    y_int = y_int.astype(args.dtype_out)

if args.stats :
    diff = (y - (y_int / (2**num_bits_out)).astype(y.dtype))

    err = np.max(np.abs(diff)) 
    print('Max : ', err)
    err = np.mean(diff) 
    print('Mean : ', err)
    err = np.mean(np.abs(diff))
    print('MAE  : ', err)
    err = np.sqrt( np.mean(diff**2) )
    print('RMSE : ', err)

if args.has_plot:
    plt.plot(x,y_int,'.')
    plt.show()
    
if args.dryrun :
    fname = os.path.realpath(
        os.path.join(
            os.path.dirname(__file__),
            '..',
            'data',
            os.path.splitext(
                os.path.basename(__file__)
            )[0]+'{n}_{x_N}.{x_F}_{y_N}.{y_F}.txt'.format(
                n   = '_n' if args.natural else '',
                x_N = num_bits_in,
                x_F = args.fr_bits_in,
                y_N = num_bits_out,
                y_F = args.fr_bits_out
            )
    ))
    os.makedirs(os.path.dirname(fname), exist_ok=True)
    print(f'Saving results in "{fname}"')

    with open(fname, 'w') as sys.stdout:
        # print('{')
        if not args.natural:
            y_int = np.array([*y_int[2**(num_bits_in-1):],*y_int[:2**(num_bits_in-1)]])
        
        for y_i in y_int:
            print(f"{y_i:0{num_bits_out//4}x}")

        # print(f"\t{num_bits_out}'h{y_int[-1]:0{num_bits_out//4}x}")
        # print('}')