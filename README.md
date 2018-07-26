# docker-dci
A script to deploy Docker Certified Infrastructure labs

To Do: 

    1. Add support for CentOS/RHEL7/SLES/Ubuntu 18.04 (Currently only Ubuntu 16.04 is used).
    2. Script currently requires at least 1 DTR node. Fix this. 
    3. Support for specific docker versions instead of latest in branch. 
    4. Support for lab clean up (currently, you must cd into the aws-v1.0.0 directory and run `../terraform destroy`)
    5. Option to display all current labs and IP information. 
    6. Fix occassional `aws_s3_bucket.dtr_storage_bucket: Error creating S3 bucket: InvalidBucketName` errors. Will have to enforce lab names. 
