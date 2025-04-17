Program Rotate
implicit none
real::x,y,z,alpha=0,degree
integer,parameter::inputid=10,outputid=20,pi=3.14159265359
integer::stat
logical::alive
character(len=100)::name,inputfile,outputfile,string,axis
  write(*,*)"Set the input file filename.xyz, input filename here"
  read(*,*)name
   inputfile=trim(name)//".xyz"

  inquire(file=inputfile, exist=alive)
    if(alive) then
      write(*,*)"which axis to rotate with, enter x, y or z:"
      read(*,*)axis
      write(*,*)"what degree:"
      read(*,*)degree
      alpha=degree*pi/180
      outputfile=trim(name)//"_rotate"//".xyz"
      open(unit=inputid,file=inputfile)
      open(unit=outputid,file=outputfile,status="replace")
        do while(.true.)
        read(inputid,'(A18,3F13.8)',iostat=stat)string,x,y,z
        if(stat/=0)exit
         select case(axis)
          case("x")
           x=x
           y=cos(alpha)*y-sin(alpha)*z
           z=sin(alpha)*y+cos(alpha)*z
          case("y")
           x=cos(alpha)*x+sin(alpha)*z
           y=y
           z=-sin(alpha)*x+cos(alpha)*z
          case("z")
           x=cos(alpha)*x-sin(alpha)*y
           y=sin(alpha)*x+cos(alpha)*y
           z=z
        end select
        write(outputid,'(A18,3F13.8)')string,x,y,z
        enddo
    else
      write(*,*)trim(inputfile), " doesn't exist."
    end if     
  end
