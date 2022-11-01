# Spring面试题

### 1、IOC与DI

- IOC：控制反转，Bean的创建、初始化、销毁等操作，由Spring去管理；

- DI：依赖注入，去使用Bean；

### 2、设计原则（松耦合设计）

单一职责

接口分离

依赖倒置

### 3、BeanFactory

BeanFactory，Bean工厂，是一种Spring容器，用来创建Bean、管理Bean、获取Bean；

BeanFactory核心子接口和实现类：

- ListableBeanFactory：

- ConfigurableBeanFactory：

- AutowireCapableBeanFactory：

- AbstractBeanFactory：

- **DefaultListableBeanFactory：重要的**

  支持单例Bean、支持Bean别名、支持父子BeanFactory、支持Bean类型转化、支持Bean后置处理、支持FactoryBean、支持自动装配等。

### 4、BeanDefinition

BeanDefinition，表示Bean的定义，Spring根据BeanDefinition来创建Bean对象；

BeanDefinition中重要的属性：

- beanClass：表示bean的类型，如UserService.class，Spring创建Bean时根据该属性得到实例化对象；
- scope：表示Bean的作用域，如：singleton、prototype、request、session、application；
- isLazy：表示Bean是否需要懒加载，懒加载的单例（singleton）bean，会在第一次getBean时候生成bean，原型（prototype）bean的isLazy属性不生效；
- dependsOn：表示bean的依赖bean，在实例化bean时，需先实例化依赖bean；
- primary：表示bean为主bean，Spring中一个类型可以有多个bean对象，依赖注入时，一个类型下有多个bean时，优先注入主bean；
- initMethodName：表示bean的初始化方法，bean在初始化时会调用该方法；

@Component、 @Bean、 \<bean/> 都会解析成BeanDefinition对象。

### BeanDefinition、BeanFactory、Bean对象

BeanFactory利用BeanDefinition来生成Bean对象；

BeanDefinition相当于BeanFactory用来生成Bean的原料；

Bean相当于BeanFactory利用BeanDefinition生产的产品。

### $$$$$$$Bean生命周期

Bean生命周期，描述Spring一个Bean的创建过程和销毁过程所经历的步骤；

可根据Bean生命周期机制，对Bean实现自定义加工。

**Bean的创建过程是重点。**

步骤：

### 5、BeanFactory与ApplicationContext的区别？



### 6、BeanFactory和FactoryBean的区别？



### 7、什么是Bean？和对象的区别？

bean：被spring容器管理的对象，由springIOC容器实例化

java对象：java实体实例

### 8、配置Bean有几种方式？

1. xml文件的<bean>标签
2. 注解@Component、@Controller、@Service等
3. JavaConfig @Bean
4. @Import

### 9、@Component与@Bean

@Component由Spring通过反射自动创建。

@Bean需要自己控制实例化过程。

### 10、Bean的作用域

通过Scope属性设置

- singleton：单例默认
- prototype：多例，bean被定义为在每次注入时都会创建一个新的对象；
- request：每个HTTP请求中创建并一个单例对象；
- Session：在一个session的生命周期内创建一个单例对象；
- Application：在ServletContext的生命周期中复用一个单例对象；
- Websocket：在websocket的生命周期中复用一个单例对象。

### 11、单例Bean的优势（单例模式的优势）

1. 减少新实例创建的内存消耗
2. 减少JVM的垃圾回收负担
3. 快速从缓存中去取bean

### 12、Spring如何处理线程安全问题

1. 将单例的变量声明在方法中
2. 将bean设置为多例
3. 将成员变量设置到ThreadLocal中（线程私有）
4. 方法加锁

### 13、Spring实例化Bean的几种方式

1. 构造器方式
2. 静态工厂方式
3. 实例工厂方式
4. FactoryBean类实现接口FactoryBean重写getObject()方法

### 14、Bean的手动装配（注入）、自动装配（自动注入）、注解装配

手动装配：\<bean>标签里指定\<property>属性，@Value

自动装配：



## Spring事务失效场景

1. ###### 抛出非RuntimeException或Error的异常，即抛出Checked Exception时失误失效；

   - Checked Exception：IOException，SQLException，ClassNotFoundException；
   - 解决：1. 捕获Checked Exception并自定义抛出RuntimeException或Error。2.@Transactional(rollbackFor = Exception.class)
