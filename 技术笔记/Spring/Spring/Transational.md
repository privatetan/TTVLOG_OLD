# Transactional

## 一、Transactional

事务：逻辑中的一组操作，要么全部成功，要么全部失败。

事务的基本特征ACID

- 原子性
- 一致性
- 隔离性
- 持久性

保证隔离性的事务隔离级别

- 未提交读
- 已提交读
- 可重复度
- 持久化



## 二、Spring事务

### 1.实现方式

- **编程式事务**

  1. TransactionTemplate 手动管理事务；
  2. TransactionManager 手动管理事务。

- **声明式事务**

  1. 基于 AspectJ，使用< tx> 和< aop>标签实现；
  
  2. 基于 @Transactional 注解实现；
  
  3. 基于 TransactionInterceptor 拦截器实现；
  
  4. 基于 TransactionProxyFactoryBean 代理Bean实现。
  
     
  

### 2.@Transactional

Spring定义

```java
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface Transactional {
   
   //指定事务管理器
   @AliasFor("transactionManager")
   String value() default "";
   //指定事务管理器
   @AliasFor("value")
   String transactionManager() default "";

   String[] label() default {};

   //设置事务的传播行为，取值0-6
   //@Transactional(propagation=Propagation.NOT_SUPPORTED)
   Propagation propagation() default Propagation.REQUIRED;
   
   //设置底层数据库的事务隔离级别，事务隔离级别用于处理多事务并发的情况，通常使用数据库的默认隔离级别即可，基本不需要进行设置
    //@Transactional(propagation=Isolation.READ_UNCOMMITTED)
   Isolation isolation() default Isolation.DEFAULT;

   //设置事务的超时秒数，默认值为-1表示永不超时
   //@Transactional(timeout=90)
   int timeout() default TransactionDefinition.TIMEOUT_DEFAULT;
   
   //设置超时字符串值，默认空
   //@Transactional(timeoutString="90")
   String timeoutString() default "";
 
   //当前事务是否为只读事务，设置为true表示只读，false则表示可读写，默认值为false
   //@Transactional(readOnly=true)
   boolean readOnly() default false;
  
   //设置需要进行回滚的异常类数组，当方法中抛出指定异常数组中的异常时，则进行事务回滚
   //@Transactional(rollbackFor={RuntimeException.class, Exception.class})
   Class<? extends Throwable>[] rollbackFor() default {};

   //设置需要进行回滚的异常类名称数组，当方法中抛出指定异常名称数组中的异常时，则进行事务回滚
   //@Transactional(rollbackForClassName={"RuntimeException","Exception"})
   String[] rollbackForClassName() default {};

   //设置不需要进行回滚的异常类数组，当方法中抛出指定异常数组中的异常时，不进行事务回滚
   //@Transactional(noRollbackFor={RuntimeException.class, Exception.class})
   Class<? extends Throwable>[] noRollbackFor() default {};
  
   //置需不回滚的异常类名称数组，当方法中抛出指定异常名称数组中的异常时，不进行回滚
   //@Transactional(noRollbackForClassName={"RuntimeException","Exception"})
   String[] noRollbackForClassName() default {};

}
```

#### @Transactional注意事项

1. @Transactional 只作用于public方法，对于非public方法事务会失效；
2. @Transactional 可应用于接口、接口方法、类、类方法上，但是建议在具体的类或方法上使用，而不要使用在类所要实现的任何接口上，
3. @Transactional 默认遇到运行期异常(RuntimeException)、错误（Error）回滚，遇到检查异常（checked）不回滚。可通过注解属性设置回滚生效/失效异常。
4. 避免同一个类中调用 `@Transactional` 注解的方法，这样会导致事务失效；
5. 正确的设置 `@Transactional` 的 `rollbackFor` 和 `propagation` 属性，否则事务可能会回滚失败;
6. 被 `@Transactional` 注解的方法所在的类必须被 Spring 管理，否则不生效；
7. 底层使用的数据库必须支持事务机制，否则不生效；



### 3.@Transactional事务实现原理

@Transactional的工作机制是基于 AOP 实现的，AOP 又是使用动态代理实现的。

如果目标对象实现了接口，默认情况下会采用 JDK 的动态代理；如果目标对象没有实现了接口，会使用 CGLIB 动态代理。



## 四、Spring‘s Transactional重要组件

### 1.事务三大接口

PlatformTransactionManager事务管理器；

TransactionDefinition：事务的一些基础信息，如传播行为、隔离级别、超时时间等；

TransactionStatus：事务的一些状态信息，如是否一个新的事务、是否已被标记为回滚。

- #### PlatformTransactionManager：事务管理器；

  ```java
  public interface PlatformTransactionManager extends TransactionManager {
    //获取事务状态
  	TransactionStatus getTransaction(@Nullable TransactionDefinition definition)
  			throws TransactionException;
    //提交
  	void commit(TransactionStatus status) throws TransactionException;
    //回滚
  	void rollback(TransactionStatus status) throws TransactionException;
  }
  ```

  实现类：

  - DataSourceTransactionManager
  - HibernateTransactionManager
  - JdbcTransactionManager
  - JmsTransactionManager
  - JpaTransactionManager
  - JtaTransactionManager

  

- #### TransactionDefinition：事务的一些基础信息，如传播行为、隔离级别、超时时间等；

  ```java
  public interface TransactionDefinition {
     /**
      * 传播行为
      */
     int PROPAGATION_REQUIRED = 0;
  
     int PROPAGATION_SUPPORTS = 1;
  
     int PROPAGATION_MANDATORY = 2;
   
     int PROPAGATION_REQUIRES_NEW = 3;
  
     int PROPAGATION_NOT_SUPPORTED = 4;
  
     int PROPAGATION_NEVER = 5;
  
     int PROPAGATION_NESTED = 6;
     
     /**
      * 隔离级别
      */
     int ISOLATION_DEFAULT = -1;
  
     int ISOLATION_READ_UNCOMMITTED = 1;  // same as java.sql.Connection.TRANSACTION_READ_UNCOMMITTED;
  
     int ISOLATION_READ_COMMITTED = 2;  // same as java.sql.Connection.TRANSACTION_READ_COMMITTED;
  
     int ISOLATION_REPEATABLE_READ = 4;  // same as java.sql.Connection.TRANSACTION_REPEATABLE_READ;
  
     int ISOLATION_SERIALIZABLE = 8;  // same as java.sql.Connection.TRANSACTION_SERIALIZABLE;
     /**
      * 超时时间
      */
     int TIMEOUT_DEFAULT = -1;
  
     default int getPropagationBehavior() {
        return PROPAGATION_REQUIRED;
     }
  
     default int getIsolationLevel() {
        return ISOLATION_DEFAULT;
     }
  
     default int getTimeout() {
        return TIMEOUT_DEFAULT;
     }
  
     default boolean isReadOnly() {
        return false;
     }
  
     @Nullable
     default String getName() {
        return null;
     }
  
     static TransactionDefinition withDefaults() {
        return StaticTransactionDefinition.INSTANCE;
     }
  }
  ```

  ##### 事务传播行为

  事务传播行为（propagation behavior）：指的就是当一个事务方法被另一个事务方法调用时，这个事务方法应该如何进行。

  ###### Propagation枚举类

  以methodA()、methodB()举例。

  ```java
  public enum Propagation {
    
    //默认事务传播行为；A存在事务，B加入A事务；单独调用B，B开启新事务
  	REQUIRED(TransactionDefinition.PROPAGATION_REQUIRED),
  
    //A存在事务，B执行A事务；单独调用B，B以非事务状态执行
  	SUPPORTS(TransactionDefinition.PROPAGATION_SUPPORTS),
  
    //A存在事务，B执行A事务；单独调用B，B抛出异常
  	MANDATORY(TransactionDefinition.PROPAGATION_MANDATORY),
  
    //A存在事务，B挂起A事务并新开事务；单独执行B时，B开启新事务；AB事务互不干扰
    //需要使用JAT事务管理器TransactionManager作为事务管理器
  	REQUIRES_NEW(TransactionDefinition.PROPAGATION_REQUIRES_NEW),
  
    //A存在事务，B挂起A事务并以非事务执行；单独执行B时，B以非事务执行
    //需要使用JAT事务管理器TransactionManager作为事务管理器
  	NOT_SUPPORTED(TransactionDefinition.PROPAGATION_NOT_SUPPORTED),
   
    //B总是非事务地执行，如果存在一个活动事务，则抛出异常
  	NEVER(TransactionDefinition.PROPAGATION_NEVER),
  
    //A存在事务，B运行在A的嵌套事务中；单独调用B, B开启新事务
    //重点：保存A事务的savePoint，嵌套事务中的B失败时，回滚至savePoint(还原点)，A事务提交/回滚B事务也会提交/回滚
  	NESTED(TransactionDefinition.PROPAGATION_NESTED);
  
  	private final int value;
  
  	Propagation(int value) {
  		this.value = value;
  	}
  
  	public int value() {
  		return this.value;
  	}
  }
  ```

  ##### REQUIRES_NEW 与 NESTED

  REQUIRED、REQUIRES_NEW与NESTED有相同功能，单独调用B时，B开启新的事务；

  区别在于：

  - REQUIRED：A、B事务相关联，互相影响；
  - REQUIRES_NEW：A、B的事务完全独立，互不影响；
  - NESTED：B的事务是A的事务的嵌套事务，即，保留A事务的savePoint，B失败，回滚至savePoint，A事务提交/回滚B事务也会提交/回滚。

  ##### 事务隔离级别

  ###### Isolation枚举类

  ```java
  public enum Isolation {
     //使用数据库默认的隔离级别
     DEFAULT(TransactionDefinition.ISOLATION_DEFAULT),
     //未提交读
     READ_UNCOMMITTED(TransactionDefinition.ISOLATION_READ_UNCOMMITTED),
     //已提交读
     READ_COMMITTED(TransactionDefinition.ISOLATION_READ_COMMITTED),
     //可重复读
     REPEATABLE_READ(TransactionDefinition.ISOLATION_REPEATABLE_READ),
     //序列化
     SERIALIZABLE(TransactionDefinition.ISOLATION_SERIALIZABLE);
  
     private final int value;
  
     Isolation(int value) {
        this.value = value;
     }
  
     public int value() {
        return this.value;
     }
  }
  ```

  

- #### TransactionStatus：事务的一些状态信息，如是否一个新的事务、是否已被标记为回滚；

  ###### TransactionStatus类

  ```java
  //继承自TransactionExecution、SavepointManager、Flushable类
  public interface TransactionStatus extends TransactionExecution, SavepointManager, Flushable {
    //是否有savePoint（还原点）
  	boolean hasSavepoint();
  	
    //刷新
  	@Override
  	void flush();
  }
  
  ```

  ###### TransactionExecution类

  ```java
  public interface TransactionExecution {
    // 判断当前的事务是否是新事务
  	boolean isNewTransaction();
    
    // 这是了这个，事务的唯一结果是进行回滚。因此如果你在外层给try catche住不让事务回滚，就会抛出你可能常见的异常：
  	// Transaction rolled back because it has been marked as rollback-only
  	void setRollbackOnly();
  
  	boolean isRollbackOnly();
    //事务事务完成，commit或rollback都算完成
  	boolean isCompleted();
  }
  ```

  ###### SavepointManager类

  ```java
  public interface SavepointManager {
    //创建savePoint
  	Object createSavepoint() throws TransactionException;
    
    //回滚至某一savePoint
  	void rollbackToSavepoint(Object savepoint) throws TransactionException;
    
    //重制savePoint
  	void releaseSavepoint(Object savepoint) throws TransactionException;
  }
  ```

  

### 2.事务拦截器（TransactionInterceptor）

它继承自`TransactionAspectSupport`类，并实现了`MethodInterceptor`接口的实现类，被事务拦截的方法最终都会执行到此增强器身上。 

`TransactionAspectSupport`类是执行事务的模板类。

`MethodInterceptor`是个环绕通知，完成开启、提交、回滚事务等操作。

##### TransactionInterceptor类

```java
public class TransactionInterceptor extends TransactionAspectSupport implements MethodInterceptor, Serializable {

	public TransactionInterceptor() {
	}

	public TransactionInterceptor(TransactionManager ptm, TransactionAttributeSource tas) {
		setTransactionManager(ptm);
		setTransactionAttributeSource(tas);
	}

  //拦截入口
	@Override
	@Nullable
	public Object invoke(MethodInvocation invocation) throws Throwable {

		Class<?> targetClass = (invocation.getThis() != null ? AopUtils.getTargetClass(invocation.getThis()) : null);

		return invokeWithinTransaction(invocation.getMethod(), targetClass, new CoroutinesInvocationCallback() {
			@Override
			@Nullable
			public Object proceedWithInvocation() throws Throwable {
				return invocation.proceed();
			}
			@Override
			public Object getTarget() {
				return invocation.getThis();
			}
			@Override
			public Object[] getArguments() {
				return invocation.getArguments();
			}
		});
	}	
}
```

##### TransactionAspectSupport类

- ###### `TransactionAspectSupport`是Spring的事务切面逻辑抽象基类

  该类实现了事务切面逻辑，但是自身设计为不能被直接使用，而是作为抽象基类被实现子类使用,应用于声明式事务使用场景

- ###### `TransactionAspectSupport`核心方法就是`invokeWithinTransactio()`

  该方法的实现会把一个对目标方法的调用包裹(可以理解成`AOP`中的`around`模式)在一个事务处理逻辑中。

  该方法何时被调用，交给实现的子类。

- ###### `TransactionAspectSupport`策略设计模式(Strategy)

  使用一个外部指定的`PlatformTransactionManager`来执行事务管理逻辑，并且使用一个外部指定的`TransactionAttributeSource`用来获取事务定义信息，即`@Transactional`这种注解上的信息。

[TransactionAspectSupport源码参考链接](https://cloud.tencent.com/developer/article/1497631)

##### 重要方法

1、**invokeWithinTransaction()方法**

该方法是对不同的事务处理方式使用不同的逻辑

对于`声明式事务`的处理与`编程式事务`的处理，重要区别在于事务属性上，因为编程式的事务处理是不需要有事务属性的。

```java
public abstract class TransactionAspectSupport implements BeanFactoryAware, InitializingBean {
  //线程本地变量去保存事务信息TransactionInfo
  private static final ThreadLocal<TransactionInfo> transactionInfoHolder =
			new NamedThreadLocal<>("Current aspect-driven transaction");

  //..................
  //核心的处理事务的模版方法
  @Nullable
	protected Object invokeWithinTransaction(Method method, @Nullable Class<?> targetClass,
			final InvocationCallback invocation) throws Throwable {

		// If the transaction attribute is null, the method is non-transactional.
    // 获取事务属性源
		TransactionAttributeSource tas = getTransactionAttributeSource();
    // 获取事务属性
		final TransactionAttribute txAttr = (tas != null ? tas.getTransactionAttribute(method, targetClass) : null);
		// 根据事务属性获取合适的事务管理器（具体策略详见方法~~~)
    final TransactionManager tm = determineTransactionManager(txAttr);

		//...........
      
		PlatformTransactionManager ptm = asPlatformTransactionManager(tm);
    //获取目标方法唯一标识（类.方法，如service.UserServiceImpl.save）
		final String joinpointIdentification = methodIdentification(method, targetClass, txAttr);

		if (txAttr == null || !(ptm instanceof CallbackPreferringPlatformTransactionManager)) {
		  // 看是否有必要创建一个事务，根据 ’事务传播行为‘，做出相应的判断
			TransactionInfo txInfo = createTransactionIfNecessary(ptm, txAttr, joinpointIdentification);

			Object retVal;
			try {
				//回调方法执行，执行目标方法（原有的业务逻辑）
				retVal = invocation.proceedWithInvocation();
			}
			catch (Throwable ex) {
        // 出现异常，进行回滚（注意：并不是所有异常都会rollback的）
        // 备注：此处若没有事务属性   会commit 兼容编程式事务吧
				completeTransactionAfterThrowing(txInfo, ex);
				throw ex;
			}
			finally {
        //清除信息
				cleanupTransactionInfo(txInfo);
			}

			if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
				// Set rollback-only in case of Vavr failure matching our rollback rules...
				TransactionStatus status = txInfo.getTransactionStatus();
				if (status != null && txAttr != null) {
					retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
				}
			}

			commitTransactionAfterReturning(txInfo);
			return retVal;
		}
    //编程式事务处理 ，逻辑与上面一致
    
		else {
			Object result;
			final ThrowableHolder throwableHolder = new ThrowableHolder();
			try {
				result = ((CallbackPreferringPlatformTransactionManager) ptm).execute(txAttr, status -> {
					TransactionInfo txInfo = prepareTransactionInfo(ptm, txAttr, joinpointIdentification, status);
					try {
						Object retVal = invocation.proceedWithInvocation();
						if (retVal != null && vavrPresent && VavrDelegate.isVavrTry(retVal)) {
							// Set rollback-only in case of Vavr failure matching our rollback rules...
							retVal = VavrDelegate.evaluateTryFailure(retVal, txAttr, status);
						}
						return retVal;
					}
					catch (Throwable ex) {
						if (txAttr.rollbackOn(ex)) {
							// A RuntimeException: will lead to a rollback.
							if (ex instanceof RuntimeException) {
								throw (RuntimeException) ex;
							}
							else {
								throw new ThrowableHolderException(ex);
							}
						}
						else {
							// A normal return value: will lead to a commit.
							throwableHolder.throwable = ex;
							return null;
						}
					}
					finally {
						cleanupTransactionInfo(txInfo);
					}
				});
			}
			catch (ThrowableHolderException ex) {
				throw ex.getCause();
			}
			catch (TransactionSystemException ex2) {
				if (throwableHolder.throwable != null) {
					logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
					ex2.initApplicationException(throwableHolder.throwable);
				}
				throw ex2;
			}
			catch (Throwable ex2) {
				if (throwableHolder.throwable != null) {
					logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
				}
				throw ex2;
			}

			// Check result state: It might indicate a Throwable to rethrow.
			if (throwableHolder.throwable != null) {
				throw throwableHolder.throwable;
			}
			return result;
		}
	}
  //..................
}
```

2、**创建事务：createTransactionIfNecessary()**

3、**准备事务：prepareTransactionInfo()**

4、**提交事务：commitTransactionAfterReturning()**



## 四、Spring Transactional存在问题

### 事务失效

1. ##### 访问权限(public)

   在`AbstractFallbackTransactionAttributeSource`类的`computeTransactionAttribute`方法中有个判断，如果目标方法不是public，则`TransactionAttribute`返回null，即不支持事务。

2. ##### 方法static/final修饰

   某个方法用`static/final`修饰了，那么在它的代理类中，就无法重写该方法，而添加事务功能。

3. ##### 方法内部调用

   原因：

   解决：1.在该Service类中注入自己， 2. 使用AopContext.currentProxy()获取代理对象。

   

4. ##### Bean未被Spring管理

5. ##### 多线程调用

   Spring的事务是通过数据库连接来实现的。

   Spring使用当前线程的ThreadLocal保存了一个map，key是数据源，value是数据库连接。

   在不同的线程中，拿到的数据库连接肯定是不一样的，所以是不同的事务。

6. ##### 表不支持事务

7. ##### 错误的传播行为

8. ##### 异常捕获未抛出

9. ##### 抛出checked异常

10. ##### 嵌套事务回滚太多



### 大事务

通常情况下，在方法上`@Transactional`注解事务功能时，有个缺点就是整个方法都包含在事务当中；

如果该方法中的query方法非常多，调用层级很深，而且有部分查询方法比较耗时的话，会造成整个事务非常耗时，而从造成大事务问题。

#### 引发的问题

1. 接口超时
2. 回滚时间长
3. 并发下数据库连接池占满
4. 数据库主从延迟
5. 锁等待
6. 死锁

#### 解决办法

1. ##### 使用编程式事务

   避免由于spring aop问题，导致事务失效的问题。

   能够更小粒度的控制事务的范围，更直观。

2. ##### 将查询(select)方法放到事务外

3. ##### 事务中避免远程调用

4. ##### 事务中避免一次性处理太多数据

5. ##### 非事务执行

6. ##### 异步处理

   

### 多线程事务