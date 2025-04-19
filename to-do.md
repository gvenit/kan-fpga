# TO-DO

## Progress

***Day Planning***
- [ ] Try  Cocotb for AXI memory and try to make sense of the signals
- [x] Correct mistakes in new top level module
- [ ] Test that the alexforencich ram works with custom depths and widths or if it needs an adapter
- [ ] Make a new overleaf project and a templates
- [ ] Write a small abstract about the Thesis
- [ ] Make a software diagram

***System Architecture***
- [x] naming conventions for internal signals - each module must have its own
- [ ] implement multiple batch design
- [ ] parameter interdependences and values (see concerns)
- [ ] specify and implement all the control signals
- [ ] the axi adapter is the wrong module to connect the result streams to the master axis dma
- [ ] specify how data processor reset works (`core_rst` signal). Is it from the zynq reset or is it by writing on an axi-lite reg?
- [ ] specify the .txt directories in vivado
- [ ] weight streams and result streams need 

***Vitis Software***
- [ ] general code outline
- [ ] find a way to add the datasets in the memory

***Thesis-Paper Writing***
- [ ] decide on diagrams
- [ ] general outline of the thesis

## Concerns

***Top Level Module Parameters***
- [x] ~~ensure with assertions the expected parameter values~~: cannot be done in verilog, so it is aborted
- [x] there must be some association with the data channels and data banks
- [ ] make sure grid and data share all these parameters (width and so on)
- [ ] more strict specifications of depths

***Control interfaces***
- [ ] the axi-lite control interfaces must have a debouncer - talk about it and see where it is needed
- [ ] one axi lite control interface might not be enough - each axi-lite has 4 registers. In such a case a wrapper might be a good idea.

## Thing that might be wrong

- not sure if the scale register has the correct width
- have not tried slicing the address bits in the top level module before. All the other times I used a slicer in the Vivado Block Design
- the dma connections to the streams might have width mismatches (they use different parameters for width specification)
- maybe dma needs different slave and master widths of data and keep
- not sure that `USER_ENABLE` (and width for the matter) are correct for the AXI Adapters in the DMA

# Problems

- still too many dependencies
- batch not implemented yet - it seems there is only as a parameter in the Data Processor and Memory Control Unit. Also in some global parameters but nowhere else
- no module for joiner for joining the results into DMA
- clear out the depths (the tables show bits or bytes? Are they correct?)
- if you want axi lite interface instead of BRAM you have to create the appropriate paramter section first - in vivado it is so full of mistakes that I cannot find actual mistakes that are not just parameters that have not been declared
- the mcu has signals that have nothing to do with the ones I tried to connect to them

<br>

# Inquiries

- [x] what is grid and scale share?
- [x] why the instantiations of verilog headers?
- [ ] when do we need the axi lite interface and when the BRAM interface?