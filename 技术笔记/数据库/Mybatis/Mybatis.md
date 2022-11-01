## 1、什么是MyBatis？

```
MyBatis是有个半自动ORM（对象关系映射）框架，所谓半自动ORM：封装了JDBC，也有对象与表的映射关系，但需要用户自己写SQL进行操作。
```

## 2、MyBatis的优缺点？

##### 优点

```
* 简化开发：用户只需关注SQL，无需关注内部对数据库的操作；
* 消除了JDBC的代码冗余；
* 与Spring框架支持较好；
* 提供映射标签，支持对象与数据库的ORM字段关系映射；提供对象关系映射标签，支持对象关系组件维护。
```

##### 缺点

```
* 考验开发人员需要对SQL的编写能力；
* 对数据库类型的依赖较高：更换SQL语言，可能会更换SQL语句；
```

## 3、#{}与${}的区别？

##### #{}

```
* 预编译处理，相当于占位符，替换为"?";
* 使用PrepareStatement来赋值；
* 有效防止SQL注入；
```

##### ${}

```
* 拼接处理，相当于字符串;
* 使用Statement赋值；
* 会有SQL注入风险；
```

## 4、类中的属性名和表中的字段名不一样？

```
1. 设置别名：在查询的sql语句中定义字段名的别名，让字段名的别名和实体类的属性名一致；
2. 使用<resultMap>组件：映射字段名和实体类属性名的关系；
```

## 5、Mybatis是如何进行分页的?

##### Mybatis使用RowBounds对象进行分页

```
针对ResultSet结果集执行的“内存分页”，而非物理分页。
可以在sql内直接书写带有物理分页的参数来完成物理分页功能，也可以使用分页插件来完成物理分页。
```

## 6、分页插件的基本原理？

##### 使用Mybatis提供的插件接口，自定义插件

```
在插件的截方法内拦截待执行的sql，然后重写sql，根据dialect方言，添加对应的物理分页语句和物理分页参数。
```

## 7、MyBatis编程步骤？

```
1、 创建SqlSessionFactory；
2、 通过SqlSessionFactory创建SqlSession；
3、 通过sqlsession执行SQL，进行数据库操作；
4、 调用session.commit()提交事务；
5、 调用session.close()关闭会话；
```

## 8、MyBatis的工作原理？

```
1）读取 MyBatis 配置文件：mybatis-config.xml 为 MyBatis 的全局配置文件，配置了 MyBatis 的运行环境等信息，例如数据库连接信息。
2）加载映射文件。映射文件即 SQL 映射文件，该文件中配置了操作数据库的 SQL 语句，需要在 MyBatis 配置文件 mybatis-config.xml 中加载。mybatis-config.xml 文件可以加载多个映射文件，每个文件对应数据库中的一张表。
3）构造会话工厂：通过 MyBatis 的环境等配置信息构建会话工厂 SqlSessionFactory。
4）创建会话对象：由会话工厂创建 SqlSession 对象，该对象中包含了执行 SQL 语句的所有方法。
5）创建Executor 执行器：MyBatis 底层定义了一个 Executor 接口来操作数据库，它将根据 SqlSession 传递的参数动态地生成需要执行的 SQL 语句，同时负责查询缓存的维护。
6）MappedStatement对象：在 Executor 接口的执行方法中有一个 MappedStatement 类型的参数，该参数是对映射信息的封装，用于存储要映射的 SQL 语句的 id、参数等信息。
7）输入参数映射：输入参数类型可以是 Map、List 等集合类型，也可以是基本数据类型和 POJO 类型。输入参数映射过程类似于 JDBC 对 preparedStatement 对象设置参数的过程。
8）输出结果映射：输出结果类型可以是 Map、 List 等集合类型，也可以是基本数据类型和 POJO 类型。输出结果映射过程类似于 JDBC 对结果集的解析过程。
```

## 9、MyBatis的功能架构？

##### API接口层

```
提供给外部使用的接口API，开发人员通过这些本地API来操纵数据库；
接口层一接收到调用请求就会调用数据处理层来完成具体的数据处理。
```

##### 数据处理层

```
负责具体的SQL查找、SQL解析、SQL执行和执行结果映射处理等；
它主要的目的是根据调用的请求完成一次数据库操作。
```

##### 基础支持层

```
负责最基础的功能支撑，包括连接管理、事务管理、配置加载和缓存处理，这些都是共用的东西，将他们抽取出来作为最基础的组件；
为上层的数据处理层提供最基础的支撑。
```

## 10、Mybatis都有哪些Executor执行器？

##### SimpleExecutor：使用一次

```
每执行一次update或select，就开启一个Statement对象；
用完后，立刻关闭Statement对象。
```

##### ReuseExecutor：重复使用

```
执行update或select，以sql作为key查找Statement对象，存在就使用，不存在就创建；
用完后，不关闭Statement对象，而是放置于Map<String, Statement>内，供下一次使用；
重复使用Statement对象。
```

##### BatchExecutor：批处理

```
执行update（没有select，JDBC批处理不支持select），将所有sql都添加到批处理中（addBatch()），等待统一执行（executeBatch()）；
它缓存了多个Statement对象，每个Statement对象都是addBatch()完毕后，等待逐一执行executeBatch()批处理。
与JDBC批处理相同。
```

## 11、Mybatis延迟加载原理？

```
Mybatis仅支持association关联对象和collection关联集合对象的延迟加载，可以配置是否启用延迟加载lazyLoadingEnabled=true|false。
association：一对一查询;
collection：一对多查询;
```

##### 原理：使用CGLIB创建目标对象的代理对象

```
当调用目标方法时，进入拦截器方法，比如调用a.getB().getName()，拦截器invoke()方法发现a.getB()是null值，
那么就会单独发送事先保存好的查询关联B对象的sql，把B查询上来，然后调用a.setB(b)，于是a的对象b属性就有值了，
接着完成a.getB().getName()方法的调用。
简言之：就是使用的时候再去通过代理获取值；
```

## 12、缓存Mybatis的一级、二级缓存？

##### 一级缓存：默认打开

```
* 基于 PerpetualCache 的 HashMap 本地缓存；
* 其存储作用域为，Session：当 Session flush 或 close 之后，该 Session 中的所有 Cache 就将清空；
* 默认打开一级缓存。
```

##### 二级缓存

```
* 一级缓存其机制相同，默认也是采用 PerpetualCache，HashMap 存储；
* 不同在于：
1. 存储作用域为，Mapper(Namespace)；
2. 可自定义存储源，如 Ehcache。
* 默认不打开二级缓存：要开启二级缓存，使用二级缓存属性类需要实现Serializable序列化接口(可用来保存对象的状态),可在它的映射文件中配置<cache/> ；
```

## 13、缓存数据更新机制？

```
当某一个作用域(一级缓存 Session/二级缓存Namespaces)的进行了C/U/D 操作后，默认该作用域下所有 select 中的缓存将被 clear;
```

## 14、使用MyBatis的mapper接口调用时有哪些要求？

```
1、Mapper接口方法名和mapper.xml中定义的每个sql的id相同。
2、Mapper接口方法的输入参数类型和mapper.xml中定义的每个sql 的parameterType的类型相同。
3、Mapper接口方法的输出参数类型和mapper.xml中定义的每个sql的resultType的类型相同。
4、Mapper.xml文件中的namespace即是mapper接口的类路径。
```

## 15、Dao(Mapper)接口的工作原理是什么？

```
* Dao接口，就是人们常说的Mapper接口;
* 接口的全限名，就是映射文件中的namespace的值;
* 接口的方法名，就是映射文件中MappedStatement的id值;
* 接口方法内的参数，就是传递给sql的参数;
* Mapper接口是没有实现类的;
* 当调用接口方法时，接口全限名+方法名拼接字符串作为key值，可唯一定位一个MappedStatement。
```

## 16、Dao接口里的方法，参数不同时，方法能重载吗？

```
Dao接口里的方法，是不能重载的，因为是全限名+方法名的保存和寻找策略。
```

## 17、Dao接口的工作原理？

```
Dao接口的工作原理是JDK动态代理;
Mybatis运行时会使用JDK动态代理为Dao接口生成代理proxy对象，代理对象proxy会拦截接口方法，转而执行MappedStatement所代表的sql，然后将sql执行结果返回。
```



