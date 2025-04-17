#!perl
#xsd2pos.pl V 1.0, Author: Professor Yan Zhao at WHUT, yan2000@whut.edu.cn
#xsd2pos.pl V 1.1, 11/14/2018 a bug fix to the order of the elements.
#v2.0, 3/21/2019 freezing the individual x, y, z components of an atom is enabled. In order to do so, do not check "Fix fractional position". 
#This is perl script for converting the Materials Studio xsd file to the POSCAR file for VASP. 
#xsd2pos.pl can read the constraints information from the xsd file, and write the constraints to the POSCAR file.
#Usage: Change the $filename variable to your xsd file, and it will generate a POSCAR.txt file in the VASP input format. You may copy and paste the text in POSCAR.txt to your POSCAR file.

use strict;
use Getopt::Long;
use MaterialsScript qw(:all);

my $filename = "CO_on_Pd(110)_OPT_DOS-1";
my $doc = $Documents{"$filename.xsd"};
my $pos = Documents->New("POSCAR.txt");
my $lattice = $doc->SymmetryDefinition;
my $FT;
my @num_atom; 
my @element;
my $ele;
my $num;
my $testif;
my $FT1;
my $FT2;
my $FT3;

$pos->Append(sprintf "$filename \n");
$pos->Append(sprintf "1.0 \n");
$pos->Append(sprintf "%f %f %f \n",$lattice->VectorA->X, $lattice->VectorA->Y, $lattice->VectorA->Z);
$pos->Append(sprintf "%f %f %f \n",$lattice->VectorB->X, $lattice->VectorB->Y, $lattice->VectorB->Z);
$pos->Append(sprintf "%f %f %f \n",$lattice->VectorC->X, $lattice->VectorC->Y, $lattice->VectorC->Z);


my $atoms = $doc->UnitCell->Atoms;

my @sortedAt = sort {$a->AtomicNumber <=> $b->AtomicNumber} @$atoms;

my $count_el=0;
my $count_atom = 0;
   $element[0]=$sortedAt[0]->ElementSymbol;
my $atom_num = $sortedAt[0]->AtomicNumber;
foreach my $atom (@sortedAt) {
  if ($atom->AtomicNumber == $atom_num) {
    $count_atom=$count_atom+1;
  } else {
    $num_atom[$count_el] = $count_atom;
    $count_atom = 1;
    $count_el = $count_el+1;
    $element[$count_el]=$atom->ElementSymbol;
    $atom_num = $atom->AtomicNumber;
  }
}
$num_atom[$count_el] = $count_atom;

foreach $ele (@element) {
   $pos->Append(sprintf "$ele ");
}
$pos->Append(sprintf "\n");

foreach $num (@num_atom) {
   $pos->Append(sprintf "$num ");
}
$pos->Append(sprintf "\n");
$pos->Append(sprintf "Selective Dynamics\nDirect \n");

foreach my $atom (@sortedAt) {

 if ($atom->IsFixed("X")) {
    $FT1 = "F";
 } else {
    $FT1 = "T";
 }
 if ($atom->IsFixed("Y")) {
    $FT2 = "F";
 } else {
    $FT2 = "T";
 }
 if ($atom->IsFixed("Z")) {
    $FT3 = "F";
 } else {
    $FT3 = "T";
 } 

if ($atom->IsFixed("FractionalXYZ")) {
    $FT = "F F F";
 } else {
    $FT = "$FT1 $FT2 $FT3";
} 

$pos->Append(sprintf "%f %f %f %s \n", $atom->FractionalXYZ->X, $atom->FractionalXYZ->Y, $atom->FractionalXYZ->Z, $FT); 
# $pos->Append(sprintf "%s %d %f %f %f %s \n", $atom->ElementSymbol, $atom->AtomicNumber, $atom->FractionalXYZ->X, $atom->FractionalXYZ->Y, $atom->FractionalXYZ->Z, $FT);
}