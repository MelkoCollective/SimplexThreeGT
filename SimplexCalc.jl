#This is a code to print the indices of one cube (3 simplex)

function Cube_Label(Dim,L)

    Nspin = 3*L^3

    Cube = zeros(Int,Nspin,Dim)

    for i = 1:L^3
        Cube[i,1] = i
        Cube[i,2] = i+1
        Cube[i,3] = i+2
    end

   println(Cube)

end

#-----------------------MAIN---------------------

Dim = 3
L = 2 

Cube_Label(Dim,L) 

println("Edlánat’e World")
