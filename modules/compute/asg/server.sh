#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
#set -xe

# =========================================
# COMMANDS TO RUN IN THE APPLICATION SERVER
# =========================================

# ======================================
# INSTALLING MYSQL IN AMAZON LINUX 2023
# ======================================
# (REF: https://dev.to/aws-builders/installing-mysql-on-amazon-linux-2023-1512)



sudo -su ec2-user

# COPY APP CODE
cd /home/ec2-user
aws s3 cp s3://${bucket_name}/application-code/app-tier app-tier --recursive

echo "========== Preparing SQL schema =========="
cp app-tier/appdb.sql /tmp/appdb.sql


sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
sudo dnf install mysql-community-client -y
mysql --version

# TO TEST CONNECTION BETWEEN APP-SERVER & DATABASE SERVER
# mysql -h "${db_host}" \
#       -u "${db_username}" \
#       -p"${db_password}" <<EOF
# CREATE DATABASE IF NOT EXISTS react_node_app;
# SHOW DATABASES;
# USE react_node_app;
# CREATE TABLE IF NOT EXISTS transactions(id INT NOT NULL
# AUTO_INCREMENT, amount DECIMAL(10,2), description
# VARCHAR(100), PRIMARY KEY(id));    
# SHOW TABLES;    
# INSERT INTO transactions (amount,description) VALUES ('400','groceries');   
# SELECT * FROM transactions;
# EOF


# TO TEST CONNECTION BETWEEN APP-SERVER & DATABASE SERVER and instert database schema

mysql -h "${db_host}" \
      -u "${db_username}" \
      -p"${db_password}" < /tmp/appdb.sql


#===============================
# COPYING CONTENT FROM S3 BUCKET
#===============================
# !!! IMP !!!
# MODIFY BELOW CODE WITH YOUR S3 BUCKET NAME
# # COPY APP CODE
# cd /home/ec2-user
# aws s3 cp s3://${bucket_name}/application-code/app-tier app-tier --recursive
# or
# sudo yum install git -y
# git clone https://github.com/pandacloud1/AWS_Project1.git application-code

# sudo sed -i "s/DB_HOST : ''/DB_HOST : \"${db_host}\"/" app-tier/DbConfig.js
# sudo sed -i "s/DB_USER : ''/DB_USER : \"${db_username}\"/" app-tier/DbConfig.js
# sudo sed -i "s/DB_PWD  : ''/DB_PWD  : \"${db_password}\"/" app-tier/DbConfig.js
# sudo sed -i "s/DB_DATABASE : ''/DB_DATABASE : \"${db_name}\"/" app-tier/DbConfig.js


sudo sed -i "s/<secret-name>/${db_secret_name}/g" app-tier/DbConfig.js
sudo sed -i "s/<region>/${aws_region}/g" app-tier/DbConfig.js

chown -R ec2-user:ec2-user /home/ec2-user/app-tier
chmod -R 755 /home/ec2-user/app-tier

#===============================
# INSTALLING NODEJS
#===============================
# (REF: https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html)

# RUN NVM/Node/PM2 AS ec2-user
sudo runuser -l ec2-user -c '
# set -xe
export HOME=/home/ec2-user
export NVM_DIR="$HOME/.nvm"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 16 and set default
nvm install 16
nvm alias default 16
nvm use 16

# Install dependencies and PM2
npm install -g pm2
cd /home/ec2-user/app-tier
npm install
npm audit fix || true

#===============================
# STARTING INDEX.JS FILE
#===============================
# Start app with PM2
pm2 start index.js
pm2 startup systemd -u ec2-user --hp /home/ec2-user
'
sudo env PATH=$PATH:/home/ec2-user/.nvm/versions/node/v16.20.2/bin /home/ec2-user/.nvm/versions/node/v16.20.2/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
sudo runuser -l ec2-user -c 'pm2 save'

# HEALTH CHECK
curl -f http://localhost:4000/health || echo "Health check failed"

# Install CloudWatch agent
sudo yum install -y amazon-cloudwatch-agent
export LOG_DIR="/home/ec2-user/.pm2/logs"
# Create CloudWatch agent configuration
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOL
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "$LOG_DIR/index-out.log",
            "log_group_name": "node-app-logs-backend",
            "log_stream_name": "{instance_id}-index-out-log",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "$LOG_DIR/index-error.log",
            "log_group_name": "node-app-logs-backend",
            "log_stream_name": "{instance_id}-index-error-log",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOL

# Start CloudWatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s



#/etc/systemd/system/pm2-ec2-user.service.
