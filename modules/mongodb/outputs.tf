output "project_id" {
  description = "MongoDB Atlas Project ID"
  value       = mongodbatlas_project.project.id
}

output "cluster_id" {
  description = "MongoDB Cluster ID"
  value       = mongodbatlas_cluster.cluster.cluster_id
}

output "cluster_name" {
  description = "MongoDB Cluster Name"
  value       = mongodbatlas_cluster.cluster.name
}

output "connection_string_standard" {
  description = "Standard MongoDB connection string"
  value       = mongodbatlas_cluster.cluster.connection_strings[0].standard
  sensitive   = true
}

output "connection_string_standard_srv" {
  description = "MongoDB SRV connection string"
  value       = mongodbatlas_cluster.cluster.connection_strings[0].standard_srv
  sensitive   = true
}

output "connection_string_private" {
  description = "Private MongoDB connection string"
  value       = try(mongodbatlas_cluster.cluster.connection_strings[0].private, "")
  sensitive   = true
}

output "mongo_uri" {
  description = "Complete MongoDB URI for applications"
  value       = mongodbatlas_cluster.cluster.mongo_uri
  sensitive   = true
}

output "mongo_uri_with_options" {
  description = "MongoDB URI with recommended options"
  value       = mongodbatlas_cluster.cluster.mongo_uri_with_options
  sensitive   = true
}

output "state_name" {
  description = "Current state of the cluster"
  value       = mongodbatlas_cluster.cluster.state_name
}
