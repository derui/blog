+++
title = "Rustでのエラーハンドリング"
author = ["derui"]
date = 2026-10-03T18:18:00+09:00
tags = ["programming"]
draft = false
+++

34日連続で雨だったそうで、そりゃー今年は涼しかったわけですね。その分千葉のあたりは大変なことになっておりますが。

Rustで真面目にWeb APIを作っていると、とても悩ましいのがエラーハンドリングだと思います。ちょっとやってみた内容を紹介します。


## Result or panic {#result-or-panic}

これについては、Javaとか他の言語のノリでpanicすると大変なことになるので、まず **原則panic禁止** くらいでいいかと思います。CLIならpanicしたほうがいいケースも多いと思いますが、Web APIでやったら多分ぶっ殺されます。
panic自体はhandlerがあったりはしますが、それに頼ったところでrewindとかそういったものもないので、SpringBootとかの黒魔術に慣れた人は、わりと気をつける必要があります（自分）。


## anyhow/eyreで潰す or 潰さない {#anyhow-eyreで潰す-or-潰さない}

エラーハンドリングを語るときに外せない [eyre](https://docs.rs/eyre/latest/eyre/)または [anyhow](https://crates.io/crates/anyhow) がまず出てくると思います。これは `Box<dyn std::error::Error + Sync + Send + 'static>` あたりを都度定義する・・・というところに対するカウンターだと理解してます。

これが効果を発揮するのは、 **とりあえずResultにするけど、エラー定義がめんどくせぇ** ってときだと思います。基本的に `eyre!` などで潰すことで、なんでも放り込めるエラーを作れます。これはプロトタイピングとか、 **APIのトップレベル** みたいな、もうハンドリングする必要がないところでは役立ちます。

が、これはTraitでは使えません。というか使うと困るのは多分自分です :angel:

```rust-ts
pub trait Hoge {
    // うーん、失敗するんだろうけどどう失敗するかわかんないな。とりあえず潰しとこう
    fn foobar() -> eyre::Result<Huga>;
}

fn main() {
    let foo = Foo::new();

    foo.foobar().map_err(|e| {
        match e {
            // さて・・・？あれ、区別できないぞ
        }
    })
}
```

traitはinterfaceというか操作の契約＝contractを表すので、エラーになるのであれば、きちんと定義しておくのがベターであるとは思います。今のところはこのように整理しました。

-   Trait境界ではeyre/anyhowを **使わない**
-   eyre/anyhowはmainとかでは使ってよし
    -   どうせpanicするレベルなので
-   DDDとかでドメイン層がある場合は・・・後述


## みんなの味方、thiserror {#みんなの味方-thiserror}

[thiserror](https://crates.io/crates/thiserror) は、おそらくエラーを定義する際にはほぼ必携のcrateです。手で書くとひっじょーにめんどくさいError traitの実装を肩代わりしてくれるのとともに、color_eyreを利用したときに役立つsource chainのハンドリングもしてくれます。

使い方はいいとして、じゃあ **いつ** 使うのか？というところです。個人的には、エラーの定義が必要だったら常に利用する、でいいとは思いますが、一個論点としては、 **Errorのchainをするかどうか？** があります。

```rust-ts
#[derive(Debug, Error)]
pub enum HogeError {
    // Errorがないので、 **どのresultから上がってきたかはわからない**
    #[error("it is hoge: {0}")]
    Hoge(String),

    // source指定すると、chainがつながったことになる
    #[error(transparent)]
    Huga(#[source] #[from] HugaError)
}
```

すっごい雑ですが、こんな感じにすると、つながっていることがわかります。

```rust-ts

#[derive(Debug, Error)]
enum Er {
    // sourceとして指定している
    #[error("this is E")]
    E(#[source] Box<dyn std::error::Error + Send + Sync + 'static>)
}


#[derive(Debug, Error)]
enum P {
    #[error("this is H")]
    H,
    // from指定で自動的にsource
    #[error("from Er")]
    E(#[from] Er)
}

fn er() -> Result<(), Er> {
    // h -> erの呼び出し + testを追加
    Err(Er::E(eyre!("test").into()))
}

fn h() -> eyre::Result<()> {
    println!("{:?}", P::H);
    // eyreのreporterを使うのでこうしておく
    // この場合、in h -> this is Eになります（ネストされたeyre!は同じ情報が入ってる状態）
    let e = eyre!(Er::E(eyre!("in h").into()));
    println!("{:?}", e);
    // この場合、from Er -> this is E -> testになります
    let e = eyre!(P::E(er().unwrap_err()));
    println!("{:?}", e);
    Ok(())
}
```

が、この場合 `P::H` は、たとえ何かしらのエラーが発生したとして、 **どのエラーが起点になったのか** がわかりません。 traitのエラーは前述の通り、何が起点になるのか・・・？はわかりません。ただ、 **エラーの内容自体はぶっちゃけなんでもいい** という特性もあります。

そこで、traitのエラーについてはこんな感じにします。

```rust-ts
// 冗長すぎるので
type E = Box<dyn std::error::Error + Sync + Send + 'static>;

#[derive(thiserror::Error, Debug)]
enum TraitError {
    // traitの契約上発生しうるエラー。発生元のエラーはなんでもいいので潰す
    #[error("Got domain error")]
    DomainError(#[source] E),

    // 他はあるかもしれないけどわかんないので、無視するために追加する
    #[error(transparent)]
    Other(#[source] E)
}
```

多分 `XxxOutCome` とかのような形で、Ok/Errを一つのenumで表現する・・・ということもありだとは思いますが、ケースによってはfast returnが非常に多岐に発生したり、TryFromとの兼ね合いがあったりとすることと、 **ドメインエラーも契約からしたらエラーだろう** というところから、こっちのほうがいいかねぇ、と感じています。設定上結構ボイラープレートになりそうな雰囲気はしますが、Rustは `HogeError::DomainError` をそのまま `map_err` に突っ込めるので、まあめんどくさいですけど・・・というところかなと。

この形にしたときの欠点は、Fromの型が解決できなくなってしまうので、 `#[from}` を利用できなくなる、というのがあります。これが使えると `?` のチェーンがキレイに書けるので悩ましいところですが。ただ、エラー本体に付加情報が必要な場合は、どっちにしろ利用できないので、そこはまあケースバイケースになるかなとは思います。


## APIでのエラーはわかりやすく {#apiでのエラーはわかりやすく}

HTTPレイヤーでのエラーは、もう全部潰してしまっていいかなと思います。

```rust-ts
enum HogeApiError {
    NotFound,
    Conflict,
    Unknown
}
```

なぜかを考えると、

-   そもそもこのエラーが終着点なので、sourceで連結する必要がない
-   ログをだしたければ、ここに到着したerror + アルファでいい
-   HTTP responseとかを返すとき、 **エラーの詳細が必要なケースはほぼない**

ので、変換処理のめんどくささなどを考えると、これくらいにしつつ、axumだったら `IntoResponse` をこの型に実装してしまえば、unit testとかも自明として作成できますし、余計な依存とかも不要になります。


## エラーの道は険しい {#エラーの道は険しい}

RustはResult/Optionのハンドリングが言語仕様側に組み込まれているものの、他の例外ベースだったり、OCaml/HaskellとかMonadベースのものともまた性質が異なっているのが特徴だと思います。個人的にはtrait境界指定がとにかくとにかくめんどくさすぎるので、もうちょっとなんとかならんか・・・と思いつつ書いてます。

asyncが絡まないんだったら楽なんですけどね、というところで今日はこんなところで。
