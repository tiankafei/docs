# docker启动软件命令的记录

## docker 启动nacos

### nacos版本：1.3.1

#### 拉取镜像

```sh
docker pull nacos/nacos-server:1.3.1
```

#### 单机启动命令

```sh
## 启动命令
sudo docker run -d -p 8848:8848 \
-e MODE=standalone \
-e PREFER_HOST_MODE=nacos-server \
-e NACOS_SERVER_IP=${nacos_ip} \
-e SPRING_DATASOURCE_PLATFORM=${db_type} \
-e MYSQL_SERVICE_HOST=${db_ip} \
-e MYSQL_SERVICE_PORT=${db_port} \
-e MYSQL_SERVICE_USER=${db_username} \
-e MYSQL_SERVICE_PASSWORD=${db_password} \
-e MYSQL_SERVICE_DB_NAME=nacos-server \
--restart=always \
--name nacos-server \
nacos/nacos-server:1.3.1

## 示例
sudo docker run -d -p 8848:8848 \
-e MODE=standalone \
-e PREFER_HOST_MODE=nacos-server \
-e NACOS_SERVER_IP=10.10.50.131 \
-e SPRING_DATASOURCE_PLATFORM=mysql \
-e MYSQL_SERVICE_HOST=10.10.50.83 \
-e MYSQL_SERVICE_PORT=3306 \
-e MYSQL_SERVICE_USER=tjcp \
-e MYSQL_SERVICE_PASSWORD=tjcp \
-e MYSQL_SERVICE_DB_NAME=nacos-server \
--restart=always \
--name nacos-server \
nacos/nacos-server:1.3.1
```

#### 停止nacos容器

```
docker stop nacos-server
```

#### 删除nacos容器

```
docker rm nacos-server
```

## docker 启动seata

### seata版本：1.3.0

#### 启动步骤：

```http
https://www.cnblogs.com/binz/p/12841125.html
```

#### 拉取镜像

```
sudo docker pull seataio/seata-server:1.3.0
```

#### 单机启动命令

```sh
## 启动命令
sudo docker run -d --restart always  \
--name seata-server \
-p 8091:8091  \
-v ${seata_home}:/seata-server \
-e SEATA_IP=${seata_ip} \
-e SEATA_PORT=${seata_Port}  \
--link nacos-server \
seataio/seata-server:1.3.0 

## 示例
sudo docker run -d --restart always  \
--name seata-server \
-p 8091:8091  \
-v /home/zwapp/seata/seata1.3/seata-server:/seata-server \
-e SEATA_IP=10.10.50.131 \
-e SEATA_PORT=8091  \
--link nacos-server \
seataio/seata-server:1.3.0 
```

#### 停止seata容器

```
docker stop seata-server
```

#### 删除seata容器

```
docker rm seata-server
```

## Dockerfile文件配置

```dockerfile
FROM hub.c.163.com/library/java:8u111-jdk

MAINTAINER lanruifeng lanruifeng@thtf.com.cn

VOLUME /tmp
VOLUME /logs

ADD jl-mlbd*.jar mlbd.jar
ENV ACTIVES=test

EXPOSE 7020

ENTRYPOINT ["java", "-jar", "/mlbd.jar", "--spring.profiles.active=${ACTIVES}"]

```

## 构建镜像脚本

```sh
#!/bin/bash
applicationName=$1
port=$2
active=$3
# 停止容器
sudo docker stop ${applicationName}
# 删除容器
sudo docker rm ${applicationName}
# 删除镜像
sudo docker rmi ${applicationName}:1.0
# 构建镜像
sudo docker build -t ${applicationName}:1.0 .
# 根据镜像启动容器
sudo docker run -d -p ${port}:${port} --name ${applicationName} -v /home/zwapp/tjcp-log/${applicationName}:/logs/ -v /usr/share/fonts:/usr/share/fonts -e ACTIVES=${active} --link nacos-server ${applicationName}:1.0
```



