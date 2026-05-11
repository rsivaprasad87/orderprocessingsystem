resource "aws_apigatewayv2_api" "orders_api" {
  name          = "orders-api-${var.environment}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.orders_api.id

  integration_type = "AWS_PROXY"
  integration_uri  = var.api_handler_arn

  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "create_order" {
  api_id    = aws_apigatewayv2_api.orders_api.id
  route_key = "POST /orders"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.api_handler_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.orders_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.orders_api.id
  name        = "$default"
  auto_deploy = true
}
