#!/bin/bash
#
vboxmanage () { VBoxManage.exe "$@"; }
declare script_path="$(readlink -f $0)"
declare script_dir=$(dirname "${script_path}")
vboxmanage natnetwork add --netname sys_net_prov --network "192.168.254.0/24" --dhcp off           
vboxmanage natnetwork modify --netname sys_net_prov --port-forward-4 "http:tcp:[]:50080:[192.168.254.10]:80"
vboxmanage natnetwork modify --netname sys_net_prov --port-forward-4 "ssh:tcp:[]:50022:[192.168.254.10]:22"
vboxmanage natnetwork modify --netname sys_net_prov --port-forward-4 "https:tcp:[]:50443:[192.168.254.10]:443"