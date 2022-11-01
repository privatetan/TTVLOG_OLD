# Redis进阶 - 底层数据结构

Redis底层数据结构包括：

- ###### 简单动态字符串 - SDS

- ###### 压缩列表 - ZipList

- ###### 链表与快速链表 - LinkedList/QuickList

- ###### 字典 - Dict

- ###### 整数集合 - IntSet

- ###### 跳跃表 - ZSkipList

## 一、简单动态字符串 - SDS

SDS是一种用于存储二进制数据的一种结构，具有动态扩容的特点，其实现位于src/sds.h与src/sds.c中。

### SDS结构

| sdshdr | buf | \0. |
|:------:|:---:|:---:|
| 头部     | 数据  | 结尾  |

`sdshdr`是头部，`buf`是真实存储用户数据的地方，`"数据" + "\0"`就是所谓的buf。

SDS有五种不同的头部，其中sdshdr5实际并未使用到，所以实际上有四种不同的头部：sdshdr5、sdshdr8、sdshdr16、sdshdr32、sdshdr64。

sdshdr头部属性：

```properties
len: 保存了SDS保存字符串的长度;
buf[]: 数组用来保存字符串的每个元素；
alloc: 分别以uint8, uint16, uint32, uint64表示整个SDS, 除过头部与末尾的\0, 剩余的字节数；
flags: 始终为一字节, 以低三位标示着头部的类型, 高5位未使用。
```

### 为什么使用SDS？

* ###### 常数复杂度获取字符串长度
  
  获取 SDS 字符串的长度只需要读取 len 属性，时间复杂度为 O(1)。
  
  而对于 C 语言，获取字符串的长度通常是经过遍历计数来实现的，时间复杂度为 O(n)。
  
  通过 `strlen key` 命令可以获取 key 的字符串长度。

* ###### 杜绝缓冲区溢出
  
  在 C 语言中使用 `strcat` 函数来进行两个字符串的拼接，一旦没有分配足够长度的内存空间，就会造成缓冲区溢出。
  
  对于 SDS 数据类型，在进行字符修改的时候，**会首先根据记录的 len 属性检查内存空间是否满足需求**，如果不满足，会进行相应的空间扩展，然后在进行修改操作，所以不会出现缓冲区溢出。

* ###### 减少修改字符串的内存重新分配次数
  
  C语言由于不记录字符串的长度，所以如果要修改字符串，必须要重新分配内存（先释放再申请），因为如果没有重新分配，字符串长度增大时会造成内存缓冲区溢出，字符串长度减小时会造成内存泄露。
  
  而对于SDS，由于`len`属性和`alloc`属性的存在，对于修改字符串SDS实现了**空间预分配**和**惰性空间释放**两种策略：
  
  ```properties
  1、空间预分配: 对字符串进行空间扩展的时候，扩展的内存比实际需要的多，这样可以减少连续执行字符串增长操作所需的内存重分配次数。
  
  2、惰性空间释放: 对字符串进行缩短操作时，程序不立即使用内存重新分配来回收缩短后多余的字节，而是使用 `alloc` 属性将这些字节的数量记录下来，等待后续使用。（当然SDS也提供了相应的API，当我们有需要时，也可以手动释放这些未使用的空间）
  ```

* ###### 二进制安全
  
  C字符串以空字符作为字符串结束的标识，而对于一些二进制文件（如图片等），内容可能包括空字符串，因此C字符串无法正确存取。
  
  SDS 的API 都是以处理二进制的方式来处理 `buf` 里面的元素，并且 SDS 不是以空字符串来判断是否结束，而是以 len 属性表示的长度来判断字符串是否结束。

* ###### 兼容部分 C 字符串函数
  
  虽然 SDS 是二进制安全的，但是一样遵从每个字符串都是以空字符串结尾的惯例，这样可以重用 C 语言库`<string.h>` 中的一部分函数。

一般来说，SDS 除了保存数据库中的字符串值以外，SDS 还可以作为缓冲区（buffer）：包括 AOF 模块中的AOF缓冲区以及客户端状态中的输入缓冲区。

## 二、压缩列表 - ZipList

##### zipList是列表键和哈希键的底层实现之一。

* 当一个列表键只包含少量列表项，并且每个列表项是**小整数值**，或是长度较短的**字符串**。
* 但一个哈希键只包含少量键值对，并且每个简直对是**小整数值**，或是长度较短的**字符串**。

满足以上条件之一，Redis就会使用ZipList来实现。

### ZipList结构

###### zipList是Redis为了节约内存而实现的，是由一系列特殊编码的连续内存块组成的顺序型数据结构。

###### 一个zipList可以包含任意个entry节点，每个entry节点保存一个字节数组（字符串）或者一个整数值。

zipList数据结构如下：

| zlbytes           | zltail        | zllen    | zlentry | zlend               |
|:-----------------:|:-------------:|:--------:|:-------:|:-------------------:|
| ziplist所占用的内存的字节数 | 最后一个entry的偏移量 | entry的数量 | 实际数据    | 终止字节, 其值为全F, 即0xff. |

### Entry节点结构

#### Entry结构：

* ###### 情况1，一般结构： `<previous_entry_length> <encoding> <content>`
  
  ```properties
  previous_entry_length: 前一个entry的大小，编码方式见下文；
  encoding: 不同的情况下值不同，用于表示当前entry的类型和长度；
  content: 真实用于存储entry表示的数据。
  ```

* ###### 情况二，存储的是int类型时：`<previous_entry_length> <encoding>`
  
  ```
  在entry中存储的是int类型时，encoding和entry-data会合并在encoding中表示，此时没有entry-data字段； 
  redis中，在存储数据时，会先尝试将string转换成int存储，节省空间
  ```

#### 结构含义：

* ###### previous_entry_length：记录前一个entry节点的长度
  
  previous_entry_length的长度可以是1字节或者5字节：
  
  - 当前一个元素长度小于254（255用于zlend）的时候，previous_entry_length长度为1个字节；
  
  - 如果长度大于等于254的时候，previous_entry_length用5个字节表示：第一字节设置为254（0xFE），后面4个字节存储一个小端的无符号整型。
  
  由于previous_entry_length属性记录了前一个节点的长度，则可以通指针运算，根据当前节点的起始地址来结算前节点的起始地址。
  
  zipList的从尾到头的遍历操作，就是根据previous_entry_length属性来实现的。

* ###### encoding：记录节点的content属性所保存的数据类型和长度
  
  根据不同的encoding长度存储不同的数据类型：
  
  - 1、2、5字节长，entry值的最高位分别为00、01、10是字节数组编码；
  - 1字节长，entry值的最高位为11是整数编码；

* ###### content：保存节点的值
  
  节点值可以是一个字节数组或者整数，值的类型和长度由encoding属性决定。

### 连锁更新

###### zipList中有多个连续，且长度在250-253字节之间的节点；在进行新增/删除节点时，导致连续多次空间扩展操作称为“连锁更新”。

连锁更新在最坏的情况下需要对zipList执行N次空间重新分配操作，每次空间重新分配的最坏复杂度为O(N)，则连锁更新的最坏复杂度为O(N^2)。

尽管连锁更新的复杂度较高，但是真正造成性能问题的几率很低：

- 首先，zipList里面正好要有多个连续，且长度介于250-253字节之间的节点；
- 其次，只要连锁更新的节点数量不多，就不会导致性能问题。

### 

## 三、链表与快速列表-LinkedList&QuickList

redis 3.2版本之前使用的是`双向链表和压缩链表` 两种，因为双向链表占用的内存要比压缩链表高，所以创建链表时首先会创建`压缩链表`，在合适的时机会转化成`双向链表`。

redis 3.2之后使用的是`quicklist链表`。

### 快速列表-QuickList

quickList结构是在redis 3.2版本中新加的数据结构，用作**列表键的底层实现。**

quickList结构在src/quicklist.c中的解释为`A doubly linked list of ziplists`意思为一个由**ziplist组成的双向链表**。

宏观上，quickList是一个双向链表，微观上quickList的每个节点是zipList。

### QuickList结构

```c
typedef struct quicklist {
    //指向头部(最左边)quicklist节点的指针
    quicklistNode *head;
    //指向尾部(最右边)quicklist节点的指针
    quicklistNode *tail;
    //ziplist中的entry节点计数器
    unsigned long count;        /* total count of all entries in all ziplists */
    //quicklist的quicklistNode节点计数器
    unsigned int len;           /* number of quicklistNodes */
    //保存ziplist的大小，配置文件设定，占16bits
    int fill : 16;              /* fill factor for individual nodes */
    //保存压缩程度值，配置文件设定，占16bits，0表示不压缩
    unsigned int compress : 16; /* depth of end nodes not to compress;0=off */
} quicklist;
```

## 四、字典-Dict

###### 字典底层使用哈希表数据结构实现：一个哈希表里可以有多个哈希表节点，每个节点保存字典中的一个键值对。

###### 字典是Redis数据库、哈希键的底层实现。

### 字典（dict）结构

```c
typedef struct dict{
    //类型特定函数
    dictType *type;
    //私有数据
    void *privdata;
    //哈希表
    dictht ht[2];
    //rehash索引
    //当rehash不在进行时，值为-1
    int rehashidx;
}dict;
```

- ###### type属性是指向dictType结构的指针
  
  每个dictType结构，保存了一簇用于操作特定类型键值对的函数，Redis会为不同类型的字典设置不同的类型特定函数。

- ###### privdata属性保存了传给特定函数的参数。

- ###### ht属性包含了两个数组，ht[0]用于保存数据，ht[1]用于rehash。

- ###### trehashidx属性记录了rehash进度，没有rehash值为-1。

### 哈希表（dictht）结构

Redis字典中的哈希表结构由dict.h/dictht结构定义

```c
typedef struct dictht{
    //哈希表数组
    dictEntry **table;
    //哈希表大小
    unsigned long size;
    //哈希表大小掩码，用于计算索引值
    //总是等于 size-1
    unsigned long sizemask;
    //该哈希表已有节点的数量
    unsigned long used;
}dictht;
```

- ###### table属性是一个数组
  
  table 中每个元素都是指向 dict.h/dictEntry 结构的指针，每个哈希表节点dictEntry都保存着键值对；
  
  哈希表节点dictEntry 结构定义如下：
  
  ```c
  typedef struct dictEntry{
       //键
       void *key;
       //值
       union{
            void *val;
            uint64_tu64;
            int64_ts64;
       }v;
       //指向下一个哈希表节点，形成链表
       struct dictEntry *next;
  }dictEntry;
  ```
  
  - key 用来保存键，val 属性用来保存值，值可以是一个指针，也可以是uint64_t整数，也可以是int64_t整数。
  - next属性是指向另一个哈希表节点的指针，next指针可以将多个哈希值相同的键值对连接到一起，使用链地址法解决哈希冲突。

- ###### size属性记录了哈希表的大小，即table数组的大小。

- ###### used属性记录了哈希表已有节点（键值对）的数量。

- ###### sizemask属性值总是等于size-1，与哈希值决定键的索引位置。

### 哈希算法--murmurHash

当字典用作数据库、哈希键的底层实现时，Redis使用MurmurHash2算法（么么哈希算法）来计算键的hash值；

MurmurHash算法的优点在于：有规律的键，也能计算出很好的随机性，算法计算速度也非常快。

redis计算哈希值和索引的方法：

```python
#1、使用字典设置的哈希函数，计算键 key 的哈希值
hash = dict->type->hashFunction(key);

#2、使用哈希表的sizemask属性和第一步得到的哈希值，计算索引值
index = hash & dict->ht[x].sizemask;
```

### 解决hash冲突

###### Redis使用**链地址法**解决键冲突：

每个哈希表节点都有个next指针，多个哈希表节点可以用next指针构成一个单向链表，被分配到同一个索引上的名个节点可以用这个单向链表连接起来，这就解决了键冲突的问题。

### rehash

###### rehash用来扩展和收缩哈希表

###### Redis哈希表执行rehash 的步骤

1. 为字典的ht[1]哈希表分配空间；
   
   这个哈希表的空间大小取决于要执行的操作，以及ht[0] 当前包含的键值对数量（也即ht[o].use属性的值）：
   
   - 扩展操作：ht[1]的大小为第一个大于等于 ht [0].used*2的2^n（2的n次方幂）；
   - 收缩操作：ht[1]的大小为第一个大于等于ht[0].used的 2^n。

2. 将保存在ht[0] 中的所有键值对rehash到ht[1]上面；

3. 迁移ht[0]数据至ht[1]后，释放ht[0]，将ht[1]设置为ht[0]，并在ht[1]新创建一个空白哈希表，为下一次 rehash
   做准备。

###### 哈希表的扩展和收缩

哈希表负载因子

```python
#哈希表负载因子 = 哈希表已保存节点数量/哈希表大小
load_factor = ht[0].used/ht[0].size
```

- ###### 表扩展：当满足以下条件时即发生哈希表扩展
  
  1. 服务器没有执行bgsave命令（RDB）或bgrewriteaof命令（AOF），且哈希表负载因子大于等于1；
  
  2. 服务器执行bgsave命令（RDB）或bgrewriteaof命令（AOF），且哈希表负载因子大于等于5。
  
  使用不同的负载因子是因为：避免在子进程存在时进行扩展操作，减少不必要的写入，以节约内存。

- ###### 表收缩：当负载因子小于0.1时，则会发生哈希表收缩

### 渐进式rehash

为了避免rehash 对服务器性能造成影响，服务器不是一次性将ht[0]里面的所有键值对全部rehash 到ht[1]，而是分多次、渐进式地将ht[o]里面的键值对慢慢地 rehash到ht[1]中。 

###### 渐进式rehash步骤

1. 为ht[1]分配空间，让字典同时持有ht[0]和ht[1]两个hash表；
2. 将字典中维持rehash索引的属性rehashidx值设置为0，表示rehash正式开始；
3. 在rehash时，每次对字典的**增删改查**操作，程序会将ht[0]哈希表在rehashidx索引上的键值对rehash到ht[1]，rehash完成后，rehashidx属性值+1；（渐进式rehash重点）
4. ht[0]的所有键值对都rehash到ht[1]后，将rehashidx值置为-1，表示rehash完成。

###### 渐进式rehash好处

渐进式rehash采用分治方式：将rehash键值对所需要的计算工作均摊到对字典的增删改查操作上，从而避免了集中式rehash的庞大计算量。

###### 渐进式rehash期间的哈希表操作

- 在渐进式rehash执行期间，对字典的删改查操作，会在ht[0]与ht[1]之间同时进行；
- 在渐进式rehash执行期间，对字典的增操作，只会在ht[1]哈希表中进行。

### 字典重点知识点

- 字典被广泛用于实现 Redis 的各种功能，其中包括数据库和哈希键。

- Redis 中的字典使用哈希表作为底层实现，每个字典带有两个哈希表，一个平时使用，另一个仅在进行 rehash 时使用。

- 当字典被用作数据库的底层实现，或者哈希键的底层实现时，Redis使用 MurmurHash2算法来计算键的哈希值。

- 哈希表使用链地址法来解决键冲突，被分配到同一个索引上的多个键值对会连接成个单向链表。

- 在对哈希表进行扩展或者收缩操作时，程序需要将现有哈希表包含的所有键值对rehash 到新哈希表里面，并且这个rehash 过程并不是一次性地完成的，而是渐进式地完成的。

## 五、整数集合（intSet）

整数集合是集合键的底层实现之一：当集合中只包含整数元素且数量不多时，Redis就使用intSet作为集合键的底层实现。

### 整数集合结构

```c
typedef struct intset{
    //编码方式
    uint32_t encoding;
    //集合包含的元素数量
    uint32_t length;
    //保存元素的数组
    int8_t contents[];
}intset;
```

- contents数组属性：是整数数组的底层实现；
  
  整数集合的每个元素都是contents数组的一个数据项，各个项按照元素大小从小到大顺序排列，数组中不包含重复项；

- length属性：记录了整数集合中的元素数量，即contents数组的size；

- encoding属性：决定contents数组中存储的元素数据类型；
  
  - encoding为intset_enc_int16时，contents就是一个int16_t类型的数组；
  - encoding为intset_enc_int32时，contents就是一个int32_t类型的数组；
  - encoding为intset_enc_int64时，contents就是一个int64_t类型的数组。

### 整数集合升级

将一个比现有类型长的元素添加到整数集合时，整数集合需先完成升级操作，才能添加。

##### 升级步骤

1. 根据新元素类型，调整整数集合数组空间大小，并为新元素分配空间；
2. 将集合数组内现有元素转化为新元素类型，并保持原顺序将元素放置到新的位置；
3. 将新元素添加到数组里面。

升级添加元素复杂度为O(N)。

###### 升级的好处

- 提升灵活性：随意添加三种类型（int16_t,int32_t,int64_t）元素，而不必担心出现类型错误；
- 节约内存：在满足添加三种类型元素的同时，又确保在需要时进行升级。

### 整数集合降级

整数集合不支持降级，一旦升级，就会一直保持升级后的编码格式。

### 整数集合重点知识

- 整数集合是集合键的底层实现之一；
- 整数集合的底层实现为数组，这个数组以有序、无重复的方式保存集合元素，在有需要时，程序会根据新添加元素的类型，改变这个数组的类型。
- 升级操作为整数集合带来了操作上的灵活性，并且尽可能地节约了内存。
- 整数集合只支持升级操作，不支持降级操作。

## 六、跳跃表（SkipList）

Redis 使用跳跃表作为有序集合键的底层实现之一：当有序集合元素比较多，或者有序集合元素是比较长的字符串时，Redis 就会使用跳跃表来作为有序集合键的底层实现。

Redis只在两个地方使用了跳跃表：

- 实现有序集合键；
- 集群节点中用作内部数据结构。

### 跳跃表数据结构

跳跃表是一种有序数据结构，它通过在每个节点中维持多个指向其他节点的指针，从而达到快速访问节点的目的。

跳跃表支持平均O（logN)、最坏O(N) 复杂度的节点查找，还可以通过顺序性操作来批量处理节点。

在大部分情况下，跳跃表的效率可以和平衡树相媲美，并且因为跳跃表的实现比平衡树要来得更为简单，所以有不少程序都使用跳跃表来代替平衡树。

### 跳跃表结构

redis跳跃表由server.h/zskiplistNode 和 server.h/zskiplist结构组成

- #### zskiplistNode结构：表示跳跃表节点
  
  ```c
  typedef struct zskiplistNode {
      //成员
      sds ele;
      //分值
      double score;
      //后推指针
      struct zskiplistNode *backward;
      //层
      struct zskiplistLevel {
          //前进指针
          struct zskiplistNode *forward;
          //跨度
          unsigned long span;
      } level[];
  } zskiplistNode;
  ```
  
  - ###### zskiplistLevel属性--level数组：层
    
    创建一个新的跳跃表，程序就会根据幂次定律随机生成1-32之间值作为层的大小（层的高度）；
    
    程序可以通过这些层来加快访问其他节点的速度，一般来说，层的数量越多，访问速度越快。
  
  - ###### level[i].forward属性：前进指针
    
    每个层都有一个指向表尾方向的前进指针（level[i].forward属性），用于表头向表尾方向访问节点。
    
    前进指针用于遍历操作；
  
  - ###### level[i].span属性：跨度
    
    记录两个节点之间的距离；
    
    节点间的跨度越大，它们就相距得越远；指向NULL的前进指针，span属性为0；
    
    跨度用于计算排位：将遍历过程中所有的跨度相加，就是目标节点在跳跃表中的排位；
  
  - ###### backward属性：后退指针
    
    每个节点只有一个指向表头方向的后退指针，用于表位向表头方向访问节点，但每次后退至前一个节点。
  
  - ###### score属性：分值
    
    分值是一个double类型的浮点数，跳跃表中的所有节点都按照分值来排序；
  
  - ###### ele属性：成员
    
    成员是一个字符串对象，保存着SDS值，且唯一。

- #### zskiplist结构：保存跳跃表节点的信息
  
  ```c
  typedef struct zskiplist {
      //表头节点，表尾节点
      struct zskiplistNode *header, *tail;
      //表中节点数量
      unsigned long length;
      //表中最大节点层数
      int level;
  } zskiplist;
  ```
  
  - ###### header属性、tail属性：分别指向表头节点、表尾节点的指针
    
    通过这两个指针，程序定位表头和表尾的复杂度为O(1)；
  
  - ###### length属性：节点数量（跳跃表长度）
    
    通过length属性，程序获取跳跃表长度复杂度为O(1)；
  
  - ###### level属性：层高最大节点层数
    
    通过level属性，程序获取层高最大节点层数复杂度为O(1)；

### 跳跃表重点知识点

1. 跳跃表是有序集合的底层实现之一；
2. Redis 的跳跃表实现由 zskiplist 和zskiplistNode 两个结构组成，其中 zskiplist用于保存跳跃表信息（比如表头节点、表尾节点、长度），而zskiplistNode 则用于表示跳跃表节点。
3. 每个跳跃表节点的层高都是 1至 32之间的随机数。
4. 在同一个跳跃表中，多个节点可以包含相同的分值，但每个节点的成员对象必须是唯一的。
5. 跳跃表中的节点按照分值大小进行排序，当分值相同时，节点按照成员对象的大小进行排序。
