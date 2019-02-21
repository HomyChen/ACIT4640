wp_setup.sh is to be run on the host machine, not the VM.

It assumes these are set up:
	- Network is set up on VM
	- ssh is set up such that "ssh wp" command is able to ssh into the VM
	- user admin is set up on the VM with password P@ssw0rd and is part of wheel group
	- ssh key is already copied into user's authorized_keys
	- admin is able to sudo without entering password