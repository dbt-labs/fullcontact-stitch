data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

data "aws_iam_policy_document" "fullcontact_kinesis" {
  statement {
    actions = [
      "kinesis:Put*",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
    ]

    resources = [
      "${aws_kinesis_stream.fullcontact.arn}"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "fullcontact_kinesis" {
    name = "fullcontact_kinesis"
    description = "Gives fullcontact lambda r/w access to fullcontact kinesis stream"
    policy = "${data.aws_iam_policy_document.fullcontact_kinesis.json}"
}

resource "aws_iam_role_policy_attachment" "fullcontact_kinesis" {
    role = "${aws_iam_role.fullcontact_lambda.name}"
    policy_arn = "${aws_iam_policy.fullcontact_kinesis.arn}"
}

data "aws_iam_policy_document" "lambda_setup" {
  statement {
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "lambda_setup" {
    name = "lambda_setup"
    description = "Gives lambda access to set itself up"
    policy = "${data.aws_iam_policy_document.lambda_setup.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_setup" {
    role = "${aws_iam_role.fullcontact_lambda.name}"
    policy_arn = "${aws_iam_policy.lambda_setup.arn}"
}

resource "aws_iam_role" "fullcontact_lambda" {
  name = "fullcontact_lambda"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

resource "aws_lambda_function" "fullcontact_fanout" {
  filename = "../target/fullcontact_lambda.zip"
  source_code_hash = "${base64sha256(file("../target/fullcontact_lambda.zip"))}"
  publish = true

  runtime = "python2.7"
  function_name = "fullcontact_fanout"
  handler = "fullcontact.handle_fanout"
  role = "${aws_iam_role.fullcontact_lambda.arn}"

  memory_size = 512
  timeout = 30

  vpc_config {
    subnet_ids = ["${var.SUBNET_IDS}"]
    security_group_ids = ["${aws_security_group.fullcontact.id}"]
  }

  environment {
    variables {
      KINESIS_STREAM_NAME = "${aws_kinesis_stream.fullcontact.name}"

      POSTGRES_HOST = "${var.POSTGRES_HOST}"
      POSTGRES_USER = "${var.POSTGRES_USER}"
      POSTGRES_PASSWORD = "${var.POSTGRES_PASSWORD}"
      POSTGRES_PORT = "${var.POSTGRES_PORT}"
      POSTGRES_DBNAME = "${var.POSTGRES_DBNAME}"

      FULLCONTACT_INPUT_EMAIL_ADDRESS_FIELD = "${var.FULLCONTACT_INPUT_EMAIL_ADDRESS_FIELD}"
      FULLCONTACT_INPUT_SCHEMA = "${var.FULLCONTACT_INPUT_SCHEMA}"
      FULLCONTACT_INPUT_TABLE = "${var.FULLCONTACT_INPUT_TABLE}"

      FULLCONTACT_API_KEY = "${var.FULLCONTACT_API_KEY}"

      STITCH_CLIENT_ID = "${var.STITCH_CLIENT_ID}"
      STITCH_API_KEY = "${var.STITCH_API_KEY}"
    }
  }
}

resource "aws_lambda_function" "fullcontact_worker" {
  filename = "../target/fullcontact_lambda.zip"
  source_code_hash = "${base64sha256(file("../target/fullcontact_lambda.zip"))}"
  publish = true

  runtime = "python2.7"
  function_name = "fullcontact_worker"
  handler = "fullcontact.handle_worker"
  role = "${aws_iam_role.fullcontact_lambda.arn}"

  timeout = 30

  vpc_config {
    subnet_ids = ["${var.SUBNET_IDS}"]
    security_group_ids = ["${aws_security_group.fullcontact.id}"]
  }

  environment {
    variables {
      KINESIS_STREAM_NAME = "${aws_kinesis_stream.fullcontact.name}"

      POSTGRES_HOST = "${var.POSTGRES_HOST}"
      POSTGRES_USER = "${var.POSTGRES_USER}"
      POSTGRES_PASSWORD = "${var.POSTGRES_PASSWORD}"
      POSTGRES_PORT = "${var.POSTGRES_PORT}"
      POSTGRES_DBNAME = "${var.POSTGRES_DBNAME}"

      FULLCONTACT_INPUT_EMAIL_ADDRESS_FIELD = "${var.FULLCONTACT_INPUT_EMAIL_ADDRESS_FIELD}"
      FULLCONTACT_INPUT_SCHEMA = "${var.FULLCONTACT_INPUT_SCHEMA}"
      FULLCONTACT_INPUT_TABLE = "${var.FULLCONTACT_INPUT_TABLE}"

      FULLCONTACT_API_KEY = "${var.FULLCONTACT_API_KEY}"

      STITCH_CLIENT_ID = "${var.STITCH_CLIENT_ID}"
      STITCH_API_KEY = "${var.STITCH_API_KEY}"
    }
  }
}

resource "aws_security_group" "fullcontact" {
  name        = "fullcontact"
  description = "Security group for fullcontact lambda"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
