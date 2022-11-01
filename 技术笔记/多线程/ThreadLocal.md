# ThreadLocal

## 1、ThreadLocal

###### 源码注解翻译：

ThreadLocal类提供线程局部变量。

 这些变量与它们对应的普通变量的不同之处在于，访问一个（通过其 get 或 set 方法）的每个线程都有自己的、独立初始化的变量副本。

 ThreadLocal 实例通常是希望将状态与线程相关联的类中的私有静态字段（例如，用户 ID 或事务 ID）。

## 2、ThreadLocal特性

- ###### 线程本地变量

- ###### 不支持线程间（包括子父线程）变量透传

- ###### 高并发，但性能不及Netty的FastLocalThread

- ###### 通过Thread类的ThreadLocalMap成员变量实现

## 3、ThreadLocalMap类

ThreadLocalMap是Thread类中成员变量，每个Thread实例都维护一个ThreadLocalMap实例；

ThreadLocal的get()、set()、remove()方法的操作都是在ThreadLocalMap上完成的。

ThreadLocalMap通过**开放地址法**实现：

- Key：ThreadLocal，Value：ThreadLocal中保存的变量，实现ThreadLocal内保存变量的值与线程绑定；

- 开放地址法底层对应的数组为Entry数组，Entry类持有了ThreadLocal对象的弱引用（WeakReference），持有了ThreadLocal中保存变量的强引用，这导致了不恰当的使用ThreadLocal容易引发内存泄漏问题。

#### ThreadLocalMap.getEntry()方法

ThreadLocalMap.getEntry()通过开放寻址法，从Entry数组中寻找ThreadLocal对应的Entry；

ThreadLocal.get()内部调用ThreadLocalMap.getEntry()方法。

#### ThreadLocalMap.set()方法

ThreadLocalMap.set()通过开放寻址法，将线程本地变量value与当前线程Thread绑定。

ThreadLocal.set()内部调用ThreadLocalMap.set()方法。

#### ThreadLocalMap.remove()方法

ThreadLocalMap.remove()方法以ThreadLocal作为Key采用开放寻址法将value与其所属线程绑定解除。

ThreadLocal.remove()内部调用ThreadLocalMap.remove()方法。

#### ThreadLocalMap.expungeStaleEntry()方法

expungeStaleEntry()通过**重新哈希**，清理已被remove或被GC回收的ThreadLocal上关联的value；

该方法可以保证由于只与Entry存在弱引用关系的ThreadLocal被GC回收后，Entry上的Value（与ThreadLocal上关联的value）能被及时清理，而不会因为Entry上的Value一直存在强引用最终导致的内存泄漏。

ThreadLocalMap#getEntry、#set、#remove方法内部最终都会尝试调用expungeStaleEntry()方法；

所以ThreadLocal#set、#get、#remove方法最终都会调用expungeStaleEntry()方法。

## 4、内存泄漏

##### 原因：

进行垃圾回收时，Entry与ThreadLocal持有弱引用，ThreadLocal对象会被回收，但是Entry与保存的value持有强引用，未能及时回收导致，内存不断泄漏。

##### 解决：

所以在每次使用完ThreadLocal后，只要调用其对应的remove()方法，就可以避内存漏泄。

因为remove()方法底层会调用ThreadLocalMap的expungeStaleEntry()方法清理value。

##### 为什么Entry不强引用ThreadLocal

源码注解上：为了避免大的ThreadLocal与长时间存活的使用场景。如果不采用Entry弱引用ThreadLocal，ThreadLocal将一直与Thread共存，这更加容易引起内存漏泄。

## 5、ThreadLocal应用场景

ThreadLocal适用方法调用链上参数的透传，但要注意是同线程间，但不适合异步方法调用的场景。

对于异步方法调用，想做参数的透传可以采用阿里开源的TransmittableThreadLocal。

权限、日志、事务等框架都可以利用ThreadLocal透传重要参数。