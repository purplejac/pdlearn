resource "aws_lambda_function" "monitoring_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "qlo_monitor_lambda-v0.2.zip"
  function_name = "${var.prefix}-pbs-monitor"
  role          = "arn:aws:iam::724772066194:role/service-role/qlo_monitor-role-rfdyb1lv"

  source_code_hash = "86acfcb1928ee1085010f88e46542f4ce21944a1009e2c8d29de8f1a01caa40e"
  handler = "lambda_function.lambda_handler"
  timeout = 20
  architectures = ["arm64"]

  runtime = "python3.9"
}

resource "aws_cloudwatch_event_rule" "monitoring_schedule" {
  name = "${var.prefix}-pbs-monitor-scheduler"
  description = "Scheduling trigger for the monitoring lambda"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "obs_monitoring_target" {
  rule = aws_cloudwatch_event_rule.monitoring_schedule.name
  target_id = "monitoring_lambda_target"
  arn = aws_lambda_function.monitoring_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitoring_schedule.arn
}
