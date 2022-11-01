## Redis入门-数据结构-Stream



Redis5.0 中还增加了一个数据类型Stream，它借鉴了Kafka的设计，是一个新的强大的支持多播的可持久化的消息队列；

Stream，从字面上看是流类型，但其实从功能上看，应该是Redis对消息队列（MQ，Message Queue）的完善实现。

## Redis消息队列的实现

- ###### PUB/SUB，订阅/发布模式

  但是发布订阅模式是无法持久化的，如果出现网络断开、Redis 宕机等，消息就会被丢弃；

- ###### 基于 List LPUSH+BRPOP  

  支持了持久化，但是不支持多播，分组消费等。

- ######  基于 Sorted-Set 的实现

  支持了持久化，但是不支持多播，分组消费等。

- ###### Stream

## Stream消息队列

###### XADD：生产消息

XADD命令，用于在某个stream（流数据）中追加消息，格式如下：

```
XADD key ID field string [field string ...]
```

- key：键；
- ID：消息ID方案，常使用*，表示由Redis生成消息ID，这也是强烈建议的方案；
- field string：消息内容，由一个或多个key-value型数据组成。

###### XREAD：消费消息

XREAD命令，从Stream中读取消息，格式如下：

```
XREAD [COUNT count] [BLOCK milliseconds] STREAMS key [key ...] ID [ID ...]
```

- [COUNT count]，用于限定获取的消息数量；

- [BLOCK milliseconds]，用于设置XREAD为阻塞模式，默认为非阻塞模式；

- ID，用于设置由哪个消息ID开始读取。

  使用0表示从第一条消息开始。

  需要注意，消息队列ID是单调递增的，所以通过设置起点，可以向后读取。

  在阻塞模式中，可以使用$，表示最新的消息ID。（在非阻塞模式下$无意义）。

XRED读消息时分为阻塞模式和非阻塞模式：

- 使用BLOCK选项可以表示阻塞模式，需要设置阻塞时长。

- 非阻塞模式下，读取完毕（即使没有任何消息）立即返回，而在阻塞模式下，若读取不到内容，则阻塞等待。

###### 典型的队列就是 XADD 配合 XREAD Block 完成。XADD负责生成消息，XREAD负责消费消息。

