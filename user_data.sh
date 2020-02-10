#!/bin/bash
apt install wget -y
snap install amazon-ssm-agent
cd /tmp
wget https://felenasoft.com/xeoma/downloads/xeoma_linux64.tgz
tar -xf xeoma_linux64.tgz
mv xeoma.app /usr/local/bin/
xeoma.app -install -hiddenmode
xeoma.app -activateOnline XXXXX-XXXXX-XXXX-XXXXX-XXXXX
xeoma.app -setpassword "XXXXXXXXXXXXXX"
xeoma.app -startservice
mkfs -t xfs /dev/xvdb
mkdir /videodata
awk -i inplace -v x="UUID=$(blkid /dev/xvdb -s UUID -o value)  /videodata  xfs  defaults,nofail  0  2" 'NR==1{print x} 1' /etc/fstab
reboot