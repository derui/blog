+++
title = "KotlinでAPIサーバーとバッチを書いてみた感想"
author = ["derui"]
date = 2019-05-02T09:29:00+09:00
lastmod = 2019-05-02T09:29:41+09:00
tags = ["Kotlin"]
draft = false
+++

去年の12月くらいから、KotlinでAPIサーバーとバッチを含むアプリケーションを業務で作っていました。その感想を書いていきます。

<!--more-->

本題の前に閑話を。世間から１週遅れくらいで、 [SEKIRO -SHADOWS DIE TWICE-](https://www.sekiro.jp/) をプレイしており、この間一周目が終わりました。私は一周目では攻略サイト等は見ないことにしているので、クリアと同時に解禁してみた所、一周目で出したエンドがなかなか厳しい（他のルートより短く、アイテムとかが集まりきらない）ものだと発覚・・・。
若干バッドっぽい選択肢ではあったんですが、まさかそういったものだとは思わず。おかげで二週目が厳しいものとなっております。

複数周回がありそうな選択肢だと、バッドっぽいのから選択する癖があるんですが、それが仇となりました。まぁ、二週目を進めている感じ、明らかにPlayer Skillが高まっており、思ったよりも苦戦はしていないのですが。

閑話休題。


## 環境の前提 {#環境の前提}

今回作ったアプリケーションは、既存のアプリケーションの完全作り直しなんですが、肝心の既存アプリケーションが **PL/SQL** で出来ており、完全新規に当たっては DDD を試験的に取り入れています。


### Middleware/Framework {#middleware-framework}

利用しているMiddleware/Frameworkは次のような感じです。

-   Spring Boot
    -   言わずと知れた。
-   Spring Batch
    -   バッチを作成する必要があったので
-   MySQL
    -   現場ではだいたいこれのようでした。
-   Kotlin
    -   今回の主役
-   jOOQ
    -   ORM。Oracleに接続する場合はcommercial licenceが必要なので注意（繋げなかった人）
-   Gradle
    -   大分こっちを選ぶ人が増えた印象


### アーキテクチャ {#アーキテクチャ}

[Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) とDDDを併用しています。Clean Architectureは、とりあえず原典に従って分割している感じですが、現状あまり困っていないです。ここについてもいつか書ければ。


### プロジェクト構成 {#プロジェクト構成}

Gradleのmulti project構成を利用して、DomainやGatewayなどの依存方向を強制しています。DDDを実践する上で、Domainに余計な依存を入れないことが重要だと思っているので、これは結構おすすめです。プロジェクトは次のように分割しています。

-   domain
-   usecase
-   api
-   batch
-   infrastructure

依存関係は以下のようになっています。domainプロジェクトは、 **test以外に外部依存ライブラリがない** という状態になっています。

```nil
domain <-- usecase <- api
        └- batch
```


### Kotlinの適用範囲 {#kotlinの適用範囲}

**全部** です。設定がめんどくさくてJavaになっているものも１ファイルくらいありますが、99.9% Kotlinで書いています。


## Kotlin + SpringBootの感想 {#kotlin-springbootの感想}

感想と言っても特筆すべきものはなく、あえて言えば **普通** です。Spring自体がKotlin対応を行っているということもあり、実に普通な書き心地です。

ただ、DIをしまくる関係上、関数で済むようなものでもinterfaceにしないといけないので、その点がストレスです。

```kotlin
@Component
class Foo(private val bar: () -> String) {
  fun exec() = bar() + "test"
}
```

みたいなクラスがあったとき、関数をDIすることが出来ない（多分）ので、わざわざinterfaceを定義する必要があります。

まぁ、interface定義自体は難しくないし、Javaから入った人もわかりやすいのでいいかと。ただ、関数がfirst classである、というkotlinの特徴を殺してしまいやすいのでなんともですが・・・。


## 書いていて課題になったところ {#書いていて課題になったところ}


### Kotlin内でのSAM変換が効かない {#kotlin内でのsam変換が効かない}

色々なところで書かれていますが、Kotlinでは **Kotlinで定義されたinterfaceについては** SAM変換が効きません。([参考](https://dev.classmethod.jp/smartphone/kotlin-everyday-12/))

関数を引数に取った場合は、当然ながらLambdaを渡せるのですが、interfaceを受け取る場合はその限りではありません。これがJavaのinterfaceでもできない、というのであればある意味一貫性があると思うのですが、 **Javaで定義されたinterfaceではできる** というのもあり、うーん、という感じです。
恐らく、Javaとの100%相互運用性、という点から出来るようになっていると思うんですが・・・。

毎回object式で書くのも、かつての無名クラスを思い出すし、冗長な記述になるので、是非できるようになっていただきたい。


### Sealed Classの使い勝手が微妙 {#sealed-classの使い勝手が微妙}

Kotlinの [sealed class](https://kotlinlang.org/docs/reference/sealed-classes.html) は、代数型データ型的な扱いをする時に役立つのですが、主にIDE（IntelliJ）側で起こる問題が厄介です。

```kotlin
sealed class A {
  object B: A()
  data class C(val foo: Int): A()
}

fun check(v:A): Bool =
  when (v) {
    is B -> true
    is C -> false
  }
```

こんなソースがあったとして、 `is <クラス>` の部分で、Aの派生クラスがtopに出てこないという問題が発生します。

-   whenのis句は、あくまで **smart castをしているだけ** です。([公式サイト](https://kotlinlang.org/docs/reference/control-flow.html#when-expression))
-   なので、kotlinとしてはその後に派生クラスだけしか来ない、という判断が難しいのでしょう
-   しかし、アプリケーション全体のサイズが増えてくると、探すだけで面倒ですので、出来れば出来て欲しい
-   実際、whenにsealed classが渡された時、派生クラスの一部しか指定していない場合はコンパイルエラーになるので、出来ないわけではなさそう

enum classではちゃんと出てくるのと、sealed classを継承したobjectだとちゃんと出てくるので、 **値かどうか** が重要な感じっぽいです。設定でなんとかなるのであればいいんですが・・・。OCamlの利用者がmatch文と同じようなもんだと思って使うと痛い目みます。（自分）


### data classとfactory {#data-classとfactory}

DDDをKotlinでやろうとすると、間違いなくdata classの恩恵を授かると思います。ただ、data classには一つ問題があり、内部状態を変更できてしまう、という課題があります。これはdata classを単にequals/toString/hashCode等々の自動生成をしてくれる機能、としかみていない弊害のような気もしますが・・・。

```kotlin
data class Foo(val a: Int, private val b: Int) {
}

val a = Foo()
a.b = 100 // エラー。
val c = a.copy(b = 100) // OK!
```

これは、data classがPOJO的なobjectのコピー生成を簡便にするためのcopyメソッドを生成するためです。本来の目的としては正しいのですが、これを使ってしまうと意味がないのです・・・。

また、private fieldもコンストラクタに書かないといけないので、結局内部構造を露呈しているのと変わりません。factoryを用意しても、copyで書き換えられます。

これを回避したければ、interfaceとの併せ技を利用する必要があります。

```kotlin
interface Foo {
  val a: Int

  fun exec(): Int

  companion object {
    fun create(v: Int): Foo = FooImpl(v)
  }
}

private data class FooImpl(override val a: Int) {
  private val b: Int

  init {
    b = a * 2
  }

  override fun exec() = b
}

// 別ファイル
val v = Foo.create(100)
v.b // エラー
v.copy // 定義されていない
v.exec() // 200
```

正直めんどくさいのですが、Kotlinは単一ファイルに複数の定義をすることが出来るので、見通し自体はそんなに悪くありません。interfaceだと外部で実装される可能性があり、それも排除したいのであれば、sealed classにするのも手でしょう。テストがめんどくさくなる気はしますが。


## でもkotlinはいいぞ {#でもkotlinはいいぞ}

使っていくうちに不満が溜まっていくのは、どんなものでもそうだと思うので仕方ないと思いますが、個人的にkotlinはかなり気に入っています。特に次の部分がお気に入りです。

-   data classでお手軽なDTO作成
    -   lombokのインストール周りで戦う必要なし
-   sealed classで擬似的な代数型
    -   メソッドの結果を返すようなところに絞って利用しています
-   同一ファイルでの複数定義
    -   なんだかんだ言いつつ、関連性の高いものを一箇所にまとめられるというのはいいものです

Java本体の機能拡充も続いていますが、まだしばらくはKotlinを続けていこうかと思います。
