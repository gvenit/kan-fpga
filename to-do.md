# TO-DO

- [ ] in the top level mdoule there must be some association with the data channels and data banks
- [ ] ensure with assertions the expected parameter values
- [ ] the axi-lite control interfaces must have a debouncer - talk about it and see where it is needed
- [ ] assertions about the control ram input parameters and the used ones (especially in the grid)
- [ ] make sure grid and data share all these parameters (width and so on)

## Thing that might be wrong

- not sure if the scale register has the correct width
- in the utils header I added 1 in case of lg1. I hope translator is fine