# Redis高可用-哨兵机制

## 一、哨兵机制

Sentinel（哨兵、哨岗）是Redis的高可用性的解决方案；

由一个或多个Sentinel实例组成的Sentinel系统，可以监视任意多个主服务器，及其从服务器：

在被监视的主服务器下线时，自动将其下某台从服务器升级为新的主服务器。

## 二、启动并初始化Sentinel

### 启动命令：

```shell
$redis-sentinel /path/to/your/sentinel.conf
或者
$redis-server /path/to/your/sentinel.conf --sentinel
```

### 启动步骤：

1. 初始化服务器；
2. 替换Sentinel专用代码；
3. 初始化Sentinel状态；
4. 初始化Sentinel的监视主服务器列表。
5. 创建连向主服务器的网络连接。

##### 1. 初始化服务器

sentinel本质上是一个运行在特殊模式下的Redis服务器，步骤与普通redis服务器类似，但是过程却有不同：
如：普通服务器在初始化时通过载入RDB文件或者AOF文件进行数据库状态还原，但是Sentinel并不使用数据库，所以就不会载入RDB或者AOF文件。

##### 2. 替换并使用Sentinel专用代码

将一部分普通redis服务器使用的代码替换成Sentinel专用代码：

- 将端口6379改成26379：
  
  Sentinel使用sentinel.c/REDIS_SENTINEL_PORT的值替换掉原来redis.h/REDIS_SERVERPORT服务器端口。

- 替换命令表：
  
  Sentinel使用sentinel.c/sentinelcmds替换原来的redis.c/redisCommandTable命令表;

##### 3. 初始化Sentinel状态

初始化一个sentinel.c/sentinelState结构（sentinel状态），该结构保存了服务器中所有和sentinel功能相关的状态（redis服务器一般由redis.h/redisServer结构保存）。

sentinel.c/sentinelState结构如下：

```c
struct sentinelState{
  //当前纪元，用于实现故障转移
  unit64_t current_epoch;

  //保存了所有被这个sentinel监视的主服务器
  //字典的键是主服务器的名字
  //字典的值时一个指向sentinelRedisInstance结构的指针
  dict *masters;

  //是否进入TILT模式
  int tilt；

  //目前正在执行的脚本数量
  int running_script;

  //进入TILT模式的时间
  mstime_t previous_time;

  //一个FOFO队列，包含所有需要执行的用户脚本
  list *scripts_queue;
}sentinelState;
```

##### 4. 初始化Sentinel状态的masters属性（主服务器列表）

masters字典记录了所有被Sentinel监视的主服务器相关信息：

- 字典的key：被监视主服务器的名字；
- 字典的value：被监视主服务器对应的sentinel.c/sentinelRedisInstance结构。

每个sentinelRedisInstance结构（实例结构）代表一个被Sentinel监视的Redis服务器实例（instance），这个实例可以时主服务器、 从服务器或者另外一个Sentinel。

##### 5. 创建连向主服务器的网络连接

Sentinel将成为主服务器的客户端，他可以向主服务器发送命令，并从命令回复中获取相关的信息。

对于每个被Sentinel监视的主服务器来说，Sentinel会创建两个连向主服务器的异步网络连接：

- 命令连接：用于向主服务器发送命令，并接收命令回复；
- 订阅连接：用于订阅主服务器的\_sentinel_:hello 频道。

## 三、获取主从服务器信息

### 获取主服务器信息

##### 发送INFO命令：

Sentinel会以“次/10s”的频率，通过命令连接向被监视的主服务器发送INFO命令，并通过分析INFO命令的回复来获取主服务器的当前信息。

分析INFO的返回可获得的信息：

- 主服务器信息：包括运行ID，服务器角色等信息，
- 从服务器信息：每个从服务器都是由一个“slave”字符串开头的行记录，每行记录了从服务器的ip地址，端口号等信息。Sentinel根据ip与端口号，就可以自动发现从服务器。

##### 创建实例结构

Sentinel将分别给主从服务器创建各自的实例结构，并且将Sentinel信息保存在主服务器实例结构的Sentinels属性中，将从服务器实例结构保存在主服务器实例结构的slaves字典里。

主服务实例结构与从服务器实例结构区别：

- flags属性值：主服务实例为SRI_MASTER,从服务器实例为SRI_SLAVE。
- name属性值：主服务器实例是用户使用Sentinel配置文件设置的，从服务器实例是Sentinel根据ip和端口号自动设置的。

### 获取从服务器信息

Sentinel发现主服务有新的从服务器时，Sentinel除了会创建新的从服务器实例结构外，还会创建新的从服务器的订阅连接和命令连接。

在创建连接后，Sentinel也会以“次/10s”的频率通过命令连接向从服务器发送INFO命令，并获取从服务器信息。

## 四、Sentinel向主从服务器发布-订阅信息

### 向主从服务器发送信息（发布消息）

默认下，Sentinel会以“次/2s”的频率，通过命令连接向所有的被监视的主从服务器发送命令：

```shell
PUBLISH _sentinel_:hello "<s_ip>,<s_port>,<s_runid>,<s_epoch>,<m_name>,<m_ip>,<m_port>,<m_epoch>"
```

- s_：为Sentinel本身信息；
- m_:为主服务器信息；
- \_sentinel_:hello：订阅的频道；
- s_epoch、m_epoch：为当前的配置纪元。

### 接收主从服务器的频道信息（订阅消息）

当Sentinel与一个主服务器或者从服务器建立起订阅连接后，Sentinel就会通过订阅连接向服务器发送命令：

```python
SUBSCRIBE _sentinel_:hello
```

Sentinel对频道\_sentinel_:hello的订阅会持续到Sentinel与服务器连接断开为止。

对于监视同一台服务器的多个Sentinel，其中一个Sentinel发送的消息会被其他Sentinel接收到，这个消息会被用于更新其他Sentinel对发送消息Sentinel的认知，也会被用于更新其他Sentinel对被监视服务器的认知。

当Sentinel从频道\_sentinel_:hello收到一条消息时，Sentinel会对这条信息进行分析，提取出Sentinel 的IP地址、端口号、运行ID等8个参数进行检查：

- 如果信息中的Sentinel运行ID与接收信息的Sentinel的运行ID相同，说明信息是自己发送的，不做处理。
- 如果信息中的Sentinel运行ID与接收信息的Sentinel的运行ID不相同，说明信息是其他Sentinel发送的，接收信息的Sentinel根据信息中的参数，对相应的主服务器实例结构进行更新。

### 更新Sentinels字典

#### Sentinels字典

在主服务器实例结构的Sentinels字典中，保存了所有监视该主服务器的Sentinel：

- sentinels字典的键：是其中一个Sentinel的名字，格式为：ip:port；
- sentinels字典的value：是对应该key的Sentinel实例结构。

#### 接收并解析Sentinel信息

当Sentinel（目标Sentinal）接收到其他Sentinel（源Sentinal）发来的信息时，会从信息中分析并提取出如下两方面的参数：

- 与Sentinel相关的参数：源Sentinel的IP地址、端口号、运行ID和配置纪元；
- 与主服务器相关的参数：源Sentinel正在监视的主服务器的名字、IP地址、端口号和配置纪元。

#### 检查并更新Sentinel字典

目标Sentinel会根据源Sentinel发送的信息，检查主服务器实例结构的sentinels字典中，源Sentinel的实例结构是否存在：

- 存在，对源Sentinel实例结构进行更新；
- 不存在，为源Sentinel创建实例结构，将该结构添加到sentinels字典中。

### 创建连向其他Sentinel的命令连接

Sentinel通过频道订阅信息发现新的Sentinel时，不仅会为新的Sentinel在主服务器sentinels字典中创建实例结构，彼此还会创建命令连接：SentinelA连向SentinelB，SentinelB连向SentinelA；

使用命令连接的各个Sentinel可以通过向其他Sentinel发送命令请求来进行信息交换；

Sentinel之间不会创建订阅连接。

## 五、检测下线状态

### 检测主观下线状态

默认下，Sentinel会以次/s的频率想所有与之建立命令连接的实例（主从服务器、其他Sentinel）发送PING命令，通过实例返回的PING命令回复来判断实例是否在线；

如果一个实例在down-after-milliseconds（Sentinel配置文件选项）毫秒内，连续向Sentinel返回无效回复，那么Sentinel会修改这个实例对应的实例结构：在结构的flags属性中打开SRI_S_DOWN标识，表示这个实例进入主观下线状态。

主观下线时长选项（down-after-milliseconds）的作用：

- 被Sentinel用来判断主服务器的主观下线状态；
- 判断主服务器属下的所有从服务器，以及所有同样监视着各个主服务器的其他Sentinel的主观下线状态。

### 检测客观下线状态

当Sentinel将主服务器判为主观下线状态后，Sentinel会向其他监视该服务器的Sentinel发送命令进行询问：是否也判定这台主服务器为下线状态（可为主观下线状态亦可为客观下线状态）；

当Sentinel接收到足够数量的已下线判断后，Sentinel会将从服务器判定为客观下线，并对主服务器执行故障转移。

#### 命令询问流程

- ##### 发送SENTINEL is-master-down-by-addr 命令
  
  ```c
  SENTINEL is-master-down-by-addr <ip> <port> <currnt_epoch> <runid>
  ```
  
  Sentinel使用该命令询问其他Sentinel是否同意主服务器已下线；
  
  ###### 值得注意：
  
  ```
  runid，可以是符号“\*”或者是目标Sentinel的局部领头Sentinel的运行ID，“*”代表命令仅用于检测主服务器的下线状态，而Sentinel的运行id则用于选举领头Sentinel。
  ```

- ##### 接收SENTINEL is-master-down-by-addr 命令
  
  当一个Sentinel（目标Sentinel）接收到另一个Sentinel（源Sentinel）发来的SENTINEL 命令，目标Sentinel会取出并分析命令请求中的参数，判断参数所指向的主服务器是否已下线，并返回包含三个参数的Multi Bulk回复给源Sentinel；
  
  三个参数：
  
  | 参数           | 意义                                                                                         |
  |:------------:|:------------------------------------------------------------------------------------------:|
  | down_state   | 返回目录Sentinel对主服务器的检查结果，1：已下线，0：未下线                                                         |
  | leader_runid | 可以是符号“\*”或者是目标Sentinel的局部领头Sentinel的运行ID，“*”代表命令仅用于检测主服务器的下线状态，Sentinel运行ID用于选举领头Sentinel； |
  | leader_epoch | 目标Sentinel的局部领头Sentinel的配置纪元，用于选举领头Sentinel，且仅在leader_runid不为“\*”符号有效。                     |

- ##### 判断客观下线
  
  根据源Sentinel的命令回复，目标Sentinel统计同意主服务器下线的数量，当数量达到配置指定的客观下线条件数量时，Sentinel会将主服务器实例结构flags属性的SRI_O_DOWN标识打开，表示主服务器已经进入客观下线状态。

Question：Sentinel实例下线如何处理？

## 六、选举领头Sentinel

当一个主服务器被判为客观下线时，监视这个主服务器的各个Sentinel会进行协商，选举出一个领头Sentinel，并由领头Sentinel对下线主服务器执行故障转移操作。

选举领头Sentinel得方法是对Raft算法的领头选举方法的实现。

选举规则与方法

- 所有在线的Sentinel都有被选为领头的Sentinel的资格；
- 每次进行领头Sentinel选举后，不管成功与否，所有Sentinel的配置纪元（epoch）值都会自增一次；
- 在一个配置纪元里，所有Sentinel都有一次将某个Sentinel设置为局部领头Sentinel的机会，并且局部领头一旦设置，在这个配置纪元里面就不能修改；
- 每个发现主服务器进入客观下线的Sentinel都会要求其他Sentinel将自己设置为局部领头Sentinel；
- 当一个Sentinel（源）向另一个Sentinel（目标）发送SENTINEL is-master-down-by-addr 命令，且命令中的runid不是“\*”而是源Sentinel的运行ID：表示源Sentinel要求目标Sentinel将前者设置为后者的局部领头Sentinel；
- Sentinel设置局部领头Sentinel的规则是：先到先得，即最先向目标Sentinel发送设置要求的源Sentinel将成为目标Sentinel局部领头Sentinel，而之后接收到的所有设置要求都会被目标Sentinel拒绝；
- 如果某个Sentinel被半数以上的Sentinel设置成了局部领头Sentinel，那么这个Sentinel将成为领头Sentinel；
- 在一个配置纪元里，只会出现一个领头Sentinel；
- 如果在给定时间内未能选举出领头Sentinel，那将在一段时间后再次进行选举，直到选出领头Sentinel为止。

## 七、故障转移

在选举出领头Sentinel后，领头Sentinel将会对一下线的主服务器执行故障转移操作；

故障转移步骤：

- ### 选出新的主服务器
  
  挑选出一个状态良好，数据完整的从服务器，然后向这个服务器发送`SLAVEOF no one`命令将这个从服务器转化为主服务器。
  
  在发送SLAVEOF no one命令后，领头Sentinel会以1s/次的频率，向被升级的从服务器发送INFO命令，并观察命令回复中的角色信息，当被升级服务器的角色从原来的slave变为master，领头Sentinel就知道被选中的从服务器已经升级为主服务器。
  
  ###### Question：如何挑选新的主服务器？

- ### 修改从服务器的复制目标
  
  领头Sentinel已下线的主服务器下的从服务器发送SLAVEOF命令，让他们去复制新的主服务器。

- ### 旧的主服务器变为从服务器
  
  最后一步就是将已经下线的主服务器设置为新的主服务器的从服务器。

## 八、Sentinel重点知识点

- Sentinel只是一个运行在特殊模式下的Redis服务器，它使用了和普通模式不一样的指令表，所以Sentinel模式与普通Redis服务器使用的命令有所不同；
- Sentinel会读入用户指定的配置文件，为每个要被监视的主服务器创建相应的实例结构，并创建连向主服务器的命令连接和订阅连接，其中命令连接用于向主服务器发送命令请求，订阅连接用于接收指定频道的信息；
- Sentinel通过向主服务器发送INFo命令来获得主服务器树下所有从服务器的地址信息，并未这些从服务器创建相应的实例结构，以及连向这些从服务器的命令连接和订阅连接；
- 一般情况下，Sentinel以10s/次的频率想被监视的主/从服务器发送Info命令，当主服务器处于下线状态，或者Sentinel正在对主服务器进行故障转移操作时，Sentinel想从服务器发送INFO命令的频率改为1s/次；
- 对于监视同一个主/从服务器的多个Sentinel来说，他们会以2s/次的频率，通过向被监视服务器的\_sentinel_:hello频道发送消息通知其他Sentinel自己的存在；
- 每个Sentinel也会从\_sentinel_:hello频道中接收其他Sentinl发来的消息，并根据这些消息为其他Sentinel创建相应的实例结构，以及命令连接；
- Sentinel与主/从服务器创建命令连接和订阅连接，Sentinel与Sentinel之间只会创建命令连接。
- Sentinel以每秒一次的频率向实例（主/从服务器，其他Sentinel）发送PING命令，并根据实例对PING命令的回复啦判断实例是否在线：当一个实例在指定时长内连续向Sentinel发送无效回复时，Sentinel会将这个实例判断为主观下线；
- 当Sentinel讲一个主服务器判断为主观下线时，它会向同样监视i这个主服务器的其他Sentinel进行询问，看他们是否同意这个主服务器已经进入主观下线状态；
- 当Sentinel接收到足够多的主观下线投票后，它会将主服务器判断为客观下线，并发器一次针对于主服务器的故障转移操作。