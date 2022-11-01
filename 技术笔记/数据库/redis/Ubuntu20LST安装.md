# Ubuntu 20LST安装Redis

## 1、安装

安装，安装完成后，Redis服务将自动启动；

```shell
sudo apt update
sudo apt install redis-server
```

检查服务的状态

```shell
sudo systemctl status redis-server
```

会显示

```
● redis-server.service - Advanced key-value store
     Loaded: loaded (/lib/systemd/system/redis-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2020-06-06 20:03:08 UTC; 10s ago
...
```

## 2、配置远程访问

1、编辑redis.conf文件

```shell
sudo vim /etc/redis/redis.conf
```

修改文件内容

```
1. bind 127.0.0.1改为 #bind 127.0.0.1 (注释掉)
2. protected-mode yes 改为 protected-mode no
3. 加入 daemonize no(这个是是否在后台启动不占用一个主程窗口)
```

2、重新启动Redis服务以使更改生效

```
sudo systemctl restart redis-server
```

3、打开防火墙

a. 自己服务器

```shell
sudo ufw allow proto tcp from 192.168.121.0/24 to any port 6379
```

b. 阿里/腾讯等云上服务器，去相关配置页面配置规则；





