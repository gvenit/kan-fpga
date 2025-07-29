# KAN SoC Application Software (AWS) on the Processing System (PS)

To avoid clatter ASW software on the PS is documented here. Even though there are many subdirectories, mainly to keep all the vitis tests seperated because Vitis tends to crash if I mix them together and work on a single workspace.

***Imortant** : _all the PS projetcs are in [System_Versions](./System_Versions/) every time I abandon an old version and go for a new one I remove all the C source files from the other one and various other files so that VSCode will not have conflicts. I only leave important stuff behind for that particular version. In other cases I delete them altogether._

<br>

## Build amd Setup notes

Whenever you start a new system version make sure to do the following:
1. The platform must be able to build on its own
2. Copy paste the src and inc folders to the application folder
3. Go to the properties of the application (not the platform) and go to `C/C++ General/Path and Symbols` and in the Includes tab add the inc folder as a workspace directory


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
- [x] memory wrapper functions
- [x] you need an invalid argument error return type
- [ ] add arguments check for register writes with half-words (almost unused) but it is dangerous for spillage in neighbouring words
- [x] whatever you do with the banks do it in kan_build_params.h and add checks.
- [x] whatever you add in the build_params must be reflected in the nextwork handler types in kan_config.h
- [x] layer config structs might need to remain only in .c and not public in the kan_config.h
- [x] the kan_config.h functions are missing stuff. See them to it (see comments in source)
- [x] change names for GRID_IS_SHARED and such
- [x] add final layer result features
- [x] add volatile wherever it is needed
- [x] data and results do not need strides and they are not knownn from the beggining
- [x] old dma examples had cache flushes that need to be imlpemented somehow
- [x] having status variable be `kan_status_t` in the source code might pose problems even if it is compatible with the defines in `xstatus.h`
- [ ] not sure if deallocation function are needed (for example in the `kan_config.h`)
- [ ] I do not have status everywhere. Should I check it more?
- [ ] Dma examples had a number of transfers, something like a for loop to attempt to do the dma transaction multiple times. I am not sure if it is needed. I have the macro for it in `kan_defines.h` commented out and not no such implementation in the main code.
- [ ] No monitoring of timing registers in main function yet (like `CTRL_REG_OFST_OPER_TMR_4B`)
- [x] While waiting for reports to end I do not report on normal operation. Only errors that shut down the core.
- [x] change size arrays type to uint16_t 
- [x] loaded register are PS to PL not the other way around
- [x] length are in packets
- [x] batch is 1
- [x] first download the packets then update the configuration
- [x] when in locked state check that operation is done else error handler
- [x] null CTRL_REG_OPER_DNE at the end of each layer
- [ ] time everything
  - [ ] all ASW (with inits)
  - [ ] all layers
  - [ ] every layer
  - [ ] _hardware metrics_
- [x] grid and scale have banks 4
- [x] change the linker script too and the datasets I think ***this is the reason why the memcpys fail as of now***
- [ ] make the memcpy more plain again since it wasn't the bug
- [x] add contract to kan layer config function
- [ ] You need a results memory space and a way to dump it
- [x] add contract to `kan_dma_disable_irq`
- [x] maybe seperate the dma interrupt attachment from the initialization because there is too much overhead in every layer call
- [x] make banks to channels
- [ ] add contract to interrupt callback and maybe better contracts in the interrupt library and to the new kan_control.h functions
- [ ] write somewhere in a contract that pl2ps interrupt triggers with the status register (27) change but not with reset and valid fields.
- [x] null interrupt register (26) jic
- [x] create a state getter function based on the one from gvenit
- [x] weight loaded ack should be after the dma rx initiation
- [x] do operation start ffs
- [ ] remove DEF_DBG everywhere not needed and also remove the kan_defines.h and xil_printf.h if it is only impolrted for debugging purposes
- [ ] optimize the callback and the state getter function


<br>

## Issues and notes on the execution

- [ ] after configuration the status of the core is idle not configuration valid...

## Inquiries

- [ ] is `static` in functions (say interrupts) really needed?
- [x] What was the region that was supposedly the same and had to loop back data with the DMA? If it is reasults, isn't there mismatch with width?
- [x] does the final layer produce a single result or not?
- [x] do I have to deal with the banks? The only thing I can thing of is that they must divide the number of transfered packets. But it is something the PL deals with.
- [x] is it better have the network and layer handlers which are statically defined and decalred in kan_config.h b dynamically configured in main? If you end up with the dynamic add free functions too.
- [x] should I do the packet displacements in `kan_config_init` with strided indexes using `data_t` or should I do it with defines of byet sizes using their base addresses?
- [x] do we need to know the banks after all? see the configuration via the regfile
- [ ] some values of registers are unkonwn (what to expect) so I have them as defines in the main and they should gradually be removed
- [ ] I do not remember what I have to do with the interrupts other than dma
- [x] not sure I handle the operation done reg `CTRL_REG_OPER_DNE` correctly
- [ ] there are not deinit functions. Are they needed?
- [x] Should I disable both data and instruction cache? I only disable data cache for now. Instruction might be good for memory operations
- [ ] weight loaded reg should not exist

