#!/bin/bash
apt-get update -y
apt-get install -y apache2 nodejs npm
systemctl start apache2
npm install -y express aws-sdk multer multer-s3 uuid
sudo npm install pm2 -g
sudo -u ubuntu sh -c "cd /home/ubuntu; git clone https://github.com/liamvu2501/Terraform_Projects.git; cp -v ~/Terraform_Projects/Thumbnail_Resized/app_frontend/app.js ~/; cp -v ~/Terraform_Projects/Thumbnail_Resized/app_frontend/index.html ~/; sed -i \"s/MyRegion/${region}/g\" ~/app.js; sed -i \"s/S3BucketIn/${tfbucket_in}/g\" ~/app.js; sed -i \"s/S3BucketOut/${tfbucket_out}/g\" ~/app.js; sed -i \"s/MyTableName/${dynamodb_name}/g\" ~/app.js; pm2 start app.js"
