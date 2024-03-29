+++
title = "初めてCDKを触ってみた"
author = ["derui"]
date = 2022-09-01T22:53:00+09:00
tags = ["AWS", "TypeScript"]
draft = false
+++

実家が秋田にあるのですが、3年振りに花火競技大会を見てきました。記憶にある限りでは初めて雨の中見ましたが、いいもんはやっぱいいもんでした。風向きだけが惜しかった。

細々となんかを作っているのですが、その過程でAWS上に環境が必要となってしまいました。そういやCDKってあったと思い出し、使ってみたのでその感想です。

<!--more-->


## CDK is 何 {#cdk-is-何}

CDKとは、 `Cloud Development Kit` の略称です。今迄CloudFormationやterraformなどがありましたが、それらよりもさらにプログラマブル、というよりもプログラミング言語自体を利用して、AWS環境を構築していくことができます。

特徴としては、

-   セキュアなリソースをより少ないコードで構築できる
-   プログラミングのイディオムを利用してモデル化していくことができる
-   アプリケーションコードまで含めて一箇所で管理できる
-   TypeScriptやJavaScript、C#やGoなど、アプリケーションを開発する言語と同じ言語で利用できる

<https://docs.aws.amazon.com/cdk/api/v2/>

terraformは、tfという専用の言語を利用していましたが、CDKでは普通のライブラリとして提供されており、一般的に利用されるプログラミング言語をフルに利用して構築できる、ということがメリットとなっているようです。


## CDKのメリデメ {#cdkのメリデメ}

どんなものにもトレードオフがあるように、CDKにも当然ながらデメリットがあります。

-   AWSのリソースしか作れない
    -   `terraform` みたいに、datadogやGCP、Azureとかまで一箇所で・・・みたいな真似は不可能です
    -   触ってみるとわかりますが、かなり手間がかかってそうなので、terraformと同様にやっていくのは無理じゃないかなと
-   遅い
    -   一応hotswapという、APIを直接叩きまくるものはあるようです
    -   が、最終的にみんな大好き `CloudFormation` で実行されるので、リソース作成とかがterraformと比較して多分倍くらい遅いです
-   既存の環境と別になる場合がある
    -   CDKが利用しているライブラリのバージョンなどがかなり古く、アプリ自体とは全然マッチしない可能性があります
    -   ライブラリ含め一箇所で・・・みたいなのは難しい場合があります


## CDKワークショップ {#cdkワークショップ}

CDKには、 [公式のワークショップ](https://cdkworkshop.com/20-typescript.html)が充実しています。というかちょっとしたAPIとかなら、この内容＋型定義とかを見てたらなんとなくできてしまう感じです。

> 今回は、TypeScriptでやりました

ワークショップの中には、resourceを新しく定義したりという、徐々に高レベルになっていくものが含まれています。CloudFormationのStackをフルに活用して、より高度化していくこともできるようです。恐らくきちんとしたサービスを、これを利用していく上ではなんぼか必要になってくるんでしょうけど、私が今やろうとしている内容だとそこまで不要でした。


## どんな感じ {#どんな感じ}

ワークショップを見てもらうのが一番速いですが、こんな感じで

-   Lambda
-   API Gateway
-   ECR
-   必要最低限のIAM

ができちゃいます。

```typescript
import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as apigw from "aws-cdk-lib/aws-apigateway";

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const lambda = new lambda.DockerImageFunction(this, "lambda", {
      functionName: "test",
      code: lambda.DockerImageCode.fromImageAsset("../"),
    });

    const restApi = new apigw.LambdaRestApi(this, "Endpoint", {
      handler: lambda,
    });
  }
}
```

CFnやterraformだと、やっぱり利用するリソースを全部定義していかないといけないため、精緻に作成することはできますが、その分とても時間がかかったり見通しが悪かったり、設定漏れなどによるセキュリティ問題などがどうしても出やすい傾向があります。CDKの標準で提供されているものを使う範囲だと、必要最小限のIAMとかしか使われないため、サクサクと作成していくことができます。


## ここがよかった {#ここがよかった}


### 差分が見やすい {#差分が見やすい}

terraformである程度のサイズをいじった方はわかると思いますが、diffを見るのが大分辛いです。CDKの場合、IAMの差分をテーブル形式で表示してくれるため、かなり見やすいです。実際には漸進的に作成していくと思うので、大量のリソースが・・・みたいなことはそこまでない気がします。きっと。

```text
Stack CdkWorkshopStack
IAM Statement Changes
┌───┬─────────────────────────────────┬────────┬─────────────────┬───────────────────────────┬──────────────────────────────────────────────────┐
│   │ Resource                        │ Effect │ Action          │ Principal                 │ Condition                                        │
├───┼─────────────────────────────────┼────────┼─────────────────┼───────────────────────────┼──────────────────────────────────────────────────┤
│ - │ ${CdkWorkshopQueue50D9D426.Arn} │ Allow  │ sqs:SendMessage │ Service:sns.amazonaws.com │ "ArnEquals": {                                   │
│   │                                 │        │                 │                           │   "aws:SourceArn": "${CdkWorkshopTopicD368A42F}" │
│   │                                 │        │                 │                           │ }                                                │
└───┴─────────────────────────────────┴────────┴─────────────────┴───────────────────────────┴──────────────────────────────────────────────────┘
(NOTE: There may be security-related changes not in this list. See https://github.com/aws/aws-cdk/issues/1299)

Resources
[-] AWS::SQS::Queue CdkWorkshopQueue50D9D426 destroy
[-] AWS::SQS::QueuePolicy CdkWorkshopQueuePolicyAF2494A5 destroy
[-] AWS::SNS::Topic CdkWorkshopTopicD368A42F destroy
[-] AWS::SNS::Subscription CdkWorkshopTopicCdkWorkshopQueueSubscription88D211C7 destroy
```

(上はワークショップから抜粋。画像じゃなかったので直接リンクできませんでした)


### テストができる {#テストができる}

terraformでもできますが、localstackを使ったりしてテストをすることもできます。当然開発→本番というようにAWS環境でも実行しなければならないのは確定ではありますが。それでも、UTができるのはかなり安心感があるのではないでしょうか


## SAMとセットで使うのがよいのかもしれない {#samとセットで使うのがよいのかもしれない}

今回、API Gatewayを利用するためにCDKを使ってますが、API Gatewayをローカルでテストする方法としては、SAM CLIでのローカル起動くらいしかなさそうでした。

ここらへんがより充実してくるとよいと思いますが、まぁそうは言ってもAWSも使ってもらわないと商売上がったりでもあるので、なかなか難しいんだろうなーと思った次第です。

terraformをやるほどでもないライトな環境構築にCDK、使ってみてはいかがでしょうか。
