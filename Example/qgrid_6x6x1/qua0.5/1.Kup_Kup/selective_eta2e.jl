using Distributed

@everywhere push!(LOAD_PATH, dirname(dirname(dirname(@__FILE__))))

#@everywhere using Pkg

#@everywhere Pkg.activate("/home/linzz/apps/Hop.jl")
@everywhere push!(LOAD_PATH,"/home/linzz/apps/Hop_old_edition/Hop.jl")
@everywhere using DelimitedFiles,LinearAlgebra,Test, Printf,Statistics
#FileIO, JLD2, YAML, DelimitedFiles
@everywhere using Hop

function sign_control(x)
    if real(x) >=0
        return x
    else
        return x
    end
end


kpoints=10
mode=9
k_vector=readdlm("k_vector.txt", ' ', Float64, '\n')
sc_size=readdlm("no_atoms.txt", ' ', Float64, '\n')
k_weight=trunc.(Int,readdlm("ibz.dat",' ',Float64,'\n')[:,4])


frequency=zeros(Float64, kpoints, mode)
for i=1:kpoints
    for j=1:mode
        frequency[i,j]=readdlm("frequency.$i.$j.dat", ' ', '\n')[end]
    end
end



v0=26;

temperature = LinRange(0, 300, 16)
T_len=length(temperature)

A_vel_p=zeros(Float64, kpoints, mode)
A_vel_n=zeros(Float64, kpoints, mode)

A_vel_p_T=zeros(Float64,T_len,kpoints, mode) #T means temeperature
A_vel_n_T=zeros(Float64,T_len,kpoints, mode)

vel_p_static=[]
vel_n_static=[]
for i = 1:kpoints
#for i = 5:5
    print(i,"\n")
    v=Int(sc_size[i,2]*v0)
    v1=v-3;v2=v-2;v3=v-1;v4=v;c1=v+1;c2=v+2;c3=v+3;c4=v+4
    kx=k_vector[i,2];ky=k_vector[i,3]
    Ham_0=Hop.Interface.createmodelopenmx("./MoSe2_$i.0.scfout")
    vel_p_0_M=[] #velocitym plus, static, matrix
    vel_p_0_M_abs=[]
    for m = v1:v4
        for n = c1:c4
            temp=getvelocity(Ham_0,1,[kx,ky,0])[n,m]+im*getvelocity(Ham_0,2,[kx,ky,0])[n,m]
            push!(vel_p_0_M,abs.(temp))
            push!(vel_p_0_M_abs,abs.(temp))
        end
    end



    vel_n_0_M=[]
    for m = v1:v4
        for n = c1:c4
            temp=getvelocity(Ham_0,1,[kx,ky,0])[n,m]-im*getvelocity(Ham_0,2,[kx,ky,0])[n,m]
            push!(vel_n_0_M,abs.(temp))
        end
    end
    """
    if i==5
        for vel_p_0_i=7:7
            vel_p_0=sign_control(vel_p_0_M[vel_p_0_i])
            vel_n_0=sign_control(vel_n_0_M[vel_p_0_i])
            print("index: ", vel_p_0_i,"\n")
            print("positive: ", vel_p_0," negative: ", vel_n_0,"\n")
        end
    else
        a_temp=findmax(vel_p_0_M_abs)
        vel_p_0_i=a_temp[2]
        vel_p_0=sign_control(vel_p_0_M[vel_p_0_i])
        vel_n_0=sign_control(vel_n_0_M[vel_p_0_i])
        print("index: ", vel_p_0_i,"\n")
        print("positive: ", vel_p_0," negative: ", vel_n_0,"\n")
    end
    """
    if i==5
        vel_p_0_i=13
    elseif i==8
        vel_p_0_i=9
    else
        a_temp=findmax(vel_p_0_M_abs)
        #vel_p_0_i=a_temp[2]

        vel_p_0_i=13
    end
    vel_p_0=sign_control(vel_p_0_M[vel_p_0_i])
    vel_n_0=sign_control(vel_n_0_M[vel_p_0_i])
    print("index: ", vel_p_0_i,"\n")
    print("positive: ", vel_p_0," negative: ", vel_n_0,"\n")






    if i==1
        push!(vel_p_static,vel_p_0)
        push!(vel_n_static,vel_n_0)

        for j =4:mode
            Ham_1= Hop.Interface.createmodelopenmx("./MoSe2_$i.$j.1.scfout")
            Ham_2= Hop.Interface.createmodelopenmx("./MoSe2_$i.$j.-1.scfout")
            vel_p_1_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_1,1,[kx,ky,0])[n,m]+im*getvelocity(Ham_1,2,[kx,ky,0])[n,m]
                    push!(vel_p_1_M,abs.(temp))
                end
            end
            vel_p_1=sign_control(vel_p_1_M[vel_p_0_i])

            vel_p_2_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_2,1,[kx,ky,0])[n,m]+im*getvelocity(Ham_2,2,[kx,ky,0])[n,m]
                    push!(vel_p_2_M,abs.(temp))
                end
            end
            vel_p_2=sign_control(vel_p_2_M[vel_p_0_i])
            print("positive_1 ", vel_p_1, " positive_2 ", vel_p_2, "\n")

            vel_n_1_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_1,1,[kx,ky,0])[n,m]-im*getvelocity(Ham_1,2,[kx,ky,0])[n,m]
                    push!(vel_n_1_M,abs.(temp))
                end
            end
            vel_n_1=sign_control(vel_n_1_M[vel_p_0_i])

            vel_n_2_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_2,1,[kx,ky,0])[n,m]-im*getvelocity(Ham_2,2,[kx,ky,0])[n,m]
                    push!(vel_n_2_M,abs.(temp))
                end
            end
            vel_n_2=sign_control(vel_n_2_M[vel_p_0_i])


            A_vel_p[i,j]=((vel_p_1+vel_p_2)/2-vel_p_0)/0.25
            A_vel_n[i,j]=((vel_n_1+vel_n_2)/2-vel_n_0)/0.25
            #print(A_vel_p[i,j],"\n")
            print("negative_1 ", vel_n_1, " negative_2 ", vel_n_2, "\n")

        end
    else
        for j =1:mode
            Ham_1= Hop.Interface.createmodelopenmx("./MoSe2_$i.$j.1.scfout")
            Ham_2= Hop.Interface.createmodelopenmx("./MoSe2_$i.$j.-1.scfout")
            vel_p_1_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_1,1,[kx,ky,0])[n,m]+im*getvelocity(Ham_1,2,[kx,ky,0])[n,m]
                    push!(vel_p_1_M,abs.(temp))
                end
            end
            vel_p_1=sign_control(vel_p_1_M[vel_p_0_i])

            vel_p_2_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_2,1,[kx,ky,0])[n,m]+im*getvelocity(Ham_2,2,[kx,ky,0])[n,m]
                    push!(vel_p_2_M,abs.(temp))
                end
            end
            vel_p_2=sign_control(vel_p_2_M[vel_p_0_i])
            print("positive_1 ", vel_p_1, " positive_2 ", vel_p_2, "\n")

            vel_n_1_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_1,1,[kx,ky,0])[n,m]-im*getvelocity(Ham_1,2,[kx,ky,0])[n,m]
                    push!(vel_n_1_M,abs.(temp))
                end
            end
            vel_n_1=sign_control(vel_n_1_M[vel_p_0_i])

            vel_n_2_M=[]
            for m = v1:v4
                for n = c1:c4
                    temp=getvelocity(Ham_2,1,[kx,ky,0])[n,m]-im*getvelocity(Ham_2,2,[kx,ky,0])[n,m]
                    push!(vel_n_2_M,abs.(temp))
                end
            end
            vel_n_2=sign_control(vel_n_2_M[vel_p_0_i])

            A_vel_p[i,j]=((vel_p_1+vel_p_2)/2-vel_p_0)/0.25
            A_vel_n[i,j]=((vel_n_1+vel_n_2)/2-vel_n_0)/0.25
            #print(A_vel_p[i,j],"\n")
            print("negative_1 ", vel_n_1, " negative_2 ", vel_n_2, "\n")
        end
    end
end

x=collect(1:mode)
k_ibz=readdlm("ibz.dat", ' ', Float64, '\n')

open("vel_p_kp.dat", "w") do io
    for i = 1:kpoints
        A_t=0
        for j =1:mode
            A_t=A_t+A_vel_p[i,j]    
        end
        writedlm(io, [k_ibz[i,1] k_ibz[i,2] A_t])
    end
end

open("vel_n_kp.dat", "w") do io
    for i = 1:kpoints
        A_t=0
        for j =1:mode
            A_t=A_t+A_vel_n[i,j]
        end
        writedlm(io, [k_ibz[i,1] k_ibz[i,2] A_t])
    end
end


open("vel_p_kp_mode.dat", "w") do io
    for i = 1:kpoints
        writedlm(io, [i])
        writedlm(io, [x A_vel_p[i,:]])
    end
end

open("vel_n_kp_mode.dat", "w") do io
    for i = 1:kpoints
        writedlm(io, [i])
        writedlm(io, [x A_vel_n[i,:]])
    end
end

"""
the temperature effect
"""


B_vel_p_T=zeros(Float64,T_len,kpoints) #T means temeperature
B_vel_n_T=zeros(Float64,T_len,kpoints)
C_vel_p_T=zeros(Float64,T_len) #T means temeperature
C_vel_n_T=zeros(Float64,T_len)

F_vel_p_T=zeros(Float64,T_len) #T means temeperature
F_vel_n_T=zeros(Float64,T_len)

eta_T=zeros(Float64,T_len)

for Ti =1:T_len
    for i=1:kpoints
        for j =1:mode
            if Ti==1
                A_vel_p_T[Ti,i,j]=A_vel_p[i,j]
                A_vel_n_T[Ti,i,j]=A_vel_n[i,j]
            else
                A_vel_p_T[Ti,i,j]=A_vel_p[i,j]*(1+2/(exp(frequency[i,j]/(0.000086173*temperature[Ti]))-1))
                A_vel_n_T[Ti,i,j]=A_vel_n[i,j]*(1+2/(exp(frequency[i,j]/(0.000086173*temperature[Ti]))-1))
            end
        end
        B_vel_p_T[Ti,i]=sum(A_vel_p_T[Ti,i,:])
        B_vel_n_T[Ti,i]=sum(A_vel_n_T[Ti,i,:])
        C_vel_p_T[Ti]=C_vel_p_T[Ti]+B_vel_p_T[Ti,i]*k_weight[i]
        C_vel_n_T[Ti]=C_vel_n_T[Ti]+B_vel_n_T[Ti,i]*k_weight[i]
    end
    C_vel_p_T[Ti]=C_vel_p_T[Ti]/sum(k_weight)
    C_vel_n_T[Ti]=C_vel_n_T[Ti]/sum(k_weight)
    F_vel_p_T[Ti]=C_vel_p_T[Ti]+vel_p_static[1]
    F_vel_n_T[Ti]=C_vel_n_T[Ti]+vel_n_static[1]
    eta_T[Ti]=(F_vel_p_T[Ti]^2-F_vel_n_T[Ti]^2)/((F_vel_p_T[Ti]^2+F_vel_n_T[Ti]^2))
end

open("vel_p_T.dat", "w") do io
    writedlm(io, [temperature C_vel_p_T])
end

open("vel_n_T.dat", "w") do io
    writedlm(io, [temperature C_vel_n_T])
end

open("eta_T.dat", "w") do io
    writedlm(io, [temperature eta_T])
end

open("p_T.dat", "w") do io
    writedlm(io, [temperature F_vel_p_T])
end

open("n_T.dat", "w") do io
    writedlm(io, [temperature F_vel_n_T])
end

open("p_T_kp.dat", "w") do io
    for Ti =1:T_len
    	for i = 1:kpoints
            writedlm(io, [temperature[Ti] k_ibz[i,1] k_ibz[i,2] B_vel_p_T[Ti,i]])
    	end
    end
end

