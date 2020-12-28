# zookeeper学习笔记

## Zookeeper：分布式协调服务

1. 配置管理（1M的数据）
2. 分布式同步（临时节点）
   - 分布式锁（设置一个临时节点，不能是序列节点）；
   - 锁依托一个父节点，且具备 -s ，说明这个父节点可以有多把锁，后面的锁盯着前面的锁（带队列或者事务模式的锁）
   - 集群管理，HA高可用选择主节点
   - 分布式ID生成器
3. 分组管理（path结构，父子节点）
4. 命名（序列节点）

## 官方网站

```http
https://zookeeper.apache.org/
```

## 下载地址

```http
https://zookeeper.apache.org/releases.html
```

## 文档地址

```http
https://zookeeper.apache.org/doc/r3.6.2/zookeeperOver.html
```

## 集群特征

zookeeper实现非常注重高性能、高可用性、严格有序的访问。可以在大型分布式系统中使用，可靠性使其不会成为单点故障，严格有序意味着可以在客户端实现复杂的同步原语。

zookeeper可以当作集群使用，很少会使用单实例。集群的两种方式：1.主从复制集群，2.无主集群（redis cluster无主模型，且数据是分片的）；对于数据来说：1.数据同步集群（每个节点存储全量数据），2.数据分片集群。

zookeeper是主从复制集群，每个节点的数据是完全一样的。写（增删改）只能发生在leader上，查可以发生在所有的节点上。主是单点，依然会存在单点的问题；

![zookeeper集群](/images/zookeeper集群.png)

### 数据可靠性

攘外必先安内：来源于快速恢复，无主的时候，必须选举出一个leader，才能对外提供服务

### paxos协议

```http
https://www.douban.com/note/208430424/
```

基于消息传递的一致性算法；到目前为止唯一的分布式一致性算法，其他的都是Paxos的改进和简化。Paxos有一个前提：没有拜占庭将军的问题（ 信任所有的通信环节）

​		Paxos描述了这样一个场景，有一个叫做Paxos的小岛(Island)上面住了一批居民，岛上面所有的事情由一些特殊的人决定，他们叫做议员(Senator)。议员的总数(Senator Count)是确定的，不能更改。岛上每次环境事务的变更都需要通过一个提议(Proposal)，每个提议都有一个编号(PID)，这个编号是一直增长的，不能倒退。每个提议都需要超过半数((Senator Count)/2 +1)的议员同意才能生效。每个议员只会同意大于当前编号的提议，包括已生效的和未生效的。如果议员收到小于等于当前编号的提议，他会拒绝，并告知对方：你的提议已经有人提过了。这里的当前编号是每个议员在自己记事本上面记录的编号，他不断更新这个编号。整个议会不能保证所有议员记事本上的编号总是相同的。现在议会有一个目标：保证所有的议员对于提议都能达成一致的看法。

​		好，现在议会开始运作，所有议员一开始记事本上面记录的编号都是0。有一个议员发了一个提议：将电费设定为1元/度。他首先看了一下记事本，嗯，当前提议编号是0，那么我的这个提议的编号就是1，于是他给所有议员发消息：1号提议，设定电费1元/度。其他议员收到消息以后查了一下记事本，哦，当前提议编号是0，这个提议可接受，于是他记录下这个提议并回复：我接受你的1号提议，同时他在记事本上记录：当前提议编号为1。发起提议的议员收到了超过半数的回复，立即给所有人发通知：1号提议生效！收到的议员会修改他的记事本，将1好提议由记录改成正式的法令，当有人问他电费为多少时，他会查看法令并告诉对方：1元/度。

![paxos协议过程](/images/paxos协议过程.png)

​		现在看冲突的解决：假设总共有三个议员S1-S3，S1和S2同时发起了一个提议:1号提议，设定电费。S1想设为1元/度, S2想设为2元/度。结果S3先收到了S1的提议，于是他做了和前面同样的操作。紧接着他又收到了S2的提议，结果他一查记事本，咦，这个提议的编号小于等于我的当前编号1，于是他拒绝了这个提议：对不起，这个提议先前提过了。于是S2的提议被拒绝，S1正式发布了提议: 1号提议生效。S2向S1或者S3打听并更新了1号法令的内容，然后他可以选择继续发起2号提议。

![paxos协议解决冲突过程](/images/paxos协议解决冲突过程.png)

### zab协议：原子广播协议

![zookeeper的ZAB协议](/images/zookeeper的ZAB协议.png)

好，我觉得Paxos的精华就这么多内容。现在让我们来对号入座，看看在ZK Server里面Paxos是如何得以贯彻实施的。

- 小岛(Island)——ZK Server Cluster
- 议员(Senator)——ZK Server
- 提议(Proposal)——ZNode Change(Create/Delete/SetData…)
- 提议编号(PID)——Zxid(ZooKeeper Transaction Id)
- 正式法令——所有ZNode及其数据

貌似关键的概念都能一一对应上，但是等一下，Paxos岛上的议员应该是人人平等的吧，而ZK Server好像有一个Leader的概念。没错，其实Leader的概念也应该属于Paxos范畴的。如果议员人人平等，在某种情况下会由于提议的冲突而产生一个“活锁”（所谓活锁我的理解是大家都没有死，都在动，但是一直解决不了冲突问题；所有人都提议，每个人都没有过半）。Paxos的作者Lamport在他的文章”The Part-Time Parliament“中阐述了这个问题并给出了解决方案——在所有议员中设立一个总统，只有总统有权发出提议，如果议员有自己的提议，必须发给总统并由总统来提出。好，我们又多了一个角色：总统。

**总统——ZK Server Leader**

又一个问题产生了，总统怎么选出来的？oh, my god! It’s a long story. 在淘宝核心系统团队的Blog上面有一篇文章是介绍如何选出总统的，有兴趣的可以去看看：http://rdc.taobao.com/blog/cs/?p=162。现在我们假设总统已经选好了，下面看看ZK Server是怎么实施的。

#### 情况一：获取数据

屁民甲(Client)到某个议员(ZK Server)那里询问(Get)某条法令的情况(ZNode的数据)，议员毫不犹豫的拿出他的记事本(local storage)，查阅法令并告诉他结果，同时声明：我的数据不一定是最新的。你想要最新的数据？没问题，等着，等我找总统Sync一下再告诉你。

#### 情况二：改数据

屁民乙(Client)到某个议员(ZK Server)那里要求政府归还欠他的一万元钱，议员让他在办公室等着，自己将问题反映给了总统，总统询问所有议员的意见，多数议员表示欠屁民的钱一定要还，于是总统发表声明，从国库中拿出一万元还债，国库总资产由100万变成99万。屁民乙拿到钱回去了(Client函数返回)。

#### 情况三：leader挂了，重新选举

总统突然挂了，议员接二连三的发现联系不上总统，于是各自发表声明，推选新的总统，总统大选期间政府停业，拒绝屁民的请求。

> 呵呵，到此为止吧，当然还有很多其他的情况，但这些情况总是能在Paxos的算法中找到原型并加以解决。这也正是我们认为Paxos是Zookeeper的灵魂的原因。当然ZK Server还有很多属于自己特性的东西：Session, Watcher，Version等等等等，需要我们花更多的时间去研究和学习。

### watch

![zookeeper的watch](/images/zookeeper的watch.png)

客户端先向ZooKeeper服务端成功注册想要监听的节点状态，同时客户端本地会存储该监听器相关的信息在WatchManager中，当ZooKeeper服务端监听的数据状态发生变化时，ZooKeeper就会主动通知发送相应事件信息给相关会话客户端，客户端就会在本地响应式的回调相关Watcher的Handler。

![zookeeper-watch](/images/zookeeper-watch.png)

#### ZooKeeper的Watch特性

- Watch是一次性的，每次都需要重新注册，并且客户端在会话异常结束时不会收到任何通知，而快速重连接时仍不影响接收通知
- Watch的回调执行都是顺序执行的，并且客户端在没有收到关注数据的变化事件通知之前是不会看到最新的数据，另外需要注意不要在Watch回调逻辑中阻塞整个客户端的Watch回调
- Watch是轻量级的，WatchEvent是最小的通信单元，结构上只包含通知状态、事件类型和节点路径。ZooKeeper服务端只会通知客户端发生了什么，并不会告诉具体内容

#### Zookeeper 的三种watch

- exites能监控自身节点的增删，以及数据的修改，不能监控子节点
- getData能监控自身节点的删除，以及自身节点数据的修改
- getchildren 能监控自身节点的删除，不能监控自身节点数据的修改，能监控子节点的增加和删除，不能监控子节点数据的修改不能监控孙子节点的增加

#### Watch事件状态

- KeeperState:Disconneced 连接失败
- KeeperState:SyncConnected 连接成功
- KeeperState:AuthFailed 认证失败
- KeeperState:Expired 会话过期

#### Watch事件类型

- EventType:NodeCreated Znode创建时间
- EventType:NodeDeleted Znode删除
- EventType:NodeDataChanged Znodes数据修改
- EventType:NodeChildrentChanged 孩子节点数据修改

#### Zookeeper的状态

- CONNECTING Zookeeper服务器不可用，客户端处于尝试链接状态
-  ASSOCIATING 
- CONNECTED 链接建立，可以与Zookeeper服务器正常通信
- CONNECTEDREADONLY 处于只读状态的链接状态，只读模式可以在构造Zookeeper时指定
- CLOSED 会话关闭，显式调用Zookeeper的close方法
- AUTH_FAILED 建立链接时，认证失败
- NOT_CONNECTED 链接断开状态

## 性能测试

ZooKeeper吞吐量，随读/写比的变化而定。在读取数量超过写入次数的应用程序中，由于写入涉及同步所有服务器的状态，因此该性能特别高。（对于协调服务来说，读取次数多于写入次数）。ZooKeeper应用程序可在数千台计算机上运行，并且在读取比写入更常见的情况下，其性能最佳，比率约为10：1。

![ZooKeeper吞吐量-随读-写比的变化而定](/images/ZooKeeper吞吐量-随读-写比的变化而定.jpg)

横轴：读取所占的比例，纵轴：每秒的查询量。当全是读取的时候，就算是3个节点的集群也能喉住80000+的请求数量。

存在错误时的可靠性表明部署如何响应各种故障。图中标记的事件如下：

1. 追随者的失败和恢复
2. 失败和其他追随者的恢复
3. 领导者的失败
4. 两个追随者的失败和恢复
5. 另一个领导者的失败

![zookeeper存在错误时的可靠性](/images/zookeeper存在错误时的可靠性.jpg)

1. 追随者失败并迅速恢复，则ZooKeeper能够在失败的情况下维持高吞吐量。
2. 领导者选举算法允许 leader 恢复得足够快，ZooKeeper只需不到200毫秒即可选出新的领导者。
3. 随着追随者的恢复，ZooKeeper能够在开始处理请求后再次提高吞吐量。

## 数据结构

Zookeeper 的数据结构类似于文件系统，不同的是 zookeeper 的每个节点都可以存储少量的数据，最大支持存储1M的数据。zookeeper数据保存在内存中，可以实现高吞吐量和低延迟数量。

![zookeeper数据结构](/images/zookeeper数据结构.jpg)

- 目录树结构
  - 持久节点（PERSISTENT）：节点创建后，一直存在，直到主动删除了该节点。
  - 临时节点（EPHEMERAL）：生命周期和客户端会话绑定，一旦客户端会话失效，这个节点就会自动删除。
  - 序列节点（SEQUENTIAL）：多个线程创建同一个顺序节点时候，每个线程会得到一个带有编号的节点，节点编号是递增不重复的

## 优势

ZooKeeper非常快速且非常简单。但是，由于其目标是作为构建更复杂的服务（例如同步）的基础，因此它提供了一组保证。这些是：

- 顺序一致性：来自客户端的更新将按照发送的顺序应用（写请求由主节点进行）
- 原子性：更新成功或失败，没有部分结果（过半成功，并同步节点和数据）
- 单个系统映像：无论客户端连接到哪个服务器，客户端都将看到相同的服务视图（主从复制模型决定的）
- 可靠性：应用更新后，此更新将一直持续到客户端覆盖更新为止（持久性）
- 及时性：确保系统的客户视图在特定时间范围内是最新的（最终一致性，过半）

## 配置文件属性描述

1. tickTime：默认2000，单位ms，主从之间心跳的时间间隔

2. initLimit：默认10次，从节点和主节点建立连接的时候，主节点允许 initLimit * tickTime 的时间延迟

3. syncLimit：默认5次，主节点下发同步任务时，从节点如果在 syncLimit * tickTime 的时间内没有返回的时候，就认为有问题

4. dataDir：数据持久化存储路径

5. clientPort：默认2181，客户端连接服务端的端口

6. maxClientCnxnx：最大客户端连接数，默认60

7. 集群配置：过半数：行数/2+1

   - server.1=node01:2888:3888
   - server.2=node02:2888:3888
   - server.3=node03:2888:3888
   - server.4=node04:2888:3888:observer

   2888端口的作用：当是leader的时候，开启的和从节点建立通信的端口，用于数据同步。

   3888端口的作用：当无主的时候，通过这个端口建立连接，进行投票，选择一个leader，让这个leader开启一个2888的端口，其他节点连接这个leader的2888的端口进行通信

8. 启动zookeeper之前，准备myid，并配置环境变量；具体安装过程参考【大数据中的安全过程】

   echo 1 > dataDir/myid

   echo 2 > dataDir/myid

   echo 3 > dataDir/myid

   echo 4 > dataDir/myid

## 主节点选举流程

> 第一次启动：按照启动顺序，当达到过半数时，server.n中n最大的那台机器就是leader。后面再启动其他节点时，即使有server.n比当前leader的n大，也只能追随当前leader节点。
>
> 运行一段时间时候，再启动时leader的选择逻辑时，先看哪些节点的数据最完整（看事务id的最大值进行比较），如果都比较完整，再看server.n中n的最大值，是leader。

![zookeeper建立连接的过程](/images/zookeeper建立连接的过程.png)

## 角色

### Leader

多个Follower和Observer追随该角色，参与增删改查的数据操作

### Follower

该角色才能支持选举，有机会能够被选中成为Leader，参与数据同步和数据查询的操作

### Observer

追随Leader，参与数据同步和数据查询的操作

## 数据时二进制安全的

外面的客户端给我推送什么样的字节数据，我原封不动的给你存进来，你那边的编解码器我不关心

## 全局事务id

> zookeeper是顺序执行的，体现在这个id身上的，所有的这种增删改这种写操作，他们都会递交给leader，因为leader是单机，所以单机维护一个单调递增的计数器很容器。

1. 事务id：一个64位的字节；0x代表16进制，16进制的每一位代表4个2进制位，那么两位代表一个字节(8位)，低32位是事务递增序列，高32位表示的是第几代leader。每次leader更新换代，后面的事务id从0开始重新计算。
2. cZxid：即Created ZXID，表示该数据节点被创建时的事务ID
3. mZxid：即Modified ZXID，表示该节点最后一次被更新时的事务ID
4. pZxid：当前节点创建的最后那一个的节点的事务id
5. ephemeralOwner：创建该临时节点的会话的sessionID。如果该节点是持久节点，那么这个属性值为0
6. 客户端连接服务端之后，客户端挂了sessionID就没了，那么临时节点就会被删除掉
7. 客户端连接服务端之后，服务端挂了，那么临时节点是否会丢失？
   - 不会丢失
   - 因为zookeeper统一了视图（单个系统影像），连sessionID都会被同步到所有的集群节点里
   - 一个新的客户端连接进来，会消耗一个事务id，说明client的sessionID会写给所有节点
   - 客户端断开连接时，会走一个删除的逻辑，要进行统一视图，所有节点都会删，会再次消耗一个事务id

## 原语API

- *create* : 在树中的某个位置创建一个节点
  - -e 表示创建的是一个临时节点
  - -s 多个线程创建同一个顺序节点时，每个线程会得到一个带有编号的节点，节点编号是递增不重复的（不会覆盖创建，分布式情况下统一命名）
- *delete* : 删除节点
- *exists* : 测试某个节点是否存在于某个位置
- *get data* : 从节点读取数据
- *set data* : 将数据写入节点
- *get children* : 检索节点的子节点列表
- *sync* : 等待数据传播

## JavaAPI

> zookeeper有session会话的概念，没有连接池的概念，每一个客户端连接都会产生一个新的session会话

### 获取Zookeeper连接，并连接监听器

```java
/**
 * 获取 ZooKeeper 对象
 * @param address
 * @return
 */
public static ZooKeeper getZooKeeper(String address){
	try {
		CountDownLatch countDownLatch = new CountDownLatch(1);
		ZooKeeper zooKeeper = new ZooKeeper(address, 1000, new DefaultWatcher(countDownLatch));

		countDownLatch.await();
		return zooKeeper;
	} catch (IOException | InterruptedException e) {
		e.printStackTrace();
		return null;
	}
}
```

```java
public class DefaultWatcher implements Watcher {
    CountDownLatch countDownLatch;
    public DefaultWatcher(CountDownLatch countDownLatch) {
        this.countDownLatch = countDownLatch;
    }
    @Override
    public void process(WatchedEvent watchedEvent) {
        switch (watchedEvent.getState()) {
            case Disconnected:
                break;
            case SyncConnected:
                countDownLatch.countDown();
                break;
            case AuthFailed:
                break;
            case ConnectedReadOnly:
                break;
            case SaslAuthenticated:
                break;
            case Expired:
                break;
            default: break;
        }
    }
}
```

### 添加节点：zk.create

```java
// CreateMode.EPHEMERAL;			临时节点
// CreateMode.EPHEMERAL_SEQUENTIAL;  临时顺序节点
// CreateMode.PERSISTENT;			持久节点
// CreateMode.PERSISTENT_SEQUENTIAL; 持久顺序节点

// ZooDefs.Ids.ANYONE_ID_UNSAFE;    任何ID不安全
// ZooDefs.Ids.AUTH_IDS;            身份验证id
// ZooDefs.Ids.CREATOR_ALL_ACL;	    创造者所有ACL
// ZooDefs.Ids.OPEN_ACL_UNSAFE;	    开放的ACL不安全
// ZooDefs.Ids.READ_ACL_UNSAFE;	    读ACL不安全

/**
 * create 方法参数
 *    第一个参数 路径
 *    第二个参数  值  bytes
 *    第三个参数  对节点的访问控制
 *    第四个参数  节点的类型 短暂  永久  序号
 * @throws KeeperException
 * @throws InterruptedException
 */
@Test
public void create() throws KeeperException, InterruptedException {
	String s = zk.create("/node5", "cjw".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
	System.out.println(s);
}
```

### 删除节点：zk.delete

```java
/**
 * 删除节点
 *    非空节点删除不掉
 * @throws InterruptedException
 * @throws KeeperException
 */
@Test
public void remove() throws KeeperException, InterruptedException {
	zk.delete("/node3", 2);
}
```

### 判断节点是否存在：zk.exists

```java
/**
 * 判断节点是否存在
 * @throws InterruptedException
 * @throws KeeperException
 */
@Test
public void exit() throws KeeperException, InterruptedException {
	// 设置为 true 会调用 zk中的监听器
	Stat exists = zk.exists("/node5", true);
	if(exists == null) {
		System.out.println("该节点不存在!");
	} else {
		System.out.println("该节点存在!");
		System.out.println(exists.getDataLength());
	}
}
```

### 获取节点内容：zk.getData

```java
/**
 * 获取节点的内容
 * @throws InterruptedException
 * @throws KeeperException
 */
@Test
public void getData() throws KeeperException, InterruptedException {
	byte[] data = zk.getData("/node3", true, null);
	System.out.println(new String(data));
}
```

### 修改节点内容：zk.setData

```java
/**
 * 修改节点内容
 * 	  version -1 自动维护
 * @throws InterruptedException
 * @throws KeeperException
 */
@Test
public void update() throws KeeperException, InterruptedException {
	Stat stat = zk.setData("/node3", "相对论".getBytes(), -1);
	System.out.println(stat.getVersion());
}
```

### 获取子节点：zk.getChildren

```java
/**
 * 获取子节点
 * @throws InterruptedException
 * @throws KeeperException
 */
@Test
 public void getchildrens() throws KeeperException, InterruptedException {
	 List<String> children = zk.getChildren("/", true);
	 for (int i = 0; i < children.size(); i++) {
		 String s =  children.get(i);
		 System.out.println(s);
	 }
 }
```

### 同步节点数据：zk.sync

```java
/**
 * 同步节点数据
 * @throws InterruptedException
 * @throws KeeperException
 */
@Test
public void sync() throws KeeperException, InterruptedException {
	zk.sync("/name2", new AsyncCallback.VoidCallback() {
		@Override
		public void processResult(int rc, String path, Object ctx) {

		}
	}, new Object());
}
```

### 获取子节点的监听器

```java
/**
 * 监听事件:子节点的数量发生改变时触发(只会触发一次)
 */
@Test
public void getchildrens2() throws KeeperException, InterruptedException {
	List<String> children = zk.getChildren("/", new Watcher() {
		@Override
		public void process(WatchedEvent event) {
			System.out.println("子节点的数量发生改变!");
		}
	});
	for (int i = 0; i < children.size(); i++) {
		String s =  children.get(i);
		System.out.println(s);
	}
	Thread.sleep(Long.MAX_VALUE);
}
```

### 获取节点数据的监听器

```java
/**
 * 监听事件:节点数据发送改变时触发(只会触发一次)
 */
@Test
public void getdata() throws KeeperException, InterruptedException {
	byte[] data = zk.getData("/name2", new Watcher() {
		@Override
		public void process(WatchedEvent event) {
			System.out.println("节点数据发送了改变!");
		}
	}, null);
	System.out.println(new String(data));
	Thread.sleep(Long.MAX_VALUE);
}
```





