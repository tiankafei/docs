# redis介绍

## redis原理

redis是单进程，单线程，为什么还那么快？

1. 完全基于内存，绝大部分请求是纯粹的内存操作，非常快速。内存比磁盘快了10W倍

   内存寻址是ns(纳秒)，磁盘寻址是ms(毫秒)，中间差了10W倍

2. 使用多路I/O复用模型的非阻塞IO，Redis的Epoll 事件模型处理请求，任意一个客户端的资源就绪之后就可以被执行，且能够顺序执行

3. 由于是单线程，因此减少了线程切换的消耗

5. 支持管道，一次发送多次请求，减少频繁IO

   1. 一次性大量插入数据

   2. 从文件中批量插入数据

      文件的换行符需要注意：redis-cli中只支持dos格式的换行符 `\r\n` ，如果你在Linux下、Mac下或者Windows下创建的文件，最好都转个码。没有转码的文件,执行会失败。

      安装转码命令

      ```shell
      yum install -y unix2dos
      ```


## linux内核

在linux系统中：“一切皆文件”。每一个socket连接都会生成一些文件描述符，由linux内核接收并进行转发给应用进程或线程。

```shell
#查看文件描述

ps -ef | grep redis
cd /proc/进程id号/fd
ll
```

## redis安装

1. 安装wget工具

   ```shell
   yum install -y wget
   ```

2. 下载redis

   ```shell
   wget http://download.redis.io/releases/redis-5.0.7.tar.gz
   ```

3. 解压

   ```shell
   tar -zvxf redis-5.0.7.tar.gz
   ```

4. 进入源码目录

   ```shell
   cd redis-5.0.7/src
   ```

5. 执行编译

   ```shell
   yum -y install gcc gcc-c++ kernel-devel
   make & make install
   ```

6. 进入源码目录，查看是否生成了可执行程序

   ```shell
   ll
   ```
   
7. 重新安装到制定目录

   ```shell
   make install PREFIX=/usr/local/redis5
   ```

8. 设置redis环境变量

   ```shell
   vi /etc/profile
   ```

   ```sh
   export JAVA_HOME=/usr/java/default
   export REDIS_HOME=/usr/local/redis5
   export PATH=$PATH:$JAVA_HOME/bin:$REDIS_HOME/bin
   ```

   ```shell
   source /etc/profile
   ```

9. redis实例安装

   ```shell
   cd
   cd redis-5.0.7/utils
   ./install_server.sh
   
   #a)一个物理机中可以有多个redis实例（进程），通过port区分
   #b)可执行程序就一份在目录，但是内存中未来的多个实例需要各自的配置文件，持久化目录等资源
   #c)service   redis_6379  start/stop/stauts     >   linux   /etc/init.d/**** 
   #d)脚本还会帮你启动！
   
   Config file    : /etc/redis/6379.conf
   Log file       : /var/log/redis_6379.log
   Data dir       : /var/lib/redis/6379
   Executable     : /usr/local/bin/redis-server
   ```

10. 停止redis

    ```shell
    service redis_6379 stop
    ```

11. 启动redis

    ```shell
    service redis_6379 start
    ```

12. 查看redis状态

    ```shell
    service redis_6379 status
    ```

13. 查看redis启动是否成功

    ```shell
    ps -ef | grep redis
    ```

14. 客户端连接命令

    ```shell
    redis-cli -h localhost -p 6379 -a password
    ```

15. 更新redis配置，增加密码

    ```sh
    vi /etc/redis/6379.conf
    ```

    ```shell
    bind 127.0.0.1 192.168.0.101
    
    # masterauth <master-password>
    requirepass tiankafei
    ```

16. ```shell
    systemctl enable redis_6379.service
    ```

17. 设置密码之后，停止服务会报错

    ```shell
    vi /etc/init.d/redis_6379
    ```

    ```sh
    # 增加密码这一行
    PASSWORD=$(cat $CONF|grep '^\s*requirepass'|awk '{print $2}'|sed 's/"//g')
    
    # $CLIEXEC -p $REDISPORT shutdown 替换为
    if [ -z $PASSWORD ]
    then 
        $CLIEXEC -p $REDISPORT shutdown
    else
        $CLIEXEC -a $PASSWORD -p $REDISPORT shutdown
    fi
    ```

18. 重新加载

    ```
    systemctl daemon-reload
    ```

## redis使用

1. 正反向索引

   正向（从左到右）：顺序从0开始，+1

   反向（从右到左）：顺序从-1开始，-1

   通过start=0,end=-1可以获取当前key的所有数据

2. Redis key值是二进制安全的，这意味着可以用任何二进制序列作为key值

   从形如”foo”的简单字符串到一个JPEG文件的内容都可以。空字符串也是有效key值。

3. 关于key的几条规则

   1. 太长的键值不是个好主意，例如1024字节的键值就不是个好主意，不仅因为消耗内存，而且在数据中查找这类键值的计算成本很高。
  2. 太短的键值通常也不是好主意，如果你要用”u:1000:pwd”来代替”user:1000:password”，这没有什么问题，但后者更易阅读，并且由此增加的空间消耗相对于key object和value object本身来说很小。当然，没人阻止您一定要用更短的键值节省一丁点儿空间。
   3. 最好坚持一种模式。例如：”object-type:id:field”就是个不错的注意，像这样”user:1000:password”。我喜欢对多单词的字段名中加上一个点，就像这样：”comment:1234:reply.to”。

### string：字符串、数组、bitmap

1. set 命令后面可以跟的参数

   nx：当key不存在的时候，才会去创建，如果存在，则会返回失败

   ```
   只能新建
   应用场景：分布式锁
   多个线程同时用这个命令进行赋值，谁赋值成功，谁就拿到了这个锁
   ```

   xx：当key存在的时候，才可以操作，如果不存在，则返回失败

   ```
   只能更新
   ```

2. key中会存在一个type，用来描述值得数据类型，用来区分是字符串、数值、bitmap

   针对字符串可以有一些运算api

   ```
   应用场景：
   抢购，秒杀（扣减库存），详情页的数值，点赞，评论
   优点：
   规避高并发下，对数据库的事务操作，完全由redis的内存操作代替
   ```

3. 对于数值型的计算能够保证其原子性

   INCR是原子操作意味着什么呢？就是说即使多个客户端对同一个key发出INCR命令，也决不会导致竞争的情况。例如如下情况永远不可能发生：『客户端1和客户端2同时读出“10”，他们俩都对其加到11，然后将新值设置为11』。最终的值一定是12，read-increment-set操作完成之前，其他客户端不会在同一时间执行任何命令。

4. string值的长度不能超过512 MB

### Bit arrays：或者说 simply bitmaps

通过特殊的命令，你可以将 String 值当作一系列 bits 处理：可以设置和清除单独的 bits，数出所有设为 1 的 bits 的数量，找到最前的被设为 1 或 0 的 bit，等等。

1. 按位(1个字节有8位)的索引，值只能是0或1

2. setbit，指定的偏移位置是位的索引的位置

3. bitpos，后面跟的start,end是字节的索引位置，返回的是位的索引位置

4. bitcount，后面跟的start,end是字节的索引位置，返回的是出现的次数 

5. bitop，按位与(有0则0，全1为1)，按位或(有1则1，全0为0)

   ```
   使用场景：
   1. 统计用户登录天数，且任意时刻或时间段
   bitcount key 0 -1（统计所有天数登录的次数之和）
   
   2. 用户只要登录，就送礼物。有2亿用户，需要备多少礼物
   活跃用户统计：1-3号连续登录，去重
   天为key，每一个用户有占一位作为值，最后使用bitcount按位或运算
   ```

### hash：由field和关联的value组成的map

值的操作类似string的处理

值如果是数值的时候，可进行数值操作

```
应用场景：
详情页的数据集
```

### list：按插入顺序排序的字符串元素的集合

Redis lists基于双向Linked Lists实现，key上面存在两个属性，一个指向头部，一个指向尾部，这意味着即使在一个list中有数百万个元素，在头部或尾部添加一个元素的操作，其时间复杂度也是常数级别的。

1. lpush 最后一个push的值始终在左侧；rpush 最后一个push的值始终的右侧

2. lpop 从左侧开始取值，取出之后同时删除；rpop 从右侧开始取值，取出之后同时删除

   ```shell
   lpush	lpop
   rpush	rpop
   #后进先出	栈(同向命令)
   lpush	rpop
   rpush	lpop
   #先进先出	队列(反向命令)
   ```

3. lrange key 0 -1得到所有值

4. lindex key index

5. lset key index value

6. lrem 正数时从左往右移除，负数时从右往左移除

7. linsert 从左往右找到第一个元素，然后在该元素之前或者之后插入

   ```shell
   index
   #数组
   ```

8. blpop、brpop 如果没有key的值时，则一直处于阻塞状态；如果有值，则直接拿出

   当多个消费者取一个key时，生产者生产了一个key以后，按照消费者的排队顺序进行依次取出

   ```shell
   #单播队列（FIFO先进先出）
   ```

9. ltrim 对两端的数据进行移除

### set：不重复且无序的字符串元素的集合

sadd k2 1 2 3 4 5

sadd k3 4 5 6 7 8

1. 求交集

   ```shell
   #直接把交集结果返回
   sinter k2 k3
   #把交集结果放到targetkey中
   sinterstore targetkey k2 k3
   ```

2. 求并集

   ```shell
   #直接把并集结果返回
   sunion k2 k3
   #把并集结果放到targetkey中
   sunion targetkey k2 k3
   ```

3. 求差集

   ```shell
   #直接把差集结果返回
   sdiff k2 k3
   sdiff k3 k2
   # 把差集结果放到targetkey中
   sdiffstore target k2 k3
   sdiffstore target k3 k2
   #sdiff 具有方向性,取出第一个key的差集，想要取出第二个的差集交换位置即可
   ```

4. 随机取出n个值，值并不从集合中删除

   ```shell
   srandmember key count -count
   如果个数为正数，返回的结果可能会出现小于等于5的情况，但能够保证返回的结果不会有重复的值出现
   如果个数为负数，则会一直返回5个结果集，但并不能保证结果集当中是否有重复的值出现
   
   #应用场景：
   抽奖：一共有10个奖品；用户数可能小于10个，也可能大于10个；中奖也分是否可以重复中奖
   ```

5. spop 随机取出一个值，并从集合中删除

   ```shell
   #应用场景：
   年会抽奖：一个人只能抽中奖一次，中奖率会不断变化
   ```

### sorted set：通过score值进行排序的集合

类似Sets,但是每个字符串元素都关联到一个叫*score*浮动数值（floating number value）。里面的元素总是通过score进行着排序，所以不同的是，它是可以检索的一系列元素。（例如你可能会问：给我前面10个或者后面10个元素）。每个值都会关联一个分数。如果分值一样，默认按照名称排序

1. 首先是一个去重的集合，如果有相同的值，则分数需要进行聚合，

   聚合的种类：最小值、最大值、求个、平均值、权重

2. 根据分数进行排序

   ```shell
   #默认按照分值从小到大排序（物理内存左小右大）
   zadd k1 8 apple 2 banana 3 orange
   #查看k1的数据集合
   zrange k1 0 -1 withscores
   ```

3. 按照分值取数

   zrangebyscore k1 2 4 取出分值范围内的数据(包含最小值和最大值的结果)

4. 取出top或者low

   ```shell
   #最小的n个 downn
   ZRANGE k1 0 downn
   #最大的n个 topn
   ZREVRANGE k1 0 topn
   
   #用负数仅仅是从n的那个位置一直到最后，依然是左小右大，依然是从小到大排的
   ZRANGE k1 -topn -1
   ```

5. 可以对分值进行操作，操作后之后，时时根据分值进行排序

   ```shell
   #排序是如何实现的
   存储结构：skip list(跳跃表)
   一级索引（在原链表的基础上，元素随机出现一级索引位置）
   二级索引（在一级索引的基础上，元素随机出现在二级索引的位置）
   三级索引...同理
   从最小的索引位置，一直找到原链表的位置，然后进行更新索引
   ```

6. 集合操作：

   支持交集：分值需要聚合

   支持并集：分值需要聚合

   支持差集

## redis发布订阅

一个发布者，多个客户端都可以接收

```shell
#监听管道：只能接收到监听之后客户端发的消息，监听之前客户端发的消息接收不到
SUBSCRIBE 管道名称
#客户端往管道里面放消息
PUBLISH 管道名称 message

应用场景：
直播，群聊
```

聊天记录存储：数据库存储全量数据

1. 实时的记录：存储到redis，使用发布订阅进行消息接收，数据可以异步存储到数据库

2. 3天内历史记录：存储到redis，使用sort set，把时间作为记录的分值

   ZREMRANGEBYRANK，按照索引位置进行删除

   ZREMRANGEBYSCORE，按照分值进行删除，因为时间是分值，可以仅仅保留3天内的数据

3. 更久之前的历史记录，存储到数据库，从数据库查询

   1. clinet------>redis

   2. redis------>other clinet

      redis------>other reids存储sort set

      redis------>service------>kafka------>dbservice------>mysql

## redis事务

因为redis是单进程，单线程的，所以当多个客户端发送事务时，根据哪个客户端发出的exec先到达，则先执行哪个客户端的事务，其他的客户端发出的事务有可能会报错，有可能会被撤销，主要看是否使用了watch命令。

1. watch：使用乐观锁的方式进行监听数据是否发生变化。如果数据没有变化，则事务会执行；如果值发生了变化，则事务自动撤销，不执行任何语句。

   使用无参数的unwatch命令可以取消监视

2. multi：开启事务

3. exec：执行所有语句。当EXEC被调用时，不管事务是否成功执行，对所有键的监视都会被取消。

   另外，当客户端断开连接时，该客户端对键的监视也会被取消。

4. discard：撤销事务。当执行DISCARD命令时，事务会被放弃，事务队列会被清空，并且客户端会从事务状态中退出。

5. **对于数值型的计算，redis可以保证其原子性**

**为什么 Redis 不支持回滚（roll back）**

如果你有使用关系式数据库的经验， 那么 “Redis 在事务失败时不进行回滚，而是继续执行余下的命令”这种做法可能会让你觉得有点奇怪，以下是这种做法的优点：

1. Redis 命令只会因为错误的语法而失败（并且这些问题不能在入队时发现），或是命令用在了错误类型的键上面：这也就是说，从实用性的角度来说，失败的命令是由编程错误造成的，而这些错误应该在开发的过程中被发现，而不应该出现在生产环境中
2. 因为不需要对回滚进行支持，所以 Redis 的内部可以保持简单且快速

有种观点认为 Redis 处理事务的做法会产生 bug，然而需要注意的是，在通常情况下，回滚并不能解决编程错误带来的问题。举个例子，如果你本来想通过INCR命令将键的值加上1，却不小心加上了2，又或者对错误类型的键执行了INCR，回滚是没有办法处理这些情况的。

## redis命令

```http
http://doc.redisfans.com/
```

### 对key操作的命令

- [DEL](http://doc.redisfans.com/key/del.html)
- [DUMP](http://doc.redisfans.com/key/dump.html)
- [EXISTS](http://doc.redisfans.com/key/exists.html)
- [EXPIRE](http://doc.redisfans.com/key/expire.html)
- [EXPIREAT](http://doc.redisfans.com/key/expireat.html)
- [KEYS](http://doc.redisfans.com/key/keys.html)
- [MIGRATE](http://doc.redisfans.com/key/migrate.html)
- [MOVE](http://doc.redisfans.com/key/move.html)
- [OBJECT](http://doc.redisfans.com/key/object.html)
- [PERSIST](http://doc.redisfans.com/key/persist.html)
- [PEXPIRE](http://doc.redisfans.com/key/pexpire.html)
- [PEXPIREAT](http://doc.redisfans.com/key/pexpireat.html)
- [PTTL](http://doc.redisfans.com/key/pttl.html)
- [RANDOMKEY](http://doc.redisfans.com/key/randomkey.html)
- [RENAME](http://doc.redisfans.com/key/rename.html)
- [RENAMENX](http://doc.redisfans.com/key/renamenx.html)
- [RESTORE](http://doc.redisfans.com/key/restore.html)
- [SORT](http://doc.redisfans.com/key/sort.html)
- [TTL](http://doc.redisfans.com/key/ttl.html)
- [TYPE](http://doc.redisfans.com/key/type.html)
- [SCAN](http://doc.redisfans.com/key/scan.html)

### String操作的命令

- [APPEND](http://doc.redisfans.com/string/append.html)
- [BITCOUNT](http://doc.redisfans.com/string/bitcount.html)
- [BITOP](http://doc.redisfans.com/string/bitop.html)
- [DECR](http://doc.redisfans.com/string/decr.html)
- [DECRBY](http://doc.redisfans.com/string/decrby.html)
- [GET](http://doc.redisfans.com/string/get.html)
- [GETBIT](http://doc.redisfans.com/string/getbit.html)
- [GETRANGE](http://doc.redisfans.com/string/getrange.html)
- [GETSET](http://doc.redisfans.com/string/getset.html)
- [INCR](http://doc.redisfans.com/string/incr.html)
- [INCRBY](http://doc.redisfans.com/string/incrby.html)
- [INCRBYFLOAT](http://doc.redisfans.com/string/incrbyfloat.html)
- [MGET](http://doc.redisfans.com/string/mget.html)
- [MSET](http://doc.redisfans.com/string/mset.html)
- [MSETNX](http://doc.redisfans.com/string/msetnx.html)
- [PSETEX](http://doc.redisfans.com/string/psetex.html)
- [SET](http://doc.redisfans.com/string/set.html)
- [SETBIT](http://doc.redisfans.com/string/setbit.html)
- [SETEX](http://doc.redisfans.com/string/setex.html)
- [SETNX](http://doc.redisfans.com/string/setnx.html)
- [SETRANGE](http://doc.redisfans.com/string/setrange.html)
- [STRLEN](http://doc.redisfans.com/string/strlen.html)

### Hash操作的命令

- [HDEL](http://doc.redisfans.com/hash/hdel.html)
- [HEXISTS](http://doc.redisfans.com/hash/hexists.html)
- [HGET](http://doc.redisfans.com/hash/hget.html)
- [HGETALL](http://doc.redisfans.com/hash/hgetall.html)
- [HINCRBY](http://doc.redisfans.com/hash/hincrby.html)
- [HINCRBYFLOAT](http://doc.redisfans.com/hash/hincrbyfloat.html)
- [HKEYS](http://doc.redisfans.com/hash/hkeys.html)
- [HLEN](http://doc.redisfans.com/hash/hlen.html)
- [HMGET](http://doc.redisfans.com/hash/hmget.html)
- [HMSET](http://doc.redisfans.com/hash/hmset.html)
- [HSET](http://doc.redisfans.com/hash/hset.html)
- [HSETNX](http://doc.redisfans.com/hash/hsetnx.html)
- [HVALS](http://doc.redisfans.com/hash/hvals.html)
- [HSCAN](http://doc.redisfans.com/hash/hscan.html)

### List操作的命令

- [BLPOP](http://doc.redisfans.com/list/blpop.html)
- [BRPOP](http://doc.redisfans.com/list/brpop.html)
- [BRPOPLPUSH](http://doc.redisfans.com/list/brpoplpush.html)
- [LINDEX](http://doc.redisfans.com/list/lindex.html)
- [LINSERT](http://doc.redisfans.com/list/linsert.html)
- [LLEN](http://doc.redisfans.com/list/llen.html)
- [LPOP](http://doc.redisfans.com/list/lpop.html)
- [LPUSH](http://doc.redisfans.com/list/lpush.html)
- [LPUSHX](http://doc.redisfans.com/list/lpushx.html)
- [LRANGE](http://doc.redisfans.com/list/lrange.html)
- [LREM](http://doc.redisfans.com/list/lrem.html)
- [LSET](http://doc.redisfans.com/list/lset.html)
- [LTRIM](http://doc.redisfans.com/list/ltrim.html)
- [RPOP](http://doc.redisfans.com/list/rpop.html)
- [RPOPLPUSH](http://doc.redisfans.com/list/rpoplpush.html)
- [RPUSH](http://doc.redisfans.com/list/rpush.html)
- [RPUSHX](http://doc.redisfans.com/list/rpushx.html)

### Set操作的命令

- [SADD](http://doc.redisfans.com/set/sadd.html)
- [SCARD](http://doc.redisfans.com/set/scard.html)
- [SDIFF](http://doc.redisfans.com/set/sdiff.html)
- [SDIFFSTORE](http://doc.redisfans.com/set/sdiffstore.html)
- [SINTER](http://doc.redisfans.com/set/sinter.html)
- [SINTERSTORE](http://doc.redisfans.com/set/sinterstore.html)
- [SISMEMBER](http://doc.redisfans.com/set/sismember.html)
- [SMEMBERS](http://doc.redisfans.com/set/smembers.html)
- [SMOVE](http://doc.redisfans.com/set/smove.html)
- [SPOP](http://doc.redisfans.com/set/spop.html)
- [SRANDMEMBER](http://doc.redisfans.com/set/srandmember.html)
- [SREM](http://doc.redisfans.com/set/srem.html)
- [SUNION](http://doc.redisfans.com/set/sunion.html)
- [SUNIONSTORE](http://doc.redisfans.com/set/sunionstore.html)
- [SSCAN](http://doc.redisfans.com/set/sscan.html)

### SortedSet操作的命令

- [ZADD](http://doc.redisfans.com/sorted_set/zadd.html)
- [ZCARD](http://doc.redisfans.com/sorted_set/zcard.html)
- [ZCOUNT](http://doc.redisfans.com/sorted_set/zcount.html)
- [ZINCRBY](http://doc.redisfans.com/sorted_set/zincrby.html)
- [ZRANGE](http://doc.redisfans.com/sorted_set/zrange.html)
- [ZRANGEBYSCORE](http://doc.redisfans.com/sorted_set/zrangebyscore.html)
- [ZRANK](http://doc.redisfans.com/sorted_set/zrank.html)
- [ZREM](http://doc.redisfans.com/sorted_set/zrem.html)
- [ZREMRANGEBYRANK](http://doc.redisfans.com/sorted_set/zremrangebyrank.html)
- [ZREMRANGEBYSCORE](http://doc.redisfans.com/sorted_set/zremrangebyscore.html)
- [ZREVRANGE](http://doc.redisfans.com/sorted_set/zrevrange.html)
- [ZREVRANGEBYSCORE](http://doc.redisfans.com/sorted_set/zrevrangebyscore.html)
- [ZREVRANK](http://doc.redisfans.com/sorted_set/zrevrank.html)
- [ZSCORE](http://doc.redisfans.com/sorted_set/zscore.html)
- [ZUNIONSTORE](http://doc.redisfans.com/sorted_set/zunionstore.html)
- [ZINTERSTORE](http://doc.redisfans.com/sorted_set/zinterstore.html)
- [ZSCAN](http://doc.redisfans.com/sorted_set/zscan.html)

### Pub/Sub发布订阅操作的命令

- [PSUBSCRIBE](http://doc.redisfans.com/pub_sub/psubscribe.html)
- [PUBLISH](http://doc.redisfans.com/pub_sub/publish.html)
- [PUBSUB](http://doc.redisfans.com/pub_sub/pubsub.html)
- [PUNSUBSCRIBE](http://doc.redisfans.com/pub_sub/punsubscribe.html)
- [SUBSCRIBE](http://doc.redisfans.com/pub_sub/subscribe.html)
- [UNSUBSCRIBE](http://doc.redisfans.com/pub_sub/unsubscribe.html)

### Transaction事务操作的命令

- [DISCARD](http://doc.redisfans.com/transaction/discard.html)
- [EXEC](http://doc.redisfans.com/transaction/exec.html)
- [MULTI](http://doc.redisfans.com/transaction/multi.html)
- [UNWATCH](http://doc.redisfans.com/transaction/unwatch.html)
- [WATCH](http://doc.redisfans.com/transaction/watch.html)

### Script脚本的命令

- [EVAL](http://doc.redisfans.com/script/eval.html)
- [EVALSHA](http://doc.redisfans.com/script/evalsha.html)
- [SCRIPT EXISTS](http://doc.redisfans.com/script/script_exists.html)
- [SCRIPT FLUSH](http://doc.redisfans.com/script/script_flush.html)
- [SCRIPT KILL](http://doc.redisfans.com/script/script_kill.html)
- [SCRIPT LOAD](http://doc.redisfans.com/script/script_load.html)

### Connection连接的命令

- [AUTH](http://doc.redisfans.com/connection/auth.html)
- [ECHO](http://doc.redisfans.com/connection/echo.html)
- [PING](http://doc.redisfans.com/connection/ping.html)
- [QUIT](http://doc.redisfans.com/connection/quit.html)
- [SELECT](http://doc.redisfans.com/connection/select.html)

### 服务器命令

- [BGREWRITEAOF](http://doc.redisfans.com/server/bgrewriteaof.html)
- [BGSAVE](http://doc.redisfans.com/server/bgsave.html)
- [CLIENT GETNAME](http://doc.redisfans.com/server/client_getname.html)
- [CLIENT KILL](http://doc.redisfans.com/server/client_kill.html)
- [CLIENT LIST](http://doc.redisfans.com/server/client_list.html)
- [CLIENT SETNAME](http://doc.redisfans.com/server/client_setname.html)
- [CONFIG GET](http://doc.redisfans.com/server/config_get.html)
- [CONFIG RESETSTAT](http://doc.redisfans.com/server/config_resetstat.html)
- [CONFIG REWRITE](http://doc.redisfans.com/server/config_rewrite.html)
- [CONFIG SET](http://doc.redisfans.com/server/config_set.html)
- [DBSIZE](http://doc.redisfans.com/server/dbsize.html)
- [DEBUG OBJECT](http://doc.redisfans.com/server/debug_object.html)
- [DEBUG SEGFAULT](http://doc.redisfans.com/server/debug_segfault.html)
- [FLUSHALL](http://doc.redisfans.com/server/flushall.html)
- [FLUSHDB](http://doc.redisfans.com/server/flushdb.html)
- [INFO](http://doc.redisfans.com/server/info.html)
- [LASTSAVE](http://doc.redisfans.com/server/lastsave.html)
- [MONITOR](http://doc.redisfans.com/server/monitor.html)
- [PSYNC](http://doc.redisfans.com/server/psync.html)
- [SAVE](http://doc.redisfans.com/server/save.html)
- [SHUTDOWN](http://doc.redisfans.com/server/shutdown.html)
- [SLAVEOF](http://doc.redisfans.com/server/slaveof.html)
- [SLOWLOG](http://doc.redisfans.com/server/slowlog.html)
- [SYNC](http://doc.redisfans.com/server/sync.html)
- [TIME](http://doc.redisfans.com/server/time.html)

## redis穿透

缓存穿透，是指查询一个数据库一定不存在的数据，从而会让数据库多做很多无用的操作，如果并发量大，或者恶意攻击，会造成数据库承担很大的压力，更有甚者会造成宕机。

缓存穿透解决方案：

1. 缓存空对象，当请求到达数据库时，如果查询结果为空，可将空值放入缓存，需要增加过期时间。

2. **布隆过滤器**拦截，把要查询的数据缓存起来（通过二进制向量和一系列随机映射函数，达到占用较少的内存，缓存较大的数据量），但是并不能达到百分之百的拦截，当请求过来时，再使用第一种方案，缓存空值，可以较大程度上减少缓存穿透的情况。

   布隆过滤器：

   ```shell
   wget https://github.com/RedisBloom/RedisBloom/archive/master.zip
   yum install -y unzip
   unzip master.zip
   cd RedisBloom-master
   make
   cp redisbloom.so /usr/local/redis5
   service redis_6379 stop
   redis-server --loadmodule /usr/local/redis5/redisbloom.so
   ```

   原理

   1. 你有啥
   2. 有的像bitmap中标记
   3. 请求的可能被误标记
   4. 但是一定概率会大量减少放行，穿透
   5. 而且成本低

   使用bitmap进行存储，数据库里有的元素(根据什么进行搜搜，就可以把这个数据放到bitmap里)的映射关系

   一个元素会经过n个或者k个不同的映射函数，会把相对应的位置由0变为1，多个元素产生的结果可能会出现碰撞，有一定的几率都是1

   用户请求过来时，搜索的元素经过bitmap映射得到0时，说明数据库里一定没有，此时就可以返回了。如果得到1时，说明数据库有的几率很大，就可以放行，到数据库里进行查询。为1时数据库里没有的几率很小，一般不会超过百分之1。

其他过滤器

1. Bloom Filter 系列改进之Counting Bloom Filter
2. 布谷鸟过滤器

## redis缓存和数据库的差别

1. 缓存的数据是不重要的
2. 缓存的数据不是全量的
3. 缓存应该随着访问进行变化，应该是经常访问的热数据（内存大小是有限制的，也就是其瓶颈）

```
# 控制最大内存(1-10G)
maxmemory bytes
#内存达到最大值时，配置驱逐策略
maxmemory-policy noeviction
1. noeviction 默认值：返回错误当内存限制达到并且客户端尝试执行会让更多内存被使用的命令（大部分的写入指令，但DEL和几个例外）
2. allkeys-lru  尝试回收最少使用的键（LRU），使得新添加的数据有空间存放。
3. volatile-lru 尝试回收最少使用的键（LRU），但仅限于在过期集合的键,使得新添加的数据有空间存放。
4. allkeys-random 回收随机的键使得新添加的数据有空间存放。
5. volatile-random 回收随机的键使得新添加的数据有空间存放，但仅限于在过期集合的键。
6. volatile-ttl 回收在过期集合的键，并且优先回收存活时间（TTL）较短的键,使得新添加的数据有空间存放。（找那个离过期时间最近的key剔除掉）

allkeys（所有的key）、volatile（马上要过期的key）
LFU（最少使用次数，碰了多少次）
LRU（最少没有用：多久没碰）

作为缓存时：一定不能用noeviction
作为数据库时：一定要用noeviction
```

一般的经验规则

- 如果没有键满足回收的前提条件的话，策略**volatile-lru**, **volatile-random**以及**volatile-ttl**就和noeviction 差不多了
- 使用**allkeys-lru**策略：当你希望你的请求符合一个幂定律分布，也就是说，你希望部分的子集元素将比其它其它元素被访问的更多。如果你不确定选择什么，这是个很好的选择。.
- 使用**allkeys-random**：如果你是循环访问，所有的键被连续的扫描，或者你希望请求分布正常（所有元素被访问的概率都差不多）。
- 使用**volatile-ttl**：如果你想要通过创建缓存对象时设置TTL值，来决定哪些对象应该被过期。
- **allkeys-lru** 和 **volatile-random**策略对于当你想要单一的实例实现缓存及持久化一些键时很有用。不过一般运行两个实例是解决这个问题的更好方法

选择正确的回收策略是非常重要的，这取决于你的应用的访问模式，不过你可以在运行时进行相关的策略调整，并且监控缓存命中率和没命中的次数，通过RedisINFO命令输出以便调优。

## redis过期时间

过期时间：你可以对key设置一个过期时间，当这个时间到达后会被删除。精度可以使用毫秒或秒。

EXPIRE key 时间	设置过期时间（倒计时，定时）

PERSIST key 时间	剔除过期时间

ttl key 查看过期时间还剩多少

1. 每次访问并不能重新计算过期时间
2. 重新修改值之后，会直接剔除过期时间

**redis如何淘汰过期时间的key**

1. 被动的访问时判定

   当客户端尝试访问的时候，key会被发现并主动剔除该key（过期的key有可能一辈子都不会被再次访问，所以这种方式并不能保证一定会把过期的key删除掉）

2. 间接主动方式：每10秒要做的事情

   1. 测试随机的20个keys进行相关过期的检测
   2. 删除所有已经过期的key
   3. 如果有多余25%的keys过期，重复步骤1
      1. 如果有满足条件3，则立即对随机的20个key进行过期检测
      2. 如果没有满足条件3，则会在另一个10秒才会对随机的20key进行过期检测

   这是一个平凡的概率算法，基本上的假设是，我们的样本是这个秘钥控件，并且我们不断重复过期检测，直到过期的keys百分之百低于25%，这意味着，在任何给定的时刻，最多会清楚25%的过期的keys。

   目的：稍微牺牲下内存，但是保住了redis性能为王。

## redis持久化

**持久化无外乎：镜像+日志**

### RDB

也称快照方式，配置每隔一段时间执行一次全量备份，Redis将数据集快照保存在磁盘上，保存在一个名为dump.rdb的二进制文件中，也可以**手动调用SAVE或BGSAVE命令**。

**原理**：主进程调用fork函数生成一个子进程（fork之后，只是复制指针，而不是复制内存，所以时间会非常快，几乎不用考虑。同时主线程实现了Copy-on-Write，当值发生变化时，指针指向一个新的地址，旧的地址的数据保持不变），子进程进行磁盘I/O操作，**操作完成后替换旧的RDB文件**。

**优点**：非常适合做备份与回滚到指定的时间点，例如我们可以每天晚上2点执行定时计划全量备份一次Redis中的数据，以后我们进行恢复的时候可以将Redis恢复到指定的时间点的版本；与AOF相比使用**RDB方式性能较高**；与AOF相比Redis**重启的速度较快**。

**缺点**：相比AOF丢失的数据可能会更多，比如设置1小时备份一次快照，那么最多会损失1小时的数据。

RDB配置：

```shell
save 900 1
save 300 10
save 60 10000
#配置解释：从下往上执行，先最后一个配置，
# 1. 在 60 秒内，如果操作次数超过 10000 次，则直接后台调用执行备份；如果没有超过 10000 次，则向上看第二个判断，此时超过了10，则立即执行备份；
# 2. 在 300 秒内，如果操作次数超过了 10 次，则直接后台调用执行备份，如果没有超过 10 次，则向上看第1个判断，此时超过了 1， 则立即执行备份。
# 3. 在 900 秒被，如果操作次数超过了 1 次，则立即执行备份
```



### AOF：Append-Only-File 持久化：保存写状态

以追加的方式记录Redis的写操作，并在Redis重启时进行重放（与MySQL的binlog日志的原理是一样的）。当AOF日志过大时，redis支持日志重写。【这里提供一个小知识点，在Redis中是先执行命令再记录日志到AOF，这也是Redis事务不支持回滚的原因：即使发生异常，没有可以用来执行回滚操作的日志。而传统的数据库例如MySQL都是先做日志然后再做操作，所以能够支持回滚】。

AOF相关配置：

```shell
# 默认关闭，若要开启将no改为yes
appendonly no
# append文件的名字
appendfilename "appendonly.aof"
# AOF文件的写入方式
# always一旦缓存区内容发生变化就写入AOF文件中
appendfsync always
# everysec 每个一秒将缓存区内容写入文件 默认开启的写入方式
appendfsync everysec
# 将写入文件的操作交由操作系统决定
appendfsync no
# 当AOF文件大小的增长率大于该配置项时自动开启重写（这里指超过原大小的100%）。
auto-aof-rewrite-percentage 100
# 当AOF文件大小大于该配置项时自动开启重写
auto-aof-rewrite-min-size 64mb
```

**原理**：操作系统将写操作首先记录到内存缓冲区中，然后使用fsync函数将数据刷新到磁盘中。

**优点**：如果不考虑性能，AOF可以最大限度保证数据完整性，可以设置每发生一次写操作就调用一次fsync函数；更加灵活，可以使用不同的fsync策略：

1. always：一旦缓存区内容发生变化就立即写入AOF文件中（最大限度保证数据的完整性，极端情况下只会丢失一条数据）
2. everysec（默认）：每个一秒将缓存区内容写入文件（最多只会丢失这一秒内且比缓存区大小小1的数据量）
3. no：将写入文件的操作交由操作系统决定，当缓冲区满的时候，才会触发写操作（会丢失一个缓冲区的数据）

**缺点**：与RDB方式相比，相同数据集大小AOF占用空间更大；若调用fsync的频率过快，性能会变差。

**需要注意的是**：AOF文件损坏？AOF文件中可能有一条命令是不完整的，比如发生正在写入的时候断电的这种情况，redis支持重放这样的AOF文件，他会在启动日志中记录错误命令的行数，并在重放时对该行进行忽略。

#### AOF重写：BGREWRITEAOF

- AOF 持久化是通过保存被执行的写命令来记录数据库状态的，所以AOF文件的大小随着时间的流逝一定会越来越大；影响包括但不限于：对于Redis服务器，计算机的存储压力；AOF还原出数据库状态的时间增加。
- 为了解决AOF文件体积膨胀的问题，Redis提供了AOF重写功能：Redis服务器可以创建一个新的AOF文件来替代现有的AOF文件，新旧两个文件所保存的数据库状态是相同的，但是新的AOF文件不会包含任何浪费空间的冗余命令，通常体积会较旧AOF文件小很多。
- AOF重写并不需要对原有AOF文件进行任何的读取，写入，分析等操作，这个功能是通过读取服务器当前的数据库状态来实现的。

**实现原理**

- 首先从数据库中读取键现在的值，然后用一条命令去记录键值对，代替之前记录该键值对的多个命令;
- 实际为了避免执行命令时造成客户端输入缓冲区溢出，重写程序在处理`list hash set zset`时，会检查键所包含的元素的个数，如果元素的数量超过了`redis.h/REDIS_AOF_REWRITE_ITEMS_PER_CMD`常量的值，那么重写程序会使用多条命令来记录键的值，而不是单使用一条命令。该常量默认值是64，即每条命令设置的元素的个数 是最多64个，使用多条命令重写实现集合键中元素数量超过64个的键；

**AOF后台重写**

- `aof_rewrite`函数可以创建新的AOF文件，但是这个函数会进行大量的写入操作，所以调用这个函数的线程将被长时间的阻塞，因为Redis服务器使用单线程来处理命令请求；所以如果直接是服务器进程调用`AOF_REWRITE`函数的话，那么重写AOF期间，服务器将无法处理客户端发送来的命令请求；
- Redis不希望AOF重写会造成服务器无法处理请求，所以Redis决定将AOF重写程序放到子进程（后台）里执行。这样处理的最大好处是： 
  - 子进程进行AOF重写期间，主进程可以继续处理命令请求
  - 子进程带有主进程的数据副本，使用子进程而不是线程，可以避免在锁的情况下，保证数据的安全性

**使用子进程进行AOF重写的问题**

子进程在进行AOF重写期间，服务器进程还要继续处理命令请求，而新的命令可能对现有的数据进行修改，这会让当前数据库的数据和重写后的AOF文件中的数据不一致

**如何修正**

- 为了解决这种数据不一致的问题，Redis增加了一个**AOF重写缓存**，这个缓存在fork出子进程之后开始启用，Redis服务器主进程在执行完写命令之后，会同时将这个写命令追加到AOF缓冲区和AOF重写缓冲区
- 即子进程在执行AOF重写时，主进程需要执行以下三个工作： 
  - 执行client发来的命令请求；
  - 将写命令追加到现有的AOF文件中；
  - 将写命令追加到AOF重写缓存中。

要保证的是：

- AOF缓冲区的内容会定期被写入和同步到AOF文件中，对现有的AOF文件的处理工作会正常进行
- 从创建子进程开始，服务器执行的所有写操作都会被记录到AOF重写缓冲区中，能够保证当前数据库的数据和重写后的AOF文件中的数据是一致的。

完成AOF重写之后

当子进程完成对AOF文件重写之后，它会向父进程发送一个完成信号，父进程接到该完成信号之后，会调用一个信号处理函数，该函数完成以下工作

- 将AOF重写缓存中的内容全部写入到新的AOF文件中；这个时候新的AOF文件所保存的数据库状态和服务器当前的数据库状态一致；
- 对新的AOF文件进行改名，原子的覆盖原有的AOF文件；完成新旧两个AOF文件的替换

当这个信号处理函数执行完毕之后，主进程就可以继续像往常一样接收命令请求了。在整个AOF后台重写过程中，只有最后的“主进程写入命令到AOF缓存”和“对新的AOF文件进行改名，覆盖原有的AOF文件。”这两个步骤（信号处理函数执行期间）会造成主进程阻塞，在其他时候，AOF后台重写都不会对主进程造成阻塞，这将AOF重写对性能造成的影响降到最低。

**触发AOF后台重写的条件**

- AOF重写可以由用户通过调用`BGREWRITEAOF`手动触发。
- 服务器在AOF功能开启的情况下，会维持以下三个变量：
  - 记录当前AOF文件大小的变量`aof_current_size`。
  - 记录最后一次AOF重写之后，AOF文件大小的变量`aof_rewrite_base_size`。
  - 增长百分比变量`aof_rewrite_perc`。
- 每次当`serverCron`（服务器周期性操作函数）函数执行时，它会检查以下条件是否全部满足，如果全部满足的话，就触发自动的AOF重写操作：
  - 没有BGSAVE命令（RDB持久化）/AOF持久化在执行；
  - 没有BGREWRITEAOF在进行；
  - 当前AOF文件大小要大于`server.aof_rewrite_min_size`（默认为1MB），或者在`redis.conf`配置了`auto-aof-rewrite-min-size`大小；
  - 当前AOF文件大小和最后一次重写后的大小之间的比率等于或者等于指定的增长百分比（在配置文件设置了`auto-aof-rewrite-percentage`参数，不设置默认为100%）

### 混合方式：RDB与AOF混合使用

将 RDB文件的内容和增量的 AOF 日志文件存在一起。这里的 AOF 日志不再是全量的日志，而是自持久化开始到持久化结束的这段时间发生的增量 AOF 日志。

### Redis官方建议

使用混合方式进行Redis的持久化。并且我们需要确保避免在RDB快照操作已经在进行时触发AOF重写，或者在AOF重写过程中允许BGSAVE，防止两个Redis后台进程同时执行磁盘I/O。

## 缓存的击穿

**描述**：缓存击穿是指缓存中没有但数据库中有的数据（一般是缓存时间到期），这时由于并发用户特别多，同时读缓存没读到数据，又同时去数据库去取数据，引起数据库压力瞬间增大，造成过大压力。

**解决方案**：

1. 设置热点数据永远不过期。
2. 从缓存中取数时，增加锁

## 缓存的雪崩

**描述**：缓存雪崩是指缓存中数据大批量到过期时间，而查询数据量巨大，引起数据库压力过大甚至宕机。和缓存击穿不同的是，缓存击穿指并发查同一条数据，缓存雪崩是不同数据都过期了，很多数据都查不到从而查数据库。

**解决方案**：

1. 缓存数据的过期时间设置随机，防止同一时间大量数据过期现象发生。
2. 如果缓存数据库是分布式部署，将热点数据均匀分布在不同的缓存数据库中。
3. 设置热点数据永远不过期。

## 缓存的一致性（双写）



## redis集群、主从复制

![集群的几种模式](/images\集群的几种模式.png)

1. 单点故障（主从集群：横向扩充）

2. 承担的压力大（读写分离：横向扩充）

3. 容量受限（：纵向扩充，按照业务线进行逻辑拆分，同一个业务线数据还很大，可以进行分片）

 **发生在客户端的解决方案**：redis server的连接成本很高，增加一层代理：1.反向代理，2.负载均衡

 1. 按照业务线进行拆分，客户端决定什么数据放到哪个redis集群下（纵向的每一个redis都是一个集群：主从集群，读写分类的）

 2. 算法拆分，key做hash取模（弊端：模数值必须固定，影响分布式下的扩展性）

 3. 随机拆分（自己都不知道扔到哪个实例上了，每一个实例的数据都不是完整的。典型应用场景：消息队列）

 4. 一致性哈希环（映射）算法，hash环上有0-2^32个点，各节点拿着一个固定的策略之进行hash算法，能够映射一个值，在hash环上就是是一个点。等数据来了的时候，拿key值进行hash算法，也能够得到一个值，对应hash环上的一个点。

    hash环的特点：只有节点映射出的点才是物理的，key映射的点都是虚拟的，物理的点用treeMap进行封装。在这个结构中虚拟的点总能找到一个离他最近的物理的点，直接把数据存上去即可。

    此时如果新增了一个node节点，得到一个物理的点，但是这个点离key值近了，数据就拿不到了。

    优点：加节点，可以分担其他节点的压力，不会造成全局洗牌。

    缺点：新增节点会造成一小部分数据不能命中（两种问题：1.会对数据库造成击穿，把压力压倒了数据库里；2.每次取离key值最近的两个物理节点，如果两个都取不到值，再去数据库里取）。

    一个node节点，可以通过多个值进行多次映射，得到多个值，可以在环上映射多个物理节点，可以解决数据倾斜的问题。

    更倾向于做为缓存使用，而不是数据库用。

**twitter/twemproxy** 可以使用作为代理。

**predixy** 可以使用作为代理。

**cluster** 可以使用作为代理。

![redis-cluster集群](/images\redis-cluster集群.png)

集群高可用：ACP原则：可用性，一致性，分区容错性


## redis开发

## redis总结

1. 单实例的，基于内存的，所以它的特征就是快
2. 因为是单实例的，延伸出了三个问题：单点故障，承担的流量过大，容量受限
3. 集群模型：复制集群（主从复制），主是单点，需要做HA高可用（sentinel），数据不能时时同步（最终一致性，但是当主或者从有一台机器挂了，数据就不能同步了，连最终一致性都谈不上），一致性的三种方案：同步：强一致；异步：可能会不一直；异步增加中间层：最终一致。
4. 集群模型：sharding分片，数据是分片的，在一个节点里看不到所有的数据，
5. 穿透、击穿、雪崩；完成分布式协调很难，需要分布式锁
6. Redisson：分布式锁