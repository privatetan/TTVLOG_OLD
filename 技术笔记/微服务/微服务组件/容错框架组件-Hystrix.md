# Hystrix

## Hystrix

Hystrix是Netflix开源的一款容错框架；

包含常用的容错方法：线程池隔离、信号量隔离、熔断、降级回退；

是用于高并发场景下构建稳定系统的容错机制。

## Hystrix容错方法

#### 1. 线程池隔离

解决线程阻塞，导致的服务器资源占用大而不可用的问题；

###### Hystrix是如何通过线程池实现线程隔离的

Hystrix通过命令模式，将每个类型的业务请求封装成对应的命令请求Command。

每个类型的Command对应一个线程池，创建好的线程池被放入到ConcurrentHashMap中的，第二次请求时，直接Map中获取该线程池。

执行Command的四种方式：

- execute()：以同步堵塞方式执行run()；
- queue()：以异步非堵塞方式执行run()；
- observe()：事件注册前执行run()/construct()；
- toObservable()：事件注册后执行run()/construct()。

执行依赖服务的线程与请求线程采用异步编程，Hystrix是结合RxJava来实现的异步编程。

通过设置线程池大小来控制并发访问量，当线程饱和的时候可以拒绝服务，防止依赖问题扩散。

尽管线程池提供了线程隔离，我们的客户端底层代码也必须要有超时设置，不能无限制的阻塞以致线程池一直饱和。

#### 2. 信号量隔离

信号量隔离采用同步编程，即执行以来服务线程与请求线程使用同一个线程执行；

不涉及远程RPC调用（没有网络开销，如访问内存缓存）则使用信号量来隔离，更为轻量、开销更小。

#### 3. 熔断

熔断器，就相当于电路保险丝，保护电器及电路；

###### Hystrix熔断器：

Hystrix在运行时向每个commandKey对应的熔断器报告成功、失败、超时和拒绝状态；

熔断器维护统计的数据，根据这些统计的信息来确认熔断器（Circuit Breaker）是否打开，打开，则拦截请求；

每隔5s（默认时间），尝试半开，允许一部分请求进入，相当于进行一次健康检查；

如果恢复，熔断器关闭，随后完全恢复调用。

###### 使用熔断器---Circuit Breaker的6个参数

**1、circuitBreaker.enabled**
是否启用熔断器，默认是TURE。

**2、circuitBreaker.forceOpen**
熔断器强制打开，始终保持打开状态。默认值FLASE。

**3、circuitBreaker.forceClosed**
熔断器强制关闭，始终保持关闭状态。默认值FLASE。

**4、circuitBreaker.errorThresholdPercentage**
设定错误百分比，默认值50%，例如一段时间（10s）内有100个请求，其中有55个超时或者异常返回了，那么这段时间内的错误百分比是55%，大于了默认值50%，这种情况下触发熔断器-打开。

**5、circuitBreaker.requestVolumeThreshold** 

默认值20.意思是至少有20个请求才进行errorThresholdPercentage错误百分比计算。比如一段时间（10s）内有19个请求全部失败了。错误百分比是100%，但熔断器不会打开，因为requestVolumeThreshold的值是20. **这个参数非常重要，熔断器是否打开首先要满足这个条件**

**6、circuitBreaker.sleepWindowInMilliseconds**
半开试探休眠时间，默认值5000ms。当熔断器开启一段时间之后比如5000ms，会尝试放过去一部分流量进行试探，确定依赖服务是否恢复。

#### 4. 降级

###### 降级：

在Hystrix执行非核心链路功能失败的情况下，我们如何进行处理？

如果我们要回退或者降级处理，代码上需要实现HystrixCommand.getFallback()方法或者是HystrixObservableCommand. HystrixObservableCommand()。

###### 降级回退方式

1. Fail Fast快速失败；
2. Fail Silent 无声失败；
3. Fallback：Static 返回默认值；
4. Fallback：Stubbed自己组装一个返回值；
5. Fallback：Cache via Network利用远程缓存；
6. Primary + Secondary with Fallback 主次方式回退（主要和次要）。

###### 小结

降级的处理方式，返回默认值，返回缓存里面的值（包括远程缓存比如redis和本地缓存比如jvmcache）。
但回退的处理方式也有不适合的场景：
1、写操作
2、批处理
3、计算
以上几种情况如果失败，则程序就要将错误返回给调用者。

### 5. 总结

Hystrix为我们提供了一套线上系统容错的技术实践方法，我们通过在系统中引入Hystrix的jar包可以很方便的使用线程隔离、熔断、回退等技术。

同时它还提供了监控页面配置，方便我们管理查看每个接口的调用情况。

spring cloud微服务中也引入了Hystrix，我们可以放心使用Hystrix的线程隔离技术，来防止雪崩这种可怕的致命性线上故障。
