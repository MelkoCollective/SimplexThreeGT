
function Cube_Label_3D(Dim,L) # ------Determine the indices of d=3 s=2
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
                    Cube[i,4] = Cube[i-L+1,3]
                else
                    Cube[i,4] = Cube[i+1,3]
                end
                if (y==L) #Y-NEIGHBOR
                    Cube[i,5] =  Cube[i-L^2+L,1]
                else
                    Cube[i,5] =  Cube[i+L,1]
                end
                if (z==L) #Z-NEIGHBOR
                    Cube[i,6] = Cube[i-L^3+L^2,2]
                else
                    Cube[i,6] = Cube[i+L^2,2]
                end
             end #x
        end #y
    end #z


   println(Cube)

end

#-----------------------MAIN---------------------

Dim = 3
L = 3 

Cube_Label_3D(Dim,L) 

println("Edlánat’e World")
