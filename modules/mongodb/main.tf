
resource "random_password" "db_user_passwords" {
  for_each = {
    for user in var.database_users : user.username => user
  }

  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true

  override_special = "!#$%&*()-_=+[]{}:?"

  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

resource "mongodbatlas_project" "project" {
  name   = "${var.project_name}-${var.environment}"
  org_id = var.org_id

  is_collect_database_specifics_statistics_enabled = true
  is_data_explorer_enabled                         = true
  is_performance_advisor_enabled                   = true
  is_realtime_performance_panel_enabled            = true
  is_schema_advisor_enabled                        = true
}

resource "mongodbatlas_cluster" "cluster" {
  project_id   = mongodbatlas_project.project.id
  name         = var.cluster_name
  cluster_type = "REPLICASET"

  provider_name               = "TENANT"
  backing_provider_name       = "GCP"
  provider_instance_size_name = "M0"
  provider_region_name        = var.gcp_region

  mongo_db_major_version = var.mongodb_version

  # lifecycle {
  #   prevent_destroy = true
  #   ignore_changes  = all
  # }
}

resource "mongodbatlas_project_ip_access_list" "ip_list" {
  for_each = {
    for idx, ip in var.allowed_ip_addresses : idx => ip
  }

  project_id = mongodbatlas_project.project.id
  cidr_block = each.value.cidr_block
  comment    = each.value.comment
}

resource "mongodbatlas_database_user" "users" {
  for_each = {
    for user in var.database_users : user.username => user
  }

  username           = each.value.username
  password           = random_password.db_user_passwords[each.key].result
  project_id         = mongodbatlas_project.project.id
  auth_database_name = "admin"

  roles {
    role_name     = each.value.role_name
    database_name = each.value.database_name
  }

  scopes {
    name = mongodbatlas_cluster.cluster.name
    type = "CLUSTER"
  }

  labels {
    key   = "environment"
    value = var.environment
  }

  labels {
    key   = "managed_by"
    value = "terraform"
  }

  lifecycle {
    ignore_changes = [
      password,
    ]
  }

  depends_on = [
    mongodbatlas_cluster.cluster,
  ]
}

resource "google_secret_manager_secret" "mongodb_user_passwords" {
  for_each = {
    for user in var.database_users : user.username => user
  }

  secret_id = "${var.environment}-mongodb-${each.key}-password"
  project   = var.gcp_project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    service     = "mongodb"
    username    = replace(each.key, "_", "-")
  }

  depends_on = [
    mongodbatlas_database_user.users,
  ]
}

resource "google_secret_manager_secret_version" "mongodb_user_passwords" {
  for_each = {
    for user in var.database_users : user.username => user
  }

  secret      = google_secret_manager_secret.mongodb_user_passwords[each.key].id
  secret_data = random_password.db_user_passwords[each.key].result

  depends_on = [
    random_password.db_user_passwords,
    mongodbatlas_database_user.users,
  ]
}

resource "google_secret_manager_secret" "mongodb_connection_strings" {
  for_each = {
    for user in var.database_users : user.username => user
  }

  secret_id = "${var.environment}-mongodb-${each.key}-connection-string"
  project   = var.gcp_project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    service     = "mongodb"
    username    = replace(each.key, "_", "-")
    database    = replace(each.value.database_name, "_", "-")
  }

  depends_on = [
    mongodbatlas_database_user.users,
  ]
}

resource "google_secret_manager_secret_version" "mongodb_connection_strings" {
  for_each = {
    for user in var.database_users : user.username => user
  }

  secret = google_secret_manager_secret.mongodb_connection_strings[each.key].id

  secret_data = format(
    "%s/%s?retryWrites=true&w=majority",
    replace(
      mongodbatlas_cluster.cluster.connection_strings[0].standard_srv,
      "mongodb+srv://",
      "mongodb+srv://${each.value.username}:${urlencode(random_password.db_user_passwords[each.key].result)}@"
    ),
    each.value.database_name
  )

  depends_on = [
    mongodbatlas_cluster.cluster,
    mongodbatlas_database_user.users,
  ]
}

resource "google_secret_manager_secret" "mongodb_config" {
  secret_id = "${var.environment}-mongodb-config"
  project   = var.gcp_project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    service     = "mongodb"
  }
}

resource "google_secret_manager_secret_version" "mongodb_config" {
  secret = google_secret_manager_secret.mongodb_config.id

  secret_data = jsonencode({
    cluster_name           = mongodbatlas_cluster.cluster.name
    project_id             = mongodbatlas_project.project.id
    connection_string_base = mongodbatlas_cluster.cluster.connection_strings[0].standard_srv

    users = {
      for user in var.database_users : user.username => {
        username          = user.username
        database          = user.database_name
        role              = user.role_name
        password_secret   = google_secret_manager_secret.mongodb_user_passwords[user.username].secret_id
        connection_secret = google_secret_manager_secret.mongodb_connection_strings[user.username].secret_id
      }
    }

    databases = distinct([
      for user in var.database_users : user.database_name
    ])
  })

  depends_on = [
    mongodbatlas_cluster.cluster,
    mongodbatlas_database_user.users,
    google_secret_manager_secret_version.mongodb_user_passwords,
    google_secret_manager_secret_version.mongodb_connection_strings,
  ]
}
