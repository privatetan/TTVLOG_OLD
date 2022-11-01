# Aware

Aware：意识，发现的意思。它的作用即是让bean感知到容器的资源。

```java
public interface Aware {}
```



## 作用

使用 Aware 接口，我们基本可以获得 Spring 所有的核心对象，代价是业务代码和 Spring 框架强耦合。

Aware 接口解决的核心问题是如何在业务代码中获得 Spring 框架内部对象的问题。



## 实现类

BeanNameAware：获取Bean名字；

BeanFactoryAware：获取 Spring 容器 beanFactory；

ApplicationContextAware：获取当前的applicationContext；

EnvironmentAware：获取环境相关信息，如属性、配置信息等；



## 实现原理

在Bean声明周期中，初始化阶段的第一步时调用invokeAwareMethods()方法完成赋值：

**Spring 在初始化 Bean 的过程中**，**判断 Bean 实现的 Aware 子接口的类型，调用 setXXX 方法将 Spring 内部对象注入到 Bean 中**，这就是 Aware 的底层原理。

