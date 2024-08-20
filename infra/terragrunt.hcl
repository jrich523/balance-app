remote_state {
  backend = "s3"
  generate = {
    path      = "backend.gen.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "jr-balance-app"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "jr-balance-app"
  }
}