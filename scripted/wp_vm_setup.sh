#!/bin/bash
vboxmanage () { VBoxManage.exe "$@"; }
declare script_path="$(readlink -f $0)"
declare script_dir=$(dirname "${script_path}")

declare vm_name="WP_VM"
vboxmanage createvm --name ${vm_name} --register

declare vm_info="$(VBoxManage.exe showvminfo "${vm_name}")"
declare vm_conf_line="$(echo "${vm_info}" | grep "Config file")"
declare vm_conf_file="$( echo "${vm_conf_line}" | grep -oE '[[:alpha:]]:(\\[^\]+){1,}\\.+\.vbox' )"
declare vm_directory_win="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\\[^\]\+\.vbox$//')"
declare vm_directory_linux="$(echo ${vm_conf_file} | sed 's/Config file:\s\+// ; s/\([[:upper:]]\):/\/mnt\/\L\1/ ; s/\\/\//g')"
vm_directory_linux="$(dirname "$vm_directory_linux")"

#echo "${vm_directory_linux}"
#echo "${vm_directory_win}"
#echo "${vm_conf_line}"
#echo "${vm_conf_file}"

vboxmanage createhd --filename "${vm_directory_win}/${vm_name}.vdi" --size 10000 -variant Standard
vboxmanage storagectl ${vm_name} --name ide1 --add ide --bootable on
vboxmanage storagectl ${vm_name} --name sata1 --add sata --bootable on
vboxmanage storageattach ${vm_name} --storagectl ide1 --port 0 --device 0 --type dvddrive --medium "../../CentOS-7-x86_64-Minimal-1810.iso"
vboxmanage storageattach ${vm_name} --storagectl ide1 --port 1 --device 1 --type dvddrive --medium "C:/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"
vboxmanage storageattach ${vm_name} --storagectl sata1 --port 0 --device 0 --type hdd --medium "${vm_directory_win}/${vm_name}.vdi" --nonrotational on
vboxmanage modifyvm ${vm_name} --ostype "RedHat_64" --cpus 1 --hwvirtex on --nestedpaging on --largepages on --firmware bios --nic1 natnetwork --nat-network1 "sys_net_prov" --cableconnected1 on --audio none --boot1 disk --boot2 dvd --boot3 none --boot4 none --memory "1280"