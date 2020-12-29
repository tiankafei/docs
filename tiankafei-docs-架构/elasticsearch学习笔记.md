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

### 9. 全文检索：term：不会被分词

> 查询不会被分词，eq相等匹配倒排索引；文档内容会被分词，相当于eq的是倒排索引

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

### 10. 全文检索：match：会被分词

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

### 11. 短语搜索：match_phrase：和全文检索相反

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
5. `filter`：`过滤器` `不计算相关度分数`，`cache`（子查询必须出现在匹配的文档中，但是不像`must`查询的分数将忽略。`filter`子句在`filter`上下文中优先执行，这意味着计分被忽略，并且子句被考虑用于缓存）
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
# demo
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

> 1. 当`bool`处在`query`上下文中时，如果`must`或者`filter`匹配了`doc`，那么`should`即便一条都不满足也可以召回`doc`
> 2. 当`bool`处在父`bool`的`filter`上下文中时 或者 `bool`处在`query`上下文且没有`must`/`filter`子句的时候，`should`至少匹配1个才能召回`doc`
>
> 如果需要类似这种查询：where name='nfc phone' and (price='2999' or desc='shouji zhong de hongzhaji')，就有2种做法：

```http
# 走嵌套bool，让should进入filter上下文：
GET /product/_search
{
  "query": {
    "bool": {
      "filter": [
        [
          {"match_phrase": {"name": "nfc phone"}},
          {"term": {"name": "nfc"}}
        ],
        {
          "bool": {
            "should": [
              { "match_phrase": {"price": "2999"}},
              { "match_phrase": {"desc": "shouji zhong de hongzhaji"}}
            ]
          }
        }
      ]
    }
  }
}
# 走单bool，query上下文，需要显式指定minimum_should_match=1
GET /product/_search
{
  "query": {
    "bool": {
      "filter": [
        [
          {"match_phrase": {"name": "nfc phone"}},
          {"term": {"name": "nfc"}}
        ]
      ],
      "should": [
        { "match_phrase": {"price": "2999"}},
        { "match_phrase": {"desc": "shouji zhong de hongzhaji"}}
      ],
      "minimum_should_match": 1
    }
  }
}
# 其实作为一个可扩展的查询接口，一般来说嵌套bool表达力更丰富，扩展性更好，所以不建议用第二种方式开发业务
```

#### 4. constant_score：不计算得分

> 当我们不关心检索词频率`TF`（`Term Frequency`）对搜索结果排序的影响时，可以使用`constant_score`将查询语句`query`或者过滤语句`filter`包装起来

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

#### 1. deep paging概念

**查询的很深，比如一个索引有三个 `primary shard`，分别存储了`6000`条数据，我们要得到第`100`页的数据（每页`10`条），类似这种情况就叫`deep paging`**

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

#### 2. 查询原理：如何得到第100页的10条数据？

##### 错误的做法

在每个 `shard` 中搜索`990`到`999`这`10`条数据，然后用这`30`条数据排序，排序之后取`10`条数据就是要搜索的数据，这种做法是错的；因为3个 `shard` 中的数据的 `_score` 分数不一样，可能这某一个 `shard` 中第一条数据的 `_score` 分数比另一个 `shard` 中第`1000`条都高，所以在每个 `shard` 中搜索`990`到`999`这`10`条数据然后排序的做法是不正确的。

##### 正确的做法

正确的做法是每个 `shard` 把`0`到`999`条数据全部搜索出来（按排序顺序），然后全部返回给 `coordinate node`，由 `coordinate node` 按 `_score` 分数排序后，取出第`100`页的`10`条数据，然后返回给客户端

![elasticsearch-deep-paging](/images/elasticsearch-deep-paging.png)

#### 3. 性能问题

1. 消耗网络带宽，因为所搜过深的话，各 `shard` 要把数据传递给 `coordinate node`，这个过程是有大量数据传递的，消耗网络
2. 消耗内存，各 `shard` 要把数据传送给 `coordinate node`，这个传递回来的数据，是被 `coordinate node` 保存在内存中的，这样会大量消耗内存
3. 消耗`cup`，`coordinate node` 要把传回来的数据进行排序，这个排序过程很消耗`cpu`

#### 4. 结论

<font color="red">**鉴于deep paging的性能问题，所有应尽量减少使用**</font>

### 16. Scroll search

```http
GET /product/_search?scroll=1m
{
  "query": {
    "match_all": {}
  },
  "sort": [
    {
      "price": "desc"
    }
  ],
  "size": 2
}
```

```http
GET /_search/scroll
{
  # 每次查询更新scroll的时间，相当于延期
  "scroll":"1m"
  "scroll_id": ""
}
```

#### 1. 基于scroll滚动技术实现大数据量搜索

**如果一次性要查出来比如10万条数据，那么性能会很差，此时一般会采取用scroll滚动查询，一批一批的查，直到所有数据都查询完为止。**

1. `scroll`搜索会在第一次搜索的时候，保存一个当时的视图快照，之后只会基于该旧的视图快照提供数据搜索，如果这个期间数据变更，是不会让用户看到的

2. 采用基于`_doc`（不使用`_score`）进行排序的方式，性能较高

3. 每次发送`scroll`请求，我们还需要指定一个`scroll`参数，指定一个`时间窗口`，每次搜索请求只要在这个事件窗口内能完成就可以了

   ```http
   # sort默认是相关度排序（"sort":[{"FIELD":{"order":"desc"}}]）,不按_score排序，按_doc排序
   # size设置的是每页显示的记录数
   # 第一次查询会生成快照
   GET /lib3/user/_search?scroll=1m #这一批查询在一分钟内完成
   {
   	"query":{
   		"match":{}
   	},
   	"sort":[  
   		"_doc"
   	],
   	"size":3 
   }
   # 第二次查询通过第一次的快照ID来查询，后面以此类推
   GET /_search/scroll
   {
     "scroll":"1m", 
     "scroll_id":""
   }
   ```

#### 2. 基于 scroll 解决深度分页问题

**原理上是对某次查询生成一个游标 `scroll_id` ， 后续的查询只需要根据这个游标去取数据，直到结果集中返回的 `hits` 字段为空，就表示遍历结束。**

<font color="red">**注意**：`scroll_id` 的生成可以理解为建立了一个临时的`历史快照`，在此之后的增删改查等操作不会影响到这个快照的结果。</font>

使用 curl 进行分页读取过程如下：

1. 先获取第一个 scroll_id，url 参数包括 /index/_type/ 和 scroll，scroll 字段指定了scroll_id 的**有效生存期，以分钟为单位，过期之后会被es 自动清理**。如果文档不需要特定排序，可以指定按照文档创建的时间返回会使迭代更高效
2. 后续的文档读取上一次查询返回的`scroll_id` 来不断的取下一页，如果`srcoll_id` 的生存期很长，那么每次返回的 `scroll_id` 都是一样的，直到该 `scroll_id` 过期，才会返回一个新的 `scroll_id`。请求指定的 `scroll_id` 时就不需要 /index/_type 等信息了。每读取一页都会重新设置 `scroll_id` 的生存时间，所以这个时间只需要满足读取当前页就可以，不需要满足读取所有的数据的时间，1 分钟足以。
3. 所有文档获取完毕之后，需要手动清理掉 `scroll_id` 。虽然`es`会有自动清理机制，但是 `srcoll_id` 的存在会耗费大量的资源来保存一份当前查询结果集映像，并且会占用文件描述符。所以用完之后要及时清理。使用 `es` 提供的 `CLEAR_API` 来删除指定的 `scroll_id`

#### 3. 基于 search_after 实现深度分页

`search_after` 是 `ES5.0` 及之后版本提供的新特性，`search_after` 有点类似 `scroll`，但是和 `scroll` 又不一样，它提供一个活动的游标，通过上一次查询最后一条数据来进行下一次查询。`search_after` 分页的方式和 `scroll` 有一些显著的区别：首先它是**根据上一页的最后一条数据来确定下一页的位置**，同时在分页请求的过程中，如果有索引数据的增删改查，这些变更也会实时的反映到游标上。

1. 第一页的请求和正常的请求一样

   ```http
   GET /order/info/_search
   {
       "size": 10,
       "query": {
           "match_all" : {
           }
       },
       "sort": [
           {"date": "asc"}
       ]
   }
   # 返回结果
   {
       "_index": "zmrecall",
       "_type": "recall",
       "_id": "60310505115909",
       "_score": null,
       "_source": {
         ...
         "date": 1545037514
       },
       "sort": [
       	1545037514
       ]
     }
   ```

2. 第二页的请求，使用第一页返回结果的最后一个数据的值，加上 `search_after` 字段来取下一页。**注意**：使用 `search_after` 的时候要将 `from` 置为 0 或 -1。

   ```http
   curl -XGET 127.0.0.1:9200/order/info/_search
   {
       "size": 10,
       "query": {
           "match_all" : {
           }
       },
       "search_after": [1545037514], # 这个值与上次查询最后一条数据的sort值一致，支持多个
       "sort": [
           {"date": "asc"}
       ]
   }
   ```

#### 4. 需要注意的点

1. 如果 `search_after` 中的关键字为654，那么654323的文档也会被搜索到，所以在选择 `search_after` 的排序字段时需要谨慎，可以使用比如`文档的id`或者`时间戳`等
2. `search_after` **适用于深度分页+ 排序**，因为每一页的数据依赖于上一页最后一条数据，所以**无法跳页请求**。
3. 返回的始终是**最新的数据**，在分页过程中数据的位置可能会有变更。这种分页方式更加符合 `moa` 的业务场景

#### 5. 番外篇：MOA业务场景

1. 医疗大数据 看病更便捷
2. 金融大数据 赚钱更给力
3. 交通大数据 出行更方便
4. 环保大数据 治污更给力
5. 舆情大数据 网络管理利器

### 17. filter缓存原理



## Mapping

### 1. 概念

`mapping`就是`ES`数据字段`field`的`type`元数据，`ES`在创建索引的时候，`dynamic mapping`会自动为不同的数据指定相应`mapping`，`mapping`中包含了字段的类型、搜索方式（`exact value`或者`full text`）、分词器等。

### 2. 查看mapping

```http
GET /product/_mappings
```

### 3. 动态mapping

1. Elasticsearch：text / keyword
2. 123456             =>	long			？为什么不是integer
3. 123.123            =>	double
4. true false          =>	boolean
5. 2020-05-20       =>	date

> <font color="red">为啥`123456`是`long`类型而不是`integer`？因为`es`的`mapping_type`是由`JSON`分析器检测数据类型，而`Json`没有隐式类型转换（`integer`=>`long` or `float`=> `double`），所以`dynamic mapping`会选择一个比较宽的数据类型。</font>

### 4. 搜索方式

1. exact value 精确匹配：在倒排索引过程中，分词器会将`field`作为一个整体创建到索引中
2. full text全文检索： 分词、近义词同义词、混淆词、大小写、词性、过滤、时态转换等

```http
# 搜索所有字段包含de的doc
GET /product/_search?q=de
# 搜索name字段包含de的doc
GET /product/_search?q=name:de
# name.keyword 不会被分词，有点儿类似 match_phrase 短语搜索，eq文档doc的属性
GET /product/_search
{
  "query": {
    "match": {
      "name.keyword": "xiaomi phone"
    }
  }
}
GET /product/_search
{
  "query": {
    "match_phrase": {
      "name": "xiaomi phone"
    }
  }
}
# 全文检索可能会搜索出多条结果 eq倒排索引
GET /product/_search
{
  "query": {
    "match": {
      "name": "xiaomi phone"
    }
  }
}
```

### 5. ES数据类型

#### 1. 核心类型

1. 数字类型

   - long
   - integer
   - short
   - byte
   - double
   - float
   - half_float
   - scaled_float
   - 在满足需求的情况下，尽可能选择范围小的数据类型

2. 字符串

   - keyword：适用于索引结构化的字段，可以用于过滤、排序、聚合。`keyword`类型的字段只能通过精确值搜索列。ID应该用`keyword`

   - text：当一个字段是要被全文搜索的，比如`Email`内容、产品描述，这些字段应该使用`text`类型。设置`text`类型以后，字段内容会被分析，在生成倒排索引之前，字符串会被分析器分成一个一个词项。`text`类型的字段不用于排序，很少用于聚合。

     > 解释一下为啥不会为`text`创建索引：字段数据会占用大量堆空间，尤其是在加载高基数`text`字段时。字段数据一旦加载到堆中，就在该段的生命周期内保持在那里。同样，加载字段数据是一个昂贵的过程，可能导致用户遇到延迟问题。这就是默认情况下禁用字段数据的原因。
     >
     > 有时，在同一字段中同时具有全文本`text`和关键字`keyword`版本会很有用：一个用于全文本搜索，另一个用于聚合和排序

   - date（时间类型）：exact value

   - boolean（布尔类型）

   - binary（二进制）：binary

   - range（区间类型）：integer_range、float_range、long_range、double_range、date_range

#### 2. 复杂类型

1. Object：用于单个JSON对象
2. Nested：用于JSON对象数组

#### 3. 地理位置

1. Geo-point：纬度 / 经度积分
2. Geo-shape：用于多边形等复杂形状

#### 4. 特有类型

1. IP地址：ip 用于IPv4和IPv6地址
2. Completion：提供自动完成建议
3. Tocken_count：计算字符串中令牌的数量
4. [Murmur3](https://www.elastic.co/guide/en/elasticsearch/plugins/7.7/mapper-murmur3.html)：在索引时计算值的哈希并将其存储在索引中
5. [Annotated-text](https://www.elastic.co/guide/en/elasticsearch/plugins/7.7/mapper-annotated-text.html)：索引包含特殊标记的文本（通常用于标识命名实体）
6. [Percolator](https://www.elastic.co/guide/en/elasticsearch/reference/current/percolator.html)：接受来自query-dsl的查询
7. Join：为同一索引内的文档定义父/子关系
8. [Rank features](https://www.elastic.co/guide/en/elasticsearch/reference/current/rank-features.html)：记录数字功能以提高查询时的点击率。
9. [Dense vector](https://www.elastic.co/guide/en/elasticsearch/reference/current/dense-vector.html)：记录浮点值的密集向量。
10. [Sparse vector](https://www.elastic.co/guide/en/elasticsearch/reference/current/sparse-vector.html)：记录浮点值的稀疏向量。
11. [Search-as-you-type](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-as-you-type.html)：针对查询优化的文本字段，以实现按需输入的完成
12. [Alias](https://www.elastic.co/guide/en/elasticsearch/reference/current/alias.html)：为现有字段定义别名。
13. [Flattened](https://www.elastic.co/guide/en/elasticsearch/reference/current/flattened.html)：允许将整个JSON对象索引为单个字段。
14. [Shape](https://www.elastic.co/guide/en/elasticsearch/reference/current/shape.html)：shape 对于任意笛卡尔几何。
15. [Histogram](https://www.elastic.co/guide/en/elasticsearch/reference/current/histogram.html)：histogram 用于百分位数聚合的预聚合数值。
16. [Constant keyword](https://www.elastic.co/guide/en/elasticsearch/reference/current/constant-keyword.html)：keyword当所有文档都具有相同值时的情况的 专业化。

#### 5. Array（数组）

在Elasticsearch中，数组不需要专用的字段数据类型。默认情况下，任何字段都可以包含零个或多个值，但是，数组中的所有值都必须具有相同的数据类型。

#### 6. ES7新增

1. Date_nanos：date plus 纳秒
2. Features：
3. Vector：as

### 6. 手工创建Mapping

```http
PUT /product
{
  "mappings": {
    "properties": {
        "field": {
          "mapping_parameter": "parameter_value"
        }
      }
  }
}
```

### 7. Mapping parameters

1. `index`：是否对创建对当前字段创建索引，默认true，如果不创建索引，该字段不会通过索引被搜索到，但是仍然会在`source`元数据中展示

2. `analyzer`：指定分析器（character filter、tokenizer、Token filters）。

3. `boost`：对当前字段相关度的评分权重，默认1

4. `coerce`：是否允许强制类型转换  true “1”=> 1  false “1”=< 1

5. `copy_to`：

   ```
   "field": {
      "type": "text",
      "copy_to": "other_field_name" 
   }
   ```

6. `doc_values`：为了提升排序和聚合效率，默认true，如果确定不需要对字段进行排序或聚合，也不需要通过脚本访问字段值，则可以禁用`doc`值以节省磁盘空间（不支持`text`和`annotated_text`）

7. `dynamic`：控制是否可以动态添加新字段

   - true 新检测到的字段将添加到映射中。（默认）
   - false 新检测到的字段将被忽略。这些字段将不会被索引，因此将无法搜索，但仍会出现在_source返回的匹配项中。这些字段不会添加到映射中，必须显式添加新字段。
   - strict 如果检测到新字段，则会引发异常并拒绝文档。必须将新字段显式添加到映射中

8. `eager_global_ordinals`：用于聚合的字段上，优化聚合性能。

   - `Frozen indices`（冻结索引）：有些索引使用率很高，会被保存在内存中，有些使用率特别低，宁愿在使用的时候重新创建，在使用完毕后丢弃数据，`Frozen indices`的数据命中频率小，不适用于高搜索负载，数据不会被保存在内存中，堆空间占用比普通索引少得多，`Frozen indices`是只读的，请求可能是秒级或者分钟级。`eager_global_ordinals`不适用于`Frozen indices`

9. `enable`：是否创建倒排索引，可以对字段操作，也可以对索引操作，如果不创建索引，仍然可以检索并在`_source`元数据中展示，谨慎使用，该状态无法修改。

   ```http
   PUT my_index 
   {
     "mappings": {
       "enabled": false 
     }
   }
   PUT my_index
   {
     "mappings": {
       "properties": {
         "session_data": {
           "type": "object",
           "enabled": false
         }
       }
     }
   }
   ```

   > <font color="red">**注意：enable只能在最顶层，并且type为object的时候设置才生效。**</font>

10. `fielddata`：查询时`内存`数据结构，在首次用当前字段聚合、排序或者在脚本中使用时，需要字段为`fielddata`数据结构，并且创建倒排索引保存到堆中

11. `fields`：给`field`创建多字段，用于不同目的（全文检索或者聚合分析排序）

12. format：格式化

    ```
    "date": {
          "type":   "date",
          "format": "yyyy-MM-dd"
     }
    ```

13. `ignore_above`：超过长度将被忽略

14. `ignore_malformed`：忽略类型错误

    ```http
    PUT my_index{
      "mappings": {
        "properties": {
          "number_one": {
            "type": "integer",
            "ignore_malformed": true
          },
          "number_two": {
            "type": "integer"
          }
        }
      }
    }
    PUT my_index/_doc/1{
      "text":       "Some text value",
      "number_one": "foo"    //虽然有异常 但是不抛出
    }
    PUT my_index/_doc/2{
      "text":       "Some text value",
      "number_two": "foo"   //数据格式不对	
    }
    ```

15. `index_options`：控制将哪些信息添加到反向索引中以进行搜索和突出显示。仅用于`text`字段

16. `Index_phrases`：提升`exact_value`查询速度，但是要消耗更多磁盘空间

17. `Index_prefixes`：前缀搜索

    1. `min_chars`：前缀最小长度，>0，默认2（包含）

    2. `max_chars`：前缀最大长度，<20，默认5（包含）

       ```
       "index_prefixes": {
       	"min_chars" : 1,
       	"max_chars" : 10
       }	
       ```

18. `meta`：附加元数据

19. `normalizer`：

20. `norms`：是否禁用评分（在`filter`和`聚合字段`上应该禁用）

21. `null_value`：为null值设置默认值（"null_value": "NULL"）

22. `position_increment_gap`：

23. `proterties`：除了`mapping`还可用于`object`的属性设置

24. `search_analyzer`：设置单独的查询时分析器

    ```http
    PUT my_index{
      "settings": {
        "analysis": {
          "filter": {
            "autocomplete_filter": {
              "type": "edge_ngram",
              "min_gram": 1,
              "max_gram": 20
            }
          },
          "analyzer": {
            "autocomplete": { 
              "type": "custom",
              "tokenizer": "standard",
              "filter": [
                "lowercase",
                "autocomplete_filter"
              ]
            }
          }
        }
      },
      "mappings": {
        "properties": {
          "text": {
            "type": "text",
            "analyzer": "autocomplete", 
            "search_analyzer": "standard" 
          }
        }
      }
    }
    PUT my_index/_doc/1{
      "text": "Quick Brown Fox" 
    }
    GET my_index/_search{
      "query": {
        "match": {
          "text": {
            "query": "Quick Br", 
            "operator": "and"
          }
        }
      }
    }
    ```

25. `similarity`：为字段设置相关度算法，支持`BM25`、`claassic（TF-IDF）`、`boolean`

26. `store`：设置字段是否仅查询

27. `term_vector`：

