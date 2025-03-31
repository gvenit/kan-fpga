# TO-DO

## Progress

***System Architecture***
- [ ] naming conventions for internal signals - each module must have its own
- [ ] parameter interdependences and values (see concerns)
- [ ] implement multiple batch design
- [ ] specify and implement all the control signals

***Vitis Software***
- [ ] general code outline
- [ ] find a way to add the datasets in the memory

***Thesis-Paper Writing***
- [ ] decide on diagrams
- [ ] general outline of the thesis

## Concerns

***Top Level Module Parameters***
- [x] ~~ensure with assertions the expected parameter values~~: cannot be done in verilog, so it is aborted
- [ ] there must be some association with the data channels and data banks
- [ ] make sure grid and data share all these parameters (width and so on)
- [ ] more strict specifications of depths

***Control interfaces***
- [ ] the axi-lite control interfaces must have a debouncer - talk about it and see where it is needed
- [ ] one axi lite control interface might not be enough - each axi-lite has 4 registers. In such a case a wrapper might be a good idea.

## Thing that might be wrong

- not sure if the scale register has the correct width
- have not tried slicing the address bits in the top level module before. All the other times I used a slicer in the Vivado Block Design