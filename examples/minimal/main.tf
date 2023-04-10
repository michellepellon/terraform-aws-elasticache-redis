module "elasticache_redis" {
  source             = "../../"
  name               = "test-tf-elasticache"
  num_cache_clusters = 2
  node_type          = "cache.r6g.large"

  subnet_ids         = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  vpc_id             = "vpc-xxx"
  source_cidr_blocks = ["10.1.0.0/16"]
}
