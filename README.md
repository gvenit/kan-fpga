# kan-fpga

A complete engine for accelerating Kolmogorov-Arnold Networks (KAN) in FPGAs. The engine is based on [faster-kan](https://github.com/AthanasiosDelis/faster-kan) and exploits the repeatitive use of data and grid elements to calculate the operations of a KAN layer. 

## FasterKAN
[faster-kan](https://github.com/AthanasiosDelis/faster-kan) uses an easier to calculate activation function, the Reflectional SWitch Activation Function:  

$$RSWAF_i(x) = 1 - \tanh^2\left(scale\times(x-grid_i)\right)$$

rather than the more complex B-spline basis. A FasterKANLayer consist of a BatchNorm Layer,the RSWAF and a Linear layer. The input feature map of the layer is forwarded to the BatchNorm Layer. Then, a matrix is formed from the equation:

$$ y_{ij} = RSWAF_i(x_j) $$

with size $len(x) \times len(grid)$. The matrix is flattened and forwarded to the Linear Layer. The number of total parameters in a layer is

$$ N_{total} = N_{grid} + 1 + N_{in} \times N_{grid} \times N_{out} = N_{grid} (N_{in}\times N_{out}+1) +1 $$


## Mapping to FPGA
In this project, the data processor does not normalize the input data and only performs the activation function and the linear layer.
RSWAF is precalculated and loaded as LUTRAM in the FPGA, thus speeding significantly the process in the cost of memory resources.
The Linear Layer is mapped as a classic systolic architecture, where data and weights are streamed from the sides of a systolic array and the outputs are accumulated on each node of the array and streamed on one of the opposite sides when the partial sum is complete.
