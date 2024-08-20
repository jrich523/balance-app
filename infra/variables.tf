variable vpc_id {
    type = string
}

variable subnets {
    type = list(string)
}

variable api_key {
    type = string
}

variable "ecs_service_desired_count" {
  type = number
  default = 1
}

variable "app_version" {
    type = string
    default = "v0.0.0"
}