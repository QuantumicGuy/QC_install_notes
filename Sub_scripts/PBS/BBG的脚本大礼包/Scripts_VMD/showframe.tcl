trace variable vmd_frame(2) w sdf
mol new
proc sdf {args} {global vmd_frame
graphics 0 delete all
graphics 0 color 16
set tmp [format %6.2f [expr ($vmd_frame(2)+1)*0.05]]
graphics 0 text {0 0 0} "${tmp}ps" size 2}
trace variable vmd_frame(2) w sdf_1
mol new
proc sdf_1 {args} {global vmd_frame
graphics 1 delete all
graphics 1 color 16
graphics 1 text {2 2 2} "332K/200ps" size 2
}