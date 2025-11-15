#!/bin/bash
set -euo pipefail

# bucket_name=$1
# internal_alb_dns_name=$2

# =========================================
# COMMANDS TO RUN IN THE WEB SERVER
# =========================================

# =========================================
# COPY WEB-TIER CODE FROM S3
# =========================================
exec > >(tee /var/log/user-data.log) 2>&1
# sudo -su ${ssh_username} # when ssh_pty = true this is not required
cd /home/${ssh_username}

# !!! IMP !!!
# MODIFY BELOW CODE WITH YOUR S3 BUCKET NAME
sudo aws s3 cp s3://${bucket_name}/application-code/web-tier web-tier --recursive
sudo chown -R ${ssh_username}:${ssh_username} /home/${ssh_username}
sudo chmod -R 755 /home/${ssh_username}

# =========================================
# INSTALLING NODEJS (FOR USING REACT LIBRARY)
# =========================================
# (REF: https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html)	
sudo runuser -l ${ssh_username} -c "
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 16
nvm use 16
cd /home/${ssh_username}/web-tier
npm install
npm audit fix

# =========================================
# BUILDING THE APP FOR PRODUCTION
# =========================================
# Below command is used to build the code which can be served by the webserver (Nginx)
cd /home/${ssh_username}/web-tier
npm run build
"
# =========================================
# INSTALLING NGINX (WEBSERVER)
# =========================================
# (REF: https://dev.to/0xfedev/how-to-install-nginx-as-reverse-proxy-and-configure-certbot-on-amazon-linux-2023-2cc9)
# NOTE: Before using the nginx.conf file in below code, ensure to add the Internal-Load-Balancer-DNS in the nginx.conf file & upload it to S3

sudo yum install nginx -y	
cd /etc/nginx
sudo mv nginx.conf nginx-backup.conf

# !!! IMP !!!
# MODIFY BELOW CODE WITH YOUR S3 BUCKET NAME
sudo aws s3 cp s3://${bucket_name}/application-code/nginx.conf .
sudo sed -i "s/<Your-Internal-LoadBalancer-DNS>/${internal_alb_dns_name}/g" nginx.conf

sudo chmod -R 755 /home/${ssh_username}
sudo service nginx restart
sudo chkconfig nginx on

# Install CloudWatch agent
sudo yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOL
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
         {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "nginx-logs-app-frontend",
            "log_stream_name": "{instance_id}-nginx-access",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "nginx-logs-app-frontend",
            "log_stream_name": "{instance_id}-nginx-error",
            "timestamp_format": "%b %d %H:%M:%S"
          }
          
        ]
      }
    }
  }
}
EOL

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s



