# SpringBoot

## 什么是SrpingBoot？

SpringBoot是 Spring 开源组织下的子项目；

是Spring组件一站式解决方案，主要是简化了使用Spring的难度，简省了繁重的配置，提供了各种启动器，开发者能快速上手。



## SpringBoot有哪些优点?

- ##### 减少开发，测试时间。

- ##### 使用JavaConfig有助于避免使用XML。

- ##### 避免大量的Maven导入和各种版本冲突；

- ##### 没有单独的Web服务器需要。

  不需要启动Tomcat，Jetty或其他任何服务器容器。

- ##### 需要更少的配置，因为没有web.xml文件。

  只需添加用@Configuration注释的类，然后添加用@Bean注释的方法，Spring将自动加载对象并像以前一样对其进行管理。甚至可以将@Autowired添加到bean方法中，以使Spring自动装入需要的依赖关系中。

- ##### 基于环境的配置。

  使用“-Dspring.profiles.active = {enviornment}”这个属性，可以将正在使用的环境传递到应用程序，在加载主应用程序属性文件后，Spring将在 “ (application{environment} .properties）“中加载后续的应用程序属性文件。



## SpringBoot的核心配置文件有哪几个?他们的区别是什么?

- ### application：

  主要用于 Spring Boot 项目的自动化配置。

- ### bootstrap：

  - 使用 Spring Cloud Config 配置中心时，这时需要在 bootstrap 配置文件中添加连接到配置中心的配置属性来加载外部配置中心的配置信息；
  - 一些固定的不能被覆盖的属性；
  - 一些加密/解密的场景。



## SpringBoot的配置文件有哪几种格式?他们有什么区别?

- ### properties

  app.user.name = javastack

- ### yaml：结构化、分层配置的数据序列化语言

  ```yaml
  app: 
    user: 
      name: javastack
  ```



## SpringBoot的核心注解是哪个?它主要由哪几个注解组成的?

### @SpringBootApplication

- @SpringBootConfiguration：组合了 @Configuration 注解，实现配置文件的功能。
- @EnableAutoConfiguration：打开自动配置的功能， 也可以关闭某个自动配置的选项，如关闭数据源自动配置功能。
- @ComponentScan：Spring组件扫描。



## 构建SpringBoot项目的方式？

- 继承spring-boot-starter-parent项目

- 导入spring-boot-dependencies项目依赖



## SpringBoot需要独立的容器运行吗？

可以不需要，内置了Tomcat/Jetty等服务器容器。



## 运行SpringBoot项目的方式？

1. 打jar包命令运行，或打war包放到容器运行；
2. 使用Maven/Gradle插件运行；
3. 直接执行main方法运行。



## SpringBoot的自动装配原理？

使用注解@EnableAutoConfiguration，@Configuration，@ConditionalOnClass；

首先得到一个配置文件，根据类路径下是否有这个类去自动配置。



## SpringBoot分页

使用“Spring Data-JPA”可以实现，将可分页的 org.springframework.data.domain.Pageable 传递给存储库方法。



## SpringBoot 中的监视器是什么?

### Spring boot actuator

可访问生产环境中正在运行的应用程序的当前状态；



## RequestMapping和GetMapping的不同之处在哪里?

- RequestMapping 具有类属性的，可以进行 GET,POST,PUT 或者其它的注释中具有的请求方法；
- GetMapping 是 GET 请求方法中的一个特例，它只是 ResquestMapping 的一个延伸，目的是为了提高清晰度。



## SpringBoot可以兼容老Spring项目吗?如何做?

可以兼容，使用 @ImportResource 注解导入老 Spring 项目配置文件。



## SpringBoot打成的jar和普通jar有什么区别?

Spring Boot 项目最终打包成的 jar 是可执行 jar ，这种 jar 可以直接通过 java -jar xxx.jar 命令来运行，这种 jar 不可以作为普通的 jar 被其他项目依赖，即使依赖了也无法使用其中的类。

Spring Boot 的 jar 无法被其他项目依赖，主要还是他和普通 jar 的结构不同。

普通的 jar 包，解压后直接就是包名，包里就是我们的代码，而 Spring Boot 打包成的可执行 jar 解压后，在 `\BOOT-INF\classes` 目录下才是我们的代码，因此无法被直接引用。

如果非要引用，可以在 pom.xml 文件中增加配置，将 Spring Boot 项目打包成两个 jar ，一个可执行，一个可引用。



## SpringBoot中如何实现定时任务?

在 Spring Boot 中使用定时任务主要有两种不同的方式，

- 一个就是使用 Spring 中的 @Scheduled 注解，
- 另一个则是使用第三方框架 Quartz、XXL-JOB。

使用 Spring 中的 @Scheduled 的方式主要通过 @Scheduled 注解来实现。





