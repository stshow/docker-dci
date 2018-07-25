#!/bin/bash
#
# Usage: 
#
#    Pre-requisite: You must have aws cli configured. 
#    
#    Functions execute in this order:
#    1.) terraform-lab
#    2.) terraform-config
#    3.) ansible-config
#    4.) terraform-init
#    5.) ansible-init

#TODO:
#1.) Make variables global to avoid requesting the same information again. 
#2.) Have script read from config file.
#3.) Consider containerizing script. 

read -p "Ticket number: " TICKET
read -p "License location (full path): " LICENSE
read -p "Private key file (full path): " KEY
read -p "AWS Private Key Name (https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:sort=keyName): " AWSKEYNAME
read -p "Lab name: " LABNAME
read -p "UCP manager count: " UCPMGR
read -p "DTR node count: " DTRWKR
read -p "Linux worker count: " LINWKR
read -p "Windows worker count: " WINWKR
read -p "UCP version: " UCPVER
read -p "DTR version: " DTRVER
read -p "Docker EE version (e.g. 17.06): " DOCKVER
read -p "Subscription from store.docker.com (Format: sub-xxx-xxx-xxx-xxx): " SUB

while true; do
    read -s -p "UCP password: " PASS
    echo
    read -s -p "UCP password (again): " PASS2
    echo
    [ "$PASS" = "$PASS2" ] && break
    echo "Please try again"
done

terraform-lab(){
    LATEST=$(curl -s https://releases.hashicorp.com/terraform/ | sed 's/<[^>]*>//g' | grep terraform | sort -V | tail -1|tr -d ' ')
    VERSION_NUMBER=$(curl -s https://releases.hashicorp.com/terraform/ | sed 's/<[^>]*>//g' | grep terraform | sort -V | tail -1 |    awk -F '_' '{print $2}' | tr -d ' ')
    mkdir -p ~/LABS/${TICKET}
    cd ~/LABS/${TICKET}
    #wget https://releases.hashicorp.com/terraform/${VERSION_NUMBER}/${LATEST}_linux_amd64.zip -O terraform.zip
    curl -o terraform.zip -L "https://releases.hashicorp.com/terraform/${VERSION_NUMBER}/${LATEST}_linux_amd64.zip"
    unzip terraform.zip
    chmod +x terraform
    #wget https://success.docker.com/api/asset/.%2Faws%2Fref-arch%2Fcertified-infrastructures-aws%2F.%2Ffiles%2Faws-v1.0.0.tar.gz -O  docker-dci-1.0.tar.gz
    curl -o docker-dci-1.0.tar.gz https://success.docker.com/api/asset/.%2Faws%2Fref-arch%2Fcertified-infrastructures-aws%2F%2Ffiles%2Faws-v1.0.0.tar.gz
    tar xvzf docker-dci-1.0.tar.gz
    cd aws-*
    cp ${LICENSE} license/
    cp ${LICENSE} .
}

terraform-config(){
    IMAGE=$(aws ec2 describe-images  --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial*  --query 'Images[*].[Name]' --output text  | sort -r -V  | head -1)
    LINOWNERID=$(aws ec2 describe-images --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial* --query 'Images[*].[OwnerId]' --output text | sort -r -V | head -1)
    WINOWNERID=$(aws ec2 describe-images --filters Name=name,Values=Windows_Server-2016-English-Full-Containers-2017.11.29 --query 'Images[*].[OwnerId]' --output text | sort -k2 -r | head -n1)
    echo "
linux_ucp_manager_count    = \"${UCPMGR}\"
linux_ucp_worker_count     = \"${LINWKR}\"
linux_dtr_count            = \"${DTRWKR}\" 
windows_ucp_worker_count   = \"${WINWKR}\"
deployment                 = \"${LABNAME}\"                 # VM/Hostname prefix string. Prepended to all resources.
ansible_inventory          = \"inventory/1.hosts\"
ucp_license_path           = \"./docker_subscription.lic\"
ucp_admin_password         = \"\"                          # If unset, check $ansible_inventory for generated value
region                     = \"us-east-1\"                  # The region to deploy (e.g. us-east-2)
key_name                   = \"${AWSKEYNAME}\"
private_key_path           = \"${KEY}\"               # The path to the private key corresponding to key_name
linux_ami_name             = \"${IMAGE}\"
linux_ami_owner            = \"${LINOWNERID}\" # OwnerID from 'aws ec2 describe-images'
windows_ami_name           = \"Windows_Server-2016-English-Full-Containers-2017.11.29\"
windows_ami_owner          = \"${WINOWNERID}\" # OwnerID from 'aws ec2 describe-images'
linux_user                 = \"ubuntu\"
efs_supported              = \"1\" # 1 if the region supports EFS (0 if not)
" > terraform.tfvars    
}

ansible-config(){
    REPLICA=$(head -3 /dev/urandom | tr -cd '[:alnum:]' | sed 's/[^0-9]*//g' |cut -c -12)
    echo "
docker_dtr_image_repository: docker
docker_dtr_version: ${DTRVER}
docker_ucp_image_repository: docker
docker_ucp_version: ${UCPVER}
docker_ee_release_channel: stable
docker_ee_version: ${DOCKVER}
docker_ee_package_version: 'latest'
docker_ee_package_version_win: 'latest'
docker_ee_version: ${DOCKVER}
docker_ee_subscriptions_ubuntu: ${SUB} # Format: sub-xxx-xxx-xxx-xxx
docker_ucp_license_path: "${LICENSE}"
docker_ucp_admin_password: ${PASS}
docker_dtr_replica_id: ${REPLICA} # (A 12-character long hexadecimal number: e.g. 1234567890ab)
cloudstor_plugin_version: 18.01.0-ce
" > group_vars/all
    echo "
[defaults]
host_key_checking = False
forks = 12
inventory = inventory
squash_actions = apk,apt,dnf,homebrew,package,pacman,pkgng,shell,win_firewall_rule,win_shell,yum,zypper
display_skipped_hosts = false
any_errors_fatal = true
callback_whitelist = logstash
callback_plugins = /etc/ansible/plugins

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
ssh_args = -C -o ControlMaster=auto -o ControlPersist=1800s
callback_whitelist = logstas
" > ansible.cfg
}


terraform-init(){
    ../terraform init
    ../terraform plan
    echo -en "\nInitiating in 5 seconds...\n"
    sleep 5
    ../terraform apply -auto-approve
}

ansible-init(){
    ssh-add $KEY
    ansible-playbook --private-key=${KEY} -i inventory install.yml
}

aws-image-list(){
    aws ec2 describe-images  --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*  --query 'Images[*].[ImageId,Name]' --output text  | sort -V  | head -1
    aws ec2 describe-images  --filters Name=name,Values=centos-7*  --query 'Images[*].[ImageId,Name]' --output text  | sort -V |head -1
}

terraform-lab
terraform-config
ansible-config
terraform-init
ansible-init
