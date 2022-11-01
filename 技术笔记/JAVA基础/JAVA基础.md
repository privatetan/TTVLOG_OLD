# 面向对象篇

## 1、面向对象与面向过程

- #### 面向对象

  描述事物解决问题的属性及行为；

  具有封装、继承、多态特性；

- #### 面向过程

  使用函数实现将分析问题的步骤，使用时调用即可；

  性能高，用于单片机等嵌入式系统；

## 2、封装、继承、多态

- #### 封装

  将数据和数据操作抽象并封装为一个整体（即对象），对外提供接口（方法）以供使用，用户无需知道内部实现细节。

  具有降低耦合，隐藏细节等好处；

- #### 继承

  新实体（对象）通过继承既有实体（对象）实现功能扩展；

  ###### 使用注意：

  ```
  1、父类变，子类就必须变。
  2、继承破坏了封装，对于父类而言，它的实现细节对与子类来说都是透明的。
  3、继承是一种强耦合关系。
  ```

  ###### 是否需要使用继承？

  是否需要从子类向父类进行向上转型（类似猫看作动物）。如果必须向上转型，则继承是必要的，但是如果不需要，则应当好好考虑自己是否需要继承。

- #### 多态

  在程序运行时，才确定了绑定在不同实体上的引用变量所指的实例对象；

  ##### 多态分类

  - 编译时多态

    静态的，主要是指方法的重载，在运行时谈不上多态；

  - 运行时多态

    动态的，它是通过动态绑定来实现的，也就是我们所说的多态性。

  ##### 实现条件

  - 继承：在多态中必须存在有继承关系的子类和父类。
  - 重写：子类对父类中某些方法进行重新定义，在调用这些方法时就会调用子类的方法。
  - 向上转型：在多态中需要将子类的引用赋给父类对象，只有这样该引用才能够调用父类的方法和子类的方法。

  ###### 实现方式

  - 继承

    继承体现在：子类对父类方法的重写，多个子类重写同一个父类方法表现出不同的行为；

  - 接口

    接口体现在：实现类对接方法的覆盖，多个实现类覆盖同一个接口方法表现出不同的行为；

    接口可以多继承，类只能单继承，所以接口多态比接口多态更灵活。

[本节博文引入](https://blog.csdn.net/jianyuerensheng/article/details/51602015)

### 3、重载（overload）、重写（override）

- #### 重载（同一个类）

  在同一个类中，多个方法的方法名相同，参数个数或顺序（类型需不同）不同；

  注意：返回值不能决定；

- #### 重写（子父类）

  子类重写父类的方法；

### 4、访问权限

- ###### public（公共）

- ###### protected（本类及子类）

- ###### defualt（包访问）

- ###### private（本类）

## 5、基本数据类型与包装类型

- #### 基本数据类型

  byte、short、int、long、float、double、boolean、char

- #### 包装类型

  Byte、Short、Integer、Long、Float、Double、Boolean、Character

###### 为什么DTO等属性要使用包装类型？

因为包装类型的默认值为null，基本数据类型默认值0或者false等，会产生问题；

## 6、equals与==

- #### equals

  比较的是两个对象的内容是否相等；

  Object中的equals等价于==。

  比较是否相等时，都是用equals；

  比较时，把常量写在前面，否则可能会出现空指针；

- #### ==

   比较的是变量(栈)内存中存放的对象的(堆)内存地址；

## 7、Object类的方法

- getClass

  获取类的字节码对象；

- ###### hashCode

  用于哈希查找，与equals方法一起被重写；

  obj1==obj2，可以推导出 obj1.hashCode()==obj2.hashCode()，反之则不成立；

- ###### equals

  比较两个对象内容是否相等；

  Object类中的equals等价于==；

- ###### clone

  保护方法，实现对象的拷贝，只有实现了 Cloneable 接口才能调用，否则抛出CloneNotSupportedException 异常；

- ###### toString

  获取对象信息；

- ###### notify、notifyAll

  多线程相关，配合 synchronized 使用，用于唤醒在该对象上**等待队列**中的某个线程。

- ###### wait、wait(time)

  多线程相关，配合 synchronized 使用，用于将作用于该对象上的线程加入等待队列并释放锁；

- ###### finalize

  垃圾回收相关：在判断对象是否可以被回收的最后一步需要判断该方法是否被重写；

## 8、对象的拷贝：浅拷贝与深拷贝

- ###### 浅拷贝

  浅拷贝仅仅复制所考虑的对象，而不复制对象所引用的对象；

  浅拷贝只是新增指针指向原来内存地址；

- ###### 深拷贝

  深拷贝把要复制的对象及其引用的对象都复制了一遍；

  深拷贝新增指针同时新增内存，并使新增指针指向新增内存；

## 9、关键字static、final

- ###### static

  使用：静态变量、静态方法，静态代码块、静态内部类；

  特性：修饰的资源属于静态资源，类实例共享，在类初始化时加载；

- ###### final

  使用：修饰类、方法、变量、常量、对象引用；

  特性：修饰的类不可被继承；修饰的方法不可被重写；修饰的变量不可被改变；修饰的引用不可变，引用对象的内容可改变；

  遵循重排序规则：

  - 在构造函数内对一个 final 域的写入，与随后把这个被构造对象的引用赋值给一个引用变量，这两个操作之间不能重排序。
  - 初次读一个包含 final 域的对象的引用，与随后初次读这个 final 域，这两个操作之间不能重排序。

## 10、String、StringBuilder、StringBuffer

- ###### String

  String是只读字符串，它并不是基本数据类型，而是一个对象；

  String是一个final类型的字符数组，所引用的字符串不能被改变；

  String的每次操作都会生成新的String对象；

  String字符串每次的“+”操作，在底层都会创建一个的StringBuilder对象，再调用append方法拼接+后面的字符。

- ###### StringBuilder

  StringBuilder继承了AbstractStringBuilder抽象类；

  StringBuilder底层维护了一个可变字符数组，可以频繁操作；

- ###### StringBuffer

  StringBuffer是线程安全的StringBuilder，底层使用synchronized关键字保证操作的线程安全；

# 容器集合篇

## 1、Collection

- ### List：元素可重复

  - ###### Vector

    底层基于数组实现；

    使用sychronized保证线程安全，但是效率低；

    扩容时，增加到原来的2倍；

    查询快，插入删除慢；

    查询元素时，基于索引复杂度为O(1)。

  - ###### ArrayList

    底层基于数组实现；

    线程不安全，效率高；

    扩容时，增加到原来的1.5倍；

    查询快，插入删除慢；

    查询元素时，基于索引复杂度为O(1)。

  - ###### LinkedList

    底层基于链表实现，还实现Queue接口可用作队列；

    灵活，无需扩容；

    查询慢，插入删除数据快；

    查询时，需要遍历链表，复杂度为O(n)。

- ### Set：元素不可重复，是Map实现类的封装

  - ###### TreeSet：有序

    底层基于红黑树(一种自平衡二叉查找树)实现；

    是TreeMap的封装，使用TreeMap 来保存所有元素；

    不能有相同元素，不可以有Null元素；

    根据元素的自然顺序进行排序；

    添加、删除操作时间复杂度都是O(log(n))。

  - ###### HashSet：无序

    底层给予哈希表实现；

    是HashMap的封装，使用HashMap 来保存所有元素；

    不能有相同元素，可以有一个Null元素，

    元素存入无序；

    查询、添加、删除操作时间复杂度都是O(1)。

  - ###### LinkedHashSet：有序

    底层基于哈希表+链表实现；

    是LinkedHashMap的封装，使用 LinkedHashMap 来保存所有元素；

    不能有相同元素，可以有一个Null元素，

    元素严格按照放入的顺序排列；

    添加、删除操作时间复杂度都是O(1)。
  
  | 类型/项目  |       TreeSet        |        HashSet         |       LinkedHashSet       |
  | :--------: | :------------------: | :--------------------: | :-----------------------: |
  |  是否有序  | 有序（元素自然顺序） |          无序          |     有序（存放顺序）      |
  |  数据结构  | 红黑树（二叉查找树） |         哈希表         |        哈希表+链表        |
  |  内部组成  | 使用TreeMap保存元素  |  使用HashMap保存元素   | 使用LinkedHashMap保存元素 |
  |  存储特点  | 不能相同，不可为null | 不能相同，可有一个null |  不能相同，可有一个null   |
  | 时间复杂度 |   增、删O(log(n))    |       增删查O(1)       |         增删O(1)          |
  
  

## 2、Map

- ###### Hashtable

  继承Dictionary 类，但功能与HashMap类似；

  线程安全，但效率低于ConcurrentHashMap（采用分段锁）；

  key，value值不能为空；

  采用除留余数法确定元素位置，非常耗时；

  初始长度是 11，每次扩充容量变为之前的2n+1（n 为上一次的长度）。

- ###### HashMap

  继承的是 AbstractMap；

  线程不安全，可使用ConcurrentHashMap保证线程安全问题；

  key，value值可以为空；

  采用取模运算（位运算）确定元素位置，简单高效；

  初始长度为 16，之后每次扩充变为原来的两倍。

- ###### TreeMap

  底层使用红黑树实现；

  实现了*SortedMap*接口，会按照`key`的大小顺序对*Map*中的元素进行排序；

- ###### LinkedHashMap

  底层基于哈希表+双向链表实现；

  key，value值可以为空；

  由于链表结构，元素迭代顺序与插入顺序相同，且迭代时，迭代链表即可；

- ###### WeakHashMap

  结构类似于HashMap；

  内部通过弱引用来管理entry，用完可以被垃圾回收；

  两次调用同一个方法其结果会不同，适用于缓存场景；

# IO篇

## 1、IO

- ### 分类

  - ###### 数据传输方式

    - ###### 字节流：读取单个字节，处理二进制文件；

      InputStream 接口及其实现类

      OutputStream 接口及其实现类

    - ###### 字符流：读取单个字符，处理文本文件；

      Reader 接口及其实现类

      Writer 接口及其实现类

  - ###### 数据流向

    - 输入流

      InputStream 接口及其实现类

      Reader 接口及其实现类

    - 输出流

      OutputStream 接口及其实现类

      Writer 接口及其实现类

  - ###### 操作

    - 文件(file)

      FileInputStream、FileOutputStream、FileReader、FileWriter

    - 数组([])

      字节数组(byte[]): ByteArrayInputStream、ByteArrayOutputStream

      字符数组(char[]): CharArrayReader、CharArrayWriter

    - 管道操作

      PipedInputStream、PipedOutputStream、PipedReader、PipedWriter

    - 基本数据类型

      DataInputStream、DataOutputStream

    - 缓冲操作

      BufferedInputStream、BufferedOutputStream、BufferedReader、BufferedWriter

    - 打印

      PrintStream、PrintWriter

    - 对象序列化反序列化

      ObjectInputStream、ObjectOutputStream

    - 转换

      InputStreamReader、OutputStreamWriter

- ### IO设计模式

  - ###### 装饰者模式

    装饰者模式：装饰者套在被装饰者之上，从而动态扩展被装饰者的功能；

    装饰者(Decorator)和具体组件(ConcreteComponent)都继承自组件(Component)；

    装饰者的方法有一部分是自己的，这属于它的功能，然后调用被装饰者的方法实现，从而也保留了被装饰者的功能；

## 2、BIO



## 3、NIO



## 4、AIO



# 高级篇

## 1、反射



## 2、范型

#### 范型与范型擦除



## Arrays.asList的坑

1. **不能直接使用 Arrays.asList 来转换基本类型数组**；
2. **Arrays.asList 返回的 List 不支持增删操作**；
3. **对原始数组的修改会直接影响得到的list**。

**[参考链接](https://www.cnblogs.com/Brake/p/12731888.html)**

