resource "aws_kinesis_stream" "fullcontact" {
  name             = "fullcontact"
  shard_count      = 1
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags {}
}

resource "aws_lambda_event_source_mapping" "fullcontact_event_source_mapping" {
  batch_size = "${var.KINESIS_WORKER_BATCH_SIZE}"
  event_source_arn = "${aws_kinesis_stream.fullcontact.arn}"
  function_name = "${aws_lambda_function.fullcontact_worker.arn}"
  starting_position = "TRIM_HORIZON"
  enabled = true
}
