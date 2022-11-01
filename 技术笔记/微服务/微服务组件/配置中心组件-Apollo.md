# Apollo

## Apollo简介

Apollo（阿波罗）是携程框架部研发并开源的一款生产级的配置中心产品；

它能够集中管理应用在不同环境、不同集群的配置，配置修改后能够实时推送到应用端；

并且具备规范的权限、流程治理等特性，适用于微服务配置管理场景。

## Apollo架构与模块

Apollo 采用分布式微服务架构；

Apollo 内部分为七个模块：四个核心模块，三个辅助模块；

- ### 四个核心模块（功能相关）
  
  1. ##### ConfigService
     
     - 提供配置获取接口
     - 提供配置推送接口
     - 服务于 Apollo 客户端
  
  2. ##### AdminService
     
     - 提供配置管理接口
     - 提供配置修改发布接口
     - 服务于管理界面 Portal
  
  3. ##### Client
     
     - 为应用获取配置，支持实时更新
     - 通过 MetaServer 获取 ConfigService 的服务列表
     - 使用客户端软负载 SLB 方式调用 ConfigService
  
  4. ##### Portal
     
     - 配置管理界面
     - 通过 MetaServer 获取 AdminService 的服务列表
     - 使用客户端软负载 SLB 方式调用 AdminService

- ### 三个辅助模块（服务发现）
  
  1. **Eureka**
     - 用于服务发现和注册
     - Config/AdminService 注册实例并定期报心跳
     - 和 ConfigService 住在一起部署
  2. **MetaServer**
     - Portal 通过域名访问 MetaServer 获取 AdminService 的地址列表
     - Client 通过域名访问 MetaServer 获取 ConfigService 的地址列表
     - 相当于一个 Eureka Proxy
     - 逻辑角色，和 ConfigService 住在一起部署
  3. **NginxLB**
     - 和域名系统配合，协助 Portal 访问 MetaServer 获取 AdminService 地址列表
     - 和域名系统配合，协助 Client 访问 MetaServer 获取 ConfigService 地址列表
     - 和域名系统配合，协助用户访问 Portal 进行配置管理

## Apollo架构

[apollo架构](https://www.infoq.cn/article/ctrip-apollo-configuration-center-architecture)

## Apollo如何实现动态更新

###### 步骤

1. 在 Apollo 控制台进行配置修改并发布后，对应的 client 端拉取到更新后，会调用到 AutoUpdateConfigChangeListener.onChange()方法；

2. 在调用 onChange 会收到对应的修改的配置信息 ConfigChangeEvent， 其中包含改动的 key 和 value, 则改动流程如下：
   
   2.1. 根据改动的配置的 key 从 springValueRegistry 找到对应的关联到这个 key 的 Spring Bean 信息，如果找不到则不处理；
   
   2.2. 根据找到的 Spring Bean 信息，进行对应关联配置的更新。

###### 问题：如何将配置 key 和 Spring Bean 关联起来

在 Apollo 代码中，通过实现 BeanPostProcessor 接口来检测所有的Spring Bean 的创建过程；

在 Spring Bean 创建的过程中会调用对应的 postProcessBeforeInitialization()方法postProcessAfterInitialization()方法；

Apollo 通过在 Bean 生成过程中，检测 Bean 类中属性和方法是否存在 `@Value` 注解；

如果存在，提出其中的 key, 其处理方法在 processField` 和 `processMethod分别处理 Field 和 Method 中可能出现的 @Value注解；

如果存在注解则将对应的信息存到 SpringValue` 对应 `springValueRegistry全局对象中，方便在其它地方可以直接获取。

在属性除了通过 @Value注入，也可以用过 xml 进行配置，在这种情况通过 processBeanPropertyValues方法来处理；

## 总结

1. ConfgService/AdminService/Client/Portal 是 Apollo 的四个核心微服务模块，相互协作完成配置中心业务功能，Eureka/MetaServer/NginxLB 是辅助微服务之间进行服务发现的模块。
2. Apollo 采用微服务架构设计，架构和部署都有一些复杂，但是每个服务职责单一，易于扩展。另外，Apollo 只需要一套 Portal 就可以集中管理多套环境 (DEV/FAT/UAT/PRO) 中的配置，这个是它的架构的一大亮点。
3. 服务发现是微服务架构的基础，在 Apollo 的微服务架构中，既采用 Eureka 注册中心式的服务发现，也采用 NginxLB 集中 Proxy 式的服务发现。
4. 配置的实时更新，是通过监控和管理@Value注解的JavaBean实现；
