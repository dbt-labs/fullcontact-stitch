variable "AWS_ACCOUNT_ID" {}
variable "AWS_PROFILE" {}

variable "SUBNET_IDS" { type = "list" }

variable "KINESIS_WORKER_BATCH_SIZE" { default = 10 }
variable "KINESIS_SHARD_COUNT" { default = 1 }

variable "POSTGRES_HOST" {}
variable "POSTGRES_USER" {}
variable "POSTGRES_PASSWORD" {}
variable "POSTGRES_PORT" {}
variable "POSTGRES_DBNAME" {}

variable "FULLCONTACT_INPUT_EMAIL_ADDRESS_FIELD" {}
variable "FULLCONTACT_INPUT_SCHEMA" {}
variable "FULLCONTACT_INPUT_TABLE" {}

variable "FULLCONTACT_API_KEY" {}

variable "STITCH_CLIENT_ID" {}
variable "STITCH_API_KEY" {}
