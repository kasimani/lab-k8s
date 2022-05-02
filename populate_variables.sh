#!/bin/bash
kubeinstall_base=`pwd`
ip_regex="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9/]+$"
digit_regex="^[1-9]{,2}$"

ipvalidator() {
count=0
local ip=$1
while [ $count = 0 ];
do
   if [[ $ip =~ $ip_regex ]]; then
      OIFS=$IFS
      IFS='.'
      ip=($1)
      IFS=$OIFS
      [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      count=$((count+1))
   else
      echo "Incorrect Address Format, Retry: "
          sleep 1
   fi
done
}

validatedigit() {
count=0
while [ $count = 0 ];
do
   if [[ $1 =~ $digit_regex ]]; then
      count=$((count+1))
   else
      echo "Enter Digits only, Retry: "
      sleep 1
   fi
done
}

echo -n "Enter Your Name: "
read name
envname=$(echo $name | tr '[:upper:]' '[:lower:]')
echo -n "Enter total number of worker nodes required: "
read nodecount
   
echo -n "Enter Master Node Mgmt IP Address [Single Master Only]: "
read mip

echo -n "Enter Subnet Prefix: "
read prefix

echo -n "Enter Gateway IP: "
read gateway

echo -n "Enter DNS IP: "
read dnsip

echo -n "Enter Destination KVM Host IP Address: "
read hostip


ipvalidator $mip

ipvalidator $gateway
ipvalidator $hostip
ipvalidator $dnsip

validatedigit $prefix
validatedigit $nodecount


while [ $count = 0 ];
do
    echo -n "Enter Destination KVM Host Root Password: "
    read rootpass
    sshpass -p $rootpass ssh-copy-id root@$hostip > /dev/null 2>&1
    status=0
    if [ $status -ne 0 ];
    then
         echo "Password is Incorrect, Retry: "
         continue
    else
         count=$((count+1))
    fi
done

### Start Polulate Group_Vars file ###
    echo "---" > $kubeinstall_base/lab_inventory/group_vars/all
    echo "environmentname: "$envname | tr '[:upper:]' '[:lower:]' >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "worker_node_count: "$nodecount >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "mgmt_prefix: "$prefix >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "mgmt_gateway: "$gateway >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "master_mgmt_ip: "$mip >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "dns_server_list: "$dnsip >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "master_vm: kubemaster" >> $kubeinstall_base/lab_inventory/group_vars/all
    
    sed -i 's/.*K8-Master.*/K8-Master ansible_host='$mip' ansible_user=root/g' $kubeinstall_base/lab_inventory/hosts
    sed -i 's/.*kvm1.*/kvm1 ansible_host='$hostip' ansible_user=root/g' $kubeinstall_base/lab_inventory/hosts
### End Polulate Group_Vars file ###


## Empty workers names text file - Before populating Worker Hostname/VM Name
cp /dev/null /tmp/workervm.txt

## Add Worker IPs in Group Vars
count=1
while [ $count -le $nodecount ]
do
    echo -n "Enter Worker-$count Node Mgmt IP Address: "
    read workerip

    echo worker_$count"_mgmt_ip": $workerip >> $kubeinstall_base/lab_inventory/group_vars/all
    echo worker_$count"_vm": K8_Worker_$count >> $kubeinstall_base/lab_inventory/group_vars/all
    echo "worker"$count"-"$envname"-"$workerip | tr '[:upper:]' '[:lower:]' >> /tmp/workervm.txt
    cp $kubeinstall_base/src/roles/master-deploy/templates/master_50-cloud-init.yaml $kubeinstall_base/src/roles/worker-deploy/templates/"worker"$count"-"$envname"-"$workerip"_50-cloud-init.yaml"
    sed -i 's/master_mgmt_ip/worker_'$count'_mgmt_ip/g' $kubeinstall_base/src/roles/worker-deploy/templates/"worker"$count"-"$envname"-"$workerip"_50-cloud-init.yaml"
    sed -i 's/.*K8-worker-'$count'.*/K8-worker-'$count' ansible_host='$workerip' ansible_user=root/g' $kubeinstall_base/lab_inventory/hosts
    count=$(($count+1))
done

