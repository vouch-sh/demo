output "workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  value       = aws_redshiftserverless_workgroup.this.workgroup_name
}

output "endpoint_address" {
  description = "Hostname of the Redshift Serverless endpoint"
  value       = aws_redshiftserverless_workgroup.this.endpoint[0].address
}

output "endpoint_port" {
  description = "Port of the Redshift Serverless endpoint"
  value       = aws_redshiftserverless_workgroup.this.endpoint[0].port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_redshiftserverless_namespace.this.db_name
}
