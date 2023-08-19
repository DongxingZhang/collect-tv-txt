sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak 
sudo sed -i "s@http://.*archive.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
sudo sed -i "s@http://.*security.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
sudo apt update
sudo apt upgrade
sudo apt autoremove


sudo apt install open-vm-tools
sudo apt install open-vm-tools-desktop
vmware-hgfsclient

sudo mkdir -p /mnt/hgfs
sudo /usr/bin/vmhgfs-fuse .host:/ /mnt/hgfs -o subtype=vmhgfs-fuse,allow_other
sudo mount -t fuse.vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other
ls -l /mnt/hgfs
sudo vi /etc/fstab

.host:/    /mnt/hgfs    fuse.vmhgfs-fuse allow_other,defaults    0    0