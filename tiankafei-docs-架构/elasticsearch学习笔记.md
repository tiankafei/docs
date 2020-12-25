# Elasticsearch学习笔记

## 帮助文档

### 中文官方文档（较老）

```http
https://www.elastic.co/guide/cn/elasticsearch/guide/current/getting-started.html#getting-started
```

### 英文最新文档（较新）

```http
https://www.elastic.co/guide/en/elasticsearch/reference/7.10/getting-started.html
```

## ES核心概念和原理

### 什么是搜索

百度、垂直搜索（站内搜索）。搜索：通过一个**关键词**或一段描述，得到你想要（相关度高）的结果

### 如何实现搜索功能

关系型数据库：性能差、不可靠、结果不准确（相关度低）

### 倒排索引、`Lucene`和全文检索

1. 倒排索引的数据结构（存储的数据）
   1. 包含这个关键词的`document list`
   2. 关键词在每个doc中出现的次数`TF term frequency `
   3. 关键词在整个索引中出现的次数`IDF inverse doc frequency`（值越大，代表相关度越低）
   4. 关键词在当前`doc`中出现的次数
   5. 每个`doc`的长度，越长相关度越低
   6. 包含这个关键词的所有`doc`的平均长度
2. `Lucene`：`jar`包，帮我们创建倒排索引，提供了复杂的`API`
3. 如果用`Luncene`做集群，会有哪些问题
   - 节点一旦宕机，节点数据丢失，后果不堪设想，可用性差
   - 自己维护，麻烦（自己创建管理索引），单台节点的承载请求的能里是有限的，需要人工做负载。

![倒排索引](/images/倒排索引.png)

### 倒排索引的特点

1. 倒排索引的数据量 > 原始数据量
2. 倒排索引做的是完全匹配，不需要全表扫描
3. 倒排索引记录着这个词出现在原始数据的那个主键，根据主键去原始数据中查询是很快的

### Elasticsearch

1. 特点
   - 分布式
   - 高性能
   - 高可用
   - 可伸缩
   - 易维护
2. 优点
   - 面向开发者友好，屏蔽了Lucene的复杂特性，集群自动发现（cluster discovery）
   - 自动维护数据在多个节点上的建立
   - 会帮我们做搜索请求的负载均衡
   - 自动维护冗余副本，保证了部分节点宕机的情况下仍然不会有任何数据丢失
   - `ES`基于`Lucene`提供了很多高级功能：复合查询、聚合分析、基于地理位置等
   - 对于大公司，可以构建几百台服务器的大型分布式集群，处理PB级别数据；对于小公司，开箱即用，门槛低上手简单
   - 相比传统数据库，提供了全文检索，同义词处理（美丽的 cls > 漂亮的 cls），相关度排名。聚合分析以及海量数据的近实时（NTR）处理，这些传统数据库完全做不到
3. 应用领域
   - 百度（全文检索，高亮、搜索推荐）
   - 各大网站的用户行为日志（用户点击、浏览、收藏、评论）
   - BI（business Intelligence商业智能），数据分析，数据挖掘统计
   - Github：代码托管平台，几千亿行代码
   - ELK：Elasticsearch（数据存储）、Logstash（日志采集）、Kibana（可视化）

### ES 核心概念

1. `cluster`（集群）：每个集群至少包含两个节点
2. `node`：集群中的每个节点，一个节点不代表一台服务器
3. `field`：一个数据字段，与`index`和`type`一起，可以定位一个`doc`
4. `document`：`es`最小的数据单元，通常是以`json`的形式存储的
5. `type`：逻辑上的数据分类，`es7.x`中删除了`type`的概念
6. `index`：一类相同或者类似的`doc`，比如一个员工索引，商品索引
7. `shard`分片：P分片，R副本
   - 一个`index`包含多个`shard`，默认5个分片，默认每个分片分配一个副本，分片的数量在创建索引的时候设置，如果想修改，需要重建索引
   - 每个`shard`都是一个`lucene`实例，有完整的创建索引的处理请求能力
   - es会自动在`nodes`上为我们做`shard`均衡
   - 一个`doc`是不可能同时存在与多个分片中的，但是可以存在于多个副本中
   - 分片和对应的副本不能同时存在于同一个节点，所以最低的可用配置是两个节点，互为主备

## 环境安装

### docker 安装配置 es

#### 拉取镜像

```sh
docker pull elasticsearch:7.6.2
```

#### 启动es

```shell
docker run -d -p 9200:9200 -p 9300:9300 --restart=always -e "discovery.type=single-node" --name=elasticsearch elasticsearch:7.6.2
```

#### 修改配置

1. 进入容器

   ```shell
   docker exec -it elasticsearch bash
   ```

2. vi config/elasticsearch.yml

   ```shell
   cluster.name: "my-application"
   node.name: "node-1"
   network.host: 0.0.0.0
   ```

3. 重启容器

   ```shell
   docker restart elasticsearch
   ```

#### 访问地址

```http
http://<IP>:<PORT>
http://192.168.21.123:9200/
```

### docker 安装配置 kibana

#### 拉取镜像

```shell
docker pull kibana:7.6.2
```

#### 启动kibana

```shell
docker run -d -p 5601:5601 --restart=always --name kibana kibana:7.6.2
```

#### 出现的问题修改配置

1. 如果出现以下页面：Kibana server is not ready yet，说明Kibana没有找到ES节点

2. 进入容器

   ```shell
   docker exec -it kibana bash
   ```

3. vi config/kibana.yml

   ```yaml
   #
   # ** THIS IS AN AUTO-GENERATED FILE **
   #
   
   # Default Kibana configuration for docker target
   server.name: kibana
   server.host: "0"
   # 中文配置
   i18n.locale: "zh-CN"
   elasticsearch.hosts: [ "http://192.168.21.123:9200" ]
   xpack.monitoring.ui.container.elasticsearch.enabled: true
   ```

4. 重启容器

   ```shell
   docker restart kibana
   ```

#### 访问地址

```http
http://<IP>:<PORT>
http://192.168.21.123:5601/
```

### es 健康检查

```http
http://<IP>:9200/_cluster/health
http://192.168.21.123:9200/_cluster/health
```

#### 集群状态

1. `cluster_name`集群名称
2. `status`集群状态`green`代表健康；`yellow`代表分配了所有主分片，但至少缺少一个副本，此时集群数据仍旧完整；`red`代表部分主分片不可用，可能已经丢失数据。
3. `number_of_nodes`代表在线的节点总数量
4. `number_of_data_nodes`代表在线的数据节点的数量
5. `active_shards`存活的分片数量
6. `active_primary_shards`存活的主分片数量 正常情况下 `shards`的数量是`pri`的两倍
7. `relocating_shards`迁移中的分片数量，正常情况为 0
8. `initializing_shards`初始化中的分片数量，正常情况为 0
9. `unassigned_shards`未分配的分片，正常情况为 0
10. `delayed_unassigned_shards`
11. `number_of_pending_tasks`，准备中的任务，任务指迁移分片等，正常情况为 0
12. `number_of_in_flight_fetch`
13. `task_max_waiting_in_queue_millis`任务最长等待时间
14. `active_shards_percent_as_number`正常分片百分比 正常情况为 100% 

#### API

1. `/_cat/allocation`      	#查看单节点的shard分配整体情况
2. `/_cat/shards`          	#查看各shard的详细情况
3. `/_cat/shards/{index}`  	#查看指定分片的详细情况
4. `/_cat/master`          	#查看master节点信息
5. `/_cat/nodes`           	#查看所有节点信息
6. `/_cat/indices`         	#查看集群中所有index的详细信息
7. `/_cat/indices/{index}` 	#查看集群中指定index的详细信息
8. `/_cat/segments`        	#查看各index的segment详细信息,包括segment名, 所属shard, 内存(磁盘)占用大小, 是否刷盘
9. `/_cat/segments/{index}`	#查看指定index的segment详细信息
10. `/_cat/count`           	#查看当前集群的doc数量
11. `/_cat/count/{index}`   	#查看指定索引的doc数量
12. `/_cat/recovery`        	#查看集群内每个shard的recovery过程.调整replica。
13. `/_cat/recovery/{index}`	#查看指定索引shard的recovery过程
14. `/_cat/health`          	#查看集群当前状态：红、黄、绿
15. `/_cat/pending_tasks`   	#查看当前集群的pending task
16. `/_cat/aliases`         	#查看集群中所有alias信息,路由配置等
17. `/_cat/aliases/{alias}` 	#查看指定索引的alias信息
18. `/_cat/thread_pool`     	#查看集群各节点内部不同类型的threadpool的统计信息,
19. `/_cat/plugins`         	#查看集群各个节点上的plugin信息
20. `/_cat/fielddata`       	#查看当前集群各个节点的fielddata内存使用情况
21. `/_cat/fielddata/{fields}`	#查看指定field的内存使用情况,里面传field属性对应的值
22. `/_cat/nodeattrs`			#查看单节点的自定义属性
23. `/_cat/repositories`		#输出集群中注册快照存储库
24. `/_cat/templates`			#输出当前正在存在的模板信息

#### 健康值状态

1. Green：所有Primary和Replica均为active，集群健康
2. Yellow：至少一个Replica不可用，但是所有Primary均为active，数据仍然是可以保证完整性的
3. Red：至少有一个Primary为不可用状态，数据不完整，集群不可用

## ES节点有哪些类型

### 1. 主节点（Master node）

1. 主节点的主要职责是负责集群层面的相关操作，管理集群变更，如创建或删除索引，跟踪哪些节点是集群的一部分，并决定哪些分片分配给哪些相关的节点

2. 主节点也可以作为数据节点，但稳定的主节点对集群的健康是非常重要的，默认情况下任何一个集群中的节点都有可能被选为主节点，索引数据和搜索查询等操作会占用大量的cpu，内存，io资源，为了确保一个集群的稳定，分离主节点和数据节点是一个比较好的选择

3. 通过配置`node.master: true`(默认)使节点具有被选举为`Master`的资格。主节点是全局唯一的，从有资格成为`Master`的节点中选举

4. 为了防止数据丢失，每个主节点应该知道有资格升为主节点的数量，默认为1，为了避免网络分区出现多主的情况，配置`discovery.zen.minimun_master_nodes`原则上最小值应该为：`(master_eligible_nodes/2)+1`

5. ```yaml
   node.master: true
   node.data: false
   ```

### 2. 数据节点（Data node）

1. 数据节点主要是存储索引数据的节点，执行数据相关操作：CRUD、搜索，聚合操作等。数据节点对cpu，内存，I/O要求较高， 在优化的时候需要监控数据节点的状态，当资源不够的时候，需要在集群中添加新的节点。

2. 通过配置`node.data: true`(默认来是一个节点成为数据节点)，也可以通过下面配置创建一个数据节点

   ```yaml
   node.master: false
   node.data: true
   node.ingest: false
   ```

### 3. 预处理节点（ingest node）

1. 这是从5.0版本开始引入的概念。预处理操作运行在索引文档之前，即写入数据之前，通过事先定义好的一系列`processors`(处理器)和`pipeline`（管道），对数据进行某种转换、富化。`processors`和`pipeline`拦截`bulk`和`index`请求，在应用相关操作后将文档传回给`index`或`bulk API`

2. 默认情况下，在所有的节点启用`ingest`。如果想在某个节点上禁用`ingest`，则可以填写配置`node.ingest: false`，也可以通过下面的配置创建一个仅用于预处理的节点：

   ```yaml
   node.master: false
   node.data: false
   node.ingest: true
   ```

### 4. 协调节点（Coordinating node）

1. 客户端请求可以发送到集群的任何节点，每个节点都知道任意文档所处的位置，然后转发这些请求，收集数据并返回给客户端，处理客户端请求的节点称为协调节点。

2. 协调节点将请求转发给保存数据的数据节点。每个数据节点在本地执行请求，并将结果返回给协调节点。协调节点收集完数据后，将每个数据节点的结果合并为单个全局结果。对结果收集和排序的过程可能需要很多CPU和内存资源。

3. 通过下面配置创建一个仅用于协调的节点：

   ```yaml
   node.master: false
   node.data: false
   node.ingest: false
   ```

### 5. 部落节点（Trible node）

1. `tribes`功能允许部落节点在多个集群之间充当联合客户端
2. 部落节点是一个单独的节点，其主要工作是嗅探远程集群的集群状态，并将它们合并在一起。为了做到这一点，它加入了所有的远程集群，使它成为一个非特殊的节点，它不属于自己的集群，而是加入了多个集群。
3. 也被称为`跨集群搜索`的功能，该功能`允许用户不仅跨本地索引，而且跨集群撰写搜索`。这意味着可以搜索属于其他远程集群的数据。

### 6. 投票节点（voting node）

1. `node.voting_only: true`（仅投票节点，即使配置了`data.master: true`，也不会参选
2. 仍然可以作为数据节点`node.data: true`

## ES如何实现高可用

1. ES在分配单个索引的分片时会将每个分片尽可能分配到更多的节点上。但是，实际情况取决于集群拥有的分片和索引的数量以及它们的大小，不一定总是能均匀地分布
2. ES不允许Primary和它的Replica放在同一个节点中，并且同一个节点不接受完全相同的两个Replica
3. 同一个节点允许多个索引的分片同时存在

## ES容错机制

1. Master选举（假如宕机节点是Master）
   - 脑裂：可能会产生多个Master节点
   - 解决：discovery.zen.minimum_master_nodes=N/2+1
2. `Replica`容错，新的（或者原有）Master节点会将丢失的Primary对应的某个副本提升为Primary
3. Master节点会尝试重启故障机
4. 数据同步，Master会将宕机期间丢失的数据同步到重启机器对应的分片上去

## 如何提高ES分布式系统的可用性及性能最大化

1. 每台节点的`shard`数量越少，每个`shard`分配的CPU、内存和IO资源越多，单个`shard`的性能越好，当一台机器一个`shard`时，单个`shard`性能最好
2. 稳定的`Master节点`对于集群的健康非常重要！理论上讲，应该尽可能的减轻`Master节点`的压力，分片数量越多，`Master节点`维护管理`shard`的任务越重，并且节点可能就要承担更多的数据转发任务，可增加`仅协调节点`来缓解`Master节点`和`Data节点`的压力，但是在集群中添加过多的`仅协调节点`会增加整个集群的负担，因为选择的主节点必须等待每个节点的集群状态更新确认。
3. 反过来说，如果相同资源分配相同的前提下，`shard`数量越少，单个`shard`的体积越大，查询性能越低，速度越慢，这个取舍应根据实际集群状况和结合应用场景等因素综合考虑
4. `data节点`和`Master节点`一定要分开，集群规模越大，这样做的意义也就越大
5. `data节点`处理与数据相关的操作，例如`CRUD`，搜索和聚合。这些操作是`I/O`，内存和`CPU`密集型的，所以他们需要更高配置的服务器以及更高的带宽，并且集群的性能冗余非常重要
6. 由于`仅投票节`不参与`Master`竞选，所以和真正的`Master`节点相比，它需要的内存和CPU较少。但是，所有`候选节点`以及`仅投票节点`都可能是`数据节点`，所以他们都需要快速稳定低延迟的网络
7. 高可用性（HA）群集至少需要三个主节点，其中`至少两个不是仅投票节点`。即使其中一个节点发生故障，这样的群集也将能够选举一个主节点。生产环境最好设置3台仅Master候选节点（node.master = true	 node.data = true）
8. 为确保集群仍然可用，集群不能同时停止投票配置中的一半或更多节点。只要有一半以上的投票节点可用，集群仍可以正常工作。这意味着，如果存在三个或四个主节点合格的节点，则集群可以容忍其中一个节点不可用。如果有两个或更少的主机资格节点，则它们必须都保持可用

## Master选举流程

### findMaster

## 简单CURD

### 创建索引

```shell
# 格式
PUT /{indexName}?pretty
# demo
PUT /product?pretty
```

### 查询索引状态

```shell
GET /_cat/indices?v
```

### 删除索引

```shell
# 格式
DELETE /{indexName}?pretty
# demo
DELETE /product?pretty
```

### 查看索引信息

```shell
# 查看索引 map 映射信息
GET /product
# 查看索引数据
GET /product/_search
```

### 插入数据

```shell
PUT /product/_doc/1
{
    "name" : "xiaomi phone",
    "desc" :  "shouji zhong de zhandouji",
    "price" :  3999,
    "tags": [ "xingjiabi", "fashao", "buka" ]
}
PUT /product/_doc/2
{
    "name" : "xiaomi nfc phone",
    "desc" :  "zhichi quangongneng nfc,shouji zhong de jianjiji",
    "price" :  4999,
    "tags": [ "xingjiabi", "fashao", "gongjiaoka" ]
}
PUT /product/_doc/3
{
    "name" : "nfc phone",
    "desc" :  "shouji zhong de hongzhaji",
    "price" :  2999,
    "tags": [ "xingjiabi", "fashao", "menjinka" ]
}
PUT /product/_doc/4
{
    "name" : "xiaomi erji",
    "desc" :  "erji zhong de huangmenji",
    "price" :  999,
    "tags": [ "low", "bufangshui", "yinzhicha" ]
}
PUT /product/_doc/5
{
    "name" : "hongmi erji",
    "desc" :  "erji zhong de kendeji",
    "price" :  399,
    "tags": [ "lowbee", "xuhangduan", "zhiliangx" ]
}
```

### 查询数据

```shell
# 查询单个document
# 格式
GET /{indexName}/_doc/{id}
# demo
GET /product/_doc/1

# 查看所有的document
# 格式
GET /{indexName}/_search
# demo
GET /product/_search

# 查询多个结果的排序
# 格式
GET /{indexName}/_search?sort=排序的字段:<asc><desc>
# demo
GET /product/_search?sort=price
GET /product/_search?sort=price:asc
GET /product/_search?sort=price:desc
GET /product/_search?q=price:2999&sort=price:desc
```

### 更新数据

```shell
# 全量更新（完全覆盖）
# 格式
PUT /{indexName}/_doc/{id}
json格式的数据

# demo
PUT /product/_doc/1
{
    "name" : "xiaomi phone",
    "desc" :  "shouji zhong de zhandouji",
    "price" :  3999,
    "tags": [ "xingjiabi", "fashao", "buka" ]
}
```

```shell
# 增量更新
# 格式
POST /{indexName}/_doc/{id}/_update
{
    "doc": json格式的数据
}

# demo
POST /product/_doc/1/_update
{
    "doc":{
        "price" :  23999
    }
}
```

### 删除数据

> 先逻辑删除，没有立即删除，后续才会物理删除

```shell
# 格式
DELETE /{indexName}/_doc/{id}
# demo
DELETE /product/_doc/1
```

## ES 常用查询

### 1. search timeout

1. 设置：默认没有`timeout`，如果设置了`timeout`，那么会执行`timeout`机制
2. `timeout`机制：假设用户查询结果有1W条数据，但是需要10s才能查询完毕，但是用户设置了1s的`timeout`，那么不管当前一共查询到了多少数据，都会在1s后停止查询，并返回当前数据
3. 用法：GET /product/_search?timeout=1s/ms/m

### 2. query_string

1. 查询所有：GET /product/_search
2. 带参数：GET /product/_search?q=name:xiaomi
3. 分页+排序：GET /product/_search?from=0&size=2&sort=price:asc

### 3. match_all：匹配所有

```http
GET /product/_search
{
  "query":{
    "match_all": {}
  }
}
```

### 4. match：name中包含“nfc”

```http
GET /product/_search
{
  "query": {
    "match": {
      "name": "nfc"
    }
  }
}
```

### 5. sort：按照加个倒序排序

```http
GET /product/_search
{
  "query": {
    "multi_match": {
      "query": "nfc",
      "fields": ["name","desc"]
    }
  },
  "sort": [
    {
      "price": "desc"
    }
  ]
}
```

### 6. multi_match：根据多个字段查询一个关键词

> name和desc中包含“nfc”

```http
GET /product/_search
{
  "query": {
    "multi_match": {
      "query": "nfc",
      "fields": ["name","desc"]
    }
  },
  "sort": [
    {
      "price": "desc"
    }
  ]
}
```

### 7. _source：元数据，想要查询多个字段

> ① 例子中为只查询“name”和“price”字段。

```http
GET /product/_search
{
  "query":{
    "match": {
      "name": "nfc"
    }
  },
  "_source": ["name","price"]
}
```

### 8. 分页：查询第一页（每页两条数据）

```http
GET /product/_search
{
  "query":{
    "match_all": {}
  },
  "sort": [
    {
      "price": "asc"
    }
  ], 
  "from": 0,
  "size": 2
}
```

### 9. term：不会被分词

```http
GET /product/_search
{
  "query": {
    "term": {
      "name": "nfc"
    }
  }
}
GET /product/_search
{
  "query": {
    "term": {
      "name": "nfc phone" 这里因为没有分词，所以查询没有结果
    }
  }
}
```

### 10. 全文检索

```http
GET /product/_search
{
  "query": {
    "match": {
      "name": "xiaomi nfc zhineng phone"
    }
  }
}
#验证分词
GET /_analyze 
{
  "analyzer": "standard",
  "text":"xiaomi nfc zhineng phone"
}
```

### 11. match_phrase：短语搜索，和全文检索相反

```http
GET /product/_search
{
  "query": {
    "match_phrase": {
      "name": "nfc phone"
    }
  }
}
```

### 12. 查询过滤

1. `bool`：可以`组合多个查询条件`，`bool`查询也是采用`more_matches_is_better`的机制，因此满足`must`和`should`子句的文档将会合并起来计算分值
2. `must`：`必须满足`（子查询必须出现在匹配的文档中，并将有助于得分）
3. `should`：`可能满足` `or`（子查询可能会出现在匹配的文档中）
4. `must_not`：`必须不满足` `不计算相关度分数` `not`（子查询不得出现在匹配的文档中，子句在过滤器上下文中执行，这意味着计分被忽略，并且子句被视为用于缓存）
5. `filter`：`过滤器` `不计算相关度分数`，`cache`（子查询必须出现在匹配的文档中，但是不像`must`查询的分数将忽略。`filter`子句在`filter`上下文中执行，这意味着计分被忽略，并且子句被考虑用于缓存）
6. `minimum_should_match`：参数指定`should`返回的文档必须匹配的子句的数量或百分比。如果`bool`查询包含至少一个`should`子句，而没有`must`或`filter`子句，则默认值为1。否则，默认值为0

#### 1. bool单条件查询

>首先筛选`name`包含`xiaomi phone`并且价格大于1999的数据（不排序），然后搜索`name`包含`xiaomi`and `desc` 包含`shouji`

```http
GET /product/_search
{
  "query": {
    "bool":{
      "must": [
        {"match": { "name": "xiaomi"}},
        {"match": {"desc": "shouji"}}
      ],
      "filter": [
        {"match_phrase":{"name":"xiaomi phone"}},
        {"range": {
          "price": {
            "gt": 1999
          }
        }}
      ]
    }
  }
}
```

#### 2. bool多条件

> name包含xiaomi 不包含erji 描述里包不包含nfc都可以，价钱要大于等于4999

```http
GET /product/_search
{
  "query": {
    "bool": {
      # name中必须包含"xiaomi"
      "must": [
        {
          "match": {"name": "xiaomi"}
        }
      ],
      # name中必须不能包含"erji"
      "must_not": [
        {
          "match": {"name": "erji"}
        }
      ],
      # should中至少满足0个条件，参见下面的 minimum_should_match 的解释
      "should": [
        {
          "match": {"desc": "nfc"}
        }
      ],
      # 筛选价格大于4999的doc
      "filter": [
        {
          "range": {
            "price": {"gt": 4999}
          }
        }
      ]
    }
  }
}
```

#### 3. minimum_should_match的嵌套查询

```http
GET /product/_search
{
  "query": {
    "bool":{
      "must": [
        {"match": { "name": "nfc"}}
      ],
      "should": [
        {"range": {
          "price": {"gt":1999}
        }},
         {"range": {
          "price": {"gt":3999}
        }}
      ],
      "minimum_should_match": 1
    }
  }
}
# 
GET /product/_search
{
  "query": {
    "bool": {
      "filter": {
        "bool": {
          "should": [
            { "range": {"price": {"gt": 1999}}},
            { "range": {"price": {"gt": 3999}}}
          ],
          "must": [
            { "match": {"name": "nfc"}}
          ]
        }
      }
    }
  }
}
```

### 13. Compound queries组合查询

> 想要一台带`NFC`功能的 或者 小米的手机 但是不要耳机

```sql
SELECT * from product where (`name` like "%xiaomi%" or `name` like '%nfc%') AND `name` not LIKE '%erji%'
```

```http
GET /product/_search
{
  "query": {
    "constant_score":{
      "filter": {
        "bool": {
          "should":[
            {"term":{"name":"xiaomi"}},
            {"term":{"name":"nfc"}}
            ],
          "must_not":[
            {"term":{"name":"erji"}}
            ]
        }
      },
      "boost": 1.2
    }
  }
}
```

> 搜索一台xiaomi nfc phone或者一台满足 是一台手机 并且 价格小于等于2999

```sql
SELECT * FROM product WHERE NAME LIKE '%xiaomi nfc phone%' OR (NAME LIKE '%phone%' AND price > 399 AND price <=999);
```

```http
GET /product/_search
{
  "query": {
    "constant_score": {
      "filter": { 
        "bool":{
          "should":[
            {
              "match_phrase": {
                "name":"xiaomi nfc phone"
              }
            },
            {
              "bool":{
                "must":[
                  {"term":{"name":"phone"}},
                  {"range":{"price":{"lte":"2999"}}}
                  ]
              }
            }
          ]
        }
      }
    }
  }
}
```

### 14. Highlight search高亮查询

```http
GET /product/_search
{
    "query" : {
        "match_phrase" : {
            "name" : "nfc phone"
        }
    },
    "highlight":{
      "fields":{
         "name":{}
      }
    }
}
```

### 15. Deep paging



### 16. Scroll search



### 17. filter缓存原理

