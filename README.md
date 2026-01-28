# Iikanji Lambda IaC

[terraform-aws-modules/lambda](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest) に頼らない、いい感じの Lambda 関数リソース IaC を考える

参考元: https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/gs-terraform-support.html

- Terraform による IaC 管理
- terraform plan/apply で change が発生するのは Lambda コードを変更した場合のみ
- `requirements.txt` サポート
