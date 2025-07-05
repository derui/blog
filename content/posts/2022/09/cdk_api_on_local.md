+++
title = "CDKで構築するAPIをローカルで確認する"
author = ["derui"]
date = 2022-09-10T10:19:00+09:00
tags = ["AWS"]
draft = false
+++

今年は残暑が厳しくないかもしれないので過ごしやすくていい感じですね。

前回はCDKを使い始めたという話になりましたが、今回はCDKで構成したものを、そのままローカルで動かしたいという要求に対してアプローチしてみました。


## こうやりたい {#こうやりたい}

CDKはお手軽にAWSにデプロイできますが、デプロイ = お金がかかることと同義なので、できればローカルで試せるだけ試してからやりたいところです。色々調べた感じでは、アプローチとしては二通りあるようでした。

-   [AWS SAM CLI](https://docs.aws.amazon.com/ja_jp/serverless-application-model/latest/developerguide/serverless-sam-cli-install-linux.html)を使って、 `sam local start-api` で立ち上げる
-   [localstack](https://github.com/localstack/localstack)を実行先にしてcdkをデプロイする
    -   使えるリソース、使えないリソースがあるのと、AWS公式ではないので、細かいところが違ったりというリスクはあります

どっちもメリデメありますが、今回はSAM CLIでやってみました。


## SAM CLIのインストール {#sam-cliのインストール}

SAM CLIは、とりあえずローカルにインストールする必要があります。

```bash
$ curl -LO <url>
$ unzip -d aws-sam-cli <file>
$ cd aws-sam-cli && sudo ./install
$ sam --version
```

こんなくらいでお手軽です。x86用とarm用でバイナリが分かれているので、その点だけ注意したらよさそうです。


## templateの抽出 {#templateの抽出}

SAM CLIは、本来はSAM = Serverless Application Modelに基づいたワークロードをサポートするためのツールなので、 `template.yml` というCloudFormationが要求されます。これはcdkから吐き出せるので、吐き出しときます。

```bash
$ npx cdk synth --no-staging > template.yml
```

こうすることで、CloudFormationのファイルが作成できます。


## APIの開始 {#apiの開始}

さて、ここまで来たら、SAM CLIからローカルAPIを立ててみます。

```bash
$ sam local start-api
Mounting <function> at http://127.0.0.1:3000/{proxy+} [DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT]
Mounting <function> at http://127.0.0.1:3000/ [DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT]
You can now browse to the above endpoints to invoke your functions. You do not need to restart/reload SAM CLI while working on your functions, changes will be reflected instantly/automatically. You only need to restart SAM CLI if you update your AWS SAM template
2022-09-03 08:40:23  * Running on http://127.0.0.1:3000/ (Press CTRL+C to quit)
```

こんな感じの表示が出たら、 `http://localhost:3000` にアクセスしてみます・・・が。ここで問題が発生するケースがあります。多分pythonとかnodeのコードをそのまま利用している場合は普通に動くと思いますが。


## DockerLambdaFunctionを使っている場合 {#dockerlambdafunctionを使っている場合}

今回、Rustで構築したため、必然的にDockerLambdaFunctionを利用することにしています。ところが、こいつはCloudFormationの中身を見てみると、ECRのイメージを参照する作りになってます(当たり前と言えば当たり前ですが)。当然、これはAWSにデプロイしてきちんと動くことが大前提となっているものなので、そうなっていること自体には問題ありません。

が、今やりたいのはあくまでローカルで動作させることなので、なんとかしてやりたいところ。基本的には以下の手順を踏むことでできそうでした。

1.  `sam build`
2.  `sam local start-api`

debugしながら見てみると、sam local start-apiでは、functionのリソース名と同じ名前でbuildして・・・という挙動のようでした。なので、一発sam buildしてからやるととりあえず上手く動作するようです。


### lambdaの中でのpathとアクセスするときの違い {#lambdaの中でのpathとアクセスするときの違い}

上記の処理で動作させられるようにはなりました。が、あまりAPI Gatewayを利用しておらず、stageの概念がいまいちわかりきっていなかったため、

-   curlで  `http://localhost:3000/foo` にアクセスする
-   Lambda内のpathだと `http://localhost:3000/prod/foo` にアクセスしたことになる

という統合が行われており、これによって結構難易度が上がったりしました。ぶっちゃけ全然わからずログを仕込んで初めて気付いたというか。


## もっとお手軽にやりたいがとりあえずはこれで十分 {#もっとお手軽にやりたいがとりあえずはこれで十分}

API Gatewayという巨大な仕様がベースになっていたり、色々やってくれるがゆえに、最初はとっつきづらくはありました。が、さしあたって使えるというレベルであれば、一旦構築してしまえば後はワークロードとして動作させられるかな、とは思います。が、Buildkitが利用できなかったりするため、multi-stageを利用していたりすると、cache戦略はかなり難しい印象です。

ここらへんはもうすこし調べて、効率的にしてみたいなーとは思います。
