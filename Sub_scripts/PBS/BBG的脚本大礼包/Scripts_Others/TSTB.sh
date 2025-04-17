#!/bin/bash
#calculat through bond and through space of a ct state
# generate input files 
# developed by zhongcheng@whu.edu.cn. Contact via E-mail or QQ:32589927 if you have any suggestions
if [ $# -lt 1 ]; then
    echo "Use Multiwfn to calculate through bond / through space contribution to transition density / hole-electron overlap or IFCT"
    echo 'usage: -[m methods, choose from td he ifct, default: he] -[n excited state number, default: 1] -[b bridge atom number, must set] -[d donor atom nunber, required by IFCT]  -[a acceptor atom number, required by IFCT] -[g grid setting, choose from 1 2 3(default)] input.fchk input.log'
    exit 1
fi
while getopts ":m:b:d:a:g:n:" opt
do
    case $opt in
        m) METHOD=$OPTARG;;
        n) NSTATE=$OPTARG;;
        b) BRIDGE=$OPTARG;;
        d) DONOR=$OPTARG;;
        a) ACCEPTOR=$OPTARG;;
        g) GRID=$OPTARG;;
        ?) echo 'usage: -[m methods, choose from td he ifct, default: he] -[n excited state number, default: 1] -[b bridge atom number, must set] -[d donor atom nunber, required by IFCT]  -[a acceptor atom number, required by IFCT] -[g grid setting, choose from 1 2 3(default)] input.fchk input.log'
        exit 1;;
    esac
done
shift $(($OPTIND - 1))
Mflag=`which Multiwfn.exe 2>/dev/null` 
if [ -z "$Mflag" ];then
	Mflag=`which Multiwfn`
fi
echo $Mflag
if [ -z "$Mflag" ];then
    echo "Multiwfn command not found, exit now"
    exit
fi

if [ -z "$METHOD" ];then
    METHOD=td
fi

if [ -z "$NSTATE" ];then
    NSTATE=1
fi

if [ -z "$GRID" ];then
    GRID=3
fi

if [ -z "$BRIDGE" ];then
    echo "Error! You must set atom index for Bridge group with -b option"
    exit
fi
# tansition density 
if [[ "$METHOD" == "td" ]];then
cat > gen_td.txt << EOF
18
1
$2
$NSTATE
1
$GRID
13
EOF
cat > gen_td_nob.txt << EOF
6
-4
$BRIDGE
-1
18
1
$2
$NSTATE
1
$GRID
13
EOF
cat > ana_td.txt << EOF
13
11
13
17
1
EOF
cat gen_td.txt | $Mflag $1 2> /dev/null
cat ana_td.txt | $Mflag transdens.cub 2> /dev/null | tee tdana_tot.log
cat gen_td_nob.txt | $Mflag $1 2> /dev/null
cat ana_td.txt | $Mflag transdens.cub 2> /dev/null | tee tdana_nobridge.log
all=`grep "Integral of all" tdana_tot.log | awk '{gsub("\r","\n");print $5}'`
ts=`grep "Integral of all" tdana_nobridge.log | awk '{gsub("\r","\n");print $5}' `
tb=`echo "$all-$ts" | bc`
tbp=`echo "scale=4;$tb/$all*100" | bc`
tsp=`echo "scale=4;$ts/$all*100" | bc`
tbp=`printf "%0.2f%%" $tbp`
tsp=`printf "%0.2f%%" $tsp`
tb=`printf "%0.5f" $tb`
ts=`printf "%0.5f" $ts`
all=`printf "%0.5f" $all`
echo "TS/TB using transition density:"
echo "Through Space CT: $ts    $tsp"
echo "Through Bond  CT: $tb    $tbp"
echo "Tot transit dens: $all"
fi

#hole - electron
if [[ "$METHOD" == "he" ]];then
cat > gen_he.txt << EOF
18
1
$2
$NSTATE
1
$GRID
EOF
cat > gen_he_nob.txt << EOF
6
-4
$BRIDGE
-1
18
1
$2
$NSTATE
1
$GRID
EOF
cat gen_he.txt | $Mflag $1 2>/dev/null | tee heana_tot.log
cat gen_he_nob.txt | $Mflag $1 2>/dev/null | tee heana_nobridge.log
all=`grep "Sr index" heana_tot.log | awk '{print $7}'`
ts=`grep "Sr index" heana_nobridge.log | awk '{print $7}'`
tb=`echo "$all-$ts" | bc`
tb=`printf "%0.5f" $tb`
tbp=`echo "scale=4;$tb/$all*100" | bc`
tsp=`echo "scale=4;$ts/$all*100" | bc`
tbp=`printf "%0.2f%%" $tbp`
tsp=`printf "%0.2f%%" $tsp`
echo "TS/TB using hole-electron overlap:"
echo "Through Space CT: $ts    $tsp"
echo "Through Bond  CT: $tb    $tbp"
echo "Tot h-e  overlap: $all"
fi


if [[ "$METHOD" == "ifct" ]];then
    if [ -z "$DONOR" ] || [ -z "$ACCEPTOR" ];then
        echo "Error! You must set atom index for both Donor and Acceptor with -d and -a, respectively"
        exit
    fi
mv hole.cub hole.cub.bak 2> /dev/null
mv electron.cub electron.cub.bak 2> /dev/null
cat > gen_ifct.txt << EOF
18
8
$2
$NSTATE
3
$DONOR
$BRIDGE
$ACCEPTOR
EOF

cat gen_ifct.txt | $Mflag $1 2> /dev/null | tee ifct_result.log 
d2b=`grep "Net  1 ->  2" ifct_result.log | awk '{gsub("\r","\n");print $13}'`
d2a=`grep "Net  1 ->  3" ifct_result.log | awk '{gsub("\r","\n");print $13}'`
b2a=`grep "Net  2 ->  3" ifct_result.log | awk '{gsub("\r","\n");print $13}'`
ts=$d2a
tb=`printf "%s\n" $d2b $b2a | sort -g | head -n 1`
all=`echo "$ts+$tb" | bc`
tbp=`echo "scale=4;$tb/$all*100" | bc`
tsp=`echo "scale=4;$ts/$all*100" | bc`
all=`printf "%0.5f" $all`
tbp=`printf "%0.2f%%" $tbp`
tsp=`printf "%0.2f%%" $tsp`
echo "TS/TB using IFCT:"
echo "Through Space CT: $ts    $tsp"
echo "Through Bond  CT: $tb    $tbp"
echo "Tot Charge Trans: $all"
fi

