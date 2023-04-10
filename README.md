# terraform-aws-elasticache-redis

This Terraform module deploys a Redis Cluster using Amazon ElastiCache. The 
cluster is managed by AWS and automatically handles standby failover, read 
replicas, backups, patching, and encryption.

## Features

- Deploy a fully-managed Redis cluster
- Automatic failover to a standby in another availability zone
- Read replicas
- Automatic scaling of storage

## About Amazon ElastiCache

### What is Amazon ElastiCache?

Before Amazon ElastiCache existed, teams would painstakingly configure the 
redis caching engines on their own. Setting up automatic failover, read 
replicas, backups, and handling upgrades are all non-trivial and AWS 
recognized they could implement these features according to best practices 
themselves, sparing customers the time and cost of doing it themselves. Behind 
the scenes, ElastiCache runs on EC2 Instances located in subnets and protected 
by security groups you specify.

### Structure of an ElastiCache Redis deployment

- **Nodes**: The smallest unit of an ElastiCache Redis deployment is a node. 
It's basically the network-attached RAM on which the cache engine (Redis in this case) runs.

- **Shards**: Also sometimes called "Node Group". A Shard is a 
replication-enabled collection of multiple nodes. Within a Shard, one node is 
the primary read/write node while the rest are read-only replicas of the 
primary node. A Shard can have up to 5 read-only replicas.

- **Cluster**: An ElastiCache cluster is a collection of one or more Shards. 
Somewhat confusingly, an ElastiCache Cluster has a "cluster mode" property that 
allows a Cluster to distribute its data over multiple Shards. When cluster mode 
is disabled, the Cluster can have at most one Shard. When cluster mode is 
enabled, the Cluster can have up to 15 Shards. A "cluster mode disabled" 
Cluster (i.e. Single Shard cluster) can be scaled horizontally by adding/removing 
replica nodes within its single Shard, vertical scaling is achieved by simply 
changing the node types. However, a "cluster mode enabled" Cluster (i.e. Multi 
Shard cluster) can be scaled horizontally by adding/removing Shards, the node 
types in the Shards can also be changed to achieve vertical scaling. Each 
cluster mode will be explained in detail below with additional info on when each 
one will be more appropriate depending on your scaling needs.

### How do you connect to the Redis Cluster?

- When connecting to Redis (cluster mode disabled) from your app, direct all 
operations to the **Primary Endpoint** of the **Cluster**. This way, in the
event of a failover, your app will be resolving a DNS record that automatically 
gets updated to the latest primary node.

-  In both "cluster mode enabled" and "cluster mode disabled" deployment models 
you can still direct reads to any of the Read Endpoints of the nodes in the 
Cluster, however you now risk reading a slightly out-of-date copy of the data 
in the event that you read from a node before the primary's latest data has 
synced to it.

### How do you scale the Redis Cluster?

You can scale your ElastiCache Cluster either horizontally (by adding more 
nodes) or vertically (by using more powerful nodes), but the method depends 
on whether Cluster Mode is enabled or disabled.

#### When Cluster Mode is Disabled

This mode is useful when you'd prefer to have only a single point for data to 
be written to the redis database. All data is written to the primary node of the 
single shard which is now replicated to the replica nodes. The advantage of this 
approach is that you're sure that all your data is present at a single point 
which could make migrations and backups a lot easier, if there's a problem with 
the primary write node however, all write attempts will fail.

- **Vertical**: You can increase the type of the read replica nodes using the 
*instance_type* parameter

- **Horizontal**: You can add up to 5 replica nodes to a Redis Cluster using the 
*cluster_size* parameter. There is always a primary node where all writes take 
place, but you can reduce load on this primary node by offloading reads to the 
non-primary nodes, which are known as Read Replicas.

For more info on both methods, see [Scaling Single-Node Redis (cluster mode disabled) Clusters][aws-es-scaling].

## Common Gotcha's

-  In the event of a Redis failover, you will experience a small period of time 
during which writes are not accepted, so make sure your app can handle this 
gracefully. In fact, consider simulating Redis failovers on a regular basis or 
with automated testing to validate that your app can handle it correctly.

- Test that your app does not cache the DNS value of the Primary Endpoint! 
Java, in particular, has undesirable defaults around DNS caching in many cases. 
If your code does not honor the TTL property of the Primary Endpoint's DNS 
record, then your app may fail to reach the new primary node in the event of a 
failure.

- The only way to add more storage space to nodes in a Redis Cluster 
(cluster mode disabled) is to scale up to a larger node type.

[aws-es-scaling]: https://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/Scaling.RedisStandalone.html
