# SimplexThreeGT
Simplex Three Gauge Theory Monte Carlo

This repository contains code for the simulation of the 3-cell classical Z2 gauge theories. The Hamiltonians are constructed on $d$-dimensional hypercubic lattices out of Ising variables interacting on hypercubic "cells" or "simplices".  Specifically

* 0-cell: a point or vertex
* 1-cell: a line or edge
* 2-cell: a square plaquette or face
* 3-cell: a cube

The theory of interest is defined with the Hamiltonian $$H = - \sum_{c_{p+1}} \prod_{i \in c_{p+1}} \sigma_i$$
where the product is over the $2(p+1)$ number of $p$-cells attached to $c_{p+1}$.
In the conventional Z2 gauge theory, $p=1$ and the Hamiltonian becomes $$H = - \sum_{c_{2}} \sigma_i \sigma_j \sigma_k \sigma_l$$
where $i,j,k,l$ label the edges (1-cells) of each square plaquette $c_2$.  In the model we are interested in, $p=2$, therefore $$H = - \sum_{c_{3}} \sigma_i \sigma_j \sigma_k \sigma_l \sigma_m \sigma_n$$
where $c_3$ are all cubes, and $i,..,n$ label the faces of each cube.

We define the Hamiltonian on a periodic hypercubic lattice of dimension $d$, with the following conventions thanks to R. Myers.  We begin with labelling the $d$ unit vectors of the hypercubic lattice: $\overrightarrow{x}_1 = (1,0,0,0,\ldots)$, $\overrightarrow{x}_2 = (0,1,0,0,\ldots)$, and so on.

First, we label all 0-cells of the hypercubic lattice.  There are $N_0$ of them, and for a hypercube of linear size $L$ the total number is $N_0 = L^d$. We label each 0-cell (vertex) as an interger $v \in [1,N_0]$.

Second, we can label all 1-cells of the lattice, where there are $d$ edges eminating (in each positive direction) from each vertex $v$, so that $N_1 = d N_0$. Each edge can be eminated by picking a unit vector and labelling it with the pair $$c_1 = (v,\overrightarrow{x}_i),$$ for $i = 1 \ldots d$.

Third, we can label all 2-cells of the lattice, by a vertex and a pair of basis vectors. $$c_2=(v,[\overrightarrow{x}_i, \overrightarrow{x}_j]),$$ and $i$ less than $j$.  Again, restricting 2-cells (faces) to point in only the positive direction, there are ${d}\choose{2}$ faces associated with each vertex. I.e. $N_2/N_0= d(d-1)/2$.

Finally, for 3-cells or cubes, labelling can be written as $$c_3 =(v,[\overrightarrow{x}_i, \overrightarrow{x}_j,\overrightarrow{x}_k]),$$ where $i$ less than $j$ less than $k$.  The number of 3-cells associated with each vertex for a $d$-dimensional hypercubic lattice is ${d}\choose{3}$, so $N_3/N_0 = d(d-1)(d-2)/6$.

For the Hamiltonian of interest, we must label all of the $2(p+1)$ interactions.  As an example, consider $p=1$, the usual Z2 gauge theory in $d$ dimensions with interactions defined on square plaquettes (2-cells). The sum $\sum_{c_{2}}$ runs over the labels $c_2$ above.  Each square plaquette has 4 edges, where the variables $\sigma$ live.  Given a plaquette labelled by $c_2$ above, the four edges are labelled by $$(v,\overrightarrow{x}_i)$$ $$(v,\overrightarrow{x}_j)$$ $$(v + \overrightarrow{x}_i,\overrightarrow{x}_j)$$ $$(v + \overrightarrow{x}_j,\overrightarrow{x}_i)$$ Note that each edge (1-cell) will be shared by some number of other plaquettes (2-cells) depending on the lattice dimension.

Similarly, consider $p=2$.  The sum $\sum_{c_{3}}$ now runs over all 3-cells, which are cubes with 6 faces (2-cells) each.  The degrees of freedom $\sigma$ lie on these 2-cells.  They can be labelled

Similarly, consider $p=2$.  The sum $\sum_{c_{3}}$ now runs over all 3-cells, which are cubes with 6 faces (2-cells) each.  The degrees of freedom $\sigma$ lie on these 2-cells.  Given a cube (3-cell) eminating from a vertex (0-cell) with label $c_3$ above, the six faces (where $\sigma$ is defined) are labelled by $$(v,[\overrightarrow{x}_i,\overrightarrow{x}_j])$$ $$(v,[\overrightarrow{x}_i,\overrightarrow{x}_k])$$ $$(v,[\overrightarrow{x}_j,\overrightarrow{x}_k])$$ $$(v+\overrightarrow{x}_k,[\overrightarrow{x}_i,\overrightarrow{x}_j])$$ $$(v+\overrightarrow{x}_j,[\overrightarrow{x}_i,\overrightarrow{x}_k])$$ $$(v+\overrightarrow{x}_i,[\overrightarrow{x}_j,\overrightarrow{x}_k])$$ Note that each variable sigma will be shared by a number of other 3-cell Hamiltonian terms.

## Topology

https://www.iue.tuwien.ac.at/phd/heinzl/node17.html
