
function Cube_Label_4D(Dim,L) # ------Determine the indices of d=3 s=3
    if Dim != 4
        println("ERROR Dim")
    end

    N0 = L^Dim               #number of vertices
    N1 = Dim*N0              #number of bonds
    Dchoose2=binomial(Dim,2)
    N2 = Dchoose2*N0  #number of plaquettes 
    Dchoose3=binomial(Dim,3)
    N3 = Dchoose3*N0  #number of cubes

    @show(N3,N2,N1,N0)

    dict1 = Dict{Tuple,Int}();  #index mapping for 1-cells
    dict2 = Dict{Tuple,Int}();  #index mapping for 2-cells
    dict3 = Dict{Tuple,Int}();  #index mapping for 3-cells
    c1 = 0
    c2 = 0
    c3 = 0
    for v = 1:N0 #loop over the vertices
        for i = 1:Dim
            c1 += 1
            Myers1 = (v,i)
            dict1[Myers1] = c1
            for j = (i+1):Dim
                c2 += 1
                Myers2 = (v,i,j)
                dict2[Myers2] = c2
                for k = (j+1):Dim
                    c3 += 1
                    Myers3 = (v,i,j,k)
                    dict3[Myers3] = c3
                end
            end
        end
    end

    ##DEBUG
    #for v = 1:N0 #loop over the vertices
    #    for i = 1:Dim
    #        for j = (i+1):Dim
    #            for k = (j+1):Dim
    #                Myers3 = (v,i,j,k)
    #                in3 = get(dict3,Myers3,0)
    #                @show(Myers3,in3)
    #            end
    #        end
    #    end
    #end

    #Next we need a data structure that, given v, gives v'(v,x) where v' = v+x_1, v' = v_x^2, etc.
    vprime = zeros(Int,N0,4) #(v,i) where i = 1,2,3,4 for unit vectorsx_i
    for v = 1:N0 #loop over the vertices
        #@show(v,mod(v,L))
        #@show(mod(v,L^2))
        #@show(mod(v,L^3))
        if (mod(v,L) != 0) #x-direction
            vprime[v,1] = v + 1
        else
            vprime[v,1] = v - (L-1)
        end

        if (mod(v-1,L^2) < (L^2-L) ) #y-direction
            vprime[v,2] = v+L
        else
            #println("Y-edge")
            vprime[v,2] = v - (L^2-L)
        end

        if (mod(v-1,L^3) < (L^3-L^2) ) #z-direction
            vprime[v,3] = v+L^2
        else
            #println("Z-edge")
            vprime[v,3] = v - (L^3-L^2)
        end

        if (mod(v-1,L^4) < (L^4-L^3) ) #z-direction
            vprime[v,4] = v+L^3
        else
            vprime[v,4] = v - (L^4-L^3)
        end
        #@show(v,vprime[v,1],vprime[v,2],vprime[v,3],vprime[v,4])
    end

#    for v = 1:N0 
#        @show(vprime[v,1])
#        @show(vprime[v,2])
#        @show(vprime[v,3])
#        @show(vprime[v,4])
#    end

    Cube = zeros(Int,N3,6) #all cubes have 6 faces 
    for v = 1:N0 #loop over the vertices
        for i = 1:Dim
            for j = (i+1):Dim
                for k = (j+1):Dim
                    Myers3 = (v,i,j,k)
                    #First 3 faces
                    c3 = get(dict3,Myers3,0) 
                    Myers2=(v,i,j)
                    Cube[c3,1]= get(dict2,Myers2,0)
                    Myers2=(v,i,k)
                    Cube[c3,2]= get(dict2,Myers2,0)
                    Myers2=(v,j,k)
                    Cube[c3,3]= get(dict2,Myers2,0)
                    #second 3 faces
                    Myers2=(vprime[v,k],i,j)
                    Cube[c3,4]= get(dict2,Myers2,0)
                    Myers2=(vprime[v,j],i,k)
                    Cube[c3,5]= get(dict2,Myers2,0)
                    Myers2=(vprime[v,i],j,k)
                    Cube[c3,6]= get(dict2,Myers2,0)
                end
            end
        end
    end

    #@show(Cube)
    for c3 = 1:N3
        println(c3," ",Cube[c3,1]," ",Cube[c3,2]," ",Cube[c3,3]," ",Cube[c3,4]," ",Cube[c3,5]," ",Cube[c3,6])
    end

    return Cube


end #Cube_Label_4D

#------------------------------------------------

function Invert_Cube_3D(Cube)

    Ncube = size(Cube,1) 
    Nspin = 3*Ncube

    Inverse = zeros(Int,Nspin,2) #each cube shares 2 spins in 3D

    for i = 1:Ncube
        for j = 1:6
            if Inverse[Cube[i,j],1] == 0 
                Inverse[Cube[i,j],1] = i
            elseif Inverse[Cube[i,j],2] == 0 
                Inverse[Cube[i,j],2] = i 
            else 
                println("Inverse Error")
            end
        end
    end

return Inverse
end #Invert_Cube

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
    for coords in Iterators.product(map(k->1:dims[k], 1:length(dims))...)
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

#-----------------------Energy Calculations---------------------

function Calc_Energy(Spin,Ncube)

    #calculate the energy
    cEnergy = 0.
    for i = 1:Ncube
        prod = 1
        for j = 1:6
            prod *= Spin[Cube[i,j]]
        end
        cEnergy += -prod
    end

    return cEnergy
end

function Elocal(C1,Spin)
    prod1 = 1
    for j = 1:6 
        #@show Spin[Cube[C1,j]]
        prod1 *= Spin[Cube[C1,j]]
    end

    return prod1 
end

function Energy_Diff(Spin, snum, Inverse)

    Cube1 = Inverse[snum,1] 
    Cube2 = Inverse[snum,2] 

    Eold = -Elocal(Cube1,Spin) - Elocal(Cube2,Spin) 
    Spin[snum] = - Spin[snum] 
    Enew = -Elocal(Cube1,Spin) - Elocal(Cube2,Spin) 

    return Enew - Eold

end #Energy_Diff

function MetropolisAccept(DeltaE,T,rng)

    if DeltaE <= 0
        return true
    else
        rnum = rand(rng)  #random number for Metropolis
        if (exp(-DeltaE/T) > rnum)
            return true
        end
    end 
    return false
end

#-----------------------MAIN---------------------
using Random
rng = MersenneTwister(1334);

Dim = 4
L = 3

@show(Dim,L)
Cube = Cube_Label_4D(Dim,L)  #One entry for every dimension
exit()

display(Cube)
Inverse = Invert_Cube_3D(Cube)
#@show Inverse

Ncube = size(Cube,1) #Ncube = L^Dim
Nspin = 3*Ncube

#Spin = ones(Int,Nspin)
Spin = rand(rng,(-1, 1), Nspin)
@show sum(Spin)
#Calculate initial energy
Energy = Calc_Energy(Spin,Ncube)
@show Energy

Es = Float64[];
Cvs = Float64[];
for T = 4.6:-0.05:0.05
     #Equilibriate
     num_EQL = 50000
     for i = 1:num_EQL
         snum = rand(rng,1:Nspin) 
         DeltaE = Energy_Diff(Spin, snum, Inverse) #flips spin
         if MetropolisAccept(DeltaE,T,rng) == true 
             global Energy += DeltaE
         else
             Spin[snum] = - Spin[snum]  #flip the spin back
         end
     end #Equilibrate
     
     E_avg = 0.
     E2 = 0.
     
     num_MCS = 5000000
     for i = 1:num_MCS
         snum = rand(rng,1:Nspin) 
         DeltaE = Energy_Diff(Spin, snum, Inverse) #flips spin
         if MetropolisAccept(DeltaE,T,rng) == true 
             global Energy += DeltaE
         else
             Spin[snum] = - Spin[snum]  #flip the spin back
         end
     
         E_avg += Energy
         E2 += Energy*Energy
     
     end #MCS
     
     #@show E_avg/num_MCS
     Cv = E2/num_MCS- (E_avg/num_MCS)^2
     push!(Es, E_avg/num_MCS/Nspin)
     push!(Cvs, Cv/Nspin/T/T)
     println(T," ",E_avg/num_MCS," ",E2/num_MCS)

end #T loop

# using UnicodePlots
# UnicodePlots.lineplot(collect(1:length(Es)), Es)
#println("Edlánat’e World")
