echo "请输入项目名称，这个名称将当作创建的文件名，可以是字母、数字、下划线等"
read -p "Enter the project name: " project_name

cat << EOF > ~/myproject/${project_name}.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello There!</h1>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOF

# 创建wsgi
cat << EOF > ~/myproject/${project_name}_wsgi.py
from ${project_name} import app

if __name__ == "__main__":
    app.run()
EOF

# 创建myproject.ini
cat << EOF > ~/myproject/${project_name}.ini
[uwsgi]
module = ${project_name}_wsgi:app

master = true
processes = 5

socket = ${project_name}.sock
chmod-socket = 660
vacuum = true

die-on-term = true
EOF

# 创建服务
sudo bash -c "cat >> /etc/systemd/system/${project_name}.service"  << EOF
[Unit]
Description=uWSGI instance to serve ${project_name}
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/myproject
Environment="PATH=/home/ubuntu/myproject/myprojectenv/bin"
ExecStart=/home/ubuntu/myproject/myprojectenv/bin/uwsgi --ini ${project_name}.ini

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl start ${project_name}
# 开机自启动
sudo systemctl enable ${project_name}

# ===============Step 6 — Configuring Nginx to Proxy Requests=========
echo "请输入域名"
read your_domain

sudo bash -c "cat >> /etc/nginx/sites-available/${project_name}"  << EOF
server {
    listen 80;
    server_name ${your_domain};

    location / {
        include uwsgi_params;
        uwsgi_pass unix:/home/ubuntu/myproject/${project_name}.sock;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/${project_name} /etc/nginx/sites-enabled
sudo systemctl restart nginx
# 重启服务
sudo systemctl restart ${project_name}
echo "安装完成"
