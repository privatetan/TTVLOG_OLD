# Circular Dependencies 

## Circular Dependencies

循环依赖：当Bean A依赖Bean B，Bean B依赖Bean A；



## Circular Dependencies in Spring

程序启动时，Spring容器会加载并实例化所有的Bean。

使用**构造器**完成依赖注入时，遇到循环依赖的Bean，Spring无法决定去优先加载哪一个Bean，此时程序会抛出BeanCurrentlyInCreationException异常：

```java
Caused by: 
org.springframework.beans.factory.BeanCurrentlyInCreationException: 
Error creating bean with name 'xxx': Requested bean is currently in creation: Is there an unresolvable circular reference?
```



## 解决Circular Dependencies

1. 重新设计组件，使其责任分离；

2. 使用**@Lazy**注解，加了@Lazy注解的依赖，在依赖注入时，会创建一个代理类注入到Bean里去；

3. 使用**Setter/Field**注入；

4. 使用**@PostConstruct**注解

   在其中一个 bean 上使用@Autowired注入一个依赖项，然后使用一个用@PostConstruct注释的方法来设置另一个依赖项。

   ```java
   @Component
   public class CircularDependencyA {
   
       @Autowired
       private CircularDependencyB circB;
   
       @PostConstruct
       public void init() {
           circB.setCircA(this);
       }
   
       public CircularDependencyB getCircB() {
           return circB;
       }
   }
   ```

5. 实现**ApplicationContextAware**和**InitializingBean**

   ```java
   @Component
   public class CircularDependencyA implements ApplicationContextAware, InitializingBean {
   
       private CircularDependencyB circB;
   
       private ApplicationContext context;
   
       public CircularDependencyB getCircB() {
           return circB;
       }
   
       @Override
       public void afterPropertiesSet() throws Exception {
           circB = context.getBean(CircularDependencyB.class);
       }
   
       @Override
       public void setApplicationContext(final ApplicationContext ctx) throws BeansException {
           context = ctx;
       }
   }
   ```

   

## 三级缓存解决 Circular Dependencies

Spring的三级缓存，解决循环依赖的关键就是：**提前暴露**

三级缓存：

```java
public class DefaultSingletonBeanRegistry extends SimpleAliasRegistry implements SingletonBeanRegistry {

	/** Cache of singleton objects: bean name to bean instance. */
	private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

	/** Cache of singleton factories: bean name to ObjectFactory. */
	private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);

	/** Cache of early singleton objects: bean name to bean instance. */
	private final Map<String, Object> earlySingletonObjects = new ConcurrentHashMap<>(16);

  /** Set of registered singletons, containing the bean names in registration order. */
	private final Set<String> registeredSingletons = new LinkedHashSet<>(256);
}
```

- 一级缓存：**singletonObjects**，存放完整的 Bean。
- 二级缓存：**earlySingletonObjects**，存放提前暴露的Bean，Bean 是不完整的，未完成属性注入和执行 init 方法。
- 三级缓存：**singletonFactories**，存放的是 Bean 工厂，主要是生产 Bean，然后将Bean存放到二级缓存中。与AOP 有关。

##### 存入三级缓存：

在实例化Bean（`AbstractAutowireCapableBeanFactory::doBean`）时，判断是否允许提前暴露对象，如果允许，则直接添加一个 ObjectFactory 到三级缓存；

```java
public class DefaultSingletonBeanRegistry extends SimpleAliasRegistry implements SingletonBeanRegistry {
   
    protected void addSingletonFactory(String beanName, ObjectFactory<?> singletonFactory) {
      Assert.notNull(singletonFactory, "Singleton factory must not be null");
      synchronized (this.singletonObjects) {
         //如果一级缓存中储存在该实例
        if (!this.singletonObjects.containsKey(beanName)) {
          //添加至三级缓存
          this.singletonFactories.put(beanName, singletonFactory);
          //移除二级缓存中的实例，确保二级缓存中没有该实例
          this.earlySingletonObjects.remove(beanName);
          
          this.registeredSingletons.add(beanName);
        }
      }
    }
}
```

