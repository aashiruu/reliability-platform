# Security Group for Postgres RDS
resource "aws_security_group" "rds_sg" {
  name        = "reliability-rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Redis ElastiCache
resource "aws_security_group" "redis_sg" {
  name        = "reliability-redis-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Postgres RDS Instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.3" # Bumped to a version definitely in AWS 2026
  instance_class         = "db.t3.micro"
  db_name                = "reliabilitydb"
  username               = "postgres"
  password               = "ReliabilityPass123"
  parameter_group_name   = "default.postgres16"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
}

# Redis Subnet Group (CRITICAL FIX)
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "reliability-redis-subnet-group"
  subnet_ids = module.vpc.database_subnets
}

# Redis ElastiCache Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "reliability-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name # Fixed reference
  security_group_ids   = [aws_security_group.redis_sg.id]
}
