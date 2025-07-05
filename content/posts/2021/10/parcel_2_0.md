+++
title = "Parcel2.0を試してみた"
author = ["derui"]
date = 2021-10-31T08:53:00+09:00
lastmod = 2021-10-31T08:53:10+09:00
tags = ["JavaScript"]
draft = false
+++

気付いたら10月も終わりです。もう今年も残りは二ヶ月ということで、月日の流れは本当に速い。

さて、先日登場したParcel2.0を個人のプロダクトで試してみたので、それについてライトに書いてみます。

<!--more-->


## Parcelとは {#parcelとは}

まず[parcel](https://parceljs.org/)とはなにか・・・ということですが、こちらについては公式ページを見てもらうのが一番早いです。あえてまとめるとすると

-   out of the boxで動作するbundler
-   dev server/hot reloadingなどが組み込み済
-   CSS/XML/JSONなどのbundleも組み込み済
-   minificationやimage optimizationなども実現
-   Rustで構築されているため、マルチコア利用かつ高速

という特徴があります。特にRustで構築されているということと、後述するようにtype checkingを省いているため、特にTypeScriptのビルドおよびbundleは特筆すべき速度です。


## parcelで動かすようにしてみる {#parcelで動かすようにしてみる}

<https://github.com/derui/simple-planning-poker>

犠牲となるのはこのリポジトリになります。元の構成はWebpack5でゼロから構築したものになります。

> 個人開発では、create-react-appとかNext.jsとかはあんまり使いたくない派閥です

<https://github.com/derui/simple-planning-poker/tree/parcel>
で、parcel化したものがこれになります。

parcelは、各種ツール(組み込まれているものに限る)の設定ファイルは自動的に読み込んでくれるので、設定ファイル群はそのまま残っています。

具体的な手順は以下のようになりました。

1.  `yarn add -D parcel @parcel/transformer-typescript-tsc tsc`
2.  postcss.config.jsとかのJavaScriptで記述されていた設定をJSONに移行
3.  TypeScriptと、tsconfig.jsonでpathsを利用していた場合、path設定を書き換える
4.  package.jsonのsourceでルートになるファイルを設定する
5.  webpackの利用をやめる


### TypeScriptを利用している場合の注意点 {#typescriptを利用している場合の注意点}

TypeScriptを利用しているとき、importでめっちゃ `../` のような相対パス表記が出るのを防ぐため、 `paths` に以下のような設定をしている場合があると思います。

```js
{
  ...,
  basePath: "./",
  paths: {
    "@/*": ["src/ts/*"]
  }
}
```

実はこの挙動ですが、TypeScriptのオリジナルコンパイラにおける独自拡張であり、Parcelでは動作しません。

parcel2.0のドキュメントではこのあたりの記述が存在しており、基本的には↓のような記述にする必要があります。

```js
{
  ...,
  basePath: ".",
  paths: {
    "~*": ["./*"]
  }
}
```

こうしないと、bundle時に超大量のエラーが出て涙することになります。


## 実際JSによる設定レスでいけたのか？ {#実際jsによる設定レスでいけたのか}

結果としては、若干書き換えは必要でしたが、 **JSでの設定レス** でビルドできることは確認しました。postcssとかeslintの設定に関しては、デフォルトの挙動で構わないのであれば、本当に設定レスで動かすことができるでしょう。

ただし、JSONベースというのは静的に決定されているものであるため、例えば production ビルドの場合は・・・というような置き換えは、Parcelの範囲ではなくソースの中に書き加える必要があります。

> 個人的にはこのへん、 `#ifdef` とかと大体一緒やなぁ、と思いました

<https://github.com/derui/simple-planning-poker/commit/5db2a4cb07d31c7a137fd14c9a57efd9292c595f#diff-32808ca7db8d5096c1eba4e5252db4715120f43417e1fcf4b869674d49e76a70>

↑のところが実例ですが、ビルド先の環境毎に変更したいというような場合は、自分でNODE\_ENVを見てやる必要があります。


## 速度はどうだった？ {#速度はどうだった}

bundle速度については、minificationを含まないビルドについては、おおよそ10倍を超える速度でビルドができました。

minificationを含む場合は、どうしても途中で直列になってしまうので若干開発時よりは遅いですが、それでも倍以上の速度でビルドできています。フィードバックループが非常に短くなるのは確実で、開発体験としてもスムーズです。


## Parcelに課題はないの？ {#parcelに課題はないの}

あります。特にTypeScriptでは、[swc](https://swc.rs/)と同様にtranspileのみを実施しているという都合上、ビルド時のtype checkingは行いません。だからくっそ速いのですが。

> 意見的には、開発時にLSPとかでtype checkingしているだろう、というのもありましたが、複数人での開発とかを考えると、絶対にCIでtype checkingを流すというのは必要だと思います

また、Parcelは **プロダクションビルド** や **開発のdev server** は提供してくれますが、テストに関しては完全にノータッチです。そのため、例えばJest + TypeScriptとかを利用する場合は、自分で設定を行う必要があります。


## まとめる {#まとめる}

-   Parcel2.0は確かに超高速
-   **メインの開発** については非常にやりやすい
-   ただし、テストのサポートがなかったり、プロダクションでのtype checkingなどを導入する必要がある

という感じかなぁ、と思います。個人開発とかでとりあえずサクッと実装したりする、というケースには非常にマッチすると思いますし、create-react-appやNext.jsみたいなもののバックエンドとして使われる、というのがあるあるなのかな、という感触です。

ただ、transpileだけするというやつは、非常に複雑になったTypeScriptのtype checkingによるビルド速度の低下に対するカウンターパンチになるので、試したことがない場合は試してみると、考えかたが変わるかもしれません。

> これもまた、考えとしては動的型付言語と静的型付言語の揺り戻しをまた見ている感じではあるのですが

個人的には、webpackとかで開発環境をミニマムに構築したりする、というのが好きなので、ちょっと味気ない感じもありますが。
