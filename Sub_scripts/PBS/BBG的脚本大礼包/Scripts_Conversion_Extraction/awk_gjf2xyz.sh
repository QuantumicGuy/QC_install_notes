#!/bin/bash

for gjf in `ls *.gjf`
do
    echo -e "Converting $gjf into ${gjf//gjf/xyz}"
    awk '
        BEGIN {Natoms = 0; fname = "'$gjf'"; sub(".gjf", "", fname)}

        NF == 4 && $1~/[A-Za-z]/ && $(NF-1)~/[0-9]/{
            Atom[Natoms] = $1; x[Natoms] = $2+0;
            y[Natoms] = $3+0; z[Natoms] = $4+0; Natoms++
        }

        END {
            print Natoms > fname".xyz"
            print fname >> fname".xyz"
            for(i = 0; i < Natoms; i++)
                printf("%s %12.8f %12.8f %12.8f\n",
                       Atom[i], x[i], y[i], z[i]) >> fname".xyz"
            close(fname".xyz")
        }
    ' ${gjf}
done

