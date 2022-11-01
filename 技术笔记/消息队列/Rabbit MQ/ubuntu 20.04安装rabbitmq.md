# Ubuntu 20.04安装RabbitMQ

## 安装过程

官网提供了一个shell脚本，如下：

```shell
#!/bin/sh

## If sudo is not available on the system,
## uncomment the line below to install it
# apt-get install -y sudo

sudo apt-get update -y

## Install prerequisites
sudo apt-get install curl gnupg -y

## Install RabbitMQ signing key
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -

## Install apt HTTPS transport
sudo apt-get install apt-transport-https

## Add Bintray repositories that provision latest RabbitMQ and Erlang 23.x releases
sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang
deb https://dl.bintray.com/rabbitmq/debian bionic main
EOF

## Update package indices
sudo apt-get update -y

## Install rabbitmq-server and its dependencies
sudo apt-get install rabbitmq-server -y --fix-missing
```

## 启动过程及常用命令

```shell
# 启动 rabbitmq 服务
sudo service rabbitmq-server start

# 关闭 rabbitmq 服务
sudo service rabbitmq-server stop

# 重启 rabbitmq 服务
sudo service rabbitmq-server restart

# 查看 rabbitmq 状态
sudo service rabbitmq-server status
```

注意，启动rabbitmq之后要启动管理服务插件，否则15672管理页面无法登录

```shell
# 启用 rabbitmq_manager
sudo rabbitmq-plugins enable rabbitmq_management
```

其次，guest用户默认只能在localhost登录，所以我们需要创建一个新的用户：

```shell
##设置账号密码
[root@rabbitmq1 ebin]# rabbitmqctl add_user admin 123456
Adding user "admin" ...
[root@rabbitmq1 ebin]# rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
Setting permissions for user "admin" in vhost "/" ...
[root@rabbitmq1 ebin]# rabbitmqctl set_user_tags admin administrator
Setting tags for user "admin" to [administrator] ...
```

安装完毕！

注意：

###### 5672端口与15672端口

1. **5672, 5671 (AMQP 0-9-1 without and with TLS)**
   
   AMQP 是 Advanced Message Queuing Protocol 的缩写，一个提供统一消息服务的应用层标准高级消息队列协议，是应用层协议的一个开放标准，专为面向消息的中间件设计。基于此协议的客户端与消息中间件之间可以传递消息，并不受客户端/中间件不同产品、不同的开发语言等条件的限制。Erlang 中的实现有 RabbitMQ 等。

2. **15672 (if management plugin is enabled)**
   
   通过 `http://serverip:15672` 访问 RabbitMQ 的 Web 管理界面，默认用户名密码都是 guest。（注意：RabbitMQ 3.0之前的版本默认端口是55672，下同）。


