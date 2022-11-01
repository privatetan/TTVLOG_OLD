# 微服务框架---Dubbo

## 1、Dubbo介绍

Apache Dubbo 是一款微服务开发框架，它提供了 **RPC通信** 与 **微服务治理** 两大关键能力；

## 2、Dubbo框架设计

![整体设计](./img/dubbo-framework.jpg)

层级说明：

1、Config配置层：对外配置接口，以ServiceConfig，ReferenceConfig为中心，可以直接初始化配置类，也可以通过spring解析配置生成配置类；

2、Proxy服务代理层：服务接口透明代理，生成服务的客户端Stub和服务器端Skeleton，以ServiceProxy为中心，扩展接口为ProxyFactory；

3、Registry注册中心层：封装服务地址的注册与发现，以服务URL为中心，扩展接口为registryFactory，Registry，RegistryService；

4、Cluster路由层：封装多个提供者的路由及负载均衡，并桥接注册中心，以Invoker为中心，扩展接口为Cluster，Directory，Router，LoadBalance；

5、Monitor监控层：RPC调用次数和调用时间监控，以Statistics为中心，扩展接口为MonitorFactory，Monitor，MonitorService；

6、Protocol远程调用层：封装RPC调用，以Invocation，Result为中心，扩展接口为Protocol，Invoker，Exporter；

7、Exchange信息交换层：封装请求响应模式，同步转异步，以Request，Response为中心，扩展接口为Exchanger，ExchangeChannel，ExchangeClient，ExchangeServer；

8、Transport网络传输层：抽象mina和Netty为统一接口，以Message为中心，扩展接口为Channel，Transporter，Client，Server，Codec；

9、Serialize数据序列化层：可复制一些工具，扩展接口为Serialization，ObjectInput，ObjectInput，ThreadPool；

关系说明：

1、在RPC中，Protocol是核心层，只要有Protocol+Invoker+Exporter就可以完成非透明的RPC调用，然后在Invoker的主过程上Filter拦截点；

2、Consumer和Provider是抽象概念，表示客户端与服务器端；