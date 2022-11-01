# Nginx



Nginx 是一个高性能的 HTTP 反向代理服务器，特点是占用内存少，并发能力强，事实上 Nginx 的并发能力确实在同类型的网页服务器中表现较好。

Nginx 专为性能优化而开发，性能是其最重要的要求，十分注重效率，有报告 Nginx 能支持高达 50000 个并发连接数。

Nginx支持：反向代理、负载均衡、动/静态资源分离、高可用等功能。



## 基本命令

查看版本：

```
nginx -v
```

启动：

```
nginx
```

关闭（有三种方式，推荐使用nginx -s quit）：

```
nginx -s stop
nginx -s quit
killall nginx # 直接杀死进程
```

重新加载 Nginx 配置：

```
nginx -s reload
```



## 配置文件：nginx.conf

```shell
########每个指令必须有分号结束#################
#### 全局块
#user administrator administrators;              #配置用户或者组，默认为nobody nobody。
#worker_processes 2;                             #允许生成的进程数，默认为1
#pid /nginx/pid/nginx.pid;                       #指定nginx进程运行文件存放地址
error_log log/error.log debug;                   #制定日志路径，级别。
                                                 #这个设置可以放入全局块，http块，server块，
                                                 #级别以此为：debug|info|notice|warn|error|crit|alert|emerg
####Events事件块
events {
    accept_mutex on;                             #设置网路连接序列化，防止惊群现象发生，默认为on
    multi_accept on;                             #设置一个进程是否同时接受多个网络连接，默认为off
    #use epoll;                                  #事件驱动模型，select|poll|kqueue|epoll|resig|/dev/poll|eventport
    worker_connections  1024;                    #最大连接数，默认为512
}

####Http块
http {
    include       mime.types;                    #文件扩展名与文件类型映射表
    default_type  application/octet-stream;      #默认文件类型，默认为text/plain
    #access_log off;                             #取消服务日志    
    log_format myFormat '$remote_addr–$remote_user [$time_local] $request $status $body_bytes_sent $http_referer $http_user_agent  $http_x_forwarded_for';                          #自定义格式
    access_log log/access.log myFormat;          #combined为日志格式的默认值
    sendfile on;                                 #允许sendfile方式传输文件，默认为off，可以在http块，server块，location块。
    sendfile_max_chunk 100k;                     #每个进程每次调用传输数量不能大于设定的值，默认为0，即不设上限。
    keepalive_timeout 65;                        #连接超时时间，默认为65s，可以在http，server，location块。

    upstream mysvr {   
      server 127.0.0.1:7878;
      server 192.168.10.121:3333 backup;         #热备
    }
    
    error_page 404 https://www.baidu.com;        #错误页
    server {
        keepalive_requests 120;                  #单连接请求上限次数。
        listen       4545;                       #监听端口
        server_name  127.0.0.1;                  #监听地址       
        location  ~*^.+$ {                       #请求的url过滤，正则匹配，~为区分大小写，~*为不区分大小写。
           #root path;                           #根目录
           #index vv.txt;                        #设置默认页
           proxy_pass  http://mysvr;             #请求转向mysvr 定义的服务器列表
           deny 127.0.0.1;                       #拒绝的ip
           allow 172.18.5.54;                    #允许的ip           
        } 
    }
}
```

nginx.conf分三部分组成：

- ##### 全局块

  主要设置一些影响 nginx 服务器整体运行的配置指令。
  比如： worker_processes 1; ， worker_processes 值越大，可以支持的并发处理量就越多。

- ##### events 事件块

  events 块涉及的指令主要影响Nginx服务器与用户的网络连接。
  比如： worker_connections 1024; ，支持的最大连接数。

- ##### HTTP 块

  诸如反向代理和负载均衡都在此配置。

  **http配置块中可以配置多个server块**，而每个server块就相当于一个虚拟主机；

  **在server块中可以同时包含多个location块**。

  - **server块**：配置虚拟主机的相关参数。

  - **location块**：配置请求路由，以及各种页面的处理情况。

    ```
    location[ = | ~ | ~* | ^~] url{
    
    }
    ```

    location 指令说明，该语法用来匹配 url，语法如上：

    - **=：**用于不含正则表达式的 url 前，要求字符串与 url 严格匹配，匹配成功就停止向下搜索并处理请求。
    - **~：**用于表示 url 包含正则表达式，并且区分大小写。
    - **~\*：**用于表示 url 包含正则表达式，并且不区分大小写。
    - **^~：**用于不含正则表达式的 url 前，要求 Nginx 服务器找到表示 url 和字符串匹配度最高的 location 后，立即使用此 location 处理请求，而不再匹配。
    - 如果有 url 包含正则表达式，不需要有 ~ 开头标识。

  



## Nginx功能

#### 反向代理

- **正向代理**：客户端发送请求至代理服务器，代理服务器将请求转发给目标服务器，**客户端与代理服务器处于同LAN内**；
- **反向代理**：客户端发送请求至代理服务器，代理服务器将请求转发给目标服务器，**代理服务器与目标服务器处于同LAN内**。

##### 反向代理配置

在location中使用**proxy_pass**配置需要转发到的目标服务器地址

##### 反向代理的好处

- 屏蔽目标服务器的真实地址，相对安全性较好；

- nginx的性能好，便于配置负载均衡和动静分离功能，合理利用服务器资源。

- 统一入口，当做负载均衡时，不管目标服务器怎么扩展部署，调用者只访问代理服务器入口即可。

  

### 负载均衡

##### nginx负载均衡策略

默认情况下，nginx的负载均衡策略为**“轮询”**

- **轮询**：默认配置，指每个请求按照请求顺序逐一分配到不同到目标服务器，如果目标服务器有宕机的，还能自动剔除。

- **权重**：通过配置权重参数（weight）来实现请求分配，目标服务器配置的权重越高，被分配的请求越多。

  ```shell
  # 在每个目标服务器后面增加权重参数（weight）
  upstream mysvr {
          server 127.0.0.1:5000 weight=5;
          server 127.0.0.1:6000 weight=10;
  }
  ```

- **ip_hash**：每个请求有对应的ip，通过对ip进行hash计算，根据这个结果就能访问到指定的目标服务器；这种方式可以保证对应客户端固定访问到对应的目标服务器；

  ```shell
  upstream mysvr {
          ip_hash; # 指定策略为通过ip进行hash之后转发
          server 127.0.0.1:5000;
          server 127.0.0.1:6000;
  }
  ```

- **fair**：按目标服务器的响应时间来分配请求，响应时间短的优先被分配；这种模式需要额外安装nginx-upstream-fair插件。

  ```shell
  # 增加fair策略
  upstream mysvr {
          fair; # 指定策略为fair
          server 127.0.0.1:5000;
          server 127.0.0.1:6000;
  }
  ```

  

### 动/静态资源分离

将静态资源(如html、js、css、图片等)单独部署一个站点，关于WebAPI获取和处理信息单独部署为一个站点。

通过location匹配规则，将匹配的请求进行不同的处理。

```shell
# 静态资源配置
location /img/ {
    root resorces;
    index index.htm index.html;
}
```



### 高可用

nginx实现高可用的方式和Redis的主从模式很相似，只是nginx使用的是keepalived来实现高可用集群。

##### keepalived简介

**keepalived**实现高可用的关键思路还是主、备节点的来回切换；

- 首先需要**配置一个VIP(虚拟IP)**，用于提供访问的接口地址，刚开始是在主节点上的；
- 当主节点发生故障时，VIP就漂移到备节点，由备节点提供服务；
- 如果主节点恢复，会通知备节点健康状态，VIP就会漂移到主节点；

由上可见，在keepalive实现高可用时，肯定要有机制选择主备节点，主备之间肯定要互相通知，不然咋知道节点之间的健康状态，所以就使用了VRRP协议，目的就是为了解决静态路由的单点故障。

**VRRP协议，全称Virtual Router Redundancy Protocol(虚拟路由冗余协议)，利用IP多播的方式实现通信**；通过**竞选协议机制**(根据配置的优先级来竞选)来将路由任务交给某台VRRP路由器，保证服务的连续性；

参考博客：https://www.cnblogs.com/zoe-zyq/p/14843709.html



