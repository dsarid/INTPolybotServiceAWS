### Start ###
Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash

IMAGEVER=$(aws ecr describe-images --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --repository-name aws-project-yolo5 --output text)

sudo -u ubuntu aws ecr get-login-password --region eu-central-1 | sudo -u ubuntu docker login --username AWS --password-stdin 019273956931.dkr.ecr.eu-central-1.amazonaws.com

sudo -u ubuntu docker stop yolo5
sudo -u ubuntu docker container prune -f
sudo -u ubuntu docker run --restart always --name yolo5 -d 019273956931.dkr.ecr.eu-central-1.amazonaws.com/aws-project-yolo5:$IMAGEVER

--//--
### End ###
# danielms-aws-project-yolo5
