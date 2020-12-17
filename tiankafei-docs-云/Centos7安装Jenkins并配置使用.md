# Centos7安装Jenkins并配置使用

## Tomcat安装并设置开机启动

### 拷贝tomat到指定目录

```sh
cp apache-tomcat-9.0.30.tar.gz /opt/software/
```

### 进入指定目录并解压tomcat

```sh
cd /opt/software/
tar -zvxf apache-tomcat-9.0.30.tar.gz
```

### 删除原压缩包

```sh
rm -rf apache-tomcat-9.0.30.tar.gz
```

### 设置tomcat启动的配置文件

```sh
vi /etc/systemd/system/tomcat.service
```

```shell
[Unit]
Description=Tomcat8080
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=oneshot
ExecStart=/opt/software/apache-tomcat-9.0.30/bin/startup.sh
ExecStop=/opt/software/apache-tomcat-9.0.30/bin/shutdown.sh
ExecReload=/bin/kill -s HUP $MAINPID
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

### 设置开机启动

```sh
sudo systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat
systemctl status tomcat
```

## Jenkin安装

### 下载Jenkins安装使用的war包

```http
http://mirrors.jenkins.io/war-stable/latest/jenkins.war
```

### 把jenkins.war拷贝到tomcat的webapp目录下

```sh
cp jenkins.war /opt/software/apache-tomcat-9.0.30/webapps/
```

### 可以通过以下地址进行访问

```http
# http://ip:tomcat的端口/jenkins
http://software:8080/jenkins/
```

### 接下来就根据提示步骤一步一步往下安装即可

## docker下安装jenkins

### 拉取镜像

```shell
docker pull jenkins/jenkins:lts
```

### 启动jenkins

```shell
mkdir -p /opt/jenkins/data

docker run -d --name jenkins -v /opt/jenkins/data:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
```

### 启动失败，查看日志

```shell
## 查看容器id
docker ps -a
## 查看容器日志
docker logs 容器id
```

### 出现的问题

```
touch: cannot touch '/var/jenkins_home/copy_reference_file.log': Permission denied
Can not write to /var/jenkins_home/copy_reference_file.log. Wrong volume permissions?
```

### 解决方案

```
使用docker安装jenkins，运行容器是出现错误：

touch: cannot touch '/var/jenkins_home/copy_reference_file.log': Permission denied

出现这样的问题，是因为将docker内的jenkins卷映射到本地磁盘时，权限不对。默认情况下，映射到本地磁盘的权限用户是root,但是容器中jenkins user的uid为1000

执行如下命令即可解决：

chown -R 1000:1000 /opt/jenkins/data/
```

### 访问地址

```http
http://192.168.0.22:8080
```

