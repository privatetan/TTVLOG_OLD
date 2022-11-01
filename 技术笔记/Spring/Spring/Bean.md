# Bean

Bean，是由Spring IOC容器管理的对象；

JavaBean，是普通java对象；



## Bean的作用域

|     作用域     |                             描述                             |
| :------------: | :----------------------------------------------------------: |
|   singleton    |    默认作用域，让 Spring 在每次需要时都返回同一个bean实例    |
|   prototype    | 每次特定的 bean 发出请求时 Spring IoC 容器就创建对象的新的 Bean 实例； |
|    request     | 将 bean 的定义限制为 HTTP 请求。只在 web-aware Spring ApplicationContext 的上下文中有效。 |
|    session     | 将 bean 的定义限制为 HTTP 会话。 只在web-aware Spring ApplicationContext的上下文中有效。 |
| global-session | 将 bean 的定义限制为全局 HTTP 会话。只在 web-aware Spring ApplicationContext 的上下文中有效。 |



## Bean的生命周期

Bean的生命周期： bean 被实例化时，需要执行一些初始化使它转换成可用状态；当 bean 不再需要且从容器中移除时，需要做一些清除工作。

- ##### 实例化（Instantiation）

  选择使用最优构造函数完成Bean的实例化

- ##### 属性赋值（Populate）

  1. Bean实例化后回调，来决定是否进行属性赋值；

  2. 对属性进行自动装配；

     使用PropertyValues容器，保存属性键值对；

     通过autowireByName()方法和autowireByType()方法完成属性自动装配；

  3. InstantiationAwareBeanPostProcessor属性赋值前回调；

  4. 属性的赋值；

     将PropertyValues容器中的属性键值对，赋值到BeanWrapper中以完成属性赋值。

- ##### 初始化（Initialization）

  1. 检测 bean 是否实现了 *Aware 类型接口，若实现，则向 bean 中注入相应的对象。
  2. 遍历执行 bean 初始化前置处理；
  3. 执行初始化操作；
     - 如果实现了initialzingBean，调用实现的 afterPropertiesSet()；
     - 如果配置了init-mothod，调用相应的init方法
  4. 遍历执行 bean 初始化后置处理；

- ##### 销毁（Destruction）

  1. 什么样的 bean才能销毁？

     bean的作用域是单例，并且给 bean设置了销毁方法或有 `DestructionAwareBeanPostProcessor`实现类时。

  2. 给 `bean` 设置销毁方法的方式？

     - 通过 `xml` 文件配置 `destroy-method` 标签属性指定的 `destroy` 方法；
     - 通过注解 `@Bean` 可以使用属性指定销毁的方法；
     - 实现 `DisposableBean` 接口；
     - 销毁方法名为接口情况下， 有 `close` 或者 `shutdown` 方法。

  3. 检查是否有 `DestructionAwareBeanPostProcessor` 实现类？

     - 实现了 `ApplicationListener` 接口；
     - 方法加上了 `@PreDestroy` 注解。

  4. 销毁流程

  

#### AbstractAutowireCapableBeanFactory.java类实现Bean的生命周期管理

```java
// AbstractAutowireCapableBeanFactory.java
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
    throws BeanCreationException {
 
    // 1. 实例化
    BeanWrapper instanceWrapper = null;
		if (mbd.isSingleton()) {
			//如果是单例，则首先从缓存中获取
			instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
		}
		if (instanceWrapper == null) {
			//缓存中获取不到，实例化bean==null，则进行实例化
			instanceWrapper = createBeanInstance(beanName, mbd, args);
		}
     //如果满足循环依赖缓存条件，先缓存具体对象
  	boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
				isSingletonCurrentlyInCreation(beanName));
		if (earlySingletonExposure) {
			if (logger.isTraceEnabled()) {
				logger.trace("Eagerly caching bean '" + beanName +
						"' to allow for resolving potential circular references");
			}
     /**
      * 循环依赖处理逻辑：
      * 将已完成实例化，但是未完成属性赋值和相关的初始化的一个不完整的 bean 添加到三级缓存 singletonFactories 中
      * 具体内部会遍历后置处理器，判断是否有SmartInstantiationAwareBeanPostProcessor的实现类，
      * 然后调用里面getEarlyBeanReference覆盖当前Bean
      * 默认不做任何操作返回当前Bean，作为拓展，这里比如可以供AOP来创建代理类
		  */
			addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
		}  
  
    Object exposedObject = bean;
    try {
        // 2. 属性赋值
        populateBean(beanName, mbd, instanceWrapper);
        // 3. 初始化
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
 
    try {
     // 4. 销毁-注册回调接口
     // 如果符合 bean 的销毁条件，则执行单例bean 的销毁工作
     // 如果实现了Disposable接口，会在这里进行注册，最后在销毁的时候调用相应的destroy方法
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    }
 
    return exposedObject;
}
```

#### 实例化(createBeanInstance()方法)

选择使用最优构造函数完成Bean的实例化



#### 属性赋值(populateBean()方法)

1. Bean实例化后回调，来决定是否进行属性赋值；

2. 对属性进行自动装配；

   使用PropertyValues容器，保存属性键值对；

   通过autowireByName()方法和autowireByType()方法完成属性自动装配；

3. InstantiationAwareBeanPostProcessor属性赋值前回调；

4. 属性的赋值；

   将PropertyValues容器中的属性键值对，赋值到beanWrapper中以实现属性赋值。



#### 初始化

##### initializeBean()：初始化方法

```java
// AbstractAutowireCapableBeanFactory.java
protected Object initializeBean(String beanName, Object bean, @Nullable RootBeanDefinition mbd) {
     //3.检查 Aware 相关接口并设置相关依赖
		invokeAwareMethods(beanName, bean);
   
     //4.BeanPostProcessor 执行 bean 初始化前置处理
		Object wrappedBean = bean;
		if (mbd == null || !mbd.isSynthetic()) {
			wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
		}
 
    // 5.若实现 InitializingBean 接口，调用 afterPropertiesSet() 方法
    // 6.若配置自定义的 init-method方法，则执行
    // 执行初始化操作
		try {
			invokeInitMethods(beanName, wrappedBean, mbd);
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					(mbd != null ? mbd.getResourceDescription() : null),
					beanName, "Invocation of init method failed", ex);
		}
  
    //7.BeanPostProceesor 执行 bean 初始化后置处理
		if (mbd == null || !mbd.isSynthetic()) {
			wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
		}
		return wrappedBean;
	}s
```

##### invokeAwareMethods()：检查Aware相关接口并设置相关依赖，即根据 bean 所实现的 Aware 的类型，向 bean 中注入不同类型的对象。

```java
private void invokeAwareMethods(String beanName, Object bean) {
		if (bean instanceof Aware) {
			// 注入 beanName 字符串
			if (bean instanceof BeanNameAware) {
				((BeanNameAware) bean).setBeanName(beanName);
			}
			//注入 ClassLoader 对象
			if (bean instanceof BeanClassLoaderAware) {
				ClassLoader bcl = getBeanClassLoader();
				if (bcl != null) {
					((BeanClassLoaderAware) bean).setBeanClassLoader(bcl);
				}
			}
			//注入 BeanFactory 对象
			if (bean instanceof BeanFactoryAware) {
				((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
			}
		}
	}
```

##### applyBeanPostProcessorsBeforeInitialization()：初始化前置处理

```java
@Override
	public Object applyBeanPostProcessorsBeforeInitialization(Object existingBean, String beanName)
			throws BeansException {

		Object result = existingBean;
    //遍历前置处理器
		for (BeanPostProcessor processor : getBeanPostProcessors()) {
			//调用 BeanPostProcessor 的前置处理器方法，来执行用户扩展的逻辑
			Object current = processor.postProcessBeforeInitialization(result, beanName);
			if (current == null) {
				return result;
			}
			result = current;
		}
		return result;
	}
```

##### invokeInitMethods：初始化操作

```java
protected void invokeInitMethods(String beanName, Object bean, @Nullable RootBeanDefinition mbd)
			throws Throwable {
		// 是否实现了 InitializingBean 接口
		boolean isInitializingBean = (bean instanceof InitializingBean);
		if (isInitializingBean && (mbd == null || !mbd.hasAnyExternallyManagedInitMethod("afterPropertiesSet"))) {
			if (logger.isTraceEnabled()) {
				logger.trace("Invoking afterPropertiesSet() on bean with name '" + beanName + "'");
			}
			// 直接调用 afterPropertiesSet()，在bean设置完所有的属性后，允许对bean的属性再次修改
			((InitializingBean) bean).afterPropertiesSet();
		}

		// 判断是否指定了 init-method()，
		// 如果指定了 init-method()，则再调用制定的init-method
		if (mbd != null && bean.getClass() != NullBean.class) {
			String[] initMethodNames = mbd.getInitMethodNames();
			if (initMethodNames != null) {
				for (String initMethodName : initMethodNames) {
					if (StringUtils.hasLength(initMethodName) &&
							!(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) &&
							!mbd.hasAnyExternallyManagedInitMethod(initMethodName)) {
						invokeCustomInitMethod(beanName, bean, mbd, initMethodName);
					}
				}
			}
		}
	}
```

两种初始化方式：

- Bean实现了InitializingBean接口：容器会调用它的afterPropertiesSet方法进行初始化，对代码有侵入性；
- Bean使用init-method方法：SpringXML配置\<bean>标签属性，现在已经很少使用；

##### applyBeanPostProcessorsAfterInitialization：初始化后置处理

```java
@Override
	public Object applyBeanPostProcessorsAfterInitialization(Object existingBean, String beanName)
			throws BeansException {

		Object result = existingBean;
     //遍历前置处理器
		for (BeanPostProcessor processor : getBeanPostProcessors()) {
			//调用 BeanPostProcessor 的后置处理器方法，来执行用户扩展的逻辑
			Object current = processor.postProcessAfterInitialization(result, beanName);
			if (current == null) {
				return result;
			}
			result = current;
		}
		return result;
	}
```



#### 销毁(registerDisposableBeanIfNecessary)

```java

protected void registerDisposableBeanIfNecessary(String beanName, Object bean, RootBeanDefinition mbd) {
     //当前 bean 的作用域不是 Prototype && requiresDestruction 返回 true
		if (!mbd.isPrototype() && requiresDestruction(bean, mbd)) {
			if (mbd.isSingleton()) {
				// Register a DisposableBean implementation that performs all destruction
				// work for the given bean: DestructionAwareBeanPostProcessors,
				// DisposableBean interface, custom destroy method.
				registerDisposableBean(beanName, new DisposableBeanAdapter(
						bean, beanName, mbd, getBeanPostProcessorCache().destructionAware));
			}
			else {
				// A bean with a custom scope...
				Scope scope = this.scopes.get(mbd.getScope());
				if (scope == null) {
					throw new IllegalStateException("No Scope registered for scope name '" + mbd.getScope() + "'");
				}
				scope.registerDestructionCallback(beanName, new DisposableBeanAdapter(
						bean, beanName, mbd, getBeanPostProcessorCache().destructionAware));
			}
		}
	}
```



## getBean()方法





## @Bean注解

@Bean注解可以把第三方组件注册到IOC容器

想要使用第三方类实现组件注册到IOC容器，却不能通过@Component及其衍生注解来进行组件定义；

如：数据库连接池，线程池。

Spring定义：

```java
@Target({ElementType.METHOD, ElementType.ANNOTATION_TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Bean {
  
   //设置生成的组件的id，如果不设置时，组件id默认为注解到方法名。
	@AliasFor("name")
	String[] value() default {};
  
  //与value属性互为别名，作用一样。
	@AliasFor("value")
	String[] name() default {};
  
  //该组件能否用@Autowired注解进行自动装配，默认true。
  //如果设置为false，则用Autowired注解进行自动装配时会报错。
	boolean autowireCandidate() default true;
  
  //指定bean创建的初始化方法
	String initMethod() default "";

  ////指定bean的销毁回调方法。
	String destroyMethod() default AbstractBeanDefinition.INFER_METHOD;

}
```

