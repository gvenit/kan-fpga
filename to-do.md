# TO-DO

## Progress

***System Architecture***
- [x] naming conventions for internal signals - each module must have its own
- [ ] implement multiple batch design
- [ ] parameter interdependences and values (see concerns)
- [ ] specify and implement all the control signals
- [ ] the axi adapter is the wrong module to connect the result streams to the master axis dma
- [ ] specify how data processor reset works (`core_rst` signal). Is it from the zynq reset or is it by writing on an axi-lite reg?
- [ ] specify the .txt directories in vivado

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

# Problems

- still too many dependencies
- batch cannot be implemented - what happens with RAM control interface
- no module for adapter/joiner
- clear out the depths (the tables show bits or bytes? Are they correct?)