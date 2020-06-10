+++
title = "最近はpure CSS + PostCSSを使っている話"
author = ["derui"]
date = 2020-06-10T21:07:00+09:00
lastmod = 2020-06-10T21:13:38+09:00
tags = ["CSS"]
draft = false
+++

緊急事態宣言は解除されましたが、相変わらず在宅勤務です。また満員電車とかに慣れるための修練が必要になりますね・・・

今日は ~~ネタがないので~~ 、最近の趣味におけるCSSの書き方を簡単に書いていきます。

<!--more-->


## なぜPure CSSに回帰したのか {#なぜpure-cssに回帰したのか}

以前は、自分で書くのは全部SCSSで、仕事ではPure CSSでした。SCSSの現場もありましたが、余計な依存を増やさないでくれ、という依頼があった時はPure CSSを書くようにしていました。

だいぶ前（PostCSSが出るより前）は、ある程度構造化したり共通化したCSSをかきたいなー、ってなった場合、SCSSなりSassやLESSといったAltCSSを選択するしかありませんでした。

> 私の把握している範囲では、です。他にあったのかもしれませんが、当時リーズナブルな手法と言ったらAltCSSだったと思います。

ただ、AltCSSはAltJSと同じような課題を抱えていました。今も余り変わらないと思いますが・・・。

-   Toolに追随する必要がある
-   機能の増えた・減ったなどに対応する必要がある
-   結局生成されるのはCSSなので、CSSの知識＋アルファが必要
-   色々やりすぎて結局保守性が下がる


## PostCSSとCSS Custom Variables {#postcssとcss-custom-variables}

PostCSSは以前から知っていましたが、実際に使ったことはありませんでした。使うだけなら、npm/yarnでCLIを入れれば使えます。

```shell
$ yarn add postcss-cli
```

PostCSSとAltCSSの違いは、色んな所で言われていますが、大きく他と違うのは、 **あくまでCSSのPostprocesser** である、ということだと理解しています。

そのため、PostCSSのpluginは大抵未来のCSS標準を試すための試金石だったり、autoprefixerに代表されるutility系が多いです。言語の根幹を変更するようなものは、ユーザーが自ら入れなければならないため、危険が少ないのも利点だと思います。

また、AltCSSを利用する最大（個人的に）の理由だった、変数についてもCustom Variableという形で利用できるようになっています。

SCSSの変数とは異なるものではありますが、逆にSCSSの変数では出来ないことも出来るので、メリット・デメリット両方があると思います。

> 特に、テーマ機能のようなものを使う場合、Custom Variablesの方が使いやすいと思います。色々問題もありますが。

なにより、最悪PostCSSが使えなくなってもダメージがそれ程でもない、というのが安心感あります。


## 最近使っているPostCSSのPlugin {#最近使っているpostcssのplugin}

-   [postcss-extend-rule](https://github.com/csstools/postcss-extend-rule)
    -   `@extend` を使えます、が、現状特に使っていないという・・・
-   [postcss-import](https://github.com/postcss/postcss-import)
    -   cssのbmportと違い、inlineでの展開が出来ます。
-   [postcss-nesting](https://github.com/jonathantneal/postcss-nesting)
    -   SCSSとかのようなnesting ruleを書けます

これだけしか使っていませんし、これ以上入れる気もあんまりしていません。

正直nestingもいらないと言えばいらないんですが、疑似要素とかを書く時に重宝するので入れています。

これくらいしか入れていなくても、それほど問題なくサクサクと書けています。複数人開発じゃないから、というのもありそうですが・・・。


## とりとめのない終わり {#とりとめのない終わり}

実際、SCSSを書いてもCSSを書いても、セレクタの命名規則だったり詳細度の話だったりは変わりません。ので、ちょっとした書き味の違いを求めるのであれば、標準であるCSSをそのまま書いたほうがメリットがあると、最近は思っています。

Sassに疲れた、とか機能を使い切れなくて悔しい、とか感じているようなら、一度Pure CSSに戻ってみてはどうでしょうか。逆に新鮮だったりするかもしれませんよ。
