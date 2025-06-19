# kan-fpga

A complete engine for accelerating Kolmogorov-Arnold Networks (KAN) in FPGAs. The engine is based on [faster-kan](https://github.com/AthanasiosDelis/faster-kan) and exploits the repeatitive use of the data and grid elements to calculate the operations of a KAN layer. 

## FasterKAN
[faster-kan](https://github.com/AthanasiosDelis/faster-kan), when compared to [pykan](), uses an easier to calculate activation function, the Reflectional SWitch Activation Function:  

$$RSWAF_i(x) = 1 - \tanh^2\left(scale\times(x-grid_i)\right)$$

rather than the more complex B-spline basis. A FasterKanAccelerator consist of a BatchNorm Layer,the RSWAF and a Linear layer. The input feature map of the layer is forwarded to the BatchNorm Layer. Then, a matrix is formed from the equation:

$$ y_{ij} = RSWAF_i(x_j) $$

with size $len(x) \times len(grid)$. The matrix is flattened and forwarded to the Linear Layer. The number of total parameters in a layer is

$$ N_{total} = N_{grid} + 1 + N_{in} \times N_{grid} \times N_{out} = N_{grid} (N_{in}\times N_{out}+1) +1 $$

## Mapping to FPGA
In this project, the data processor does not normalize the input data 
and only performs the activation function and the linear layer.
RSWAF is precalculated and loaded as LUTRAM in the FPGA, 
thus speeding significantly the process in the cost of memory resources.
The Linear Layer is mapped as a parallelized version of the classic systolic architecture, 
where data and weights are streamed from the sides of a systolic array 
and the outputs are accumulated on each node of the array 
and streamed on one of the opposite sides when the partial sum is complete.

### Linear Processing Cube
The Linear Processing Cube (LPC) consists of Linear Processing Elements (LPE)
that are connected as follows:

- Input Data (or data from the first operand in general) are streamed from left to right.
- Input Weights (or data from the second operand in general) are streamed from top to bottom.
- Output Data are streamed from up to down.

For a Matrix-Matrix Multiplication (MMM), let A and B be two matrices 
of sizes $A \times C$ and $C \times B$ respectively 
and let the processing unit be a LPC of size $K \times N \times M$, 
where $K \times N$ the size of input data matrix from the left face of LPC, 
$K \times M$ the size of input data matrix from the top face of LPC and  
$N \times M$ the size of output data matrix from the down face of the LPC.
In order to calculate the MMM, 
we split the matrices in sizes $\frac{A}{N} \times K$ and $K \times \frac{B}{M}$, 
resulting in matrices:

$$A_n = a_{ic} \ , \ nN \le i \lt (n+1)N, \ 0 \le c \lt C$$ 
$$B_m = b_{cj} \ , \ mM \le j \lt (m+1)M, \ 0 \le c \lt C$$

Then, these matrices are converted to 3D Tensors using the following transform:

$$T(A)^n_{lik} = (A_n)_{i,(lK+k)} \ , \ nN \le i \lt (l+1)N, \ 0 \le l \lt \frac{C}{K}, \ 0 \le k \lt K$$
$$T(B)^m_{lkj} = (B_m)_{(lK+k),j} \ , \ mM \le j \lt (m+1)M, \ 0 \le l \lt \frac{C}{K}, \ 0 \le k \lt K$$

These matrices are streamed in the processor for $\frac{C}{K}$ cycles, 
and the theroetical latency of each iteration is:
$$\begin{gather*}
Iteration \ Latency &=& (\text{Input Length})  \\
                    &+& (\text{\#Cycles to reach last Row LPE})  \\
                    &+& (\text{\#Cycles to reach last Column LPE})  \\
                    &+& (\text{\#Parallel Processes})  \\
                    &=& \frac{C}{K} + M + N + K - 3
\end{gather*}$$

The LPC is fully compliant with the AXI-Stream Protocol, and produces results after all input channels
have provided the LPC with packets of the same length. 

### RSWAF
In this project, the first operand is of the MMM is the output of the module that calculates RSWAF.
This module works in a stream-wise fashion, where the input data, grid and scale are streamed.
The component then synchronizes the flows and calculates the difference between the data and the grid,
multiplies the result with the scale and 
then forwards the absolute value of the product to a ROM that is utilized as a Look-Up Table (LUT) for the
$sech^2$ function.

### Controllers & FIFOs
To achieve maximum throughput, the data, grid and scale parameters are loaded on on-chip memory in memory banks.
The core's Memory Control Unit efficiently polls data from these banks and feeds then to the data processor.
The weights of the linear layer are streamed from outside the core.
The core utilizes an asynchronous FIFO adapter to temporarily store the input stream, to poll 
and to distribute the input weights to their corresponding channels. 
On the contrary, the output matrix are first stored in a buffer.
A switch mechanism polls and packetizes data from the buffer and 
streams the packets in a single channel.
The core utilizes an asynchronous FIFO adapter to output the results in packets,
where each packet is labeled based on the row that the sequential data were polled from. 

A Central Control Unit manages the high level PS-PL communication 
and is the module that coordinates the core's internal processes.

Both weight and result streams are AXI-Stream compliant and can operate on independent clock
streams than the fsm and core clocks. 
In case of more than one batch,
the result stream makes use of the TID flag to indicate the corresponding batch.

### Resource utilization
- The number of DSP slices are:
    - $D \times B$ for multiplications in the RSWAF module,
    - $D \times B \times R$ for Multiply-and-Accumulate in the LPC and
    - $B \times R$ for partial sum accumulations in the LPC. In case of $D == 1$, no extra DSPs are needed.

    where $D$ is the number of data channels, 
    $R$ is the number of result channels 
    and $B$ is the number of batches in the design.
- The number of Block RAMs varies based on the core's channel sizes, memory and FIFO depths, as well as the data widths. Assuming a block ram can store $Q$ bits in any combination of data width and depth, we get $BRAM_X = \frac{DW \times Depth}{Q}$ for a resource $X$.
    - $BRAM_{rslt}$ for the asynchronous FIFO adapter for the results,
    - $BRAM_{wght}$ for the asynchronous FIFO adapter for the weights,
    - $B \times D \times \frac{DW_{AXIL}}{DW_{X}} \times \max(\frac{BRAM_X \times DW_{X}}{D \times DW_{AXIL}}, 1)$ of memory storage for data type $X = \{data,grid,scale\}$, 
        where $BRAM_{x}$ is the number of block RAMs allocated in the simple case of a single channel.
    - For grid and scale, the default configuration assumes $B=D=1$.

# Notes
- AXI-Lite interfaces for data, grid and scale on-chip memory storage operating on independent clocks.
- AXI-Lite interface for configuring the core from the Processing System operating on fsm clock.
- AXI-Stream interfaces for weights and results operating on independent clocks.
- Data processing procedures operate on core clock.
- In synchronous mode, core and fsm clocks are expected to be driven by the same clock.
- In asynchronous mode, it is recommended that the core clock speed is an integer multiple of the fsm closk speed, and the two clocks are phase-aligned.

# Important
- This repo is designed to produce files and run tests in linux systems. 
    If you want to use in windows (for example to use Vivado and Vitis) on a Windows environment, 
    it is highly recommended to clone this repo in the desired windows path using WSL.


# To-Do (Important)
- [ ] Most python tests are old or have low coverage of the UUT's functionality and need to be updated. 
- [ ] Integrate dataset and KAN model to the repository
- [ ] Integrate quantization of the KAN model to the repository. 
- [ ] Integrate a valid vivado projects to the repository.
- [ ] Integrate vitis project to the repository.

# To-Do (Secondary)
- [ ] Upgrade to / add option for AXI interfaces for data, grid and scale on-chip memory storage.
- [ ] Option to use Distributed RAM instead of Block Ram for small memory depths.
- [ ] Update `KanAccelerator_simgen.py` to use actual data instead of randomly generated ones.