# Thesis on Kolomogorov-Arnold Networks (KANs)

## Structure

- [ ] **COVER**
- [ ] **CONTENT TABLE**
- [ ] **LIST OF FIGURES**
- [ ] **LIST OF TABLES**
- [ ] **ABSTRACT**
- [ ] **1 - INTRODUCTION**
  - [ ] Motivation for this research
    - [ ] _new field_
    - [ ] _few accelerator designs_
  - [ ] Design of KAN on FPGAs
    - [ ] NNs on FPGAs
    - [ ] Lack of KAN Design
  - [ ] The kan-fpga project
  - [ ] Goals of this work
    - [ ] Need for benchmarking
    - [ ] Need for a PS around the FPGA
- [ ] **2 - RELATED WORK**
  - [ ] _FPGAs as ANN acceleration devices_ (???)
  - [ ] _KAN_ (???)
    - [ ] pykan
    - [ ] FastKAN
    - [ ] FasterKAN
- [ ] **3 - THEORY**
  - [ ] Neural Networks _(basics)_
    - [ ] General
    - [ ] MLP
    - [ ] Comparison
  - [ ] Overview of KANs _(george will send inspo paper)_
    - [ ] Kolmogorov-Arnold Representation Theorem
    - [ ] KAN as Neural Networks
    - [ ] basis functions
- [ ] **4 - SYSTEM DESCRIPTION**
  - [ ] High Level Overview of PL and PS
  - [ ] PL Structure *(Treated as a Blackbox Component)*
    - [ ] Components *(Block Design)*
    - [ ] KAN Accelerator Input/Output Interface Description 
    - [ ] _Data flow_ *(Block Design)* (???)
  - [ ] PS Structure
    - [ ] Kan custom C library
    - [ ] Memory Management / Storage
    - [ ] Control flow
- [ ] **5 - RESULTS**
  - [ ] Setup
    - [ ] **PS/PL** parameters / configurations
    - [ ] Timing methods
      - [ ] PS timing
      - [ ] PL timing
  - [ ] Results
    - [ ] _Accuracy_ *(Pretrained Model, given by the paper george will send)* (???)
    - [ ] Execution Times & Latency Metrics
      - [ ] _comparison with edge device_ (???)
    - [ ] Utilization and ASW size
    - [ ] _Misc_ (???)
- [ ] **6 - CONCLUSIONS**
  - [ ] Evalutation of project
  - [ ] Future work *(Genlty note you want to improve on the stuff you see as issues but are *definately* not)*
- [ ] **ABBREVIATIONS**
- [ ] **BIBLIOGRAPHY**

Some morre info on each chapter is given on the following subsections.

<br>

---

### 1. INTRODUCTION

I suspect 5 to 7 paragraphs tops, no figures, many abbreviations for the first time and modest references.

<br>

**Motivation for this research _(1-2 paragraphs)_**

Structure:
1. New paper. Old conception new applications.
2. Accelerated designs. Software implementations vs hardware

You need:
- [ ] Info on when KANs started. Is the paper you have the first? What did it do?
- [ ] Advantage difference of KANs vs MLPs?
- [ ] Find uses
- [ ] Find accelerated designs

<br>

**Design of KAN on FPGAs _(1-2 paragraphs)_**

Structure:
1. NNs on FPGAs. FPGAs are edge devices. Pros of speed and power consumption
2. No FPGA KAN designs

You need:
- [ ] simple and well-known papers for FPGA implementaiton of MLPs
- [ ] whatever you find on KANs
- [ ] why FPGA for NNs in general?

<br>

**KAN FPGA Project _(1 paragraph)_**

Talk about the paper and the team. Small mention of the inspo.

You need:
- [ ] read the paper to see what it is about
- [ ] see gvenit github and see inspo
- [ ] See all the things you do not do (training, application and datasets)

<br>

**Goals of this Work _(1-2 paragraphs)_**

Structure:
1. Need for a PS around the FPGA. HDL core is not standalone. ASW framework / SDK / lib
2. Need for benchmarking. Both on PL anm ASW terms

You need:
- [ ] be sure what you will write in general. Leave it for later do not rush this

<br>

### 2. RELATED WORK

*Very not sure about how this should be approached, but all and all 4 paragraphs*

**FPGAs as ANN acceleration devices _(2 paragraphs)_**

Strusture:
1. Need for fast and energy efficient inference. Mention edge-computations. Mention medical devices
2. FPGAs as suitable edge device. NN implementations on FPGAs on the edge (references)

You need:
- [ ] References about the need of edge computation of NNs
- [ ] FPGA NNs edge implementation references
- [ ] Read the paper and metion whatever it says about medical devices

**KAN Related Work _(2 paragraphs)_**

Strucutre:
1. Main paper and its [repo](https://kindxiaoming.github.io/pykan/index.html). Mention [pykan](https://kindxiaoming.github.io/pykan/index.html) which is the most used tool
2. Faster implementations. [FastKAN](https://github.com/ZiyaoLi/fast-kan) and [FasterKAN](https://github.com/AthanasiosDelis/faster-kan), which is the inspo of our design.

You need:
- [ ] Good mention of all the sources without too many details

<br>

### 3. THEORY

Keep it simple and cochise, might show a graph or two to get accross the differences of KANs with MLPs. Around 4 to 6 paragraphs.

**Neural Networks Basics _(2 to 3 paragraphs)_**

Structure:
1. General Info on NNs. What they are. Inference usage. Focus on classification of images.
2. MLPs and KANs. MLP simple base model, with static activation functions. KAN with the trained activation functions. Mention  differences in what they are and offer briefly

You need:
- [ ] Good understanding and phrasing of the concept of what an NN is, especially in vision applications.
- [ ] MLPs what they are and concepts like layers, params and activation functs.

***Overview of KANs _(2-3 paragraphs)_***

Structure:
1. Kolmogorov-Arnold Representation Theorem. Global approximation theorem.
2. KAN as Neural Networks. Structure. Combination with linear layers
3. Activation functions. Reflectional SWitch Activation Function (RSWAF) vs B-splines.

You will need to reference the [faster-kan](https://github.com/AthanasiosDelis/faster-kan) and maybe other sources from the [official repo of the paper](https://kindxiaoming.github.io/pykan/index.html) and [openkan](http://openkan.org/)

You need:
- [ ] Kolmogorov-Arnold Representation Theorem
- [ ] Global Approximation Theorem
- [ ] Know all network parameters: layers, neurons, weights and activation functions 
- [ ] Know the RSWAF parameters: grid and scale

<br>

### 4. SYSTEM DESCRIPTION

**High Level Overview of PL and PS**

<br>

**PL Structure _(3-5 paragraphs)_**

The PL strucutre will be mainly treated as a black box but I can insert the DrawIO schematic *that must be updated*.

Structure:
1. Components - Blocks in the PL. Small destinction between custom blocks inside the KanAccelerator and Xilinx IPs.
2. The PS and its interfaces. AXI interfaces between the various blocks. Control signals, like interrupts.
3. KAN Accelerator inputs, outputs and interfaces. Channels / Streams and control signals. Register file.
4. Mention of other custom blocks briefly
5. Clock Domains. Brief mention

You need:
- [ ] Actually make the diagram of components
- [ ] Might need a dataflow diagram too
- [ ] Mainly talk with gvenit and find what he wants disclosed

<br>

**PS Structure _(4-8 paragpraphs)_**

The heart of the work. Might need a porgram flow diagram and a conceptual memory layout.

Structure:
1. Bare-Metal application. Testing purposes and faster development.
2. Program flow. Description of the execution.
3. Memory transcations and spaces. DDR, AXI regfiles and AXI brams. Linker script
4. Custom C Portable library. Dependencies on xilinx SDK. Go into detail.

You need:
- [ ] write this after final implementation

<br>

---

## Inquiries

### Theory
- what is quadrature?
- some function types:
	- what are **piecewise linear functions**
	- what are **splines** and what are **b-splines**?
	- what are **Radial Basis Functions (RBFs)**?
	- what are **Reflectional SWitch Activation Functions (RSWAF)**?
- make sure you know 100% what a kenrel function means
- what is the accuracy metric _Pearson correlation coefficient_?