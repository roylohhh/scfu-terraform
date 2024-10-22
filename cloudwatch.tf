resource "aws_cloudwatch_log_group" "csiro_state_machine_log_group" {
  name = "csiro_state_machine_log_group"
}

resource "aws_cloudwatch_log_group" "csiro_api_gateway_log_group" {
  name = "csiro_api_gateway_log_group"
}
