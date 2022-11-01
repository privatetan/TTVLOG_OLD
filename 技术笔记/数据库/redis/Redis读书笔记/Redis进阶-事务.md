# Redis进阶-事务

## Redis事务

redis使用multi、exec、watch等命令来实现事务功能。

redis事务提供了一种将多个命令请求打包，然后一次性、按顺序地执行多个命令且不会被中断机制。

## redis事务相关命令

- Multi ：开启事务，redis会将后续的命令逐个放入队列中，然后使用EXEC命令来原子化执行这个命令系列。
- Exec：执行事务中的所有操作命令。
- discard：取消事务，放弃执行事务块中的所有命令。
- watch：监视一个或多个key,如果事务在执行前，这个key(或多个key)被其他命令修改，则事务被中断，不会执行事务中的任何命令。
- unwatch：取消WATCH对所有key的监视。

## 事务的执行过程

事务以multi命令开始，将多个操作命令放入事务（事务队列）中，最后由exec命令将事务提交给redis服务器执行。

## 事务的实现

### 事务的三个阶段

- ##### 事务开始
  
  multi命令的执行标志事务的开始；
  
  multi命令将发送该命令的客户端从`非事务状态`切换至`事务状态`；
  
  multi命令是通过在客户端状态的flags属性中打开`reids_multi`标识来实现的；
  
  multi命令伪代码：
  
  ```c
  def multi():
     //打开事务标识
     client.flags |= REDIS_MULTI
     //返回OK回复
     replyOK()
  ```

- ##### 命令入队
  
  当客户端处于非事务状态时，客户端发送的命令会立即被服务器执行；
  
  当客户端处于事务状态时，服务器会根据客户端发来的不同的命令执行不同的操作：
  
  - 如果客户端发送的命令为exec、discard、watch、multi四个命令的其中一个，服务器会立即执行这个命令；
  - 反之，服务器会将命令放入一个事务队列里面，并向客户端返回queued。
  
  ###### 事务队列（FIFO队列）
  
    客户端的事务状态保存在mstate属性里面：
  
  ```c
  typedef struct redisClient{
     //事务状态
     multiState mstate;
  }redisClient;
  ```
  
  事务状态包含了一个事务队列，和一个记录入队命令个数的计数器（即队列长度）：
  
  ```c
  typedef struct multiState{
     //事务队列
     multiCmd *commands;
     //已经入队命令的个数
     int count;
  }redisClient; 
  ```
  
  事务队列是一个保存了入队命令的multiCmd类型的数组：
  
  ```c
  typedef struct multiCmd{
     //参数
     robj **argv;
     //参数数量
     int argc;
     //命令指针
     struct redisCommand *cmd;
  }multiCmd; 
  ```
  
  事务队列以先进先出（FIFO）的方式保存入对的命令。

- ##### 事务执行
  
  当客户端发送exec命令时，服务器先执行exec命令，然后遍历改客户端的事务队列，并执行队列中的命令，将结果返回给客户端。

## watch命令（CAS乐观锁操作）

watch命令是一个乐观锁：

- 在exec命令执行前，监视任意数量的数据库键；
- 在exec执行时，检查被监视的键时都至少有一个已经被修改，如果被修改，则服务器拒绝执行事务。

### 使用watch命令监视数据库键

每个redis数据库都保存着一个watched_keys字典；

字典的key记录被监视的数据库键，字典的value是记录了监视数据库键的客户端链表；

结构如下

```c
typedef struct redisDb{
  //正在被watch命令监视的键
  dict *watched_keys;
}
```

通过watched_keys可以知道那些数据库键正在被监视，以及那些客户端正在监视这些数据库键；

### 监视机制的触发

所有对数据库数据进行修改的命令，如SET、LPUSH等，在执行之后都会调用multi.c/touchWatchKey函数对watched_keys字典进行检查，查看是否有客户端正在监视刚刚被命令修改过的数据库键，如果有，touchWatchKey函数会将监视被修改键的客户端的REDIS_DIRTY_CAS标识打开，表示该客户端的事务安全性已经被破坏。

touchWatchKey函数的定义：

```c
def touchWatchKey(db key):
    //如果键key存在于数据库的watched_keys字典中
    //那么说明至少有一个客户端在监视这个key
    if key in db.watched_keys:
       //遍历所有监视键key的客户端
       for client in de.watched_keys[key]:
           //打开标识
           client.flags |= REDIS_DIRTY_CAS
```

### 判断事物是否安全

当服务器接收到一个客户端发来的EXEC命令时，服务器会根据这个客户端是否打开了REDIS_DIRTY_CAS标识来决定是否执行事务：

- 如果打开，则说明监视的key有被修改过的记录，客户端提交的事务不安全，服务器则拒绝客户端提交的事务；

- 反之，则事务安全，并执行事务；

## 事务的ACID性质

在关系型数据库中，使用ACID来检验事务功能的可靠性和安全性；

在Redis中，事务总是具有原子性，一致性和隔离性，并且在AOF持久化模式下，appendfsync=always时，事务具有持久性。

- 原子性
  
  redis事务不支持回滚机制，作者认为不支持回滚是因为，这种复杂的功能和redis追求的简单高效不相符，且redis事务出现的错误一般都是编程错误产生的，通常产生于开发环境，没必要为redis开发事务回滚功能。

- 一致性
  
  redis通过错误检测和简单的设计来保证事务的一致性。

- 隔离性
  
  redis使用单线程方式来执行事务，在事务执行期间，服务器不会对事务进行中断；
  
  redis的事务总是以串行化方式运行，事务总是具有隔离性的。

- 持久性
  
  redis没有为事务提供持久化功能，redis事务的持久型由持久化模式决定：
  
  AOF模式下。appendsync=always，事务具有持久性。

## redis事务的其他实现

- ##### 基于Lua脚本
  
  Redis可以保证脚本内的命令一次性、按顺序地执行，其同时也不提供事务运行错误的回滚，执行过程中如果部分命令运行错误，剩下的命令还是会继续运行完。

- ##### 基于中间标记变量
  
  通过另外的标记变量来标识事务是否执行完成，读取数据时先读取该标记变量判断是否事务执行完成。但这样会需要额外写代码实现，比较繁琐。

## 事务重点知识点

- 事务提供了一种将多个命令打包，然后一次性、有序地执行的机制。

- 多个命令会被入队到事务队列中，然后按先进先出（FIFO）的顺序执行。

- 事务在执行过程中不会被中断，当事务队列中的所有命令都被执行完毕之后，事务才会结束。

- 带有watch命令的事务会将客户端和被监视的键在数据库的watched_keys字 典中进行关联，当键被修改时，程序会将所有监视被修改键的客户端的REDIS_ DIRTY_CAS标志打开。

- 只有在客户端的REDIS_DIRTY_CAS标志未被打开时，服务器才会执行客户端提交的事务，否则的话，服务器将拒绝执行客户端提交的事务。

- Redis的事务总是具有ACID中的原子性、一致性和隔离性，当服务器运行在AOF 持久化模式下，并且appendfsync=always时，事务也具有持久性。