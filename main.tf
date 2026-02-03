resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_exec" {
  for_each = {
    basic = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }

  role       = aws_iam_role.lambda_exec.name
  policy_arn = each.value
}

# --- func_hello_world
data "archive_file" "func_hello_world_src_zip" {
  type        = "zip"
  source_dir  = "${path.root}/func_hello_world/src"
  output_path = "${path.root}/func_hello_world/archive.zip"

  excludes = [
    "*.pyc",
    "**/__pycache__/",
  ]
}
resource "aws_lambda_function" "func_hello_world" {
  function_name    = "func_hello_world"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app.index"
  runtime          = "python3.14"
  filename         = data.archive_file.func_hello_world_src_zip.output_path
  source_code_hash = data.archive_file.func_hello_world_src_zip.output_base64sha256
}
