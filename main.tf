# Terraform module creates a Redis Elasticache resources on AWS.
#
# ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html

resource "aws_elasticache_replication_group" "default" {
  engine = "redis"

  # Name of the parameter group to associate with this replication group.
  # If this argument is omitted, the default cache parameter group for the
  # specified engine is used. 
  parameter_group_name = aws_elasticache_parameter_group.default.name

  # Name of the cache subnet group to be used for the replication group.
  subnet_group_name = aws_elasticache_subnet_group.default.name

  # One or more Amazon VPC security groups associated with this replication 
  # group.
  security_group_ids = [aws_security_group.default.id]

  # The replication group identifier.
  #
  # - Must contain 1 to 20 alphanumeric characters or hyphens.
  # - Must begin with a letter.
  # - Cannot contain two consecutive hyphens.
  # - Cannot end with a hypehn.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Clusters.Create.CON.Redis.html
  replication_group_id = var.name

  # The number of clusters this replication group initially has.
  # If automatic_failover_enabled is true, the value of this parameter must be at least 2.
  # The maximum permitted value for number_cache_clusters is 6 (1 primary plus 5 replicas).
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/Scaling.RedisReplGrps.html
  num_cache_clusters = var.num_cache_clusters

  # The compute and memory capacity of the nodes.
  # Generally speaking, the current generation types provides more memory and
  # computational power at a lower cost when compared to their equivalent
  # generation counterparts.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html
  node_type = var.node_type

  # The port number on which the cache accepts connections.
  # Redis' default port is 6379.
  port = var.port
  
  # Every cluster has a weekly maintenance window during which any system
  # changes are applied. Specifies the weekly time range during which
  # maintenance on the cluster is performed. It is specified as a range in
  # the format ddd:hh24:mi-dd:hh24:i. (Example "sun:23:00-mon:01:30")
  # The minimum maintenance window is a 60 minute period.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/maintenance-window.html
  maintenance_window = var.maintenance_window

  # The daily time range during which automated backups are created 
  # (e.g. 04:00-09:00). Time zone is UTC. Performance may be degraded while a 
  # backup runs. Set to empty string to disable snapshots.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-automatic.html
  snapshot_window = var.snapshot_window

  # The number of days for which ElastiCache will retain automatic cache cluster 
  # snapshots before deleting them. Set to 0 to disable snapshots.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/backups-automatic.html
  snapshot_retention_limit = var.snapshot_retention_limit

  # Indicates whether Multi-AZ is enabled. When Multi-AZ is enabled, a read-only 
  # replica is automatically promoted to a read-write primary cluster if the 
  # existing primary cluster fails. If you specify true, you must specify a 
  # value greater than 1 for replication_group_size.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/AutoFailover.html
  automatic_failover_enabled = var.automatic_failover_enabled

  # Whether any modifications are applied immediately, or during the next
  # maintenance window.
  #
  # ref: https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_ModifyCacheCluster.html
  apply_immediately = var.apply_immediately

  # Specifies whether minor version engine upgrades will be applied 
  # automatically to the cache during the maintenance window.
  #
  # ref:
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Version number of the cache engine to be used. If not set, defaults to the
  # latest version.
  #
  # ref: https://docs.aws.amazon.com/cli/latest/reference/elasticache/describe-cache-engine-versions.html
  engine_version  = var.engine_version

  # A user-created description for the replication group.
  description = var.description

  # A mapping of tags to assign to the resource.
  tags = var.tags
}

resource "aws_elasticache_parameter_group" "default" {
  name        = var.name
  family      = var.family
  description = var.description
}

resource "aws_elasticache_subnet_group" "default" {
  name        = var.name
  subnet_ids  = var.subnet_ids
  description = var.description
}

resource "aws_security_group" "default" {
  name   = local.security_group_name
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = local.security_group_name }, var.tags)
}

locals {
  security_group_name = "${var.name}-elasticache-redis"
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}
