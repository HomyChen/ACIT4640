#!/bin/bash
vboxmanage () { VBoxManage.exe "$@"; }
declare script_path="$(readlink -f $0)"
declare script_dir=$(dirname "${script_path}")

vboxmanage startvm "acit_4640_pxe"
until [[ $(ssh -q pxe exit && echo "online") == "online" ]] ; do
  sleep 10s
  echo "waiting for pxe server to come online"
done
scp ./kickstart/wp_ks.cfg pxe:/usr/share/nginx/html/
scp -r ./setup pxe:/usr/share/nginx/html/
ssh pxe 'sudo chown nginx:wheel /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'chmod ugo+r /usr/share/nginx/html/wp_ks.cfg'
ssh pxe 'chmod ugo+rx /usr/share/nginx/html/setup'
ssh pxe 'chmod -R ugo+r /usr/share/nginx/html/setup/*'

declare vm_name="WP_VM_Homy"
vboxmanage createvm --name ${vm_name} --register

declare vm_info="$(VBoxManage.exe showvminfo "${vm_name}")"
declare vm_conf_line="$(echo "${vm_info}" | grep "Config file")"
declare vm_conf_file="$( echo "${vm_conf_line}" | grep -oE '[[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox' )"
declare vm_directory_win="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\\[^\]\+\.vbox$//')"
declare vm_directory_linux="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\([[:upper:]]\):/\/mnt\/\L\1/ ; s/\\/\//g')"
vm_directory_linux="$(dirname "$vm_directory_linux")"

vboxmanage createhd --filename "${vm_directory_win}/${vm_name}.vdi" --size 10000 -variant Standard
vboxmanage storagectl ${vm_name} --name ide1 --add ide --bootable on
vboxmanage storagectl ${vm_name} --name sata1 --add sata --bootable on
vboxmanage storageattach ${vm_name} --storagectl ide1 --port 0 --device 0 --type dvddrive --medium "../../CentOS-7-x86_64-Minimal-1810.iso"
vboxmanage storageattach ${vm_name} --storagectl ide1 --port 1 --device 1 --type dvddrive --medium "C:/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
vboxmanage storageattach ${vm_name} --storagectl sata1 --port 0 --device 0 --type hdd --medium "${vm_directory_win}/${vm_name}.vdi" --nonrotational on
vboxmanage modifyvm ${vm_name} --ostype "RedHat_64" --cpus 1 --hwvirtex on --nestedpaging on --largepages on --firmware bios --nic1 natnetwork --nat-network1 "sys_net_prov" --cableconnected1 on --audio none --boot1 disk --boot2 net --boot3 none --boot4 none --memory "1280" --macaddress1 "020000000001"
vboxmanage startvm ${vm_name}