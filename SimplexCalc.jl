
function Cube_Label_3D(Dim,L) # ------Determine the indices of d=3 s=3
    if Dim != 3
        println("ERROR Dim")
    end
    Ncube = L^Dim
    Nspin = Dim*Ncube

    println(Nspin)

    Cube = zeros(Int,Ncube,6)

    # First round 
    for i = 1:L^3
        Cube[i,1] = Dim*(i-1) + 1
        Cube[i,2] = Dim*(i-1) + 2
        Cube[i,3] = Dim*(i-1) + 3
    end

    # Second round 
    i = 0
    for z=1:L
        for y=1:L
            for x=1:L
                i += 1
                if (x==L) #X-NEIGHBOR
                    Cube[i,4] = Cube[i+1-L,1]
                else
                    Cube[i,4] = Cube[i+1,1]
                end
                if (y==L) #Y-NEIGHBOR
                    Cube[i,5] =  Cube[i+L-L^2,2]
                else
                    Cube[i,5] =  Cube[i+L,2]
                end
                if (z==L) #Z-NEIGHBOR
                    Cube[i,6] = Cube[i+L^2-L^3,3]
                else
                    Cube[i,6] = Cube[i+L^2,3]
                end
             end #x
        end #y
    end #z


#   println(Cube)

return Cube

end #Cube_Label_3D

#------------------------------------------------

function Cube_Label(Dim,L)

    Ncube = L^Dim
    Cube = zeros(Int,Ncube,2*Dim)

    # First round 
    for i = 1:Ncube
        for j = 1:Dim
            Cube[i,j] = Dim*(i-1) + j
        end
    end

    # Second round
    i=0
    dims = ntuple(_->L, Dim)
    for coords in Iterators.product(map(k->1:dims[k], dims)...)
        i += 1
        for j = 1:Dim
            plane1 = L^(j-1)
            plane2 = L^(j)
            if coords[j] == L
                Cube[i,j+Dim] = Cube[i+plane1-plane2,j]
            else
                Cube[i,j+Dim] = Cube[i+plane1,j]
            end
        end
    end
    return Cube
end

#-----------------------Energy Calculation---------------------

function Calc_Energy(Spin,Ncube)

    #calculate the energy
    Energy = 0
    for i = 1:Ncube
        prod = 0
        for j = 1:6
            global prod *= Spin[Cube[i,j]]
        end
        global Energy += -prod
    end

return Energy
end

#-----------------------MAIN---------------------

Dim = 3
L = 3 

Cube = Cube_Label_3D(Dim,L)  #One entry for every dimension
@show Cube

Ncube = L^Dim
Nspin = 3*Ncube

Spin = ones(Int,Nspin)
@show size(Spin),Spin

@show Calc_Energy(Spin,Ncube)

println("Edlánat’e World")
