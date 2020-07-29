#!/bin/bash
export DB_HOST="mongodb://${db_host}:27017/posts"

cd /home/ubuntu/web-app
npm install
pm2 start app.js

sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

node seeds/seed.js