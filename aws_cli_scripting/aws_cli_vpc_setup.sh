#!/bin/bash

#Variables
vpc_cidr="172.16.0.0/16"
vpc_name="4640_vpc_2"
subnet_cidr="172.16.2.0/24"
subnet_name="4640_sn_web_2"
gateway_name="4640_gw_2"
default_cidr="0.0.0.0/0"
security_group_name="4640_web_sg_2"
security_group_desc="Allow http, https, and ssh access from bcit"
bcit_cidr="142.232.0.0/16"
availability_zone="us-west-2a"

my_ip="0.0.0.0/0"

#VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query Vpc.VpcId --output text)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name
echo "vpc_id=$vpc_id" >> state_file

#Subnet
subnet_id=$(aws ec2 create-subnet  --availability-zone $availability_zone --vpc-id $vpc_id --cidr-block $subnet_cidr --query Subnet.SubnetId  --output text)
aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=$subnet_name
echo "subnet_id=$subnet_id" >> state_file

#Gateway
gateway_id=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws ec2 create-tags --resources $gateway_id --tags Key=Name,Value=$gateway_name
aws ec2 attach-internet-gateway --internet-gateway-id $gateway_id --vpc-id $vpc_id
echo "gateway_id=$gateway_id" >> state_file

#Route Table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text)
rt_association_id=$(aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $subnet_id --query AssociationId --output text)
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block $default_cidr --gateway-id $gateway_id --output text 
echo "route_table_id=$route_table_id" >> state_file
echo "rt_association_id=$rt_association_id" >> state_file

#Security Group
security_group_id=$(aws ec2 create-security-group --group-name "$security_group_name" --description "$security_group_desc" --vpc-id $vpc_id --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr $bcit_cidr
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 80 --cidr $bcit_cidr
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 443 --cidr $bcit_cidr
echo "security_group_id=$security_group_id" >> state_file

#aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr $my_ip
#aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 80 --cidr $my_ip
#aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 443 --cidr $my_ip

