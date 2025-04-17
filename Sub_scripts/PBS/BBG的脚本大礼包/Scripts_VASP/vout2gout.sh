#!/bin/sh
#
#    Name:
#        vout2gout v0.0
# 
#    Author:
#        yangwang2008@gmail.com, Jan. 2010   modified by yuanjianyong, 2021/12/14
# 
#    Description:
#        A script to convert VASP OUTCAR file to GAUSSIAN *.out file
# 
#    Usage:
#        voutgout [ OUTCAR ] [ POTCAR ]
# 
#    Input file:
#        VASP OUTCAR file ( default name: OUTCAR ) & VASP POTCAR file ( default name: POTCAR ) 

# GaussView是个我一直比较喜欢的软件，用起来很舒服。但一般它只能配合Gaussian使用，如果想要可视化其他程序的计算结果，就需要转换文件格式为Gaussian的输出格式。在此我就奉献一下我写的GaussView对VASP的接口程序——vout2gout，用它你就可以用GaussView查看VASP的结构优化过程和结果。
# 一  程序描述：
# 1. 名称：vout2gout
# 2. 版本：v0.0
# 3. 编写语言：Shell通用脚本（awk）。
# 4. 运行环境：Linux, Unix以及Windows下的cygwin等。
# 二  功能：
# 1. 将OUTCAR文件转成GaussView可识别的*.out文件。
# 2. 显示晶胞。
# 3. 可视化几何构型的优化过程。
# 4. 查看优化过程中体系总能量和力（RMS平均）的变化曲线。
# 5. 可视化各个步骤中的各原子的受力情况以及预测下一步各原子的位移。
# 6. 导出优化过程的动画。
# 三  使用方法：
# 1. 在Unix下（如果用Windows，则需要装cygwin）把vout2gout脚本文件增加可执行属性：
# chmod a+x vout2gout
# 2. 在命令行执行：
# ./vout2gout  输入文件名
# 其中，输入文件名就是VASP计算所得的OUTCAR文件名。vout2gout转换后的文件是“输入文件名.out”
# 如果输入文件名缺省：
# ./vout2gout
# 那么vout2gout就会将当前目录下的OUTCAR文件转为OUTCAR.out文件。
# 建议将vout2gout放在一个固定目录下（如/home/username/bin），再将这个目录的路径包含在环境变量PATH里。这样在任何目录下你就可以直接调用本程序：
# vout2gout  
# 3. 用GaussView打开转好的*.out文件。在打开“Open Files”对话框选取文件时，记得勾选最下方的“Read intermediate Geomoetries (Gaussian Optimizations only)”复选框。 这时你就能看到并选取各个优化步骤的结构了。（附图1）
# 4. 查看优化过程中体系总能量和平均力的变化曲线：
# 菜单Results | Optimization... （附图2）
# *注意：图中能量和力的单位分别是：eV和eV/Agstrom
# 5.  可视化各个步骤中的各原子的受力情况以及预测下一步各原子的位移：
# 菜单Results | Vibration... |  Show displacement vectors（附图3）
# 如果箭头太小，可以拖动Scale滑条放大。
# 6. 导出动画：
# 菜单File| Save Movie
# 四  测试版本：
# VASP 4.6，VASP 5.2
# GaussView 4.1.2
# 欢迎大家在其他版本的VASP和GaussView上测试（如有问题请联系我）。


# scaling factor of forces
SCALING_FACTOR=1.0


# get OUTCAR/POTCAR file name
if [ $# -eq 0 ]; then
    inp1="OUTCAR"
	inp2="POTCAR"
elif [ $# -eq 1 ]; then
    inp1=$1
	inp2="POTCAR"
elif [ $# -eq 2 ]; then
	inp1=$1
	inp2=$2
fi

# check existence of OUTCAR file
if [ ! -f "$inp1" ]; then
    echo Error: cannot find OUTCAR file "$inp1".
    exit 1;
fi

# check existence of POTCAR file
if [ ! -f "$inp2" ]; then
    echo Error: cannot find POTCAR file "$inp2".
    exit 1;
fi

cat $inp2 > temp
cat $inp1 >> temp

awk -v scal=$SCALING_FACTOR '
BEGIN{
    ielem = 0;
    N = 0;        # total number of atoms
    flagUV = 0;
    iuv = 0;
    flagEN = 0;
    flagPos = 0;
    iat = 0;
    istep = 0;

    printf( " GradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGrad\n");
}
{
    # get element types
    if( $0 ~ / VRHFIN =/ ){
        ix =  index($2,":");
        if( ix == 0 ){
            elem[ ielem ] = substr($2,2);
        }
        else{
            elem[ ielem ] = substr($2,2,ix-2);
        }
        ielem ++;
    }

    # get number of atoms for each element
    if( $0 ~ / ions per type = / ){
        for( i = 5; i <= NF; i ++ ){
            nat[i-5] = $i;
            N += nat[i-5];
        }
        # get array of element names
        ix = 0;
        for( j = 0; j < ielem; j ++ ){
            for( i = 0; i < nat[j]; i ++ ){
                elemname[ix] = elem[ j ];
                ix ++;
            }
        }
    }

    # get components of unit vectors
    if( $0 ~ /direct lattice vectors/ ){
        flagUV = 1;
    }
    else if( flagUV && iuv < 3 ){
        uv[iuv, 0] = $1;
        uv[iuv, 1] = $2;
        uv[iuv, 2] = $3;
        iuv ++;
		
		if (iuv == 3) {
			iuv = 0;
			flagUV = 0;
		}
    }

    # get total energy
    if( $0 ~ /FREE ENERGIE OF THE ION-ELECTRON SYSTEM \(eV\)/ ){
        flagEN = 1;
    }
    ## DFT energy + vdW energy (D3) 
    else if( flagEN == 1 && $0 ~ /energy\(sigma->0\)/ ){
        energy = $7;
        flagEN = 2;
    }
    ## DFT + vdW energy (D2,obsolete)
    else if( flagEN == 2 && $0 ~ /Estimated total energy \(eV\):/ ){
        energy = $5;
		flagEN = 3;
    }

    # get components of atom position vectors and forces
    if( $0 ~ /POSITION/ && $0 ~ /TOTAL-FORCE/ ){
        flagPos = 1;
    }
    else if( flagPos == 1 ){
        flagPos = 2;
    }
    else if( flagPos == 2 && iat < N ){
        xyz[iat, 0] = $1;
        xyz[iat, 1] = $2;
        xyz[iat, 2] = $3;
        force[iat, 0] = $4;
        force[iat, 1] = $5;
        force[iat, 2] = $6;
        maxf[iat] = sqrt(force[iat, 0]^2);
        maxf[iat] = force[iat, 1]^2 > maxf[iat]^2 ? sqrt(force[iat, 1]^2) : maxf[iat];
        maxf[iat] = force[iat, 2]^2 > maxf[iat]^2 ? sqrt(force[iat, 2]^2) : maxf[iat];
        fsum2[iat] = force[iat, 0]^2 + force[iat, 1]^2 + force[iat, 2]^2;
        iat ++;
    }
	
	
    # output the content with g16 format
	if( flagPos == 2 && iat == N && ( flagEN == 2 || flagEN == 3)){
        # print out Coordinates
        printf( " GradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGrad\n");
        printf( "                         Standard orientation:\n");
        printf( " ---------------------------------------------------------------------\n");
        printf( " Center     Atomic     Atomic              Coordinates (Angstroms)\n");
        printf( " Number     Number      Type              X           Y           Z\n");
        printf( " ---------------------------------------------------------------------\n");
        for( i = 0; i < N; i ++ ){
            printf( "%5i %10s %13i    %12.6f%12.6f%12.6f\n", i+1, elemname[i], 0, 
                    xyz[i,0], xyz[i,1], xyz[i,2]);
        }
        for( j = 0; j < 3; j ++ ){
            printf( "%5i %10s %13i    %12.6f%12.6f%12.6f\n", j+i+1, "Tv", 0, 
                    uv[j,0], uv[j,1], uv[j,2]);
        }
        printf( " ---------------------------------------------------------------------\n");

        # print out energy and forces
        printf( " SCF Done:  E =%16.8f     A.U.\n", energy );
        maxforce = maxf[0];
        rmsforce = fsum2[0];
        for( i = 1; i < N; i ++ ){
             maxforce = maxf[i] > maxforce ? maxf[i] : maxforce;
             rmsforce += fsum2[i];
        }
        rmsforce = ( rmsforce / N / 3 ) ^ 0.5;
        printf( " Cartesian Forces:  Max%16.9f RMS%16.9f\n", maxforce, rmsforce);

        # print out step number
        printf( " GradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGrad\n");
        printf( " Step number%4i\n\n\n", istep+1);

        # print out force vectors
        printf( " GradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGrad\n");
        printf( "                         Standard orientation:\n");
        printf( " ---------------------------------------------------------------------\n");
        printf( " Center     Atomic     Atomic              Coordinates (Angstroms)\n");
        printf( " Number     Number      Type              X           Y           Z\n");
        printf( " ---------------------------------------------------------------------\n");
        for( i = 0; i < N; i ++ ){
            printf( "%5i %10s %13i    %12.6f%12.6f%12.6f\n", i+1, elemname[i], 0, 
                    xyz[i,0], xyz[i,1], xyz[i,2]);
        }
        printf( " ---------------------------------------------------------------------\n");
        printf( "\n Harmonic frequencies (cm**-1), IR intensities (KM/Mole), Raman scattering\n" );
        printf( " activities (A**4/AMU), depolarization ratios for plane and unpolarized\n" );
        printf( " incident light, reduced masses (AMU), force constants (mDyne/A),\n" );
        printf( " and normal coordinates:\n" );
        printf( "%23i\n", 1 );
        printf( " Frequencies --%11.4f\n", maxforce );
        printf( " IR Inten    --%11.4f\n", rmsforce );
        printf( " Atom AN      X      Y      Z\n" );
        for( i = 0; i < N; i ++ ){
            printf( "%4i%4s  %7.2f%7.2f%7.2f\n", i+1, elemname[i], 
                force[i, 0]*scal, force[i, 1]*scal, force[i, 2]*scal );
        }
        printf( "\n -------------------\n");
        printf( "\n GradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGrad\n");

        istep ++;
        iat = 0;
        flagPos = 0;
		flagEN = 0;
    }
}
END{
    printf( " GradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGradGrad\n");
    printf( "\n Normal termination of Gaussian 16.\n" );
}
' temp > "$inp1".out

rm temp



