#apt update
#
## Add Docker's official GPG key:
#apt-get install ca-certificates curl -y
#install -m 0755 -d /etc/apt/keyrings
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
#chmod a+r /etc/apt/keyrings/docker.asc
#
## Add the repository to Apt sources:
#echo \
#  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#  tee /etc/apt/sources.list.d/docker.list > /dev/null
#apt-get update

# apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# sudo usermod -aG docker ubuntu

# apt install unzip
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# ./aws/install

sudo -u ubuntu aws ecr get-login-password --region eu-central-1 | sudo -u ubuntu docker login --username AWS --password-stdin 019273956931.dkr.ecr.eu-central-1.amazonaws.com

export IMAGEVER=0.0.10
sudo -u ubuntu docker container prune -f
sudo -u ubuntu docker run -d --restart always -p 8443:8443 019273956931.dkr.ecr.eu-central-1.amazonaws.com/aws-project-polybot:$IMAGEVER


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

IMAGEVER=$(aws ecr describe-images --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --repository-name aws-project-polybot --output text)

sudo -u ubuntu aws ecr get-login-password --region eu-central-1 | sudo -u ubuntu docker login --username AWS --password-stdin 019273956931.dkr.ecr.eu-central-1.amazonaws.com

sudo -u ubuntu docker stop polybot
sudo -u ubuntu docker container prune -f
sudo -u ubuntu docker run --restart always --name polybot -d -p 8443:8443 019273956931.dkr.ecr.eu-central-1.amazonaws.com/aws-project-polybot:$IMAGEVER

--//--
### End ###
# danielms-aws-project-poly-az2
