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
