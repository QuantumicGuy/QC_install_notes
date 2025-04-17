Multiwfn 1.fchk -ESPrhoiso 0.001 < ESPiso.txt
move /Y density.cub density1.cub
move /Y totesp.cub ESP1.cub
Multiwfn 2.fchk -ESPrhoiso 0.001 < ESPiso.txt
move /Y density.cub density2.cub
move /Y totesp.cub ESP2.cub
Multiwfn 3.fchk -ESPrhoiso 0.001 < ESPiso.txt
move /Y density.cub density3.cub
move /Y totesp.cub ESP3.cub
Multiwfn 4.fchk -ESPrhoiso 0.001 < ESPiso.txt
move /Y density.cub density4.cub
move /Y totesp.cub ESP4.cub

move /Y *.cub "C:\soft\VMD"