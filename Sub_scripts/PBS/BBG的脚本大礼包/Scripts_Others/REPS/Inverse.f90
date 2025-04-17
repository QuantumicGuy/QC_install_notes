Program Inverse
implicit none
real::x,y,z,a=0,b=0,c=0
integer,parameter::inputid=10,outputid=20
integer::stat
logical::alive
character(len=100)::name,inputfile,outputfile,string
  write(*,*)"Set the input file filename.xyz, input filename here"
  read(*,*)name
   inputfile=trim(name)//".xyz"

  inquire(file=inputfile, exist=alive)
    if(alive) then
      write(*,*)"enter center Cartesian coordinates x y z, eg. 1.2 2.0 3.4"
      read(*,*)a,b,c
      outputfile=trim(name)//"_inverse"//".xyz"
      open(unit=inputid,file=inputfile)
      open(unit=outputid,file=outputfile,status="replace")
        do while(.true.)
        read(inputid,'(A18,3F13.8)',iostat=stat)string,x,y,z
        if(stat/=0)exit
          x=2*a-x
          y=2*b-y
          z=2*c-z
        write(outputid,'(A18,3F13.8)')string,x,y,z
        enddo
    else
      write(*,*)trim(inputfile), " doesn't exist."
    end if     
  end
