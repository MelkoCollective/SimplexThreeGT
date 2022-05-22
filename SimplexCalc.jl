
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
    #Nspin = Dim*Ncube

    Cube = zeros(Int,Ncube,2*Dim)

    # First round 
    for i = 1:Ncube
        for j = 1:L
            Cube[i,j] = Dim*(i-1) + j
        end
    end

    # Second round
    i=0
    dims = ntuple(_->L, Dim)
    for coords in Iterators.product(map(k->1:dims[k], dims)...)
        i += 1
        #@show coords
        for j = 1:Dim
            #@show coords[j]
            #@show Cube[i,j+Dim]

            plane1 = L^(j-1)
            plane2 = L^(j)

            if coords[j] == L
                Cube[i,j+Dim] = Cube[i+plane1-plane2,j]
            else
                Cube[i,j+Dim] = Cube[i+plane1,j]
            end
        end
    end
    @show Cube
end

#-----------------------MAIN---------------------

Dim = 3
L = 3 

Cube = Cube_Label_3D(Dim,L) 
println(Cube)

#Cube_Label(Dim,L)

Cube_Label(Dim,L)  #One entry for every dimension

println("Edlánat’e World")
