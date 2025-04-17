#!/bin/bash
grep "SCF Done" *_*_?.log >> Energy.out
grep "SCF Done" *_*_??.log >> Energy.out
  i=0
  energy=0
echo"monomer energy (au)"
read monomer
  cat Energy.out | while read a b c d energy
    do
     i='expr $i+1'
     energy='expr $energy-2*\$monomer'
     echo $i $energy > BE.out
   done
     

