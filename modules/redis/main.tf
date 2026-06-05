resource "google_redis_instance" "redis_instance" {
  name               = "${var.env}-redis"
  region             = var.region
  tier               = var.redis_tier
  memory_size_gb     = var.memory_size_gb
  authorized_network = var.vpc_id

  redis_version = "REDIS_7_0"
  
  redis_configs = {
    "maxmemory-policy" = "noeviction"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "TUESDAY"
      start_time {
        hours   = 0
        minutes = 30
        seconds = 0
        nanos   = 0
      }
    }
  }

  labels = {
    env  = var.env
    name = "${var.env}-redis"
  }
}
