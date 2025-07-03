# ChenGroupHPC User Guide
---
#### 高性能计算集群,张江高研院1-326室
##### host IP: * Port: 22
##### ssh user\@* -p 22

---

## 1. 硬件环境

1 台存储兼登陆管理节点、4 台计算节点，共 5 台机器。  
共 800 核心、3.1T 内存、80T 数据存储。

### 管理节点：

| 硬件 | 容量 |
|------|------|
| CPU | AMD EPYC 9124 (3.0GHz / 16 核 / 64MB / 200W) × 2 |
| MEM | 16G / DDR5 / 4800MHz × 8 |
| SSD | 960G / 2.5 × 2（Raid 1）|
| HDD | 16T / 7200RPM / 3.5 × 6（Raid 5）|
| 汇总 | 32 核心、128G 内存、960G 系统存储、80T 数据存储 |

### 计算节点（共 4 台）：

| 硬件 | 容量 |
|------|------|
| CPU | AMD EPYC 9654 (2.4GHz / 96 核 / 384MB / 360W) × 2 |
| MEM | 32G / DDR5 / 4800MHz × 24 |
| SSD | 960G / 2.5 × 1 |
| 汇总 | 192 核心、768G 内存、960G 系统存储 |

---

## 2. 软件环境

| 序号 | 软件类型 | 名称及版本 |
|------|----------|-------------|
| 1 | 操作系统 | Rocky Linux 8.10 |
| 2 | 作业调度 | Slurm 作业调度系统 |
| 3 | 环境管理 | module 环境管理系统 |
| 4 | 编译器 | GCC |
| 5 | 网络 | 10 Gbps |
| 6 | 应用软件 | Gaussian16、ORCA 6.0.1、CP2K 2024.1、Quantum Espresso 7.2、VASP 6.3.2、lammps/20240829.1、lammps/20230328、gromacs/2024.5、gmx_mmpbsa/1.6.4、ChemShell 23.0.3、amber/2022 |

---

## 3. 架构拓扑

|机柜物理位置 SJTU-ZIAS-1-326-D28|
|------|
| 计算节点，node4<br>* |
| 计算节点，node3<br>* |
| 计算节点，node2<br>* |
| 计算节点，node1<br>* |
| 管理节点，master<br>* |

---

## 4. 集群启动方法

### 注意事项：

- 请注意集群开关机顺序
- 开机顺序：先管理节点，后计算节点  
- 关机顺序：先计算节点，后管理节点  
- 注：等节点开关机成功后，再操作另外节点。

---

## 5. 用户指引

- #### 账号创建
组内新成员需要使用171集群时，需要经过陈老师同意，root用户给新成员创建账号，创建账号脚本目录为`/usr/bin/adduser.sh`，新用户会自动加入gaussian组，并设置slurm作业数上限为20
```bash
#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 username"
    exit 1
fi
USERNAME="$1"
BASE="/public/home"
HOME="${BASE}/${USERNAME}"
if ! getent group gaussian > /dev/null; then
    echo "Error: group 'gaussian' does not exist."
    exit 1
fi
useradd -d "$HOME" -m -G gaussian "$USERNAME"
if [[ $? -ne 0 ]]; then
    echo "Error: user '$USERNAME' creation failed."
    exit 1
fi
echo "111111" | passwd --stdin "$USERNAME"
su - "$USERNAME" -c "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"
su - "$USERNAME" -c "cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys"
su - "$USERNAME" -c "echo 'StrictHostKeyChecking no' > ~/.ssh/config"
cd /var/yp && make
sacctmgr -i add user name="$USERNAME" account=job20
echo "用户 '$USERNAME' 创建完成：已加入组 gaussian，Slurm 限制设置为 job20。"
```

```bash
$ adduser.sh user1
```

如果要删除用户user1，需将其目录删除，并移除slurm的关联
```bash
$ pkill -u user1
$ userdel -r user1
$ sacctmgr -i delete user name=user1
```

##### 新用户及时登录并更改密码！！！自己保留好密码！！！
```bash
$ passwd
```
按照提示输入原始默认密码`111111`，依次输入新密码，完成密码更改

- #### 作业数限制
目前每个普通用户作业数上限为20

如需更改作业上限，由管理员操作
新建用户加入限制组
```bash
$ sacctmgr add user name=新用户名 account=job20
# 更改限制，将20限制改为100
# 新建100组
$ sacctmgr add account name=job100 description="Limit to 100 jobs" organization=default
$ sacctmgr modify account job100 set MaxJobs=100
$ sacctmgr remove user where name=需要更改的用户名 account=job20
$ sacctmgr add user name=需要更改的用户名 account=job100

$ systemctl restart munge slurmctld slurmdbd slurmd
```
- #### 安装程序
用户可根据自身需求，自行在自己账号下安装程序，安装教程可参考`https://github.com/QuantumicGuy/QC_install_notes`

171集群也预装了一些组内常用的程序，如`Gaussian16, ORCA, xTB, CREST, CP2K, QuantumEspresso, VASP, Amber, GROMACS, Lammps, ChemShel, Anaconda3, cmake, gcc, openmpi`等，程序目录为`/public/apps/` `/public/soft/`，可以通过module来进行调用
```bash
[hkang@master ~]$ module avail
---------------------------------------------------------------------------------- /public/apps/modulefiles -----------------------------------------------------------------------------------
amber/22            chemshell/23.0.1  cp2k/2024.1      gaussian/g16C01(default)  gcc/12.1.0      lammps/20230328  multiwfn/3.8_dev  openmpi/4.1.8  orca/6.1.0  vasp/6.3.2
anaconda3/2024.2.1  cmake/3.26.3      gaussian/g16A03  gcc/9.3.0                 gromacs/2024.5  lammps/20240829  openmpi/4.1.6     orca/6.0.1     qe/7.2      xtb/6.7.1

---------------------------------------------------------------------------- /public/apps/intel/oneapi/modulefiles ----------------------------------------------------------------------------
compiler-rt/2022.1.0    compiler/2022.1.0    debugger/2021.6.0       icc/2022.1.0    init_opencl/2022.1.0  mkl32/2022.1.0  oclfpga/2022.1.0  tbb32/2021.6.0
compiler-rt/latest      compiler/latest      debugger/latest         icc/latest      init_opencl/latest    mkl32/latest    oclfpga/latest    tbb32/latest
compiler-rt32/2022.1.0  compiler32/2022.1.0  dev-utilities/2021.6.0  icc32/2022.1.0  mkl/2022.1.0          mpi/2021.6.0    tbb/2021.6.0
compiler-rt32/latest    compiler32/latest    dev-utilities/latest    icc32/latest    mkl/latest            mpi/latest      tbb/latest
```
对应的提交作业脚本目录为`/public/slurm-script/`，用户可复制到自己的账号目录下，进行编辑修改

- #### 调试debug
##### 所有用户禁止在登陆节点运行作业/debug！！！
如有命令行运行需要，请申请资源到计算节点执行，如
```bash
$ srun -p normal -n 4 --pty /bin/bash
$ module load gaussian/g16C01
$ which g16
/public/apps/g16C01/g16/g16
$ nohup g16 test_gaussian.gjf > test_gaussian.log &
```

目前`Gaussian16, ORCA, xTB, CREST`已经经过测试可正常运行，公共目录下的所有程序可通过环境变量管理工具module调用，使用方法如下

### 5.1 Gaussian16
`/public/apps/`目录下安装了两个版本的Gaussian程序`Gaussian16 C.01, Gaussian16 A.03`
`/public/slurm-script/`目录下有对应版本的提交作业脚本`rg16, rg16a03`
以`rg16`为例
```bash
#!/bin/bash
input_file="$1"
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found."
    exit 1
fi
filename=$(basename -- "$input_file")
filename_no_ext="${filename%.*}"
echo "The job is: ${filename_no_ext}"
export GAUSS_SCRDIR=~/scr
mkdir -p "$GAUSS_SCRDIR" #设置Gaussian计算临时文件目录，可更改为自己想要存放的目录
# Submit the job to SLURM
sbatch << EOF
#!/bin/bash
#SBATCH -J ${filename_no_ext} #作业名称
#SBATCH -N 1 #申请1个计算节点
#SBATCH -n 40 #申请40个核
#SBATCH -p normal #提交到normal队列，目前171集群只有这一个队列
#SBATCH --mail-type=BEGIN,END,FAIL,REQUEUE #可以自行选择作业结束发送提醒到个人邮箱
#SBATCH --mail-user=xxx@xxx.com #可以自行选择作业结束发送提醒到个人邮箱
#SBATCH -o ${filename_no_ext}.log #输出文件

cd $(pwd)
module load gaussian/g16C01 #载入Gaussian16 C.01版本
#module load gaussian/g16A03 #载入Gaussian16 A.03版本,对应rg16a03
g16 $input_file
EOF
# chmod +x rg16, use rg16 in any directory(e.g., rg16 test.gjf) #rg16a03
```
用户可将其复制到自己账号目录下，修改作业核数内存等设置，并添加可执行权限
```bash
$ cd /public/slurm-script/
$ cp rg16 rg16a03 ~/bin/
$ cd ~/bin/
$ chmod +x rg16 rg16a03
```
提交Gaussian作业
```bash
$ rg16 test_gaussian.gjf
```
*注: 171集群设置了gaussian用户组，创建账号时会自动加入用户组，获得Gaussian程序计算权限*
### 5.2 ORCA
`/public/apps/`目录下安装了ORCA-6.0.1, openmpi-4.1.8程序`orca-6.1.0, openmpi/4.1.8`,ORCA的并行依赖openmpi，不同版本ORCA对应指定的openmpi
`/public/slurm-script/`目录下有对应版本的提交作业脚本`rorca`
```bash
#!/bin/bash
input_file="$1"
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found."
    exit 1
fi
filename=$(basename -- "$input_file")
filename_no_ext="${filename%.*}"
echo "The job is: ${filename_no_ext}"
# Submit the job to SLURM
sbatch << EOF
#!/bin/bash
#SBATCH -J ${filename_no_ext}
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -p normal
#SBATCH -o ${filename_no_ext}.out

cd $(pwd)
module load orca/6.1.0
module load openmpi/4.1.8
/public/apps/orca-6.1.0/orca $input_file > ${filename_no_ext}.out
EOF
# chmod +x rorca, use rorca in any directory(e.g., rorca test.inp)
```

用户可将其复制到自己账号目录下，修改作业核数内存等设置，并添加可执行权限

提交ORCA作业
```bash
$ rorca test_orca.inp
```
### 5.3 xTB/CREST
`/public/apps/`目录下安装了xTB-6.7.1, CREST-3.0.2程序`/public/apps/xtb-dist/bin/xtb, /public/apps/xtb-dist/bin/crest`
`/public/slurm-script/`目录下有对应版本的提交作业脚本`rxtb, rcrest, rcrestts`,分别为xtb作业，crest构象搜索作业，crest过渡态构象搜索作业
```bash
#!/bin/bash
input_file="$1"
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found."
    exit 1
fi
filename=$(basename -- "$input_file")
filename_no_ext="${filename%.*}"
echo "The job is: ${filename_no_ext}"
# Submit the job to SLURM
sbatch << EOF
#!/bin/bash
#SBATCH -J ${filename_no_ext}
#SBATCH -N 1
#SBATCH -n 40
#SBATCH --mem=200G
#SBATCH -p normal
#SBATCH -o ${filename_no_ext}.log

cd $(pwd)
module load xtb/6.7.1
xtb $input_file --chrg 0 --uhf 0 --opt extreme
#crest $input_file --rthr 0.5 --chrg 0 --uhf 0 --noreftopo -T 40 --cluster 20 #对应rcrest
#crest $input_file --rthr 0.5 --chrg 0 --uhf 0 --noreftopo -T 40 --cluster 20 --cinp TS #对应rcrestts
EOF
# chmod +x rxtb, use rxtb in any directory (e.g., rxtb test.xyz) #rcrest #rcrestts
```
用户可将其复制到自己账号目录下，修改作业核数内存等设置，**同时根据自己的体系修改xtb可执行参数！**，并添加可执行权限

提交xtb, CREST作业
```bash
$ rxtb test_xtb.xyz
or
$ rcrest test_crest.xyz
or
$ rcrestts test_crestts.xyz
```
---
## About
- 该文档仅供组内成员使用，请勿外传！
- 合理申请计算资源，尽可能让每个人都能运行作业
- 171集群使用过程中有任何问题，或者需要在公共目录下安装程序，可以联系管理员康豪, *hkang@sjtu.edu.cn*
- Rev. 2025/06/23