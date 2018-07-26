# docker-dci
A script to deploy Docker Certified Infrastructure labs

AWS Usage (with config file):

```
$ cat ~/.terr-script.conf 
## This file will be sourced if present.

TERRVER=0.11.5
LICENSE=/path/to/docker_subscription.lic
KEY=/path/to/ssh-key.pem
AWSKEYNAME=name-of-key # from AWS EC2 console
SUB=sub-xxx-xxx-xxx-xxx # from store.docker.com
REGION=region # E.g. us-east-2
```

```
$ terraform-docker-dci-aws.sh 
Ticket number: TEST123
Lab name: TEST123
UCP manager count: 1
DTR node count: 1
Linux worker count: 1
Windows worker count: 0
UCP version: 3.0.1
DTR version: 2.5.3
Docker EE version (e.g. 17.06): 17.06
UCP password: 
UCP password (again): 
Please try again
UCP password: 
UCP password (again): 
```

Result:

```
$ cd ${HOMEDIR}/LABS/${TICKET-NUMBER}

$ ls -1
aws-v1.0.0
docker-dci-1.0.tar.gz
LAB-INFO.txt
terraform
terraform.zip

$ cat ${HOMEDIR}/LABS/${TICKET-NUMBER}/aws-v1.0.0/terraform.log # terraform debug logging.
```


**To Do:**

    1. Add support for CentOS/RHEL7/SLES/Ubuntu 18.04 (Currently only Ubuntu 16.04 is used).
    2. Script currently requires at least 1 DTR node. Fix this. 
    3. Support for specific docker versions instead of latest in branch. 
    4. Support for lab clean up (currently, you must cd into the aws-v1.0.0 directory and run `../terraform destroy`)
    5. Option to display all current labs and IP information. 
    6. Fix occassional `aws_s3_bucket.dtr_storage_bucket: Error creating S3 bucket: InvalidBucketName` errors. Will have to enforce lab names. 
