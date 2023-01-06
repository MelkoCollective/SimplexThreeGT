# SimplexThreeGT
Simplex Three Gauge Theory Monte Carlo

This repository contains code for the simulation of the 3-cell classical Z2 gauge theories. The Hamiltonians are constructed on $d$-dimensional hypercubic lattices out of Ising variables interacting on hypercubic "cells" or "simplices".  Specifically

* 0-cell: a vertex
* 1-cell: a line or edge
* 2-cell: a square plaquette
* 3-cell: a cube

The theory of interest is defined with the Hamiltonian:
$$
H = - \sum_{c_{p+1}} \prod_{i \in c_{p+1}} \sigma_i
$$:q
where the product is over the $2(p+1)$ number of $p$-cells attached to $c_{p+1}$.
In the conventional Z2 gauge theory, $p=1$ and the Hamiltonian becomes
$$
H = - \sum_{c_{2}} \sigma_i \sigma_j \sigma_k \sigma_l
$$
where $i,j,k,l$ label the edges (1-cells) of each square plaquette $c_2$.  In the model we are interested in, $p=2$, therefore
$$
H = - \sum_{c_{3}} \sigma_i \sigma_j \sigma_k \sigma_l \sigma_m \sigma_n
$$
where $c_3$ are all cubes, and $i,..,n$ label the faces of each cube.

We define the Hamiltonian on a periodic hypercubic lattice of dimension $d$.