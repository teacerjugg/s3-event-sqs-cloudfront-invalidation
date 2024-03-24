# S3イベント通知によるCloudFrontのキャッシュクリア

## 構成

TODO

## 事前準備

- AWS CLIのインストール[^1]
- Terraformのインストール[^2]
- Rustのインストール[^3]
- Cargo Lambdaのインストール[^4]

## 使用方法

1.  （任意） `terraform`
    ディレクトリ配下に環境毎のディレクトリを作成する（ `dev` や `prod`
    など）

2.  `terraform/dev` を参考に，プロバイダおよび各モジュールを設定する

3.  `main.tf` を作成したディレクトリに `terraform.tfvars`
    を作成し，以下のようにS3バケット名とCloudFrontディストリビューションIDの連想配列を設定する

    ``` terraform
    # terraform.tfvars
    s3_bucket_cloudfront_map = {
      # "バケット名" = "ディストリビューションID"
      "test-bucket" = "E2GPOD6OSBK7CL"
    }
    ```

4.  （任意）AWS
    CLIにプロファイル[^5]を設定しているやAPIキーを使用する場合は `mise`
    [^6]や `direnv` [^7]を使用して，環境変数を設定する

    ``` toml
    # miseを使用した場合の環境変数の設定例
    [env]
    AWS_PROFILE = "test-profile"
    ```

5.  `terraform init`
    を実行してプロバイダの取得およびモジュールの読込みを行なう

6.  `terraform plan` で作成されるリソースを確認して， `terraform apply`
    でリソースを作成する

## 補足

### ディレクトリ構成

``` bash
/
├── README.md
├── docs/
│  └── README.org # README.mdの生成用
├── s3-event-sqs-clear-cloudfront-cache/ # キャッシュ削除用のLambdaにデプロイするコード
│  ├── Cargo.lock
│  ├── Cargo.toml
│  ├── src/
│  └── target/
└── terraform/ # デプロイ用のTerraform
  ├── dev/     # テスト用の環境
  └── modules/ # モジュールディレクトリ
```

### なぜLambdaの実行にSchedulerを使用しているのか

TODO

[^1]: <https://aws.amazon.com/jp/cli/>

[^2]: <https://www.terraform.io/>

[^3]: <https://www.rust-lang.org/>

[^4]: <https://github.com/cargo-lambda/cargo-lambda>

[^5]: <https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-configure-files.html#cli-configure-files-format-profile>

[^6]: <https://mise.jdx.dev/>

[^7]: <https://direnv.net/>
