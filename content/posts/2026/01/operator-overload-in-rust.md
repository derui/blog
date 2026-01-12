+++
title = "RustでOperator Overloadを利用したDSLを作ってみる"
author = ["derui"]
date = 2026-01-12T17:29:00+09:00
tags = ["programming", "rust"]
draft = false
+++

気が付いたら2025年が終わってました。今年の抱負とか考える前に仕事が始まったので、今年もいきあたりばったりに行きていければと思います。

最近Rustで細々と格闘しているんですが、ちょっとやってみたいことがあってやってみたらできたので、小ネタとして残しておこうかと思います。


## やりたいこと {#やりたいこと}

諸事情で、代数式をstructとして管理することをしています。毎度ですが、なんでそういうことをしようとしているのか？は聞いてはなりません。

```rust
// こんなtraitを定義しておく
trait Equation {
    // envは変数のhashmap
    fn evaluate(&self, env: &HashMap<String, f32>) -> f32;
}
```

こんなtraitを実装したものを考えたいです。なお実装は自明なので省きます。で、これを普通に実装すると、ちょっと複雑になっただけで大変なことになります。

```rust
// 3.2 + 3.4
let e = ArithmeticEquation::new(Add, ConstantEquation::new(3.2), ConstantEquation::new(3.4))

// 掛け算とかがnestすると大変なことになる
```

これをなんとかある程度楽にしたい、というのがモチベーションです。


## 方法の検討 {#方法の検討}

Rustだと、大きく3通りのやり方があると思います。

1.  procedural macroを実装する
2.  lexer/parserを利用してparseを実装する
3.  operator overloadとstructを駆使して頑張る

macroとoperator overloadはcompile時に、lexer/parserは動的になる感じです。最終的にはlexer/parserが必要になりそうなんですが、一旦は静的にできれば（テストを書いたりするときに）便利です。となると、macroかoperator overloadが選択肢になる感じですね。

> lexer/parser自体を生成するmacroとかはあるようですが、そもそもparseするという行為自体が、compileした後の話になるので。


## Operator overloadを検討してみる {#operator-overloadを検討してみる}

RustのOperator overloadは大変に強力である意味シンプルなのですが、 **Scopingが困難** です。 KotlinとかのOperator overloadでは、interfaceの実装元とかで切り分けられたり、scoped functionを利用することで、DSL/operator overloadの利用範囲をscopingすることがるできます。

```kotlin
object Ops {
    operator fun invoke(f: Ops.() -> Unit) {
        f()
    }

    infix fun String.test(rhs: String): boolean {...}
}

// こんな感じで使える
Ops {
    "hoge" test "foo"
}
// 外だと明示的なimportが必要。
```

翻ってRustのOperator overloadは、標準にある `Add` や `Sub` といったTraitを型に対して実装する・・・という形です。

<https://doc.rust-lang.org/rust-by-example/trait/ops.html>

さて、ここでRustのtraitに対する実装の可視性なんですが、 **基本的にpublicのtraitに対する実装はpublic** になるようです。当然typeがpublicであることも前提ですが。
<https://users.rust-lang.org/t/visibility-of-trait-implementation/6789>

そうなると、そもそも **Scopingする** というのはほぼ不可能・・・という結論になります。


### traitに対するimplか、traitの実装にたいするimplか {#traitに対するimplか-traitの実装にたいするimplか}

今回は、事実上 `Equation` というtraitに対するoperator overloadの設計です。こうなると、 **traitに対する実装** なのか、 **structに対する実装** なのか？を考える必要があります。

ここでOOP脳というかJavaの心だと、 **traitに対して実装したらいいんでね？** と思ってしまうところだと思います。これが罠？で、Rustだとtraitに対する実装は **基本的にBoxで包む必要があります** 。

```rust
trait Foo {
    // ...
}

impl Add for dyn Foo {} // 大抵ダメ
impl Add for impl Foo {} // こっちもダメ
impl Add for Box<dyn Foo> {} // 大体はこれ
```

これはRustにおけるtrait実装のruleらしいのでこうなるとのことです。が、保持するときとかはしょうがないですが、DSLを作っているときにはあんまり気にしたくないものです。


## こうしてみた {#こうしてみた}

紆余曲折がありましたが、こんな感じにしてみました。

```rust
// Operationを実装するためのnewtype
struct Ops(Box<dyn Equation>)

impl Add for Ops {
    // 普通に実装できる
}

// 変換のためにFromをいくつか実装
impl From<Ops> for Box<dyn Equation> {}

impl From<Box<dyn Equation>> for Ops {}

// f32に対してEquationに変換するのがあったとして
// 3.2 + 5.4がこんな感じにできる
let e: Box<dyn Equation> = (Ops::constant(3.2) + 5.4.into()).into()
```

-   Opsに対してのみ実装したらよい
-   基本型に対する変換を実装すれば、 `into()` は必要だがそこそこ読める

目的としては、静的な式に対して解決する・・・という感じなのでそこまで凝ってません。testで書く分にはだいぶましになります。


## DSLの限界とparser/lexerを選ぶべきタイミング {#dslの限界とparser-lexerを選ぶべきタイミング}

RustでもDSL自体はできます。が、やはりそれぞれ必要なタイミングを見極めたほうがいいかなと思います。

-   外部から動的に読み込む予定がない &amp;&amp; 複雑な構文 = macro
-   外部から動的に読み込む予定がある = parser/lexer
-   計算などを自然に表現したい = operator overload

今回の例だと、最終的にはparser実装したほうがいいな、とは思います。ただ、お仕事のkotlinだと割とDSLを書くことが多いので、Rustでもできないかな？というところでした。Rustだとnewtypeを実装してもpenaltyがないので（コンパイル時間以外は）、overload を多用する場合は、newtype + overloadがいいのかなぁ、とは現状思ってます。単一の `struct` に対してであれば、overloadで大体問題ないとも思いますが。
