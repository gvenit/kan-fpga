# KAN SoC Application Software (AWS) on the Processing System (PS)

To avoid clatter ASW software on the PS is documented here. Even though there are many subdirectories, mainly to keep all the vitis tests seperated because Vitis tends to crash if I mix them together and work on a single workspace.

<br>

## Project outlines

### Headers

The headers are presented in a general order of importance (the ones mentioned first usually configure the ones below).

First these headers act as ma

- **kan_build_params.h** : user defined macros that set up the general build of the project.
  - Sets up the used RAM types for data, grid and scale
  - Sets up the datatype of packets inside the array (byte or half-word)
  - Sets up execution parameters like if the ASW will be verbose or not, or if it is in debug mode.
  - Sets up the number of KAN layers
  - Sets up the number of data, grid and scale on each layer
- **kan_defines.h** : macros for masks and device IDs usually taken from `xparameters.h` and configured by `kan_build_params.h` 
  - Interrupt controller defines
  - RAM memories definitions
  - DMA defines
- **kan_status.h** : has genreral type difinitions, status / error codes and error handling
  - custom type for booleans
  - custom type for byte sizes
  - enumaration of function return statuses
  - error handling inline function
- **kan_memory_map.h** : contains the definitions of all used memory mapped peripherals. Usually taken from `xparameters.h`
  - control register addresses and masks
  - data, scale and grid bram addresses
- **kan_config.h** : configures the network parameters based mainly on the datasets and the `kan_build_params.h`
  - Custom type for whole network handler struct
  - Custom type for single layer handler struct
  - Custom type for data and resultsn buffer
  - initialization and destruction functions
- **kan_memory.h** : wrapper for memory operations
  - register read
  - register write


<br>

## To-Do

- [ ] have the list of [header files](#headers) completed and working
- [ ] memory wrapper functions
- [x] you need an invalid argument error return type
- [ ] add arguments check for register writes with half-words (almost unused) but it is dangerous for spillage in neighbouring words
- [x] whatever you do with the banks do it in kan_build_params.h and add checks.
- [ ] whatever you add in the build_params must be reflected in the nextwork handler types in kan_config.h
- [x] layer config structs might need to remain only in .c and not public in the kan_config.h
- [x] the kan_config.h functions are missing stuff. See them to it (see comments in source)
- [x] change names for GRID_IS_SHARED and such
- [x] add final layer result features
- [ ] add volatile wherever it is needed
- [x] data and results do not need strides and they are not knownn from the beggining
- [ ] old dma examples had cache flushes that need to be imlpemented somehow
- [ ] having status variable be `kan_status_t` in the source code might pose problems even if it is compatible with the defines in `xstatus.h`
- [ ] not sure if deallocation function are needed (for example in the `kan_config.h`)

<br>

## Inquiries

- [ ] is `static` in functions (say interrupts) really needed?
- [x] What was the region that was supposedly the same and had to loop back data with the DMA? If it is reasults, isn't there mismatch with width?
- [x] does the final layer produce a single result or not?
- [x] do I have to deal with the banks? The only thing I can thing of is that they must divide the number of transfered packets. But it is something the PL deals with.
- [x] is it better have the network and layer handlers which are statically defined and decalred in kan_config.h b dynamically configured in main? If you end up with the dynamic add free functions too.
- [x] should I do the packet displacements in `kan_config_init` with strided indexes using `data_t` or should I do it with defines of byet sizes using their base addresses?
- [ ] do we need to know the banks after all? see the configuration via the regfile
- [ ] some values of registers are unkonwn (what to expect) so I have them as defines in the main and they should gradually be removed
