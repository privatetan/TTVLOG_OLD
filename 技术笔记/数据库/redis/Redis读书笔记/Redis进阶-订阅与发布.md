# Redis进阶-订阅与发布

##### Redis 发布订阅(pub/sub)是一种消息通信模式：发送者(pub)发送消息，订阅者(sub)接收消息。

Redis 通过 **publish**（发布）、 **subscribe**（订阅）等命令实现了订阅与发布功能；

发布/订阅提供两种信息机制， 分别是 **订阅/发布到频道** 和 **订阅/发布到模式**。

## 一、订阅/发布到频道（channel）

Redis 的 **subscribe** 命令可以让客户端（client）订阅任意数量的频道（channel），而且频道（channel）可以被多个客户端（client）订阅；

当有新信息发送到被订阅的频道（channel）时， 信息就会被发送给所有订阅指定频道的客户端（client）。

### 订阅频道 （subscribe）

* ##### 使用

发布者发布消息的命令是 subscribe ，用法是 subscribe channel ，如订阅 channel1；

```basic
127.0.0.1:6379> subscribe channel1 
(integer) 1
```

* ##### 原理

每个 Redis 服务器进程都维持着一个表示服务器状态的 `redis.h/redisServer` 结构；

结构的 `pubsub_channels` 属性是一个字典， 这个字典就用于保存订阅频道的信息：

```c
struct redisServer { //服务器状态数据结构
    dict *pubsub_channels;//保存订阅频道信息的字典；
};
```

字典的**key**为正在被订阅的频道， 而字典的**value**则是一个链表， 链表中保存了所有订阅这个频道的客户端。

**subscribe**命令的行为可以用以下伪代码描述：

````c
def SUBSCRIBE(client, channels):
    # 遍历所有输入频道
    for channel in channels:
        # 将客户端添加到链表的末尾
        redisServer.pubsub_channels[channel].append(client)
````

通过 `pubsub_channels` 字典， 程序只要检查某个频道（channel）是否为字典的键key， 就可以知道该频道是否正在被客户端订阅；

只要取出某个键的值， 就可以得到所有订阅该频道的客户端的信息。

### 发送信息 （publish）

* ##### 使用

发布者发布消息的命令是 publish,用法是 publish channel message，如向 channel1说一声hello；

```basic
127.0.0.1:6379> publish channel1 hello
(integer) 1
```

* ##### 原理

当调用 `PUBLISH channel message` 命令， 程序首先根据 `channel` 定位到字典的键， 然后将信息发送给字典值链表中的所有客户端。

**publish** 命令的实现可以用以下伪代码来描述：

```c
def PUBLISH(channel, message):
    # 遍历所有订阅频道 channel 的客户端
    for client in server.pubsub_channels[channel]:
        # 将信息发送给它们
        send_message(client, message)
```

### 退订频道（unsubscribe）

使用 **unsubscribe **命令可以退订指定的频道；

这个命令执行的是订阅的反操作： 它从 `pubsub_channels` 字典的给定频道（键）中， 删除关于当前客户端的信息， 这样被退订频道的信息就不会再发送给这个客户端。

## 二、订阅/发布到模式（pattern）

当使用**publish**命令发送信息到某个频道（channel）时， 不仅所有订阅该频道的客户端会收到信息， 如果有某个/某些模式（pattern）和这个频道（channel）匹配的话， 那么所有订阅这个/这些模式的客户端也同样会收到信息。

### 订阅模式（psubscribe）

* ##### 使用

使用subscribe订阅模式，用法是 psubscribe channel[通配符] ，如订阅 channel1，channel2，channel3；

通配符中?表示1个占位符，\*表示任意个占位符(包括0)，?\*表示1个以上占位符

````basic
127.0.0.1:6379> psubscribe channel? //?: 1个占位符,
(integer) 1
````

* ##### 原理

每个 Redis 服务器进程都维持着一个表示服务器状态的 `redis.h/redisServer` 结构；

`redisServer.pubsub_patterns` 属性是一个链表，链表中保存着所有和模式相关的信息：

```c
struct redisServer {
    list *pubsub_patterns;//链表
};
```

链表中的每个节点都包含一个 redis.h/pubsubPattern 结构：

```c
typedef struct pubsubPattern {
    redisClient *client;//订阅模式的客户端
    robj *pattern;//保存着被订阅的模式
} pubsubPattern;
```

每当调用 psubscribe 命令订阅一个模式时， 程序就创建一个包含客户端信息和被订阅模式的 pubsubPattern 结构， 并将该结构添加到 redisServer.pubsub_patterns 链表中；

通过遍历整个 `pubsub_patterns` 链表，程序可以检查所有正在被订阅的模式，以及订阅这些模式的客户端。

### 发送消息（publish）

发送信息到模式的工作也是由 publish 命令进行的；

完整描述 publish 功能的伪代码定于如下：

```c
def PUBLISH(channel, message):
    # 遍历所有订阅频道 channel 的客户端
    for client in server.pubsub_channels[channel]:
        # 将信息发送给它们
        send_message(client, message)
    # 取出所有模式，以及订阅模式的客户端
    for pattern, client in server.pubsub_patterns:
        # 如果 channel 和模式匹配
        if match(channel, pattern):
            # 那么也将信息发给订阅这个模式的客户端
            send_message(client, message)
```

### 退订模式（punsubscribe）

使用 punsubscribe 命令可以退订指定的模式；

 这个命令执行的是订阅模式的反操作： 程序会删除 `redisServer.pubsub_patterns` 链表中， 所有和被退订模式相关联的 `pubsubPattern` 结构， 这样客户端就不会再收到和模式相匹配的频道发来的信息；

## 3、总结

* 使用`punsubscribe`只能退订通过`psubscribe`命令订阅的规则，不会影响直接通过subscribe命令订阅的频道；同样unsubscribe命令也不会影响通过psubscribe命令订阅的规则；
* 订阅频道（channel）信息由服务器进程维持的 `redisServer.pubsub_channels` 字典（dict）保存，字典的键为被订阅的频道，字典的值为订阅频道的所有客户端；
* 当有新消息发送到频道（channel）时，程序遍历频道（键）所对应的（值）所有客户端，然后将消息发送到所有订阅频道的客户端上；
* 订阅模式（pattern）信息由服务器进程维持的 `redisServer.pubsub_patterns` 链表（list）保存，链表的每个节点都保存着一个 `pubsubPattern` 结构，结构中保存着被订阅的模式，以及订阅该模式的客户端。程序通过遍历链表来查找某个频道是否和某个模式匹配；
* 当有新消息发送到频道（channel）时，除了订阅频道（channel）的客户端会收到消息之外，所有订阅了匹配频道的模式（pattern）的客户端，也同样会收到消息；
* 退订频道和退订模式分别是订阅频道和订阅模式的反操作。

