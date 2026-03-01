output "address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_db_instance.this.db_name
}

output "db_instance_resource_id" {
  description = "DBI resource ID of the RDS instance (used in IAM policy ARNs)"
  value       = aws_db_instance.this.resource_id
}
