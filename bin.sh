#!/bin/bash
# PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
# export PATH

# 针对Ubuntu 22.04操作系统

# ===============Step 1 — Installing the Components from the Ubuntu Repositories===========
# 更新apt
sudo apt update
# 安装python3所需要的包
sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools

# Step 2 — Creating a Python Virtual Environment
# 安装python虚拟环境
sudo apt install python3-venv
sudo apt install nginx
# 创建项目目录
mkdir -p ~/myproject
# 进入项目目录
cd ~/myproject
# 创建虚拟环境
python3.10 -m venv myprojectenv
# 激活虚拟环境
source myprojectenv/bin/activate

# Step 3 — Setting Up a Flask Application
pip install wheel
pip install uwsgi flask

cat << EOF > ~/myproject/myproject.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello There!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOF


# 创建wsgi
cat << EOF > ~/myproject/wsgi.py
from myproject import app

if __name__ == "__main__":
    app.run()
EOF

# 退出环境
deactivate

# 创建myproject.ini
cat << EOF > ~/myproject/myproject.ini
[uwsgi]
module = wsgi:app

master = true
processes = 5

socket = myproject.sock
chmod-socket = 660
vacuum = true

die-on-term = true
EOF

# 创建服务
sudo bash -c "cat >> /etc/systemd/system/myproject.service"  << EOF
[Unit]
Description=uWSGI instance to serve myproject
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/myproject
Environment="PATH=/home/ubuntu/myproject/myprojectenv/bin"
ExecStart=/home/ubuntu/myproject/myprojectenv/bin/uwsgi --ini myproject.ini

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl start myproject

# 分配组
sudo chgrp www-data /home/ubuntu

# ===============Step 6 — Configuring Nginx to Proxy Requests=========
echo "请输入域名"
read your_domain
cat << EOF > /etc/nginx/sites-available/myproject
server {
    listen 80;
    server_name $your_domain;

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/ubuntu/myproject/myproject.sock;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
sudo ufw allow 'Nginx Full'
sudo systemctl restart nginx

echo "安装完成"
