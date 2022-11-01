# Spring Cloud Config

## Spring Cloud Config

Spring cloud Config配置中心，使用Git/Svn等版本控制器来存放和管理配置信息；

没有图形管理界面，没有数据库。

## Spring Cloud Config核心组件

- #### Config Server
  
  缓存配置文件的服务器(用于缓存 git 服务器上的配置文件（服务名称-环境.properties）信息)；

- #### Config Client
  
  读取 ConfigServer 配置文件信息；

## Spring Cloud Config实现原理

1. 用户提交配置文件信息到版本控制器:git/SVN 服务器上存放；

2. ConfigServer 缓存从 git 服务器上获取到的配置文件信息；

3. ConfigClient 端从 ConfigServer 端获取配置文件信息。

## Spring Cloud Config 配置文件实时刷新

- 默认情况下不能实时刷新配置文件信息,需要重启服务器才能刷新配置文件,这样不是很方便

- ###### SpringCloud Config 分布式配置中心支持手动刷新和自动刷新:
  
  - **手动刷新:** 需要人工调用接口，读取最新配置文件信息 -- SpringBoot Actuator监控中心
    
    ```
      SpringBoot Actuator监控中心
      1.引入actuator依赖spring-boot-starter-actuator
      2.在配置文件中开启监控端点
      management.endpoints.web.exposure.include="*"    # 开启所有端点
      3.启动运行configClient
      4.在需要刷新的controller类中的bean当标注@RefreshScope注解使actuator刷新生效
    ```
  
  - **自动刷新:** 消息总线进行实时通知--SpringCloudBus
    
    ```
    SpringCloudBus 通过一个轻量级消息代理连接分布式系统的节点（有点像消息队列那种）。
    
    这可以用于广播状态更改（如配置更改）或其他管理指令。
    
    SpringCloudBus提供了通过post方法访问的endpoint/bus/refresh（spring boot 有很多监控的endpoint，比如/health），这个接口通常由git的钩子功能（监听触发）调用，用以通知各个SpringCloudConfig的客户端去服务端更新配置。
    ```
