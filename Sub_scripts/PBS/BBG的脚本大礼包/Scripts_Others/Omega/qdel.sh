#!/bin/bash

echo "initial task number"
read ini
echo "final task number"
read fin
for((i=${ini};i<`expr ${fin} + 1`;i++))
  do 
    qdel ${i}
  done
