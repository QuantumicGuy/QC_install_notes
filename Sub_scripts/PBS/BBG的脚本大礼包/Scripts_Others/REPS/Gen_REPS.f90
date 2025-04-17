!this script generate multi-points rigid energy potential surface Gaussian input files along various axis.
!make sure everything is well-set in the first input file
Program Gen_REPS
implicit none
real::nsize,x,y,z
integer::nstep,i,j,k,nTarg,nAtom,n,outputid,length,stat,nLine
integer,parameter::inputid=10
character(len=100)::inputfile,outputfile,outputchk,string,name,axis,half
logical alive

write(*,*)"Set the input file filename.com, input filename here"
read(*,*)name
inputfile=trim(name)//".com"
inquire(file=inputfile, exist=alive)
 if(alive) then
write(*,*)"nstep:"
read(*,*)nstep
write(*,*)"nsize(au):"
read(*,*)nsize
write(*,*)"Total atoms of entire system:"
read(*,*)nAtom
write(*,*)"Total atoms of Target molecule:"
read(*,*)nTarg
n=nAtom-nTarg
write(*,*)"Target molecule is the first or second molecule (input first or second):"
read(*,*)half
write(*,*)"Leave the first line chk defination. Total number of lines above cartesian coordinates except the first line:"
read(*,*)nLine
write(*,*)"Directions(input x y or z)"
read(*,*)axis
write(unit=string,fmt='(i2)')nstep

   do j=1,nstep
    if(j>99) then
     write(unit=string,fmt='(I3)')j
    else if(j>9) then
     write(unit=string,fmt='(I2)')j
    else 
     write(unit=string,fmt='(I1)')j
    end if
    outputfile=trim(name)//"_"//trim(string)//".com"
    outputchk=trim(name)//"_"//trim(string)//".chk"
    outputid=100+j
    open(unit=inputid,file=inputfile)
    open(unit=outputid,file=outputfile,status="replace")
     read(inputid,'(A5)')string 
     write(outputid,"(A5,A40)")string,outputchk
      do i=1,nLine
       read(inputid,'(A)')string
       write(outputid,*)string
      enddo
      do k=1,nAtom
       read(inputid,'(A18,3F13.8)')string,x,y,z
       select case(half)
        case("second")
         if(k>n) then
          select case(axis)
          case("x")
           x=x+j*nsize 
          case("y")
           y=y+j*nsize
          case("z")
           z=z+j*nsize
          end select
         endif
        case("first")
         if(k<=nTarg) then
          select case(axis)
          case("x")
           x=x+j*nsize 
          case("y")
           y=y+j*nsize
          case("z")
           z=z+j*nsize
          end select
         endif
        end select
       write(outputid,'(A18,3F13.8)')string,x,y,z
      enddo
      do while(.true.)
       read(inputid,'(A)',iostat=stat)string
       if(stat/=0)exit
       write(outputid,*)string
      enddo
   close(inputid)
   close(outputid)
 enddo
 else
  write(*,*)trim(inputfile), " doesn't exist."
 end if     
end
