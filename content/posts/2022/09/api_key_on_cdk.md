+++
title = "CDKで構築したAPI GatewayにAPI keyを使うようにしたい"
author = ["derui"]
date = 2022-09-19T10:15:00+09:00
tags = ["AWS"]
draft = false
+++

三連休が二回あるというのはいいなぁと思うものの、仕事できる日数が減るということもまた事実。ずっと仕事していたいというワーカホリックではないと思ってますが、意外とコミットしたい場合に時間が使えないというのは、それはそれでストレスです。

今回は、CDKでAPI Gatewayを作ったとき、API keyをどうやってやればいいんだこれ・・・ってなったのを解決したので、それについて書きます。

<!--more-->


## こうやりましょう {#こうやりましょう}

```typescript
export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const handler = new lambda.DockerImageFunction(this, "handler", {
      functionName: "test-handler",
      code: lambda.DockerImageCode.fromImageAsset("../"),
    });

    const restApi = new apigw.LambdaRestApi(this, "Endpoint", {
      handler: handler,
      apiKeySourceType: apigw.ApiKeySourceType.HEADER,
      proxy: false,
    });

    const integration = new apigw.LambdaIntegration(handler, {
      proxy: true,
    });

    const resource = restApi.root.addResource("api1");
    resource.addMethod("POST", integration, { apiKeyRequired: true });
    resource.addMethod("OPTIONS", integration, { apiKeyRequired: false });

    new apigw.RateLimitedApiKey(this, "default", {
      apiKeyName: "default",
      apiStages: [
        {
          api: restApi,
          stage: restApi.deploymentStage,
        },
      ],
      resources: [restApi],
      enabled: true,
      throttle: {
        rateLimit: 10,
        burstLimit: 10,
      },
    });
  }
}
```


## 簡単な説明 {#簡単な説明}

今回使ったものは、 `LambdaRestApi` のconstructです。こいつは、API Gatewayを使う上でこんな感じにしてくれます。

-   Lambda functionとGatewayの間におけるIAMの諸々
-   proxy設定

ですが、今回作ろうとしているやつは、preflightが必要で、かつこのpreflightにはAPI keyを使えない・・・という話がありそうでした(実際にどうなのかは確認しきれてない)。なので、optionsにはAPI keyを利用させたくないのですが、  `LambdaRestApi` にはそういう設定はできず、全部のmethodに対してどう設定するか・・・しか行うことができません。

そこで、まずせっかくやってくれてるものですが、まずproxy設定を削除します。

```typescript
const restApi = new apigw.LambdaRestApi(this, "Endpoint", {
  handler: handler,
  apiKeySourceType: apigw.ApiKeySourceType.HEADER,
  proxy: false, // ←ここ
});
```

こうすると、 `{proxy+}` という定義が削除される代わりに、全部自分で定義してやる必要があります。ただ、今回の処理は基本的に全部lambdaに流れてきてもらって問題ないやつなので、proxyはしときたいです。

その場合、integrationというものを設定する必要があります。これをやっているのがこれです。

```typescript
const integration = new apigw.LambdaIntegration(handler, {
  proxy: true,
});
```

ここでproxyを設定することにより、 `addMethod` でhttp methodを追加するときに、どういうintegrationを行うのか？を設定できます。あとは、 `addMethod` のオプションでAPI keyを必要とするかどうか？を決定していきます。


## APIキーの作り方 {#apiキーの作り方}

APIキーは、幾つかの作り方があります。

-   APIのconstructから  `addApiKey` で追加する
-   ApiKeyのconstructを作ってAPIと関連づける
-   UsagePlanとセットで作る

今回、あんまり叩かれすぎても困るので、UsagePlanと関連づけるようにしました。 `RateLimitedApiKey` を作ることで、 **UsagePlan** と **ApiKey** をペアで作成してくれます。

この場合、ApiKeyとRestApiの接続するためには、まずstageで接続しないといけません(API Gatewayのマネコン上にあるstageと同じ)。これをやらないと、UsagePlanが上手く機能してくれません。ここが結構注意ですが、マネコンを見ながら想像していくのがまぁいいのかなぁ、という感じでした。


## わかってしまえばわかるけど {#わかってしまえばわかるけど}

CDKをちょろちょろ触ってみて、最終的にCloudFormationになるということ、大体はAWSにおけるResource表現と変わらないということがわかると、terraformとかよりも書きやすい感じがします。

terraformよりも明示的にわかりやすいのは、慣れ親しんだ言語自体で作成できるため、ループとか変数を使うために特殊なことをする必要がない、という点ですね。

> terraformも最新だとまだわかりやすいですが、やっぱり色々と課題があると思ってます

逆に、CDKはCFnを裏で実行するため、terraformよりも処理が圧倒的に遅いです。API Gatewayとlambdaを作るだけで、更新でも60秒とか必要になります。一応開発中はterraform同様にAPI実行していくということができるのですが。ただterraformだとrollbackとかしてくれず、中途半端な状態になるケースもありますが、CFnはそこらへんもハンドリングしてくれるので、トレードオフかなぁという。

これから先どうなっていくのかはわかりませんが、その快適さはなかなかなものですので、一回触ってみるのはいかがでしょうか。
