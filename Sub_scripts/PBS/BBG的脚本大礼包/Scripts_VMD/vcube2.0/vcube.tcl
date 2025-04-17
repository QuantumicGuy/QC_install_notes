if 0 {
    VCUBE Version 2.0
    update date: 2021-01-08
	Feature: High throughput cube render using vmd; High quality image; 
    made by Zhong Cheng; QQ:32589927, E-mail:ggdhzdx@qq.comment
	Feel free to contact me if you have any suggestions or find bugs  
}

package provide vcube 2.0
# todo list
# vlabel and vmeasure and label
# cube file with multicube
# vstyle to specific (local & global)
# set default style

puts "vcube loaded..."
puts "vcube version 2.0 developed by ZhongCheng@whu.edu.cn"
puts {type "vhelp" to get list of available functions and keyboard shortcuts}
puts {type "vhelp function" to get detailed usage of that function}

namespace eval ::vcube {

    namespace export vcube vmol vc vshowalways vgroup vreset vrender vrenders vrename vmscale vcscale viso vapply valpha vstyle vlabel vhelp vsc vtachyopt Vnav_mol Vnav_iso Vnav_alpha Vnav_cscale Vnav_mscale Vglobal_switch Vpreview 
    global env
    global style_dir
	global script_dir 
    global image_viewer
    global optix
    global ospray
    global nproc 
    set ::nproc 100
    set ::script_dir ""
    set ::image_viewer "eog gwenview" 
    # check if TachyonInternal is available
    if {[lsearch [render list] TachyonLOptiXInternal] >= 0} {
        puts "TachyonLOptiXInternal is available. Turn it on by input \"set optix 1\""
        set ::optix 0
    } else { set ::optix 0 }
    if {[lsearch [render list] TachyonLOSPRayInternal] >= 0} {
        puts "TachyonLOSPRayInternal is available. Turn it on by input \"set ospray 1\""
        set ::ospray 0
    } else { set ::ospray 0}
    variable global_adj 1
    variable show_switch 0 # "0 show top; 1 show group; 2 show all"
    variable tachyon_options ""
    variable tachyon_defaults "-format BMP -aasamples 24 -fullshade "
	variable tachyon_user ""
    variable current_style ""
    variable suface_type ""  # normal or map
    variable show_always ""  # molids that always display, set by vshowalways function by user
    variable separator "_"
    variable groupbyidx {end-1} # group by list elements generate by separator, -1 mean not last elements
    variable grouplist ""      # grouplist generate by vgroup using separator
    variable map_scale_value {-0.03 0.03} # default scale for map cube
	variable color_scale BWR   #default color scale for map cube
}

proc ::vcube::vhelp {args} {
    if {$args eq ""} {
        puts {vcube [map] cubefilename    : input cubefiles to render}
        puts {vmol filename               : load only molecules}
        puts {vc molid                    : display and free target molecule }
        puts {viso iso1 iso2 molids       : set iso value for molids}
        puts {valpha alpha_value molids   : set alpha(transparency) for molids}
        puts {vstyle stylename molids     : apply style to molids}
        puts {vmscale min max molids      : set min and max map scale to molids}
		puts {vcscale min max molids      : set color scale}
        puts {vrender suffix scale        : render all figures with scale and filename is appended by suffix}
        puts {vrenders filename scale     : render current scene with scale}
        puts {vgroup string               : set the file name separator or molids to group mol }
		puts {vapply scriptfile molid     : apply vmd script file to molids}
        puts {vshowalways molids          : set the target molid to show always}
        puts {vreset                      : reset all molecules}
		puts {vtachyopt                   : set additional tachyon options, overwrite settings in styles}
		puts {vlabel                      : set labels for molecules}
        puts {vrename str1 str2 molid     : substitude str1 by str2 for names of molid, regexp is supported }
        puts {vh function                 : list all function, or show usage of specifed function}
        puts {-----------------------------------------------------------------------------------}
        puts {keyboard shortcut: }
        puts {a d        : previous or next molecule}
        puts {w s        : previous or next molecule with same group unfreeze together}
        puts {q e        : decrease or increase iso}
        puts {Pgup Pgdn  : previous or next style}
        puts {v          : render current scene for preview}
        puts {g          : switch between display single/group/all molecules}
		puts {Ins Del    : previous or next color scale}
		puts {left up    : decrease or increase min value of mapped value}
		puts {down right : decrease or increase max value of mapped value}
        puts {f          : adjust iso or alpha with shortcut local or global}
        puts {-----------------------------------------------------------------------------------}
        puts {variables: }
        puts {nproc        :max number of threads used by tachyon, default is the number of cores minus 2}
        puts {image_viewer :set program to preview image in Linux, default is eog and gwenview }
        puts {optix        :If set to 1, will use TachyonLOptiXInternal to render image, default is 0 }
        puts {ospray       :If set to 1, will use TachyonLOSPRayInternal to render image, default is 0 }
    }
    if {$args eq "viso"} {
        puts {viso iso1 iso2 molids       : set iso value for molids}
        puts {viso                        : list iso value for all the molecules}
        puts {viso 0.02 -0.02             : set iso value for all the molecules}
        puts {viso r                      : reverse orbital phase}
        puts {viso 1000 1000              : remove surface}
        puts {viso 0.01 -0.01 1 2 3       : set iso value for all molecule 1 2 and 3} 
    }
    if {$args eq "vstyle"} {
        puts {vstyle stylename molids     : apply style to molids}
        puts {vstyle                      : list all the available style and show corresponding comments}
        puts {vstyle sob-art.stl          : apply sob-art.stl style to all molecules} 
        puts {vstyle sob-art.stl 1 2      : apply sob-art.stl style to molecules 1 2} 
        puts {vstyle sob-esp0.mstl        : apply sob-esp0.mstl mapped style to all molecules} 
    }
    if {$args eq "vcube"} {
        puts {vcube [map] cubefilename                   : input cubefiles to render}
        puts {vcube *.cube                               : render all cube file in current directory}
        puts {vcube a1_oH.cub a1_oL.cub a1_oH1.cub       : render three cube file }
        puts {vcube map 1_d.cub 1_e.cub 2_d.cub 2_e.cube : map a1_e.cub a2-e.cub to a1_d.cub and 2a_d.cube, respectively}
        puts {vcube map *.cub                            : same as above, because *e.cub fill will after *d.cub}
        puts {vcube *d.cub map *e.cub                    : same as above, cub in *e.cub will map to cub in *d.cub one by one}
    }
    if {$args eq "vmol"} {
        puts {vmol filename             : load files as molecules, available type: https://www.ks.uiuc.edu/Research/vmd/plugins/molfile/}
        puts {vcube *.pdb               : read all pdb file, the filetype will be determined by filename suffix}
        puts {vcube *.cub               : read all cube files, but the surface will not shown}
    }
    if {$args eq "vc"} {
        puts {vc molid                    : unfreeze and make top target molecule}
        puts {vc                          : unfreeze all the mol and make the last one top}
        puts {vc 0                        : unfreeze mol id 0 and make it top }
        puts {vc 0 1 2                    : unfreeze mol id 0 1 2 and make 2 top }
        puts {The unfreeze molecules are not necessarily displayed,}
        puts {the keyboard shortcut g controls how molecules are displayed }
    }
    if {$args eq "vgroup"} {
        puts {vgroup string       : set the file name separator to group files, if string is one elem }
        puts {vgroup              : view current separator and file groups}
        puts {vgroup _            : file a1_oH.cub and a1_oL.cub will be in the same group} 
        puts {vgroup _e           : file a1_e1.cub and a1_o1.cub will be in the different group}
        puts {vgroup {- 2}        : sep by - and use 0 to 2 elements to group: a-1-e-1.cub and a-1-o-1.cub in different group}
        puts {vgroup {- -1}       : sep by - and use elements other than 0 to 1 to group: a-1-e-1.cub and a-2-e-1.cub in same group}
       	puts {vgroup by 1,2 4,5   : molid 1,2 in one group 4,5 in another group }
    }
    if {$args eq "vmscale"} {
        puts {vmscale min max molids      : set min and max map scale to molids}
        puts {vmscale                     : view current map scale}
        puts {vmscale -0.02 0.02          : set map scale to -0.02 0.02 for all}
        puts {vmscale -0.02 0.02 top      : set map scale to -0.02 0.02 for the top molecule}
        puts {vmscale -0.02 0.02 1 2      : set map scale to -0.02 0.02 for molid 1 2}
    }
	
	if {$args eq "vcscale"} {
        puts {vcscale color_scale_name    : set color scale for all molids}
        puts {vcscale                     : view current color scale and available color scale}
        puts {vcscale BWR                 : set color scale to BWR for all}
    }
    
    if {$args eq "valpha"} {
        puts {valpha alpha_value molids   : set alpha(transparency) for molids}
        puts {valpha                      : view current alpha value}
        puts {valpha 0.6                  : set alpha to 0.6 for all molecule}
        puts {valpha 0.5 0 1 2            : set alpha to 0.5 for molid 0 1 2}
    }
    if {$args eq "vreset"} {
        puts {vreset        : reset all to the initial conditions }
        puts {The show_always will be cleaned}
    }
	if {$args eq "vrender"} {
        puts {vrender suffix scale molids : render molids with scale_factor and out figure name is appended by suffix}
        puts {vrender                     : render all with 3 fold scale }
        puts {vrender "" 4                : render all with 4 fold scale }
		puts {vrender "_topview" 2        : render all with 2 fold scale and the output filename is appendewd by "_topview"}
    }
	if {$args eq "vrenders"} {
        puts {vrenders name scale_factor   : reset all to the initial conditions }
        puts {vrenders                     : render current scene to "current.bmp" with 3 fold scale}
        puts {vrenders " "  4              : render current scene to "current.bmp" with 4 fold scale}
		puts {vrenders "c01" 2             : render current scene to "c01" with 2 fold scale}
    }
	if {$args eq "vrename"} {
        puts {vrename str1 str2 molids     : replace str1 by str2 for names fo molids, str1 could be regexp }
        puts {vrename oH HOMO              : replace oH by HOMO for all molecule names}
        puts {vrename {^} view1_  1 2 3    : add prefix view1_ to molecule 1 2 3}
        puts {vrename {\d} ""              : remove first encountered digits of all mol name}
        puts {vrename {\d+} ""             : remove first encountered consecutive digits of all mol name}
        puts {vrename {\..*} ""            : remove file name suffix (e.g. cub) of all mol name}
        puts {vrename {.cub} _side.cub     : append suffix _side to all mol name}
    }
	if {$args eq "vapply"} {
        puts {vapply script_file molids   : apply user writen script file to molids }
        puts {vapply script_file          : apply script file to all molids}
		puts {vapply script_file 2 3 4    : apply script_file to molid 2 3 4}
    }
    if {$args eq "vshowalways"} {
        puts {vshowalways molids          : set the target molid to show always}
        puts {vshowalways                 : cancel showalways molecule}
        puts {vshowalways 1 2             : set molid 1 2 to show always and unset other molid}
    }
	if {$args eq "vtachyopt"} {
        puts {vtachyopt                   : show the current used tachyon option and other available options }
        puts {vtachyopt " "               : use default tachyon options}
		puts {vtachyopt "-trans_orig"     : use this tachyon options that suitable for small alpha surface}
    }
}


proc ::vcube::vreset {args} {
    # reset view of target molids
    variable show_always
    variable show_switch
    set show_always ""
    set show_switch 0
    if {$args eq ""} {set args [molinfo list]}
    foreach i $args {
        mol free $i
        mol on $i
    }
    display resetview
}

proc ::vcube::vcube {args} {
    # args are list of cube files
    # to render mapped cube, the format of args could be 
    # map dens1 map1 dens2 map2... or
    # dens1 dens2... map map1 map2...
    variable surface_type
     if {[lsearch $args map] == -1} {
        set surface_type norm
        set basecubes [glob {*}$args]
        set mapcubes ""
        }
    if {[lsearch $args map] == 0} {
        set surface_type map
        set basecubes ""
        set mapcubes ""
        puts [glob {*}$args]
        foreach {a b} [glob {*}$args] {
            lappend basecubes $a
            lappend mapcubes $b
        }
    }
    if {[lsearch $args map] > 0} {
        set surface_type map
        set x [lsearch $args map]
        set basecubes [glob {*}[lrange $args 0 [expr $x -1]]]
        set mapcubes [glob {*}[lrange $args [expr $x + 1] end]]
    }
    if {[llength $mapcubes] == 0} {
        foreach i $basecubes {
            mol new $i type cube
            mol addrep top
            mol modstyle 1 top Isosurface [Vautoiso $i ] 0 0 0 1 1
            mol addrep top
            mol modstyle 2 top Isosurface [Vautoiso $i m] 0 0 0 1 1
        }
        vstyle sob-art.stl
    } elseif {[llength $mapcubes] == [llength $basecubes]} {
        foreach i $basecubes j $mapcubes {
            mol new $i type cube
            mol addfile $j type cube
            mol addrep top
            mol modstyle 1 top Isosurface [Vautoiso $i] 0 0 0 1 1
            mol modcolor 1 top Volume 1
        }
		Vautomap $j
        vstyle sob-esp1.mstl
    } else {
        puts "Error! Number of base cubes do not equal number of map cubes"
    }
    vgroup
}

proc ::vcube::vmol {args} {
    # args are list of cube files
    variable surface_type
    set surface_type norm
    set files [glob {*}$args]
    foreach i $files {
        mol new $i 
    }
    vstyle sob-art.stl
    vgroup
}

proc ::vcube::vrename {str1 str2 args} {
    #rename molecule name by subsitude str1 with str2 for molids in args
    set mol_id $args
    if {$mol_id eq ""} {
        set mol_id [molinfo list]
    } 
    foreach i $mol_id {
        set cname [molinfo $i get name] 
        regsub -expanded $str1 $cname $str2 newname
        puts "${cname} -> ${newname}"
        mol rename $i $newname
    }
}
#guess isovalue based on cubefile name
proc ::vcube::Vautoiso {cubename {sign p}} {
    variable separator
    array set defisop {esd 0.001 orb 0.025 den 0.001 elf 0.01 lol 0.01 rdg 0.5 ele 0.001 ole -0.001}
    array set defisom {esd -0.001 orb -0.025 den -0.001 elf -0.01 lol -0.01 rdg 0.5 ele -0.001 ole 0.001}
    set basename [file rootname $cubename]
    set cubetype [lindex [split $basename $separator] end]
    set cubetype [string range $cubetype end-2 end]
    puts $cubetype
    if {[string match {o[HL]*} $cubetype] > 0 } {
        set cubetype orb
    }
    if {![info exists defisop($cubetype)]} {
        if {$sign == "p"} { 
            return 0.01
        } elseif {$sign == "m"} {
            return -0.01
        }
    }
    if {$sign == "p"} {
        return $defisop($cubetype) 
    } elseif {$sign == "m"} {
        return $defisom($cubetype)
    }
}

proc ::vcube::Vautomap {cubename} {
    variable separator
	variable map_scale_value
	variable color_scale
    array set defcscale {esp BWR lmd RGB}
    array set defmscale {esp {-0.03 0.03} lmd {-0.04 0.02}} 
    set basename [file rootname $cubename]
    set cubetype [lindex [split $basename $separator] end]
    set cubetype [string range $cubetype end-2 end]
    if {![info exists defcscale($cubetype)]} {
        set color_scale BWR
    } else {
	    set color_scale $defcscale($cubetype)
	}
	if {![info exists defmscale($cubetype)]} {
        set map_scale_value {-0.03 0.03}
    } else {
	    set map_scale_value $defmscale($cubetype)
    }
}

proc ::vcube::vtachyopt {{option_name ""}} {
	variable tachyon_user
	variable tachyon_options
	if {$option_name == ""} {
		puts "Current tachyon options is $tachyon_options"
		puts "available tachyon options are (** for default):"
		puts "-trans_raster3d / -trans_vmd / -trans_orig**"
		puts "-shadow_filter_on** / -shadow_filter_off"
	} else {
		set tachyon_options $option_name
		set tachyon_user $option_name
	}
}

proc ::vcube::vstyle {{style_name ""} args} {
    # if no args, this function list all the available stylefiles
    # else the first argument is style name and the left args are molids
    # If no molid is specified the style will apply to all mol
    global style_dir
    variable current_style
    variable surface_type
	variable tachyon_user
	variable tachyon_options
    set full_name ""
    if {$surface_type == "map"} {
        set ext .mstl
    } elseif {$surface_type == "norm"} {
        set ext .stl
    }
    # check if style_name is specified
    if {$style_name eq ""} {
        # if not specified list all style name and comment
        set avail_style [glob [file join ${style_dir} *$ext]]
        foreach i $avail_style {
            set basename [file rootname [file tail $i]]
            set fp [open $i]
            set lines [split [read $fp] "\n"]
            set comment [string trim [lindex $lines 0] " #"]
            puts [format "%-20s:%s" $basename $comment]
        }
    } else {
        # if specified, check if file exist 
        if {[file exists [file join ${style_dir} $style_name]] == 1} {
            set full_name $style_name
        } elseif {[file exists [file join ${style_dir} $style_name$ext]] == 1} {
            set full_name $style_name$ext
        } else {
            puts "$style_name not found in ${style_dir}"
        }
    }
    if {$full_name != ""} {
        set current_style $full_name
        source [file join ${style_dir} $current_style]
        set mol_id $args
        if {$mol_id eq ""} {
            set mol_id [molinfo list]
            puts "set style to $current_style"
        } else {
            foreach i $mol_id {
                puts "$i set style to $current_style"
            }
        }
        foreach i $mol_id {
            mol top $i
            Vapply_style vcube$i
			if {$tachyon_user != ""} {
				sets tachyon_options $tachyon_user
			}
		}
    }
}

proc ::vcube::vapply {{script_file ""} args} {
    # if no args, this function check all the available script file in script_dir
    # and in current folder that end with .vmd or .tcl
    # else the first argument is style name and the left args are molids
    # If no molid is specified the style will apply to all mol
    global script_dir
    global style_dir
	set full_name ""
    if {$script_dir eq ""} {
        set script_dir $style_dir
    }
    if {$script_file eq ""} {
        # if not specified list all script file name
        set current_script [glob -nocomplain *.vmd *.tcl]
        puts $current_script
        set avail_script [glob -nocomplain [file join ${script_dir} *.vmd] [file join ${script_dir} *.tcl]]
        puts $avail_script
        set avail_script [list {*}$current_script {*}$avail_script]
        puts $avail_script
    } else {
        # if specified, check if file exist 
        if {[file exists [file join ${script_dir} $script_file]] == 1} {
            set full_name [file join ${script_dir} $script_file]
        } elseif {[file exists $script_file] == 1} {
            set full_name $script_file
        } else {
            puts "$script_file not found in ${script_dir} or current folder"
        }
    }
    if {$full_name != ""} {
        set mol_id $args
        if {$mol_id eq ""} {
            set mol_id [molinfo list]
            puts "apply $full_name to all molid"
        } else {
            foreach i $mol_id {
                puts "$full_name to $i"
            }
        }
        foreach i $mol_id {
            mol top $i
            source $full_name
        }
    }
}
proc ::vcube::Vnav_style {direction} {
    # direction argument accept n or p for next or previous
    variable surface_type
    variable current_style
    global style_dir
    if {![info exists surface_type]} {
        set mol_info [list {*}[mol list top]]
        set repidx [expr [lsearch $mol_info Atom] + 2]
        set repnum [lindex $mol_info $repidx]
        puts "$repnum"
        if {$repnum == 1} {set surface_type norm}
        if {$repnum == 2} {set surface_type map}
        if {$repnum == 3} {set surface_type norm}
        puts "set surface_type to $surface_type base on number of reps"
    }
    if {$surface_type == "map"} {
        set avail_style [glob [file join ${style_dir} *.mstl]]
    } elseif {$surface_type == "norm"} {
        set avail_style [glob [file join ${style_dir} *.stl]]
    }
    set all_style ""
    foreach as $avail_style {
        lappend all_style [file tail $as]
    }
    set cidx [lsearch $all_style $current_style] 
    set nidx [expr {$cidx + 1}]
    set pidx [expr {$cidx - 1}]
    if {$nidx >= [llength $all_style]} {set nidx 0}
    if {$pidx < 0} {set pidx [expr [llength $all_style] - 1]}
    puts "available styles: $all_style"
    set nstyle [lindex $all_style $nidx]
    set pstyle [lindex $all_style $pidx]
    if {$direction eq "n"} {
        vstyle $nstyle
    } elseif {$direction eq "p"} {
        vstyle $pstyle
    }
}

proc ::vcube::vmscale {{v1 ""} {v2 ""} args} {
    variable map_scale_value
    if {$v1 eq ""} {
        puts "map scale value is $map_scale_value"
    } else {
        # set mapped scale
        if {$args eq ""} {set args [molinfo list]}
        foreach i $args {
            mol scaleminmax $i 1 $v1 $v2
        }
        set map_scale_value "$v1 $v2"
        puts "Min Max mapped value is $v1 $v2"
    }
}

proc ::vcube::Vnav_mscale {direction} {
    variable map_scale_value
    set lsv [lindex $map_scale_value 0]
	set usv [lindex $map_scale_value 1]
	set ldsv [expr abs([Vcalc_delta $lsv])]
	set udsv [expr abs([Vcalc_delta $usv])]
	
    if {$direction eq "l"} {
		set lsv [expr $lsv - $ldsv ]
    } elseif {$direction eq "u"} {
		set lsv [expr $lsv + $ldsv ]
    } elseif {$direction eq "r"} {
		set usv [expr $usv + $udsv ]
    } elseif {$direction eq "d"} {
		set usv [expr $usv - $udsv ]
    }
	set usv [string trimright [format %.8f $usv] 0]
	set lsv [string trimright [format %.8f $lsv] 0]
	vmscale $lsv $usv
}

proc ::vcube::vcscale {{cs ""} args} {
    variable color_scale
    if {$cs eq ""} {
        puts "mapped color scalar is $color_scale"
		puts "available color scales are:"
		puts "RWB BWR RGryB BGryR RGB BGR RWG GWR GWB BWG BlkW WBlK"
    } else {
        # set mapped scale
		set color_scale $cs
		color scale method $color_scale
        puts "color scale is $color_scale"
    }
}

proc ::vcube::Vnav_cscale {direction} {
    variable color_scale
    set cslist "RWB BWR RGryB BGryR RGB BGR RWG GWR GWB BWG BlkW WBlK"
    set cidx [lsearch $cslist $color_scale]
    set nidx [expr {$cidx + 1}]
    set pidx [expr {$cidx - 1}]
    if {$nidx >= [llength $cslist]} {set nidx 0}
    if {$pidx < 0} {set pidx [expr [llength $cslist] - 1]}
    set nc [lindex $cslist $nidx]
    set pc [lindex $cslist $pidx]
    if {$direction eq "n"} {
		vcscale $nc
    } elseif {$direction eq "p"} {
		vcscale $pc
    }
}

proc ::vcube::vc {args} {
    # display and free the target molecule 
    mol fix all
    if {$args eq ""} {set args [molinfo list]}
    foreach i $args {
        mol free $i
        mol top $i
    }
    Vshow_mol
}
# call vc to navigate through mol ecules
# with N for next and P for previous
# lower case n and p means free all the molecules of same group 
# which is defined by file name with part after last _ discarded
proc ::vcube::Vnav_mol {direction} {
    variable grouplist
    set idlist [molinfo list]
    set id [molinfo top]
    set cidx [lsearch $idlist $id]
    set nidx [expr {$cidx + 1}]
    set pidx [expr {$cidx - 1}]
    if {$nidx >= [llength $idlist]} {set nidx 0}
    if {$pidx < 0} {set pidx [expr [llength $idlist] - 1]}
    set nid [lindex $idlist $nidx]
    set pid [lindex $idlist $pidx]
    if {$direction eq "n"} {
        vc $nid 
        Vfree_mol [lindex $grouplist $nidx]
    } elseif {$direction eq "p"} {
        vc $pid
        Vfree_mol [lindex $grouplist $pidx]
    }
    if {$direction eq "N"} {
        vc $nid 
    } elseif {$direction eq "P"} {
        vc $pid
    }
}

proc ::vcube::Vfree_mol {idxlist} {
    foreach i $idxlist {mol free $i} 
}


# grouplist is a 2D list, the elements are group of molid, not index
proc ::vcube::vgroup {{sep ""} args} {
    variable separator
    variable groupbyidx
    variable grouplist ""
    set filelist ""
    set headerlist ""
    if {[llength $sep] > 1} {
        set separator [lindex $sep 0]
        set groupbyidx [lreplace $sep 0 0]
    } elseif {[llength $sep] == 1} {
        set separator $sep
        set groupbyidx {end-1}
    }
    if {$separator == "by"} {
        puts "group by user defined group"
        set idlist [molinfo list]
        foreach i $idlist {
            set found 0
            foreach g $args {
                set glist [split $g ","]
                if {[lsearch $glist $i] >=0} {
                    lappend grouplist $glist
                    set found 1
                    break
                }
            }
            if {$found == 0} {
                lappend grouplist [list $i]
            }
        }
        puts $grouplist
    } else {
        puts "separator is $separator, identify group by idx $groupbyidx"
        set idlist [molinfo list]
        foreach i $idlist {
            lappend filelist [molinfo $i get name]
        }
        foreach i $filelist {
            if {[string match "-*" $groupbyidx]} { 
                set gb [string trim $groupbyidx "-"] 
                set e [lrange [split $i $separator] 0 $gb]
                set s [lreplace [split $i $separator] 0 $gb]
            } else {
                set s [lrange [split $i $separator] 0 $groupbyidx]
                set e [lreplace [split $i $separator] 0 $groupbyidx]
            }
            set file_header [join $s $separator]
            set file_tailer [join $e $separator]
            lappend headerlist $file_header
            dict lappend groupdict $file_header  $file_tailer
        }
        foreach i $headerlist {
            set group [lsearch -all $headerlist $i]
            set idgroup ""
            foreach g $group {
                lappend idgroup [lindex $idlist $g]
            }
            lappend grouplist $idgroup
            dict lappend groupdict $i $idgroup
        }
        dict for {headname tailname} $groupdict {
            set tmp ""
            foreach e $tailname {dict set tmp $e 1}
            set unique_tail [dict keys $tmp]
            puts [format "%-20s%s" $headname $unique_tail]
        }
    }
}

proc ::vcube::viso {{isoplus ""} {isominus ""} args} {
    # set iso for one or more molecules 
    # if no input, then print list of current isovalues
    variable surface_type 
    if {$isoplus eq ""} {
        foreach i [molinfo list] {
            set isop ""
            set isom ""
            set isop [lindex [molinfo $i get {{rep 1}}] 0 1]
            if {$surface_type != "map"} {
                set isom [lindex [molinfo $i get {{rep 2}}] 0 1]
            }
            if {[molinfo top] eq $i} {
                puts "isovalue of $i is $isop $isom TOP"
            } else {
                puts "isovalue of $i is $isop $isom"
            }

        }
    } elseif {$isoplus eq "r"} {
	    if {$args eq ""} {set args [molinfo list]}
		foreach i $args {
            set isop ""
            set isom ""
            set isop [lindex [molinfo $i get {{rep 1}}] 0 1]
			set isop [expr $isop * -1]
            if {$surface_type != "map"} {
                set isom [lindex [molinfo $i get {{rep 2}}] 0 1]
				set isom [expr $isom * -1]
            }
	        mol modstyle 1 $i Isosurface $isop 0 0 0 1 1
            mol modstyle 2 $i Isosurface $isom 0 0 0 1 1	
		}
	} else {
        if {$args eq ""} {set args [molinfo list]}
        foreach i $args {
            mol modstyle 1 $i Isosurface $isoplus 0 0 0 1 1
            mol modstyle 2 $i Isosurface $isominus 0 0 0 1 1
        }
    }
}


#increase or decrease iso value
proc ::vcube::Vnav_iso {direction} {
    variable global_adj
    if {$global_adj == 0} {
        Vadj_iso top $direction
    } elseif {$global_adj == 1} {
        foreach i [molinfo list] {
            Vadj_iso $i $direction
        }
    }
}
proc ::vcube::Vadj_iso {molid direction} {
    variable surface_type
    set isop [lindex [molinfo $molid get {{rep 1}}] 0 1]
    set isodp [Vcalc_delta $isop]
    set isopp [string trimright [format %.10f [expr $isop + $isodp]] 0]
    set isopm [string trimright [format %.10f [expr $isop - $isodp]] 0]
    if {$surface_type != "map"} {
        set isom [lindex [molinfo $molid get {{rep 2}}] 0 1]
        set isodm [Vcalc_delta $isom]
        set isomp [string trimright [format %.10f [expr $isom + $isodm]] 0]
        set isomm [string trimright [format %.10f [expr $isom - $isodm]] 0]
    } else {
        set isomm 0
        set isomp 0
    }
    if {$direction eq "n"} {
        viso $isopp $isomp $molid
        puts "isovalue is $isopp $isomp for $molid"
    } elseif {$direction eq "p"} {
        viso $isopm $isomm $molid
        puts "isovalue is $isopm $isomm for $molid"
    }
}
proc ::vcube::Vcalc_delta {isov {delta 1}} {
    set isov01 [expr $isov / 10]
    set isov01 [string trimright [format %.10f $isov01] 0]
    if {abs($isov01) < 1} {
        set iso0 [string trimright $isov01 123456789]
        set isod ${iso0}$delta
    } elseif {abs($isov01) >= 1} {
        set isod [expr $dalta*10**floor(log10($isov01))]
    }
	set isod [string trimright [format %.8f $isod] 0]
    return $isod
}
# used to switch variable global_adj
# which is to specify whether the adjustment is local or global
proc ::vcube::Vglobal_switch {} {
    variable global_adj
    if {$global_adj == 0} {
        set global_adj 1
        puts "adjust global"
    } elseif {$global_adj == 1} {
        set global_adj 0
        puts "adjust local"
    }
}

proc ::vcube::Vshow_switch {} {
    variable show_switch
    if {$show_switch == 0} {
        set show_switch 1
        puts "show group"
        Vshow_mol
    } elseif {$show_switch == 1} {
        set show_switch 2
        puts "show all"
        Vshow_mol
    } elseif {$show_switch == 2} {
        set show_switch 0
        puts "show top"
        Vshow_mol
    }
}

#show specific molecule based on show_switch
proc ::vcube::Vshow_mol {} {
    variable show_switch
    variable show_always
    variable grouplist
    mol off all
    if {$show_switch == 0} {
        mol on top
    } elseif {$show_switch == 2} {
        mol on all
    } elseif {$show_switch == 1} {
        set idlist [molinfo list]
        set id [molinfo top]
        set cidx [lsearch $idlist $id]
        set cgroup [lindex $grouplist $cidx]
        foreach i $cgroup {
            mol on $i
        }
    }
    foreach i $show_always {
        mol on $i
    }
}

proc ::vcube::vshowalways {args} {
    variable show_always
    if {$args eq ""} {
        set show_always ""
    } else {
        set show_always $args
    }
    puts "always show $args"
    Vshow_mol
}

proc ::vcube::valpha {{alpha_value ""} args} {
    set molid [molinfo top]
    if {$alpha_value eq ""} {
        set calpha [lindex [material settings vcube${molid}a] 5]
        puts "current alpha value is $calpha"
    } else {
        set alpha_value [string trimright [format %.4f [expr $alpha_value]] 0]
        if {$args eq ""} {set args [molinfo list]}
        foreach i $args {
            material change opacity vcube${i}a $alpha_value
            if {[lsearch [material list] vcube${i}b] > 0} {
                material change opacity vcube${i}b $alpha_value
            }
            puts "alpha is $alpha_value for $i"
        }
    }
}

proc ::vcube::Vnav_alpha {direction} {
    variable global_adj
    if {$global_adj == 0} {
        set mol_id [molinfo top]
        Vadj_alpha $mol_id $direction
    } elseif {$global_adj == 1} {
        foreach i [molinfo list] {
            Vadj_alpha $i $direction
        }
    }
}
proc ::vcube::Vadj_alpha {mol_id direction} {
    set calpha [lindex [material settings vcube${mol_id}a] 5]
    if {$direction eq "n"} {
        set calpha [expr $calpha + 0.05]
        if {$calpha > 1} {set calpha 1}
        valpha $calpha $mol_id
    } elseif {$direction eq "p"} {
        set calpha [expr $calpha - 0.05]
        if {$calpha < 0} {set calpha 0}
        valpha $calpha $mol_id
    }    
}

proc ::vcube::vrenders {{filename "current"} {scale 3}} {
    global env
    global tcl_platform
    global optix
    global ospray
    variable tachyon_defaults
    variable tachyon_options
    file mkdir VCUBE
    set wkdir [file join [pwd] "VCUBE"]
    # set idlist [molinfo list]
    lassign [display get size] w h
    set res "[expr $w * $scale] [expr $h * $scale]"
    if {[string trim $filename] == ""} {
        set filename "current"
    }
    if {$optix} {
        render aasamples TachyonLOptiXInternal 24
        render aosamples TachyonLOptiXInternal 24
        set outfile  [file join $wkdir ${filename}.ppm]
        puts $res
        display resize {*}$res
        render TachyonLOptiXInternal $outfile
        return
    }
    if {$ospray} {
        render aasamples TachyonLOSPRayInternal 24
        render aosamples TachyonLOSPRayInternal 24
        set outfile  [file join $wkdir ${filename}.ppm]
        puts $res
        display resize {*}$res
        render TachyonLOSPRayInternal $outfile
        return
    }
    set tachyon_cmd [lindex [regsub \" [regsub \" [render options Tachyon] \{] \}] 0]
    set full_options "$tachyon_defaults -res $res -numthreads [Vnthread] $tachyon_options"
    puts "tachyon options: $full_options"
    set batchfile [open [file join $wkdir renderall.bat] w]
    set scriptname ${filename}.dat
    puts $scriptname
    set outfile  ${filename}.bmp
    render Tachyon [file join "VCUBE" $scriptname]
    puts $batchfile "\"$tachyon_cmd\" \"$scriptname\" $full_options -o \"$outfile\""
    close $batchfile
	#generate linux batch render file
	set full_options "$tachyon_defaults -res $res $tachyon_options"
	set shfile [open [file join $wkdir renderall.sh] w]
	fconfigure $shfile -translation lf
	puts $shfile "if \[ -n \"\$1\" \];then NC=\"-numthreads \$1\";fi"
	puts $shfile "tachyon_cmd=\$(which vmd | sed 's/bin\\/vmd/lib\\/vmd\\/tachyon_LINUXAMD64/')"
    set scriptname ${filename}.dat
    puts $scriptname
    set outfile  ${filename}.bmp
    puts $shfile "\"\$tachyon_cmd\" \"$scriptname\" $full_options \$NC -o \"$outfile\""
	close $shfile
	puts "nproc:[Vnthread], resolution:$res, filename:${filename}.bmp Render Now?(Y/n)"
    set runcmd_win [file join $wkdir renderall.bat]
    set runcmd_linux [file join $wkdir renderall.sh]
	gets stdin render_flag
	if {[string match -nocase "n*" $render_flag]} {
        if {$tcl_platform(platform) eq "windows"} {
            puts "you need to run $runcmd_win manually to render images"
            exec {*}[auto_execok start] "" $wkdir
        }
        if {$tcl_platform(platform) eq "unix"} {
            puts "you need to run $runcmd_linux manually to render images"
        }
	} else {
        if {$tcl_platform(platform) eq "windows"} {
            puts "run $runcmd_win now..."
			cd VCUBE
            exec {*}[auto_execok start] "" $runcmd_win
			cd ..
        }
        if {$tcl_platform(platform) eq "unix"} {
            puts "run $runcmd_linux now..."
			cd VCUBE
            exec {*}[auto_execok bash] $runcmd_linux >@stdout
			cd ..
        }
	}
} 
proc ::vcube::vrender {{suffix ""} {scale 3} args} {
    global env
    global tcl_platform
    global optix
    global ospray
    variable tachyon_defaults
    variable tachyon_options
    variable show_switch
    variable grouplist
    file mkdir VCUBE
    set wkdir [file join [pwd] "VCUBE"]
    set idlist [molinfo list]
    lassign [display get size] w h
    set res "[expr $w * $scale] [expr $h * $scale]"
    set suffix [string trim $suffix]
    if {$args eq ""} {
        if {$show_switch == 0} {
            set args [molinfo list]
        } elseif {$show_switch == 1} {
            set group1st ""
            foreach g $grouplist {lappend group1st [lindex $g 0]}
            set args [lsort -unique $group1st]
        } elseif {$show_switch == 2} {
            set id [molinfo top]
            set args [list $id]
        }
    }
    if {$optix} {
        render aasamples TachyonLOptiXInternal 24
        render aosamples TachyonLOptiXInternal 24
        foreach i $args {
            vc $i
            set originfile [string trim [molinfo $i get name] \}\{  ]
            if {[llength $originfile] == 1} {
                set basename [file rootname $originfile]
            } else {
                set basename [file rootname [lindex $originfile end]]
            }
            set outfile  [file join $wkdir ${basename}${suffix}.ppm]
            puts $res
            display resize {*}$res
            render TachyonLOptiXInternal $outfile
        }
        return
    }
    if {$ospray} {
        render aasamples TachyonLOSPRayInternal 24
        render aosamples TachyonLOSPRayInternal 24
        foreach i $args {
            vc $i
            set originfile [string trim [molinfo $i get name] \}\{  ]
            if {[llength $originfile] == 1} {
                set basename [file rootname $originfile]
            } else {
                set basename [file rootname [lindex $originfile end]]
            }
            set outfile  [file join $wkdir ${basename}${suffix}.ppm]
            puts $res
            display resize {*}$res
            render TachyonLOSPRayInternal $outfile
        }
        return
    }
    set tachyon_cmd [lindex [regsub \" [regsub \" [render options Tachyon] \{] \}] 0]
    #generate windows batch render file
    set full_options "$tachyon_defaults -res $res -numthreads [Vnthread] $tachyon_options"
    puts "tachyon options: $full_options"
    set batchfile [open [file join $wkdir renderall.bat] w]
    foreach i $args {
        vc $i
        set originfile [string trim [molinfo $i get name] \}\{  ]
        if {[llength $originfile] == 1} {
            set basename [file rootname $originfile]
        } else {
            set basename [file rootname [lindex $originfile end]]
        }
        set filename ${basename}${suffix}.dat
        puts $filename
        set outfile  ${basename}${suffix}.bmp
        render Tachyon [file join "VCUBE" $filename]
        puts $batchfile "\"$tachyon_cmd\" \"$filename\" $full_options -o \"$outfile\""
    }
    close $batchfile
	#generate linux batch render file
	set full_options "$tachyon_defaults -res $res $tachyon_options"
	set shfile [open [file join $wkdir renderall.sh] w]
	fconfigure $shfile -translation lf
	puts $shfile "if \[ -n \"\$1\" \];then NC=\"-numthreads \$1\";fi"
	puts $shfile "tachyon_cmd=\$(which vmd | sed 's/bin\\/vmd/lib\\/vmd\\/tachyon_LINUXAMD64/')"
	foreach i $args {
        vc $i
        set originfile [string trim [molinfo $i get name] \}\{  ]
        if {[llength $originfile] == 1} {
            set basename [file rootname $originfile]
        } else {
            set basename [file rootname [lindex $originfile end]]
        }
        set filename ${basename}${suffix}.dat
        set outfile ${basename}${suffix}.bmp
        puts $shfile "\"\$tachyon_cmd\" \"$filename\" $full_options \$NC -o \"$outfile\""
    }
	close $shfile
	puts "nproc:[Vnthread], resolution:$res. Render Now?(Y/n)"
    set runcmd_win [file join $wkdir renderall.bat]
    set runcmd_linux [file join $wkdir renderall.sh]
	gets stdin render_flag
	if {[string match -nocase "n*" $render_flag]} {
        if {$tcl_platform(platform) eq "windows"} {
            puts "you need to run $runcmd_win manually to render images"
            exec {*}[auto_execok start] "" $wkdir
        }
        if {$tcl_platform(platform) eq "unix"} {
            puts "you need to run $runcmd_linux manually to render images"
        }
	} else {
        if {$tcl_platform(platform) eq "windows"} {
            puts "run $runcmd_win now..."
			cd VCUBE
            exec {*}[auto_execok start] "" $runcmd_win
			cd ..
        }
        if {$tcl_platform(platform) eq "unix"} {
            puts "run $runcmd_linux now..."
			cd VCUBE
            exec {*}[auto_execok bash] $runcmd_linux >@stdout
			cd ..
        }
	}
}

proc ::vcube::Vnthread {} {
    global nproc
    set ncores [numberOfCPUs]
    set nthread [expr $ncores / 2 -2]
    if {$nthread < 1} {set nthread 1}
    if {$nthread > $nproc} {set nthread $nproc}
    return $nthread
}

proc ::vcube::Vpreview {} {
    variable tachyon_defaults
    variable tachyon_options
    global tcl_platform
    global optix
    global ospray
    global image_viewer
    set preview_file "preview.bmp"
    if {$optix} {
        set preview_file "preview.ppm"
        render aasamples TachyonLOptiXInternal 12
        render aosamples TachyonLOptiXInternal 12
        render TachyonLOptiXInternal $preview_file
    } elseif {$ospray} {
        set preview_file "preview.ppm"
        render aasamples TachyonLOSPRayInternal 12
        render aosamples TachyonLOSPRayInternal 12
        render TachyonLOSPRayInternal $preview_file
    } else {
        set wkdir [pwd]
        set filename [file join $wkdir "preview.dat"]
        set tachyon_cmd [lindex [regsub \" [regsub \" [render options Tachyon] \{] \}] 0]
        set full_options "$tachyon_defaults -aasamples 12 -numthreads [Vnthread] $tachyon_options"
        puts "tachyon options: $full_options"
        render Tachyon $filename
        exec $tachyon_cmd $filename {*}$full_options  -o $preview_file
    }
    if {$tcl_platform(platform) eq "windows"} {
        exec {*}[auto_execok start] $preview_file
    }
    if {$tcl_platform(platform) eq "unix"} {
        set run_flag 0
        if {[info exists $image_viewer]} {
            exec $image_viewer $preview_file
        } else {
            set viewer_not_found  1
            foreach com [split $image_viewer] {
                if { [catch {exec which $com} vprev_com] ==0 } {
                    puts "use $com to view image..." 
                    set viewer_not_found 0
                    exec $com $preview_file
                    break
                }
            }
            if {$viewer_not_found == 1} {
                puts "eog or gwenview can not found, could not display image"
                puts "you can use \"set vprev_com xxx\" to set an available image viewer"
            } 
        }
    }
}


proc ::vcube::numberOfCPUs {} {
    # Windows puts it in an environment variable
    global tcl_platform env
    if {$tcl_platform(platform) eq "windows"} {return $env(NUMBER_OF_PROCESSORS)}
    # Check for sysctl (OSX, BSD)
    set sysctl [auto_execok "sysctl"]
    if {[llength $sysctl]} {
        if {![catch {exec {*}$sysctl -n "hw.ncpu"} cores]} {return $cores}
    }
    # Assume Linux, which has /proc/cpuinfo, but be careful
    if {![catch {open "/proc/cpuinfo"} f]} {
        set cores [regexp -all -line {^processor\s} [read $f]]
        close $f
        if {$cores > 0} {return $cores}
    }
    # No idea what the actual number of cores is; exhausted all our options
    # Fall back to returning 1; there must be at least that because we're running on it!
    return 1
}


namespace import ::vcube::*
user add key a {::vcube::Vnav_mol p}
user add key d {::vcube::Vnav_mol n}
user add key w {::vcube::Vnav_mol P}
user add key s {::vcube::Vnav_mol N}
user add key q {::vcube::Vnav_iso n}
user add key e {::vcube::Vnav_iso p}
user add key Home {::vcube::Vnav_alpha n}
user add key End {::vcube::Vnav_alpha p}
user add key Insert {::vcube::Vnav_cscale n}
user add key Delete {::vcube::Vnav_cscale p}
user add key Up {::vcube::Vnav_mscale u}
user add key Down {::vcube::Vnav_mscale d}
user add key Left {::vcube::Vnav_mscale l}
user add key Right {::vcube::Vnav_mscale r}
user add key Page_Up {::vcube::Vnav_style p}
user add key Page_Down {::vcube::Vnav_style n}
user add key f {::vcube::Vglobal_switch}
user add key g {::vcube::Vshow_switch}
user add key v {::vcube::Vpreview}
