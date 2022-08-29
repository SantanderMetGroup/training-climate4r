# Introduction

## Climate4R overview

<p align="center">
<img src="https://github.com/SantanderMetGroup/climate4R/blob/master/man/figures/climate4R_2.png"/>
</p>

For futher detail, visit https://github.com/SantanderMetGroup/climate4R and refer to the climate4R article in EMS:
> M. Iturbide, J. Bedia, S. Herrera, J. Baño-Medina, J. Fernández, M.D. Frías, R. Manzanas, D. San-Martín, E. Cimadevilla, A.S. Cofiño and JM Gutiérrez (2019) The R-based climate4R open framework for reproducible climate data access and post-processing. *Environmental Modelling & Software*, **111**, 42-54. [DOI: /10.1016/j.envsoft.2018.09.009](https://doi.org/10.1016/j.envsoft.2018.09.009)

## Overview of reproducible execution environments

The ability to reproduce your results with climate4R or any piece of software is essential.
In this [initial overview](https://docs.google.com/presentation/d/1RN_JyOMQmKTN1kRSMwx67v1RXyyl80dOkUFRiINbfa4/edit?usp=sharing)
we briefly present the conda environment manager and other tools to improve the reproducibility of your execution environment
 
## climate4R installation

The simplest way to locally install climate4R is using [conda](https://docs.conda.io/en/latest/miniconda.html) (or [mamba](https://mamba.readthedocs.io/en/latest/installation.html) for a usually faster installation):

```
conda create --name climate4R
conda activate climate4R
conda install -c conda-forge -c r -c defaults -c santandermetgroup climate4r
```
## climate4R environment options

During the tutorial, we can use either:

 * a local installation of climate4R
 * the climate4R JupyterHub, available at http://hub.climate4R.ifca.es
 * or the My Binder environment available through the [![MyBinder badge](https://img.shields.io/badge/Launch%20in-JupyterLab-red)](https://mybinder.org/v2/gh/SantanderMetGroup/binder-climate4r/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSantanderMetGroup%252Ftraining-climate4r%26urlpath%3Dlab%252Ftree%252Ftraining-climate4r%252F%26branch%3DBuenosAires2022) badge in this repository.
