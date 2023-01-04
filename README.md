# EpHam
Hello everyone, I will propose to my girlfriend on January 7, 2022

EpHam is a package for interfacing Caesar package with Hop package to construct a Hamiltonian with Electron-phonon coupling from first-principles calculations.

To construct a Hamiltonian with Electron-phonon coupling, one should use Caesar first to perform lattice dynamics calculations and then generate atomic configurations consistent with the nuclear density arising from phonons. At each atomic configuration, the Hamiltonian can be constructed directly by Hop. Electronic quantities in the presence of phonons can be renormalized by averaging their value over all possible atomic configurations.



## Requirements

The following packages are required:

1. Hop (https://github.com/Hop-developers/Hop.jl): construct Hamiltonian based on nonorthogonal localized orbitals (NoLO) as implemented in OpenMx.
2. Caesar: perform lattice dynamics calculations using the finite-displacement method and generate possible atomic configurations consistent with the nuclear density arising from phonons.  It is not widely opened yet. Upon a reasonable request, this package shall be available from the author Bartomeu Monserrat (<https://www.msm.cam.ac.uk/people/monserrat>). 

## Author

Zuzhang Lin (ZuzhangLin@outlook.com)
