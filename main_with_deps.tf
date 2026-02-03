# src/ 配下コードのハッシュを計算するための zip アーカイブ
data "archive_file" "func_with_dep_src_zip" {
  type        = "zip"
  source_dir  = "${path.root}/func_with_dep/src"
  output_path = "${path.root}/func_with_dep/archive_src.zip"

  excludes = [
    "*.pyc",
    "**/__pycache__/",
  ]
}

# sam build および zip アーカイブ作成 (これが最終的に Lambda 関数で使われる)
resource "terraform_data" "func_with_dep_sam_build_archive" {
  triggers_replace = {
    sha256 = data.archive_file.func_with_dep_src_zip.output_base64sha256
  }

  provisioner "local-exec" {
    when        = create
    command     = "sam build"
    working_dir = "${path.root}/func_with_dep"
  }

  # func_with_dep/archive.zip を作成する
  provisioner "local-exec" {
    when        = create
    command     = "zip -r ../../../archive.zip ."
    working_dir = "${path.root}/func_with_dep/.aws-sam/build/HelloWorldFunction"
  }
}

resource "aws_lambda_function" "func_with_dep" {
  function_name    = "func_with_dep"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.14"
  filename         = "${path.root}/func_with_dep/archive.zip"
  source_code_hash = terraform_data.func_with_dep_sam_build_archive.triggers_replace.sha256
}
