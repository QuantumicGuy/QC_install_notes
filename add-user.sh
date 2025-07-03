#!/bin/bash
#

if [[ $# -ne 1 ]]
then
    echo "usage:$0 username"
    exit 1
fi

#add user
#GROUP=users
BASE="/public/home"
HOME="${BASE}/${1}"
id gaussian
NUM=$?
if [[ $NUM -ne 0 && "x$1" == "xgauss" ]];then
    useradd -d $HOME $1
elif [[ $NUM -eq 0 && "x$1" != "xgauss" ]];then
    useradd -d $HOME -G gaussian $1
else
    useradd -d $HOME $1
fi
#init password
echo "111111" | passwd --stdin $1
#ssh 
su -c "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''" $1
su -c "cat ~/.ssh/id_rsa.pub >~/.ssh/authorized_keys " $1
su -c "echo 'StrictHostKeyChecking no'>~/.ssh/config" $1
#update nis db
cd /var/yp && make

