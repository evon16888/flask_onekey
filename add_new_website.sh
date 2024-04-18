echo "请输入项目名称，这个名称将当作创建的文件名，可以是字母、数字、下划线等"
read project_name

cat << EOF > ~/myproject/$project_name.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello There!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOF

# 以上测试通过

# 创建wsgi
cat << EOF > ~/myproject/wsgi.py
from myproject import app

if __name__ == "__main__":
    app.run()
EOF

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
# 开机自启动
sudo systemctl enable myproject

# ===============Step 6 — Configuring Nginx to Proxy Requests=========
echo "请输入域名"
read your_domain

sudo bash -c "cat >> /etc/nginx/sites-available/myproject"  << EOF
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
sudo systemctl restart nginx
# 重启服务
sudo systemctl restart myproject
echo "安装完成"
