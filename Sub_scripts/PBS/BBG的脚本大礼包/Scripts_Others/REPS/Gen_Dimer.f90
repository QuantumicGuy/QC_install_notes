Program Gen_Dimer
implicit none
real::x=0,y=0,z=0,dx,dy,dz
integer::ll,nn,mm
integer,parameter::inputid=10,outputid=20
logical::alive
character(len=100)::name,inputfile,outputfile
write(*,*)"Set the input file filename.xyz, input filename here"
read(*,*)name
inputfile=trim(name)//".xyz"
outputfile=trim(name)//"_dimer"//".xyz"
inquire(file=inputfile, exist=alive)
  if(alive) then
  write(*,*)"What to do? translate, enter 1; rotate, enter 2; inverse, enter 3; or either eg. 1 2"
  read(*,*)ll,nn,mm
    open(unit=inputid,file=inputfile)
    open(unit=outputid,file=outputfile,status="replace")
    select case(ll)
      case(1)
      write(*,*)"enter increment x y z, eg. 1.2 2.0 3.4"
      read(*,*)dx,dy,dz
      do while(.true.)
        read(inputid,'(A18,3F13.8)')string,x,y,z
          x=x+dx
          y=y+dy
          z=z+dz
        write(outputid,'(A18,3F13.8)')string,x,y,z
      if(stat/=0)exit
      enddo
         
  else
    write(*,*)trim(inputfile), " doesn't exist."
  end if  
