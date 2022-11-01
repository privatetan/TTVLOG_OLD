# Redis高可用-集群机制

## 一、Redis集群

redis集群是redis提供的分布式数据库方案；

集群通过分片（Sharding）来进行数据共享，并提供复制和故障转移功能。

## 二、节点

一个节点就是一个运行在集群模式下的Redis服务器；

一个Redis集群通常由多个节点（node）组成；

连接各个节点使用cluster meet命令来完成：

```c
cluster meet <ip> <port>
```

使用cluster meet 命令可以让node节点与ip和port指定的节点进行握手，握手成功，node节点就会将指定节点添加至当前所在集群。

### 启动节点

redis服务器启动时候，会根据cluster-enabled配置选项是否为yes来决定是否开启服务器的集群模式；

运行在集群模式下的节点，会继续使用所有在单机模式中使用的服务器组件：

```
1. 节点会继续使用文件事件来处理命令请求和返回命令回复；
2. 节点会继续使用时间事件来执行serverCron函数，而serverCron函数又会调用集群模式特有的clusterCron函数；
3. 节点会继续使用数据库来保存键值对数据，键值对依然会是各种不同类型的对象；
4. 节点会继续使用RDB、AOF持久化模块来执行持久化工作；
5. 节点会继续使用发布与订阅模块来执行PUBLISH、SUBSCRIBE等命令；
6. 节点会继续使用复制模块来进行节点的复制功能；
7. 节点会继续使用Lua脚本环境来执行客户端输入的Lua脚本。
```

clusterCron函数：负责执行在集群模式下需要执行的常规操作，如向集群中的其他节点发送Gossip消息，检查节点是否下线，检查是否需要对下线的节点进行自动故障转移。

### 集群数据结构

##### clusterNode结构

每个节点都会使用clusterNode结构保存自身信息，如节点的创建时间、节点名字等；

clusterNode结构如下：

```c
typedef struct clusterNode {
    //节点创建时间
    mstime_t ctime; 
    //节点的名字，由40个十六进制字符组成
    char name[CLUSTER_NAMELEN]; 
    //节点标识
    //使用各种不同的标识值记录节点的角色（主节点、从节点）
    //以及节点目前所处的状态（在线、下线）
    int flags;    
    //节点当前配置纪元，用于实现故障转移
    uint64_t configEpoch; 
    //槽
    unsigned char slots[CLUSTER_SLOTS/8]; 
    // ....
    //节点的IP地址
    char ip[NET_IP_STR_LEN];  
    // ....
   //连接节点所需的有关信息 （IP、port）
    clusterLink *link; 
} clusterNode;
```

##### clusterLink结构

clusterNode结构的link属性是一个clusterLink结构，该结构保存了连接节点所需的有关信息，比如套接字描述符，输入缓冲区和输出缓冲区；

clusterLink结构如下：

```c
typedef struct clusterLink {
    //连接创建时间
    mstime_t ctime;   
    //连接
    connection *conn; 
   //输出缓冲区，保存着等待发送给其他节点的消息（message ）
    sds sndbuf; 
    //输入缓冲区，保存从其他节点接收到的消息
    char *rcvbuf; 
    //输入缓冲区大小（已使用容量）
    size_t rcvbuf_len; 
    //输入缓冲区最大容量
    size_t rcvbuf_alloc;
    //与这个连接相关联的节点，如果没有的话就为NULL
    struct clusterNode *node;
} clusterLink;
```

- ###### redisClient结构与clusterLink的异同之处
  
  - 相同：两者都有自己的套接字描述符和输入、输出缓冲区；
  - 不同：redisClient结构中的套接字和缓冲区是作用于连接客户端，而clusterLink结构中的套接字和缓冲区是作用于连接点的。

##### clusterState结构

每个节点都保存着一个用于记录当前节点所在集群的状态等信息的clusterState结构；

clusterState结构如下：

```c
typedef struct clusterState {
    //当点节点指针
    clusterNode *myself; 
    //集群当前配置纪元，用于实现故障转移
    uint64_t currentEpoch;
    //当前节点所在集群的状态：在线or下线
    int state; 
    //集群中至少处理着一个槽的节点数量
    int size;
    //集群节点名单
    //字典的键：节点名字，字典的值：节点对应的clusterNode结构
    dict *nodes; 
    // ...
} clusterState;
```

### cluster meet命令的实现

通过向节点A发送CLUSTER MEET命令，客户端可以让接收命令的节点A将节点B添加到节点A所在的集群里面：

```c
cluster meet <ip> <port>
```

节点A收到命令后，将与节点B握手，进行通讯准备；

##### 握手过程

1. 收到命令后，节点A为节点B创建一个clusterNode结构，并将该结构添加至自己的clusterState.nodes字典里；
2. 节点A将根据cluster meet命令给定的IP和端口号，向节点B发送一条meet消息；
3. 节点B将接收到meet消息，节点B会为节点A创建一个clusterNode结构，并将该结构添加至自己的clusterState.nodes字典里；
4. 节点B向节点A返回一条PONG消息；
5. 节点A收到PONG消息后，通过消息节点A可以知道节点B已经成功接收到发送的meet消息；
6. 节点A将向节点B返回一条PING消息；
7. 节点B接收到节点A返回的PING消息，就知道节点A已经成功接收PONG消息，握手完成。

完成握手后，节点A将节点B的消息通过Gossip协议传播给集群中的其他节点，让其他节点与节点B进行握手，经过一段时间后，集群中所有节点将与节点B建立连接。

## 三、槽指派

redis集群通过分片的方式来保存数据库中的键值对：
集群的整个数据库被分为16384个槽，数据库中的每个键都属于着16384个槽中的一个，集群的每个节点可以处理0个或最多16384个槽。

当数据库中的16384个槽都有节点在处理时，集群处于上线状态（OK）；如果数据库中有任何一个槽没有得到处理，那么集群处于下线状态（fail）。

通过向节点发送CLUSTER ADDSLOTS命令，可以讲一个或者多个槽指派给节点。

### 记录节点的槽指派信息

clusterNode结构的slots属性和numslot属性记录了节点负责处理哪些槽：

```c
typedef struct clusterNode {

    unsigned char slots[CLUSTER_SLOTS/8]; 

    sds slots_info; 

    int numslots;  
} clusterNode;
```

- ###### slots属性
  
  slots属性是一个二进制位数组，长度为16384/8 = 2048字节，共包含16384个二进制位；
  
  0为起始索引，16383为终止索引，根据索引位上的二进制值来判单是（1）否（0）处理槽；
  
  在slots数组中，检查槽处理和处理槽的复杂度都是O(1)：基于索引。

- ###### numslots属性
  
  记录负责处理槽的数量，即slots数组中值为1的二进制位数量。

### 传播节点的槽指派信息

节点除了会将自己负责处理的槽记录在clusterNode结构的slots属性和numslots属性外，还会将自己的slots数组通过消息发送给集群中的其他节点，告知其他节点自己负责的槽。

集群中的每个节点都会将自己的slots数组通过消息发送给集群中的其他节点，并且每个接收到slots数组的节点都会将数组保存到相应节点的clusterNode结构中，所以，集群中的每个节点都会知道数据库中的16384个槽分别被指派给了集群中的那些节点。

### 记录集群所有槽指派信息

clusterState结构slots数组记录了集群中所有16384个槽的指派信息；

结构如下：

```c
typedef struct clusterState {

  clusterNode *slots[16384];

}clusterState;
```

- ###### slots属性
  
  slots数组包含了16384个元素，每个元素都是只想clusterNode结构的指针：
  
  - 如果slots[i]指针指向null，表示槽i尚未被指派；
  - 如果slots[i]指针指向一个clusterNode结构，表示槽i已经指派给了clusterNode结构所代表节点。

##### clusterState解决的问题

- 通过将所有槽的指派信息保存在clusterState.slots数组里，检查slots[i]的复杂度为O(1)（只需要访问clusterState.slots[i]），若只使用节点的clusterNode.slots数组保存槽指派信息，则复杂度为O(N)（N为需要遍历的clusterState.nodes属性）。

clusterState.slots数组保存了集群中所有槽的指派信息，clusterNode.slots数组只记录了clusterNode结构所代表节点的槽指派信息，两者都有必要的作用。

### CLUSTER ADDSLOTS命令的实现

CLUSTER ADDSLOTS命令将一个或多个槽，指派给接收该命令的节点负责：

```
CLUSTER ADDSLOTS <slot> [...slot]
```

命令伪代码

```c
def CLUSTER_ADDSLOTS(*all_input_slots):
   //遍历所有输入槽，检查是否都是未指派
   for i in all_input_slots:
       if clusterState.slots[i] != NULL:
         reply_error()
         return

   //如果都是未指派槽，再次遍历
   for i in all_input_slots:
       //将slots[i]的指针指向代表当前节点的clusterNode结构
       clusterState.slots  = cluserState.myself
       //将节点slots数组在索引i上的二进制位设置为1
       setSlotBit(clusterState.myself.slots,1)
```

## 四、在集群中执行命令

在对数据库的16384个槽进行了指派后，集群就进入了上线状态，客户端就可以向集群节点发送数据命令，并计算出要处理的数据库键属于那个槽：

- 接收数据库键有关命令，接收命令的节点计算出要处理的数据库键属于那个槽；
- 判断槽是否由当前节点处理：
  - 如果键所在的槽指派给了当前接收命令节点，那么节点就直接执行该命令；
  - 如果没有指派给当前节点，节点首先会返回MOVED错误（包含正确节点信息）给客户端，指引客户端转向（redirect）至正确节点，再次发送命令。

### 计算键对应的槽

节点使用如下算法来计算给定键key属于那个槽：

```c
def slot_number(key):
    return CRC16(key) & 16383
```

- CRC16(key)：用于计算key的CRC-16校验和；
- & 16383：用于计算出一个介于0-16383之间的整数作为key的槽号。

### 判断槽是否由当前节点处理

计算出键对应的槽i后，节点就会检查自己在clusterState.slots数组中的项i，判断所在的槽是否由自己负责：

- if(clusterState[i] == clusterState.myself) ，说明槽i由当前节点负责，节点执行命令；
- if(clusterState[i] != clusterState.myself)，说明槽i非由当前节点负责，节点会根据clusterState.slots[i]指向的clusterNode结构所在的节点IP和端口号，向客户端返回MOVED错误，指引客户端转向至正确节点。

### MOVED错误

当节点发现键对应的槽非自己负责，节点就会向客户端返回一个MOVED错误，指引客户端转向负责该槽的节点。

MOVED 格式：

```
MOVED <slot> <ip>:<port>
```

##### ⚠️注意⚠️

集群模式的客户端在接收到MOVED错误时，并不会打印出MOVED错误，而是根据MOVED错误自动进行节点转向，并打印出转向信息；

单机模式下的客户端在接受到MOVED错误时，会打印出MOVED错误，不清楚MOVED错误的作用从而不会进行转向。

### 节点数据库实现

集群节点保存键值对及其过期时间的方式，与单机redis服务器保存方式一致。

集群节点与单机在数据库最大的区别就是：节点只能使用0号数据库，单机没有限制。

集群中，除了将键值对保存在数据库外，节点还会用clusterState结构中的slots_to_keys跳跃表来保存槽和键之间的关系：

slots_to_keys结构：

```c
typedef struct clusterState{
   //...
   zskiplist *slots_to_keys
   //...
}clusterState;
```

slots_to_keys跳跃表的每个节点的分值（Score）都是一个槽号，每个节点的成员（member）都是一个数据库键：

- 添加键值对到数据库时，节点就会将键及键的槽号关联到slots_to_keys跳跃表；
- 删除一个键值对时，节点就会在slots_to_keys跳跃表接解除与该键与槽号的关联。

通过在slots_to_keys跳跃表中记录各个数据库键所属槽，节点可以很方便的对属于某个或者某些槽的所有数据库进行批量操作：

- CLUSTER GETKEYSINSLOT <slot> <count> 命令，通过遍历slots_to_keys跳跃表查询最多count个属于槽slot的数据库键。

## 五、重新分片

### 重新分片的作用

可以将任意数量已经指派给某个节点的槽改为指派给另外的节点，并且相关槽所属键值对也很从源节点移动到目标节点。

重新分片操作可以在线进行，分片过程中，源节点和目标节点可以继续处理命令请求。

### 重新分片实现原理

重新分片操作是由Redis集群管理软件redis-trib负责执行的：redis提供重新分片的所有命令，而redis-trib则通过向源节点和慕白哦节点发送命令来执行重新分片操作。

redis-trib对单槽slot执行重新分片操作步骤：

1. ###### 就绪目标节点
   
   redis-trib对目标节点发送cluster setslot <slot> importing <sorceid>命令，让目标节点准备好从源节点导入（import）属于槽slot的键值对；

2. ###### 就绪源节点
   
   redis-trib对源节点发送cluster setslot <slot> migrating <targetid>命令，让源节点住呢比好讲述与slot槽的键值对迁移（migrate）至目标节点；

3. ###### 获取源节点键名
   
   redis-trib对源节点发送cluster getkeysinslot <slot> <count>命令，获得最多count个属于槽slot的键值对的键名；

4. ###### 迁移键
   
   对于步骤3中获得的每一个键名，redis-trib都要向源节点发送一个migate <tagetIp> <targetPort> <keyName> 0 <timeour>命令，将被选中的键原子地从源节点迁移至目标节点；

5. ###### 重复3-4步骤
   
   重复3、4步骤，直至源节点保存的所有槽slot的键值对都被迁移至目标节点位置；

6. ###### 槽slot指派
   
   redis-trib向集群中的任意一个节点发送cluster setslot <slot> node <tagetId>命令，将槽slot指派给目标节点；
   
   这一指派信息会通过消息发送至整个集群，最终集群中的所有节点都会知晓槽slot已经指派给了目标节点。

## 六、ASK错误

在进行重新分片时，源节点向目标节点迁移槽的过程中可能会出现：

`属于被迁移槽的一部分键值对保存在源节点里面，而另一部分键值对则保存在目标节点里面。`

当客户端向源节点发用一个与数据库键有关的命令，且命令要处理的数据库键恰属于正在被迁移的槽：

- 源节点首先会在自己数据库查找指定的键，找到就执行命令；
- 找不到，则判断是否在进行重新分片，否，说明键key不存在；是，说明键key可能在目标节点里，返回ASK错误。

###### ⚠️注意⚠️

集群模式redis-cli在接到ASK错误时不会打印错误，而是自动根据错误提供提供的IP和端口进行转向操作；

单机模式redis-cli在接到ASK错误时会打印错误。

### cluster setslot importing命令实现

clusterState结构的importing_slots_from数组，记录了当前节点（目标节点）正在从其他节点导入的槽：

```c
typedef struct clusterState{
  //...
  clusterNode *importing_slots_from[16384];
  //...
}clusterState;
```

如果importing_slots_from[i]值不为NULL，而是指向一个clusterNode结构，表示当前节点正在从clusterNode代表的节点导入槽i。

重新分片时，向目标节点发送命令cluster setslot <slot> importing <sorceid> ：
可以将目标节点clusterState.importing_slots_from[i]的值设置为sourceId代表的节点的clusterNode结构。

### cluster setslot migrating命令实现

clusterState结构的migrating_slots_to数据，记录了当前节点（源节点）正在迁移至其他节点的槽：

```c
typedef struct clusterState{
  //...
  clusterNode *migrating_slots_to[16384];
  //...
}clusterState;
```

如果migrating_slots_to[i]值不为NULL，而是指向一个clusterNode结构，表示当前节点正在将槽i导入至clusterNode代表的节点。

重新分片时，向源节点发送命令cluster setslot <slot> migrating <targetid>：
可以将源节点clusterState.migrating_slots_to[i]的值设置为targetid代表的节点的clusterNode结构。

### ASKING命令

asking命令唯一要做的就是打开发送该命令的客户端的redis_asking标识；

asking伪代码：

```c
def ASKING():
    //打开标识
    client.flags != REDIS_ASKING
    //向客户端返回OK
    reply("OK")
```

客户端向某节点发送一个关于槽i的命令：

- 如果槽i有没有指派给个该节点，该节点键返回一个MOVED错误；

- 如果该节点的importing_slots_from[i]现实节点正在导入槽i，并且发送命令的客户端带有REDIS_ASKING标识，该节点将破例执行这个关于槽i的命令一次；

当客户端接收到ASK错误并转向至正在导入槽的节点时，客户端会先向节点发送一个ASKING命令，然后才重新发送想要执行的命令：因为如果客户端不发送ASKING命令，而直接发送想要的执行的命令，那么客户端发送的命令将会被节点拒绝执行，并返回MOVED错误。

客户端的REDIS_ASKING标识是一个一次性标识，即：当节点执行了带有REDIS_ASKING标识的客户端发送的命令后，客户端的REDIS_ASKING标识就会被移除。

### ASK错误与MOVED错误异同

- ###### 相同
  
  ASK错误和MOVED错误都是会导致客户端转向；

- ###### 不同
  
  - MOVED错误代表槽的负责权已经从一个节点转移到另一个节点；
  - ASK错误只是两个节点在进行槽迁移时过程中的临时措施。

## 七、复制与故障转移

Redis集群中的节点分为：主节点（master）、从节点（slave）：

- 主节点：用于处理槽；
- 从节点：用于复制主节点，并在被复制的主节点下线时，代替下线主节点继续处理命令请求。

### 设置从节点

设置从节点命令：cluster replicate <nodeId>，可以让接收命令的节点成为nodeId所指定节点的从节点，并开始对主节点进行复制；

一个节点成为从节点，并开始复制某个主节点这一信息会通过消息发送给集群中的其他节点，最终集群中的所有节点都会知道某个从节点正在复制某个主节点。

集群中的所有节点都会在代表主节点的clusterNode结构的slaves属性和numslaves属性中记录正在辅助这个主节点的从节点名单。

### 故障检测

###### 疑似下线（PFAIL）

集群中的每个节点都会定期向集群中的其他节点发送PING消息，检测对方是否在线；

如果在规定时间内没有接收到目标节点的PONG消息回复，那么发送PING消息的节点就会将目标节点标记为疑似下线。

###### 已下线（FAIL）

在集群中，如果半数以上负责处理槽的主节点都将某个主节点node报告为疑似下线，那么这个主节点node将被标记为已下线状态；

然后将主节点node标记为已下线的节点，会向集群广播一条关于主节点node的FAIL消息，收到FAIL消息的节点都会讲节点node标记为已下线。

### 故障转移

当从节点发现正在复制的主节点被标记为已下线时，从节点将会对下线主节点进行故障转移；

故障转移步骤：

1. 选中下线主节点下的一个从节点，成为新的主节点；
2. 选中的从节点执行slaveof no one 命令，成为新主节点；
3. 新主节点将下线主节点的槽，撤销并重新指派给自己
4. 新主节点通过发送PONG命令，告知集群其他节点，下线主节点已被替代；
5. 新主节点接收并处理命令请求，完成故障转移。

### 选举新主节点

新的主节点是通过选举产生的；

选举方法和Sentinel选举方法类似，都是基于Raft算法的领头选举方法实现的。

## 八、集群重点知识点

1. 集群通过握手来将其他节点添加到自己所处的集群中；
2. 集群中的16384个槽，可以分别指派给集群中的各个节点，每个节点都会记录哪些槽指派给了自己，而哪些槽指派给了其他节点；
3. 节点在接受到一个命令请求时，首先检查命令处理的键对应的槽是否由自己负责，不是的话，节点会返回一个MOVED错误，并携带相关信息指引客户端转向至正确的节点。
4. 对于集群的重新分片是由redis-trib负责的，重新分片的关键是将属于某个槽的所有键值对从一个节点转移至另一个节点；
5. 在进行重新分片时，如果节点A的槽正迁移至节点B，当接受到命令请求时，节点A未能在数据库中找到时，节点A会向客户端返回一个ASK错误，指引客户端到节点B去执行；
6. MOVED错误：表示槽的负责权已经转移到其他节点；ASK错误：只是两个节点在迁移槽的过程中使用的一种临时措施；
7. 集群里的从节点用于复制主节点，并在主节点下线时，代替主节点继续处理命令请求；
8. 集群中节点通过发送和接收消息来进行通信，常见的消息有：MEET、PING、PONG、PUBLISH、FAIL五种。
