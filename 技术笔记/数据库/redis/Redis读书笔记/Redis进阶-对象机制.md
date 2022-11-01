# Redis 进阶-对象机制

Redis的每种对象其实都由**对象结构(redisObject)** 与 **对应编码的数据结构**组合而成，而每种对象类型对应若干**编码**方式，不同的编码方式所对应的**底层数据结构**是不同的。

## 对象结构(redisObject)

### 为什么Redis会设计redisObject对象？

Redis 必须让每个键都带有类型信息，使得程序可以检查键的类型，并为它选择合适的处理方式。

操作数据类型的命令除了要对键的类型进行检查之外，还需要根据数据类型的不同编码进行多态处理。

为了解决以上问题，**Redis 构建了自己的类型系统**，主要功能有：

```tex
1. redisObject 对象；
2. 基于 redisObject 对象的类型检查；
3. 基于 redisObject 对象的显式多态函数；
4. 对 redisObject 进行分配、共享和销毁的机制。
```

### redisObject数据结构

redisObject 是 Redis 类型系统的核心，数据库中的每个键、值, 以及 Redis 本身处理的参数, 都表示为这种数据类型。

```c
/*
 * Redis 对象
 */
typedef struct redisObject {
    // 类型
    unsigned type:4;
    // 编码方式
    unsigned encoding:4;
    // LRU - 24位, 记录最末一次访问时间（相对于lru_clock）; 或者 LFU（最少使用的数据：8位频率，16位访问时间）
    unsigned lru:LRU_BITS; // LRU_BITS: 24
    // 引用计数
    int refcount;
    // 指向底层数据结构实例
    void *ptr;
} redisObject;
```

**其中type、encoding和ptr是最重要的三个属性**。

* **type**
  
  type记录了对象所保存的值的类型，它的值可能是以下**常量**中的一个：
  
  ```c
  /*
  * 对象类型
  */
  #define OBJ_STRING 0 // 字符串
  #define OBJ_LIST 1 // 列表
  #define OBJ_SET 2 // 集合
  #define OBJ_ZSET 3 // 有序集
  #define OBJ_HASH 4 // 哈希表
  ```

* **encoding**
  
  encoding记录了对象所保存的值的编码，它的值可能是以下常量中的一个：
  
  ```c
  /*
  * 对象编码
  */
  #define OBJ_ENCODING_RAW 0     /* Raw representation */
  #define OBJ_ENCODING_INT 1     /* Encoded as integer */
  #define OBJ_ENCODING_HT 2      /* Encoded as hash table */
  #define OBJ_ENCODING_ZIPMAP 3  /* 注意：版本2.6后不再使用. */
  #define OBJ_ENCODING_LINKEDLIST 4 /* 注意：不再使用了，旧版本2.x中String的底层之一. */
  #define OBJ_ENCODING_ZIPLIST 5 /* Encoded as ziplist */
  #define OBJ_ENCODING_INTSET 6  /* Encoded as intset */
  #define OBJ_ENCODING_SKIPLIST 7  /* Encoded as skiplist */
  #define OBJ_ENCODING_EMBSTR 8  /* Embedded sds string encoding */
  #define OBJ_ENCODING_QUICKLIST 9 /* Encoded as linked list of ziplists */
  #define OBJ_ENCODING_STREAM 10 /* Encoded as a radix tree of listpacks */
  ```

* **ptr**
  
  **ptr是一个指针，指向实际保存值的数据结构**，这个数据结构由type和encoding属性决定。
  
  例如， 如果一个redisObject 的type 属性为`OBJ_LIST` ， encoding 属性为`OBJ_ENCODING_QUICKLIST` ，那么这个对象就是一个Redis 列表（List)，它的值保存在一个QuickList的数据结构内，而ptr 指针就指向quicklist的对象；

* **lru**
  
  lru记录了对象最后一次被命令程序访问的时间。
  
  **空转时长**：当前时间减去键的值对象的lru时间，就是该键的空转时长。Object idletime命令可以打印出给定键的空转时长。
  
  如果服务器打开了maxmemory选项，并且服务器用于回收内存的算法为volatile-lru或者allkeys-lru，那么当服务器占用的内存数超过了maxmemory选项所设置的上限值时，空转时长较高的那部分键会优先被服务器释放，从而**回收内存**。

## 命令的类型检查和多态

### Redis是如何处理一条命令的呢？

###### 当执行一个处理数据类型命令的时候，redis执行以下步骤

```tex
1. 根据给定的key，在数据库字典中查找和他相对应的redisObject，如果没找到，就返回NULL； 
2. 检查redisObject的type属性和执行命令所需的类型是否相符，如果不相符，返回类型错误； 
3. 根据redisObject的encoding属性所指定的编码，选择合适的操作函数来处理底层的数据结构； 
4. 返回数据结构的操作结果作为命令的返回值。
```

## 对象共享

redis一般会把一些常见的值放到一个共享对象中，这样可使程序避免了重复分配的麻烦，也节约了一些CPU时间。

如果对复杂度较高的对象创建共享对象，需要消耗很大的CPU，用这种消耗去换取内存空间，是不合适的。

## 引用计数以及对象的消毁

redisObject中有refcount属性，是对象的引用计数，计数0那么就是可以回收。

```tex
1、每个redisObject结构都带有一个refcount属性，指示这个对象被引用了多少次； 
2、当新创建一个对象时，它的refcount属性被设置为1； 
3、当对一个对象进行共享时，redis将这个对象的refcount加一； 
4、当使用完一个对象后，或者消除对一个对象的引用之后，程序将对象的refcount减一； 
5、当对象的refcount降至0 时，这个redisObject结构，以及它引用的数据结构的内存都会被释放。
```

## 小结

* redis使用自己实现的对象机制（redisObject)来实现类型判断、命令多态和基于引用次数的垃圾回收；

* redis会预分配一些常用的数据对象，并通过共享这些对象来减少内存占用，和避免频繁的为小对象分配内存。