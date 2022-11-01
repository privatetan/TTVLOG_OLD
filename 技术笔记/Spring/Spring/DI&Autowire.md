# ID&Autowire



## DI：依赖注入

DI（依赖注入）是对IOC（控制反转）Bean的使用。

Spring注入方式有：

- ##### 构造器注入（Constructor Injection）【推荐】

  ````java
  class UserApi{
     private UserService userService;
     @Autowired
     public UserApi(UserService userService){
        this.userService = userService;
     }
  }
  ````

- ##### Setter注入（Setter Injection）

  ```java
  class UserApi{
     private UserService userService;
     @Autowired
     public void setUserService(UserService userService){
         this.userService = userService;
     }
  }
  ```

- ##### Field注入 （Field Injection）

  ```java
  class UserApi{
     @Autowired
     private UserService userService;
  }
  ```



## Autowire：自动装配

### XML注入

Spring XML使用autowire属性，以实现自动装配Bean依赖。

```xml
<bean id="user" class="com.viewscenes.netsupervisor.entity.User" autowire="byName"></bean>
```

Spring在接口AutowireCapableBeanFactory中提供了四种自动装配策略；

```java
public interface AutowireCapableBeanFactory{

	//无需自动装配
	int AUTOWIRE_NO = 0;

	//按名称自动装配bean属性
	int AUTOWIRE_BY_NAME = 1;

	//按类型自动装配bean属性
	int AUTOWIRE_BY_TYPE = 2;

	//按构造器自动装配
	int AUTOWIRE_CONSTRUCTOR = 3;

	//过时方法，Spring3.0之后不再支持
	@Deprecated
	int AUTOWIRE_AUTODETECT = 4;
}
```

- ##### no：

  不使用自动装配；

- ##### byName

  使用Bean名称来自动装配；

- ##### byType

  使用Bean类型来自动装配；

- ##### constructor

  使用构造器注入，具有相同类型的Bean注入时，还是通过Bean的类型来确定。

- ##### autodetect：Spring3.0弃用

  首先会尝试使用constructor进行自动装配，如果失败再尝试使用byType；

### 注解注入

@Autowired：Spring2.5开始自带；

@Inject：JSR-330；

@Resource：JSR-250。

- #### @Autowired

  @AutoWired是Spring自带的方式；

  @AutoWired可以用在构造器、方法、属性、参数、注解上面；

  @AutoWired装配策略：

  - 默认按照byType类型装配，类型匹配不到，可配合使用@Qualifier注解实现byName来确定Bean；
  - 如果根据类型匹配到多个实例，可以在Bean上使用@Primary、@Priority设置匹配优先级，解决类型冲突；
  - required属性默认为true，即指定找不到相应Bean时抛出NoSuchBeanDefinitionException异常。

  @AutoWired，通过后置处理器AutowiredAnnotationBeanPostProcessor类实现依赖注入。

  

- #### @Inject

  @Inject是JSR-330标准，Spring版本3以上，支持jakarta.inject.Inject和javax.inject.Inject；

  @Inject可以用在方法、属性、构造器上；

  @Inject与@AutoWired装配策略基本一致，区别在于@Inject没有required属性，没有Bean时会报异常；

  @Inject，通过后置处理器AutowiredAnnotationBeanPostProcessor类实现依赖注入。

  

- #### @Resource

  @Resource是JSR-250标准，JDK6以上自带，Spring版本要求2.5以上 ；

  @Resource可以用在方法、属性、类上。

  @Resource装配策略：

  - 默认按照byName名称装配，匹配不到，则按byType类型进行匹配智能匹配；
  - 如果根据类型匹配到多个实例，可以在Bean上使用@Primary解决类型冲突；

  @Resource：通过后置处理器CommonAnnotationBeanPostProcessor类实现依赖注入。

  

  