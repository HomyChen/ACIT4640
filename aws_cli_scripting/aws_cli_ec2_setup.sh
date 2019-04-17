#!/bin/bash

source state_file

#Variables
ssh_key_name="hchen_aim_key"
centos_7_ami_id="ami-01ed306a12b7d1c96"
instance_type="t2.micro"
instance_ip="172.16.2.101"
key_file="hchen_aim_key.pem"

#Force deletion of EBS disk when instances terminates - block-device-mappings
instance_id=$(aws ec2 run-instances \
         --image-id $centos_7_ami_id \
         --count 1 \
         --instance-type $instance_type \
         --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true}" \
         --key-name $ssh_key_name \
         --security-group-ids $security_group_id \
         --subnet-id $subnet_id \
         --private-ip-address $instance_ip \
         --user-data file://ec2_userdata.yml \
         --query 'Instances[*].InstanceId' \
         --output text)

while state=$(aws ec2 describe-instances \
                        --instance-ids $instance_id \
                        --query 'Reservations[*].Instances[*].State.Name' \
                        --output text );\
      [[ $state = "pending" ]]; do
     echo -n '.' # Show we are working on something
     sleep 3s    # Wait three seconds before checking again
done

echo -e "\n$instance_id: $state"

addr_association_id=$(aws ec2 associate-address \
                           --instance-id $instance_id \
                           --allocation-id $elastic_ip_allocation_id \
                           --query 'AssociationId' \
                           --output text)

ssh -i "../../${key_file}" centos@${elastic_ip}
