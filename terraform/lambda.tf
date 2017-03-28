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

resource "aws_iam_role" "fullcontact_lambda" {
  name = "fullcontact_lambda"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

resource "aws_lambda_function" "fullcontact_fanout" {
  filename = "../target/fullcontact_lambda.zip"
  source_code_hash = "${base64sha256(file("../target/fullcontact_lambda.zip"))}"

  runtime = "python2.7"
  function_name = "fullcontact_fanout"
  handler = "fullcontact.handle_fanout"
  role = "${aws_iam_role.fullcontact_lambda.arn}"

  timeout = 300

  vpc_config {
    subnet_ids = "${var.SUBNET_IDS}"
    security_group_ids = []
  }

  environment {
    variables {
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

  runtime = "python2.7"
  function_name = "fullcontact_worker"
  handler = "fullcontact.handle_worker"
  role = "${aws_iam_role.fullcontact_lambda.arn}"

  timeout = 30

  vpc_config {
    subnet_ids = "${var.SUBNET_IDS}"
    security_group_ids = []
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
