## Description

This repo is associated with the following paper:

> *Trait anxiety is associated with hidden state inference during aversive reversal learning* (2022). O Zika, K Wiech, A Reinecke, M Browning, NW Schuck - bioRxiv, https://doi.org/10.1101/2022.04.01.483303

It contain code for both models (1-state and n-state) as well as a `demonstration.mlx` which can be run to simulate, visualzie and fit the models. 

## Steps
1. Clone the repo with submodules:

```bash
git clone --recurse-submodules git@github.com:ozika/state-inference-models-zika2022.git

```

2. Open MATLAB (2018+) and add the folder to your path

```MATLAB
addpath(genpath('state-inference-models-zika2022'))
```

3. Open the `scripts/demonstration.mlx` notebook.
