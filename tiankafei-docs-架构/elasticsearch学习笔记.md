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

### 倒排索引、Lucene和全文检索

1. 倒排索引的数据结构
   1. 包含这个关键词的document list
   2. 关键词在每个doc中出现的次数：TF term frequency
   3. 关键词在整个索引中出现的次数：IDF inverse doc frequency
   4. 关键词在当前doc中出现的次数
   5. 每个doc的长度，越长相关度越低
   6. 包含这个关键词的所有doc的平均长度
2. Lucene：jar包，帮我们创建倒排索引，提供了复杂的API
3. 如果用Luncene做集群，会有哪些问题
   - 节点一旦宕机，节点数据丢失，后果不堪设想，可用性差
   - 自己维护，麻烦（自己创建管理索引），单台节点的承载请求的能里是有限的，需要人工做负载。

![倒排索引](/images/倒排索引.png)

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
   - ES基于Lucene提供了很多高级功能：复合查询、聚合分析、基于地理位置等
   - 对于大公司，可以构建几百台服务器的大型分布式集群，处理PB级别数据；对于小公司，开箱即用，门槛低上手简单
   - 相比传统数据库，提供了全文检索，同义词处理（美丽的 cls > 漂亮的 cls），相关度排名。聚合分析以及海量数据的近实时（NTR）处理，这些传统数据库完全做不到
3. 应用领域
   - 百度（全文检索，高亮、搜索推荐）
   - 各大网站的用户行为日志（用户点击、浏览、收藏、评论）
   - BI（business Intelligence商业智能），数据分析，数据挖掘统计
   - Github：代码托管平台，几千亿行代码
   - ELK：Elasticsearch（数据存储）、Logstash（日志采集）、Kibana（可视化）

### ES 核心概念

1. cluster（集群）：每个集群至少包含两个节点
2. node：集群中的每个节点，一个节点不代表一台服务器
3. field：一个数据字段，与index和type一起，可以定位一个doc
4. document：es最小的数据单元，通常是以json的形式存储的
5. type：逻辑上的数据分类，es7.x中删除了type的概念
6. index：一类相同或者类似的doc，比如一个员工索引，商品索引
7. shard分片：P分片，R副本
   - 一个index包含多个shard，默认5个分片，默认每个分片分配一个副本，分片的数量在创建索引的时候设置，如果想修改，需要重建索引
   - 每个shard都是一个lucene实例，有完整的创建索引的处理请求能力
   - es会自动在nodes上为我们做shard均衡
   - 一个doc是不可能同时存在与多个分片中的，但是可以存在于多个副本中
   - 分片和对应的副本不能同时存在于同一个节点，所以最低的可用配置是两个节点，互为主备