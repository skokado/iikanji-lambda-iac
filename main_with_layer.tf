data "archive_file" "layer_requirements" {
  type        = "zip"
  source_file = "${path.root}/func_with_layer/layer/requirements.txt"
  output_path = "${path.root}/func_with_layer/layer_archive_src.zip"
}

# requirements.txt のハッシュをトリガーに sam build を実行する
resource "terraform_data" "layer_sam_build" {
  triggers_replace = {
    sha256 = data.archive_file.layer_requirements.output_base64sha256
  }

  provisioner "local-exec" {
    when        = create
    command     = "sam build Layer"
    working_dir = "${path.root}/func_with_layer"
  }

  provisioner "local-exec" {
    when        = create
    command     = "zip -r ../../../layer_archive_build.zip ."
    working_dir = "${path.root}/func_with_layer/.aws-sam/build/Layer"
  }
}

resource "aws_lambda_layer_version" "this" {
  filename            = "${path.root}/func_with_layer/layer_archive_build.zip"
  layer_name          = "func_with_layer_layer"
  source_code_hash    = terraform_data.layer_sam_build.triggers_replace.sha256
  compatible_runtimes = ["python3.14"]
}

# src/ 配下コードのハッシュを計算するための zip アーカイブ
data "archive_file" "func_with_layer_src_zip" {
  type        = "zip"
  source_dir  = "${path.root}/func_with_layer/src"
  output_path = "${path.root}/func_with_layer/archive_src.zip"

  excludes = [
    "*.pyc",
    "**/__pycache__/",
  ]
}

# # sam build および zip アーカイブ作成 (これが最終的に Lambda 関数で使われる)
resource "terraform_data" "func_with_layer_sam_build_archive" {
  triggers_replace = {
    sha256 = data.archive_file.func_with_layer_src_zip.output_base64sha256
  }

  provisioner "local-exec" {
    when        = create
    command     = "sam build Function"
    working_dir = "${path.root}/func_with_layer"
  }

  # func_with_layer/archive.zip を作成する
  provisioner "local-exec" {
    when        = create
    command     = "zip -r ../../../archive.zip ."
    working_dir = "${path.root}/func_with_layer/.aws-sam/build/Function"
  }
}

resource "aws_lambda_function" "func_with_layer" {
  function_name    = "func_with_layer"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.14"
  filename         = "${path.root}/func_with_layer/archive.zip"
  source_code_hash = terraform_data.func_with_layer_sam_build_archive.triggers_replace.sha256
  layers           = [aws_lambda_layer_version.this.arn]
}
