+++
title = "OpenAPI3 Generatorで使える値の調べ方"
author = ["derui"]
date = 2019-07-24T20:15:00+09:00
lastmod = 2019-07-24T20:15:03+09:00
tags = ["Java"]
draft = false
+++

人事／総務の業務上の問題を解決するために、APIを作ろうということになりました。せっかくなのでOpenAPI3を使おうぜ、となったんですが、Swagger2と構成が違っていて、テンプレートをいじるときにどういう値を視ればいいのか・・・がわからんかったです。

<!--more-->

それをどう見ればいいか、のメモ書きです。


## まず見るリポジトリ {#まず見るリポジトリ}

<https://github.com/OpenAPITools/openapi-generator.git>

OpenAPI3のSpecifiationから、Server/Clientの生成をするための公式ツールです。jarが提供されているので、Javaが動けばだいたい動きます。

Swaggerのときも同じものがありましたが、OpenAPIに分化してからorganizationも分離しています。このGeneratorは各種言語のClient/Serverを生成するため、各言語用のテンプレートが置かれています。


## 各言語のテンプレート {#各言語のテンプレート}

<https://github.com/OpenAPITools/openapi-generator/blob/master/modules/openapi-generator/src/main/resources>

リポジトリ上のリソース内に、各言語/フレームワークごとに分かれています。ここにテンプレートがありますが、このテンプレートの中を見ても、使われてる変数はわかりますが、 ****どういう値を使えるか**** はわかんないです。

実際、ここはテンプレートだけなので、これを利用して生成している場所は別にあります。


## 各言語の生成箇所 {#各言語の生成箇所}

各言語ごとのCLIはここで定義されています。ただ、これを見ても、どのテンプレートを使うんだ？ということしかわかりません。

<https://github.com/OpenAPITools/openapi-generator/tree/master/modules/openapi-generator/src/main/java/org/openapitools/codegen/languages>

実際にテンプレートに値を注入している場所はここです。

<https://github.com/OpenAPITools/openapi-generator/blob/master/modules/openapi-generator/src/main/java/org/openapitools/codegen/DefaultGenerator.java>

この中の、 `generateApis` というメソッドの中で定義されています。基本的にOpenAPI3のYAMLから取得できる情報はここから取得できます。なので、ここを見ると、自分のテンプレートで使いたい値が見つかる・・・かもしれません。


## メモ書きもしていく宣言 {#メモ書きもしていく宣言}

簡単に見つかるだろー、ってなったら見つからなかったのと、デフォルトの提供されているテンプレートだと思ったものと違う可能性もあるので、テンプレートを編集するための第一手として。私を含め誰かの参考になれば・・・。

> OpenAPI3だとSpringFoxでSwagger2の形式で吐き出せない、みたいなのもありますので、Swagger2を使い続けるか、OpenAPI3を使うかは計画的に。

気づいたら7月が終わりそうです。ブログをもうちょっと書いていきたいので、お手軽にかけそうなものがあれば書いていきたい所存。
