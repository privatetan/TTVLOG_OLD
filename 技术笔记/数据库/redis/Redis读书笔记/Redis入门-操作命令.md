# Redis入门-操作命令

## 操作库

````properties
select <db>: 切换数据库；
dbsize: 查看当前数据库key数量；
flushdb: 清空当前库；
flushall: 清空所有库；
````

## 1、键（Key）

```properties
#----------操作相关--------------
* del <key>:  key存在时删除，不存在的key会被忽略；
* unlink <key>: 异步删除key；
* exists <key>: 检查key是否存在，存在返回1，否则返回0；
* keys <pattern>: 查找所有符合给定模式（pattern）的 key；示例:   KEYS a*；
* type <key>: 返回 key 所储存的值的类型；
#-------------------------------
move <key> db: 将key移动到给定的数据库db中；
randomkey: 从当前数据库中随机返回一个 key；
rename <key> <newkey>: 修改key的名称；
renamenx <key> <newkey>: 仅当newkey不存在时，将key改名为newkey；
dump <key>: 序列化key，并返回被序列化的值；
#--------过期相关---------
* expire <key> seconds: 设置key过期时间（秒）；
rexpireat <key> timestamp: key设置过期时间（时间戳-秒）；
* pexpire <key> milliseconds: key设置过期时间（毫秒）；
pexpireat <key> milliseconds-timestamp: key设置过期时间（时间戳-毫秒）；
* ttl <key>: 返回key 的剩余的过期时间（秒）；
pttl <key>: 返回key 的剩余的过期时间（毫秒）；
* persist <key>: 移除key的过期时间；
```

## 2、字符串（String）

```properties
set <key> <value>:   设置key及其值；
get <key>:   获取key的值；
getset <key> <value>:   以新换旧，将key的值设为value，并返回key的旧值(old value)；
* setnx <key> <value>:   只有在key不存在时设置key的值；---分布式锁的实现命令
stelen <key>:   返回key所储存的字符串值的长度；
append <key> <value>:   追加值，key存在追加，不存在新增；

#------批量设置/获取值------
mset <key1> <value1> [...<keyN> <valueN>]:   设置多个key与值；
mget <key1> [...<keyN>]:   获取多个key的值；
msetnx <key1> <value1> [...<keyN> <valueN>]:   同时设置一个或多个key-value对，当且仅当所有给定key都不存在；

#------范围设置/获取值------
setrange <key> offset value:   同value覆盖从偏移量（offset）开始的值,；
getrange <key> start end:   返回key中字符串值的子字符，字符串的截取范围包括start和end在内；

setbit <key> offset value:   对key所储存的字符串值，设置或清除指定偏移量上的位(bit)；
getbit <key> offset:   对key所储存的字符串值，获取指定偏移量上的位(bit)，当偏移量比字符串值的长度大，或key不存在时，返回0；

#------过期时间---------
setex key seconds value:   将值value关联到key ，并设置key的过期时间（秒）；
psetex key milliseconds value:   将值value关联到key ，并设置key的过期时间（毫秒）；

#-------数值增减---------
incr <key>:   将key中储存的数字值+1（原子）；
decr <key>:   将key中储存的数字值-1；
incrby <key> increment:   将key所储存的值加上给定的增量值（increment）；
decrby <key> decrement:   将key所储存的值减去给定的减量值（decrement）；
incrbyfloat <key> increment:   将key所储存的值加上给定的浮点增量值（increment）；
```

## 3、哈希表（Hash）

```properties
hmset <key> <field1> <value1> [...<fieldN> <valueN> ]:   同时将多个 field-value (域-值)对设置到哈希表 key 中；
hmget <key> <field1> [...fieldN]:   获取所有给定字段的值；
hset <key> <field> <value>:   将哈希表 key 中的字段 field 的值设为 value ；
hget <key> <field>:   获取存储在哈希表中指定字段的值；
hkeys <key>:    获取所有哈希表中的字段；
hvals <key>:    获取哈希表中所有值。

HINCRBY key field increment :   为哈希表 key 中的指定字段的整数值加上增量 increment ；
HINCRBYFLOAT key field increment :   为哈希表 key 中的指定字段的浮点数值加上增量 increment 。

HSETNX key field value :   只有在字段 field 不存在时，设置哈希表字段的值；
HEXISTS key field :   查看哈希表 key 中，指定的字段是否存在；
HGETALL key :   获取在哈希表中指定 key 的所有字段和值；
HLEN key :   获取哈希表中字段的数量；
HSCAN key cursor [MATCH pattern] [COUNT count] :   迭代哈希表中的键值对；
HDEL key field1 [field2] : 删除一个或多个哈希表字段；
```

## 4、列表（List）

```properties
lpush <key> <value1> [...valueN] : 头部插值;
lpop <key>: 移出并获取头部值；
rpush <key> <value1> [...valueN]:  尾部插值;
rpop <key>: 移出并获取尾部值；
lpushx <key> <value> : 将一个值插入到已存在的列表头部；
rpushx <key> <value> : 将一个值插入到已存在的列表尾部；

#------阻塞--------
blpop <key1> [key2 ] timeout: 移出并获取列表的头部元素，没有元素会阻塞；
brpop <key1> [key2 ] timeout:  移出并获取列表的尾部元素，没有元素会阻塞；
brpoplpush <popList> <pushList> timeout:  从popList列表中移出一个值，插入到pushList列表中并返回它； 没有元素会阻塞。

#$------索引---------
lindex <key> index:  通过索引获取列表中的元素；
lset <key> index <value>: 通过索引设置列表元素的值；

#------范围------
lrange <key> start end: 获取列表指定范围内[start,end]的元素；
ltrim <key> start stop: 保留指定范围[start,end]的元素；

#------其他------
lrem <key> count <value>: 移除列表中与参数 VALUE 相等的元素；count=0,移除所有相同，count>0,从头部开始移除count个，count<0,从尾部开始移除count个； 
linsert <key> before|after pivot <value>: 在列表的元素pivot前或者后插入元素； 
llen <key>:  获取列表长度；
rpoplpush <popList> <pushList>:  从popList尾部移除出一个值，插入到pushList列表中并返回它；
```

## 5、集合（Set）

```properties
sadd <key> <member1> [...memberN]: 向集合添加一个或多个成员；
scard <key>: 获取集合的成员数；

sdiff	<key1> [...keyN]: 返回第一个集合与其他集合之间的差异；
sdiffstore destination <key1> [...keyN]: 返回给定所有集合的差集并存储在 destination 中；
sinter <key1> [...key2]:  返回给定所有集合的交集；
sinterstore destination <key1> [...keyN]: 返回给定所有集合的交集并存储在 destination 中；
sunion <key1> [...key2] : 返回所有给定集合的并集；
sunionstore destination <key1> [...keyN]: 所有给定集合的并集存储在 destination 集合中；

sismember <key> member:  判断 member 元素是否是集合 key 的成员；
smembers <key>: 返回集合中的所有成员；
smove <oldset> <newset> member: 将 member 元素从 oldset 集合移动到 newset 集合
spop <key> : 移除并返回集合中的一个随机元素；
srandmenber <key> [count] : 返回集合中一个或多个随机数；
srem <key> <member1> [...memberN] : 移除集合中一个或多个成员；
sscan <key> cursor [MATCH pattern] [COUNT count] : 迭代集合中的元素；
```

## 6、有序集合（Zset）

```properties
zadd <key> score1 member1 [score2 member2] :    向有序集合添加一个或多个成员，或者更新已存在成员的分数；
zcard <key> :    获取有序集合的成员数；
zcount <key> min max :    计算在有序集合中指定区间[min, max]分数的成员数；
zincrby <key> increment member :   有序集合中对指定成员的分数加上增量 increment；
zinterstore destination numkeys <key> [...keyN] :   计算给定的一个或多个有序集的交集并将结果集存储在新的有序集合 destination 中；
zlexcount <key> min max :   在有序集合中计算指定字典区间[min, max]内成员数量；

zrange <key> start stop [WITHSCORES] :   通过索引区间[start, stop]返回有序集合指定区间内的成员；
zrangebylex <key> min max [LIMIT offset count] :   通过字典区间[min, max]返回有序集合的成员；
zrangebyscore <key> min max [WITHSCORES] [LIMIT] :   通过分数返回有序集合指定区间[min, max]内的成员；
zrank <key> member :   返回有序集合中指定成员的索引；
zrem <key> member [member ...] :   移除有序集合中的一个或多个成员；
zremrangebylex <key> min max :   移除有序集合中给定的字典区间[min, max]的所有成员；
zremrangebyrank <key> start stop :   移除有序集合中给定的排名区间[start, stop]的所有成员；
zremrangebyscore <key> min max :   移除有序集合中给定的分数区间[min, max]的所有成员；
zrevrange <key> start stop [WITHSCORES] :   返回有序集中指定区间[start, stop]内的成员，通过索引，分数从高到低；
zrevrangebyscore <key> max min [WITHSCORES] :   返回有序集中指定分数区间[max, min]内的成员，分数从高到低排序；
zrevrank <key> member :   返回有序集合中指定成员的排名，有序集成员按分数值递减(从大到小)排序；
zscore <key> member :   返回有序集中，成员的分数值；
zunionstore destination numkeys <key> [...<keyN>] :   计算给定的一个或多个有序集的并集，并存储在新的 key 中；
zscan <key> cursor [MATCH pattern] [COUNT count] :   迭代有序集合中的元素（包括元素成员和元素分值）；
```







