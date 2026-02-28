data "aws_availability_zones" "available" {
  state            = "available"
  exclude_zone_ids = ["use1-az3"]

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
