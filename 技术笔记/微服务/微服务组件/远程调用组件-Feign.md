# Feign

## Feign远程调用

 Feign 的英文表意为“假装，伪装，变形”， 是一个http请求调用的轻量级框架，可以以Java接口注解的方式调用Http请求，而不用像Java中通过封装HTTP请求报文的方式直接调用。

Feign通过处理注解，将请求模板化，当实际调用的时候，传入参数，根据参数再应用到请求上，进而转化成真正的请求，这种请求相对而言比较直观。

Feign被广泛应用在Spring Cloud 的解决方案中，是学习基于Spring Cloud 微服务架构不可或缺的重要组件。

## Feign远程调用基本流程

1. 微服务启动时，Feign对带有@FeignClient注解的接口进行扫描；
2. 使用JDK Proxy创建远程接口的本地代理实例，并注入到IOC容器中；
3. 当远程接口被调用时，由本地Proxy代理实例去完成真正的远程访问，并返回结果。

## Feign远程调用重要组件

- #### 处理器组件Handler
  
  - ###### InvocationHandler
    
    InvocationHandler是JDK处理器；
  
  - ###### FeignInvocationHandler & HystrixInvocationHandler
    
    1. FeignInvocationHandler：是Feign默认处理器，继承自InvocationHandler；
       
       FeignInvocationHandler就只有一个invoke()方法，但是功能复杂：
       
       - 根据Java反射的方法实例，在dispatch 映射对象中，找到对应的MethodHandler 方法处理器；
       - 调用MethodHandler方法处理器的 invoke(...) 方法，完成实际的HTTP请求和结果的处理。
       
       在FeignInvocationHandler类中，维护了一个Map<Method, MethodHandler> 的dispatch对象，用于保存方法实例对象和方法处理器的映射：
       
       默认的调用处理器 FeignInvocationHandle，在处理远程方法调用的时候，会根据Java反射的方法实例，在dispatch 映射对象中，找到对应的MethodHandler 方法处理器，然后交给MethodHandler 完成实际的HTTP请求和结果的处理。
    
    2. HystrixInvocationHandler是Feign与Hystrix结合时使用的处理器，同样继承自InvocationHandler；
  
  - ###### MethodHandler
    
    MethodHandler是Feign中的方法处理接口；
    
    就只有一个invoke()方法，主要职责是完成实际远程URL请求，然后返回解码后的远程URL的响应结果。
  
  - ###### SynchronousMethodHandler
    
    是methodhandler的默认实现类，提供了基本的远程URL的同步请求处理。
    
    工作步骤：
    
    1. 首先通 RequestTemplate 请求模板实例，生成远程URL请求实例 request；
    2. 然后用自己的 feign 客户端client成员，excecute(…) 执行请求，并且获取 response 响应；
    3. 对response 响应进行结果解码。

- #### 客户端组件Client
  
  客户端组件是Feign中一个非常重要的组件，负责端到端的执行URL请求。
  
  其核心的逻辑：发送request请求到服务器，并接收response响应后进行解码。
  
  由于不同的feign.Client 实现类，内部完成HTTP请求的组件和技术不同，故，feign.Client 有多个不同的实现：
  
  - ###### Client.Default 类
    
    默认的feign.Client 客户端实现类，内部使用HttpURLConnnection 完成URL请求处理；
  
  - ###### ApacheHttpClient 类
    
    ApacheHttpClient 客户端类的内部，使用 Apache HttpClient开源组件完成URL请求的处理。
    
    ```
    从代码开发的角度而言，Apache HttpClient相比传统JDK自带的URLConnection，增加了易用性和灵活性，它不仅使客户端发送Http请求变得容易，而且也方便开发人员测试接口。既提高了开发的效率，也方便提高代码的健壮性。
    
    从性能的角度而言，Apache HttpClient带有连接池的功能，具备优秀的HTTP连接的复用能力。关于带有连接池Apache HttpClient的性能提升倍数，具体可以参见后面的对比试验。
    
    ApacheHttpClient 类处于 feign-httpclient 的专门jar包中，如果使用，还需要通过Maven依赖或者其他的方式，倒入配套版本的专门jar包。
    ```
  
  - ##### OkHttpClient类
    
    OkHttpClient 客户端类的内部，使用OkHttp3 开源组件完成URL请求处理。
    
    ```
    OkHttp3 开源组件由Square公司开发，用于替代HttpUrlConnection和Apache HttpClient。
    
    由于OkHttp3较好的支持 SPDY协议（SPDY是Google开发的基于TCP的传输层协议，用以最小化网络延迟，提升网络速度，优化用户的网络使用体验。），从Android4.4开始，google已经开始将Android源码中的 HttpURLConnection 请求类使用OkHttp进行了替换。
    
    也就是说，对于Android 移动端APP开发来说，OkHttp3 组件，是基础的开发组件之一。
    ```
  
  - ###### LoadBalancerFeignClient 类
    
    LoadBalancerFeignClient 内部使用了 Ribben 客户端负载均衡技术完成URL请求处理。
    
    ```
    在原理上，简单的使用了delegate包装代理模式：Ribben负载均衡组件计算出合适的服务端server之后，由内部包装 delegate 代理客户端完成到服务端server的HTTP请求；
    
    所封装的 delegate 客户端代理实例的类型，可以是 Client.Default 默认客户端，也可以是 ApacheHttpClient 客户端类或OkHttpClient 高性能客户端类，还可以其他的定制的feign.Client 客户端实现类型。
    ```

## Feign远程调用执行流程

由于Feign远程调用接口的JDK Proxy实例的InvokeHandler调用处理器有多种，导致Feign远程调用的执行流程，也稍微有所区别，但是远程调用执行流程的主要步骤，是一致的。

这里主要介绍两类JDK Proxy实例的InvokeHandler调用处理器相关的远程调用执行流程：

- #### 默认的调用处理器 FeignInvocationHandler 相关的远程调用执行流程；
  
  1. ###### 通过Spring IOC 容器实例，装配代理实例，然后进行远程调用；
  
  2. ###### 执行 InvokeHandler 调用处理器的invoke(…)方法；
  
  3. ###### 执行 MethodHandler 方法处理器的invoke(…)方法；
  
  4. ###### 通过 feign.Client 客户端成员，完成远程 URL 请求执行和获取远程结果。
  
  默认的与 FeignInvocationHandler 相关的远程调用执行流程，在运行机制以及调用性能上，满足不了生产环境的要求，为啥呢？ 大致原因有以下两点：
  
  （1） 没有远程调用过程中的熔断监测和恢复机制；
  
  （2） 也没有用到高性能的HTTP连接池技术。

- #### 调用处理器 HystrixInvocationHandler 相关的远程调用执行流程。
  
  HystrixInvocationHandler是支持 熔断监测和恢复机制 Hystrix 技术的远程调用执行流程。
