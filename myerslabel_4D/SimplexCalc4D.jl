
function Cube_Label_4D(Dim,L) # ------Determine the indices of d=3 s=3
    if Dim != 4
        println("ERROR Dim")
    end

    N0 = L^Dim  #number of vertices
    N1 = Dim*N0 #number of bonds
    N2 = binomial(Dim,2)*N0  #number of plaquettes 
    N3 = binomial(Dim,3)*N0  #number of cubes

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
    vplus = zeros(Int,N0,4) #(v,i) where i = 1,2,3,4 for unit vectorsx_i
    vminus = zeros(Int,N0,4) # the v-x_i version for the gauge flip
    for v = 1:N0 #loop over the vertices
        #@show(v,mod(v,L))
        #@show(mod(v,L^2))
        #@show(mod(v,L^3))
        if (mod(v,L) != 0) #x-direction
            vprime = v + 1
        else
            vprime = v - (L-1)
        end
        vplus[v,1] = vprime
        vminus[vprime,1] = v 

        if (mod(v-1,L^2) < (L^2-L) ) #y-direction
            vprime = v+L
        else
            #println("Y-edge")
            vprime = v - (L^2-L)
        end
        vplus[v,2] = vprime
        vminus[vprime,2] = v 

        if (mod(v-1,L^3) < (L^3-L^2) ) #z-direction
            vprime = v+L^2
        else
            #println("Z-edge")
            vprime = v - (L^3-L^2)
        end
        vplus[v,3] = vprime
        vminus[vprime,3] = v 

        if (mod(v-1,L^4) < (L^4-L^3) ) #z-direction
            vprime = v+L^3
        else
            vprime = v - (L^4-L^3)
        end
        vplus[v,4] = vprime
        vminus[vprime,4] = v 
       #@show(v,vplus[v,1],vplus[v,2],vplus[v,3],vplus[v,4])
    end

#    for v = 1:N0 
#        @show(vplus[v,1])
#        @show(vplus[v,2])
#        @show(vplus[v,3])
#        @show(vplus[v,4])
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
                    Myers2=(vplus[v,k],i,j)
                    Cube[c3,4]= get(dict2,Myers2,0)
                    Myers2=(vplus[v,j],i,k)
                    Cube[c3,5]= get(dict2,Myers2,0)
                    Myers2=(vplus[v,i],j,k)
                    Cube[c3,6]= get(dict2,Myers2,0)
                end
            end
        end
    end

    #@show(Cube)
    #for c3 = 1:N3
    #    println(c3," ",Cube[c3,1]," ",Cube[c3,2]," ",Cube[c3,3]," ",Cube[c3,4]," ",Cube[c3,5]," ",Cube[c3,6])
    #end

    Star = zeros(Int,N1,6) #gauge stars have 6 faces in 4D ONLY
    for v = 1:N0 #loop over the vertices
        for i = 1:Dim
            Myers1 = (v,i) #this is your bond
            c1 = get(dict1,Myers1,0) 
            pcount = 0 #plaquette counter sould to from 1 to 6
            for j = 1:Dim #loop over the rest of the bonds 
                if i == j
                    #do nothing
                elseif j<i
                    Myers2=(v,j,i)
                    pcount += 1
                    Star[c1,pcount] = get(dict2,Myers2,0)
                    Myers2=(vminus[v,j],j,i)
                    pcount += 1
                    Star[c1,pcount] = get(dict2,Myers2,0)
                elseif j>i
                    Myers2=(v,i,j)
                    pcount += 1
                    Star[c1,pcount] = get(dict2,Myers2,0)
                    Myers2=(vminus[v,j],i,j)
                    pcount += 1
                    Star[c1,pcount] = get(dict2,Myers2,0)
                else
                    @show("star error 1")
                end
            end
            if pcount != 6 
                @show("star error 2")
            end
        end
    end

#    for c1 = 1:N1 
#        println(Star[c1,1])
#        println(Star[c1,2])
#        println(Star[c1,3])
#        println(Star[c1,4])
#        println(Star[c1,5])
#        println(Star[c1,6])
#    end
#    println(Star[1,1]," ",Star[1,2]," ",Star[1,3]," ",Star[1,4]," ",Star[1,5]," ",Star[1,6])

    return Cube, Star


end #Cube_Label_4D

#------------------------------------------------

function Invert_Cube_4D(Cube,N0,N1,N2,N3)

    Ncube = N3
    Nspin = N2

    Inverse = zeros(Int,Nspin,4) #each cube shares 2 spins in 3D, and 4 in 4D

    for i = 1:Ncube
        for j = 1:6
            if Inverse[Cube[i,j],1] == 0 
                Inverse[Cube[i,j],1] = i
            elseif Inverse[Cube[i,j],2] == 0 
                Inverse[Cube[i,j],2] = i 
             elseif Inverse[Cube[i,j],3] == 0 
                Inverse[Cube[i,j],3] = i 
              elseif Inverse[Cube[i,j],4] == 0 
                Inverse[Cube[i,j],4] = i 
         else 
                println("Inverse Error")
            end
        end
    end

return Inverse
end #Invert_Cube

#-----------------------Energy Calculations---------------------

function Calc_Energy(Spin,Ncube,Cube)

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

function Elocal(C1,Spin,Cube)
    prod1 = 1
    for j = 1:6 
        #@show Spin[Cube[C1,j]]
        prod1 *= Spin[Cube[C1,j]]
    end

    return prod1 
end

function Single_Spin_Flip(Spin, snum, Inverse,Cube,H) # This depends on dimension still

    Cube1 = Inverse[snum,1] 
    Cube2 = Inverse[snum,2] 
    Cube3 = Inverse[snum,3] 
    Cube4 = Inverse[snum,4] 

    Eold = -Elocal(Cube1,Spin,Cube) - Elocal(Cube2,Spin,Cube) - Elocal(Cube3,Spin,Cube) - Elocal(Cube4,Spin,Cube) 
    Spin[snum] = - Spin[snum] 
    Enew = -Elocal(Cube1,Spin,Cube) - Elocal(Cube2,Spin,Cube) - Elocal(Cube3,Spin,Cube) - Elocal(Cube4,Spin,Cube) 

    deltaHenergy = -2*H*Spin[snum] #assuming Spin has changed sign

    return Enew - Eold 

end #Single_Spin_Flip

function Gauge_Star_Flip(Spin,bnum,Inverse,Star)  #This only works for 4D

    Eold = 0
    Enew = 0
    for pcount = 1:6
        snum = Star[bnum,pcount]
        Cube1 = Inverse[snum,1] 
        Cube2 = Inverse[snum,2] 
        Cube3 = Inverse[snum,3] 
        Cube4 = Inverse[snum,4] 
        Eold += -Elocal(Cube1,Spin) - Elocal(Cube2,Spin) - Elocal(Cube3,Spin) - Elocal(Cube4,Spin) 
        Spin[snum] = - Spin[snum] 
        Enew += -Elocal(Cube1,Spin) - Elocal(Cube2,Spin) - Elocal(Cube3,Spin) - Elocal(Cube4,Spin) 
    end

    println("Need H field in Gauge Flip")

    return Enew - Eold

end #Gague_Star_Flip

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
function main()

    rng = MersenneTwister(1334);
    
    L = 3
    Dim = 4
    H = 0  #magnetic/matter field
    
    N0 = L^Dim  #number of vertices
    N1 = Dim*N0 #number of bonds
    N2 = binomial(Dim,2)*N0  #number of plaquettes 
    N3 = binomial(Dim,3)*N0  #number of cubes
    
    @show(Dim,L)
    Cube, Star = Cube_Label_4D(Dim,L)  #One entry for every dimension
    
    #display(Cube)
    Inverse = Invert_Cube_4D(Cube,N0,N1,N2,N3)
    #@show Inverse
    
    Ncube = N3 #4D definitions
    Nspin = N2
    Nbond = N1
    
    #Spin = ones(Int,Nspin)
    Spin = rand(rng,(-1, 1), Nspin)
    #@show sum(Spin)
    #Calculate initial energy
    Energy = Calc_Energy(Spin,Ncube,Cube)
    @show Energy
    
    #Es = Float64[];
    #Cvs = Float64[];
    for T = 2.0:-0.1:0.10
         #Equ2libriate
         num_EQL = 1000
         for i = 1:num_EQL
            #---- Single Spin Flip
            for j = 1:10 #(Nspin÷2)
                 snum = rand(rng,1:Nspin) 
                 DeltaE = Single_Spin_Flip(Spin, snum, Inverse,Cube,H) #flips spin
                 if MetropolisAccept(DeltaE,T,rng) == true 
                     Energy += DeltaE
                 else
                     Spin[snum] = - Spin[snum]  #flip the spin back
                 end
            end
            ##---- Gauge Star Flip (6 spins)
            #for j = 1:(Nbond÷12)
            #    bnum = rand(rng,1:Nbond)  
            #    DeltaE = Gauge_Star_Flip(Spin,bnum,Inverse,Star)  #This only works for 4D
            #    if MetropolisAccept(DeltaE,T,rng) == true 
            #        global Energy += DeltaE
            #    else
            #       for pcount = 1:6 #flip back the 6 spins that were flipped in the gauge move
            #           pnum = Star[pnum,pcount]
            #           Spin[pnum] = - Spin[pnum] 
            #       end
            #    end
            #end
        end #Equilibrate
    
        E_avg = 0.
        E2 = 0.
        M_avg = 0.
        M2 = 0.

        Mag = 0
        for s in Spin
            Mag += s
        end
        #@show(Mag)

        num_MCS = 10000
        for i = 1:num_MCS
           #---- Single Spin Flip
           for j = 1:10 #(Nspin÷2)
                snum = rand(rng,1:Nspin) 
                DeltaE = Single_Spin_Flip(Spin, snum, Inverse,Cube,H) #flips spin
                if MetropolisAccept(DeltaE,T,rng) == true 
                    Energy += DeltaE
                    Mag += 2*Spin[snum] # Spin has been flipped
                else
                    Spin[snum] = - Spin[snum]  #flip the spin back
                end
           end
           ##---- Gauge Star Flip (6 spins)
           #for j = 1:(Nbond÷12)
           #    bnum = rand(rng,1:Nbond)  
           #    DeltaE = Gauge_Star_Flip(Spin,bnum,Inverse,Star)  #This only works for 4D
           #    if MetropolisAccept(DeltaE,T,rng) == true 
           #        global Energy += DeltaE
           #    else
           #       for pcount = 1:6
           #           pnum = Star[bnum,pcount]
           #           Spin[pnum] = - Spin[pnum] 
           #       end
           #    end
           #end
           ##---- collect data
           E_avg += Energy
           E2 += Energy*Energy
           M_avg += Mag;
           M2 += Mag*Mag;

        
        end #MCS
         
         #@show E_avg/num_MCS
         Cv = E2/num_MCS- (E_avg/num_MCS)^2
         Susc = M2/num_MCS- (M_avg/num_MCS)^2
         println(T," ",E_avg/num_MCS/Nspin," ",Cv/Nspin/T/T," ",M_avg/num_MCS/Nspin," ",Susc/Nspin/T)
    
    end #T loop

end #main

using Random
main()
    
# using UnicodePlots
# UnicodePlots.lineplot(collect(1:length(Es)), Es)
#println("Edlánat’e World")
