Program translate
implicit none
real::x,y,z,dx=0,dy=0,dz=0
integer,parameter::inputid=10,outputid=20
integer::stat
logical::alive
character(len=100)::name,inputfile,outputfile,string
  write(*,*)"Set the input file filename.xyz, input filename here"
  read(*,*)name
   inputfile=trim(name)//".xyz"

  inquire(file=inputfile, exist=alive)
    if(alive) then
      write(*,*)"enter increment x y z, eg. 1.2 2.0 3.4"
      read(*,*)dx,dy,dz
      outputfile=trim(name)//"_Tran"//".xyz"
      open(unit=inputid,file=inputfile)
      open(unit=outputid,file=outputfile,status="replace")
        do while(.true.)
        read(inputid,'(A18,3F13.8)',iostat=stat)string,x,y,z
        if(stat/=0)exit
          x=x+dx
          y=y+dy
          z=z+dz
        write(outputid,'(A18,3F13.8)')string,x,y,z
        enddo
    else
      write(*,*)trim(inputfile), " doesn't exist."
    end if     
  end
