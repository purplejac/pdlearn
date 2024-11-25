#
# Build and configure the QloApps monitoring lambda
#

# Create the lambda itself, uploading code from a local zip file
#
resource "aws_lambda_function" "monitoring_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "qlo_monitor_lambda-v0.4.zip"
  function_name = "${var.prefix}-pbs-monitor"
  role          = "arn:aws:iam::724772066194:role/service-role/qlo_monitor-role-rfdyb1lv"

  source_code_hash = <ZIP-FILE-HASH>
  handler = "lambda_function.lambda_handler"
  timeout = 20
  architectures = ["arm64"]

  runtime = "python3.9"
}

#
# Create a scheduling trigger rule for the lambda
# 
resource "aws_cloudwatch_event_rule" "monitoring_schedule" {
  name = "${var.prefix}-pbs-monitor-scheduler"
  description = "Scheduling trigger for the monitoring lambda"
  schedule_expression = "rate(5 minutes)"
}

#
# Map the rule to the lambda
#
resource "aws_cloudwatch_event_target" "obs_monitoring_target" {
  rule = aws_cloudwatch_event_rule.monitoring_schedule.name
  target_id = "monitoring_lambda_target"
  arn = aws_lambda_function.monitoring_lambda.arn
}

#
# Create the eventbridge lambda invocation to function with the schedule_expression
#
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitoring_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitoring_schedule.arn
}
