+++
title = "OCamlでMonadを使う時はppx_letを使おう"
author = ["derui"]
lastmod = 2019-09-14T11:15:26+09:00
tags = ["OCaml"]
draft = true
+++

ちょっとしたCLI（ある程度出来たら記事にします）をOCamlで作っています。その際、初めて[ppx\_let](https://github.com/janestreet/ppx%5Flet)を使ってみたんですが、なかなか良かったので紹介します。

<!--more-->

[ppx\_let](https://github.com/janestreet/ppx%5Flet)は、OCaml界隈では知らない人のいない[Jane Street](https://www.janestreet.com/)社が公開しているPPX拡張です。


## OCamlでmonadを扱う時の課題 {#ocamlでmonadを扱う時の課題}

大抵、resultとかoption（特にresult）をmonadicにつなげていく時、大抵は下のような書き方になります。

```ocaml
let bind v ~f = match v with
  | Ok v -> f v
  | Error _ as v -> v
let (>>=) v f = bind v ~f

let foo = function
  | v when v > 10 -> Ok v
  | _ -> Error "error"


let bar v = Ok (v * 10)

let () =
  let v = foo 12 >>= bar in
  match v with
  | Ok v -> Printf.printf "result %d\n" v
  | Error e -> Printf.printf "error %s\n" e
```

`>>=` とかのoperatorを使うのが一般的かと思います。これは非常にシンプルな例なので、operatorでも特に困りません。

しかし、ある程度の規模になってくると、ある時点で取得したデータを、後に使いたい、ということが非常によくあります。

```ocaml
foo v >>= fun v1 ->
bar v1 >>= fun v2 ->
foobar v1 v2
```

これが続くと、特にreadabilityの点で問題になってきます。

-   関数のformatの派閥によっては読みづらい
    -   ocamlformatを使っても解決にならないです
-   単純に毎回 `fun` を書くのが面倒
    -   OCamlにHaskellのdo構文のようなものはありませんので。

これらを解決するために、PPX拡張が色々出ています。lwt用にlwt\_ppxとかあったりします。


## ppx\_letの特徴 {#ppx-letの特徴}

詳しくはppx\_letのreadmeを読むのが早いのですが、overviewとして次のように書かれています。

> The aim of this rewriter is to make monadic and applicative code look nicer by writing custom binders the same way that we normally bind variables

すごい簡単に言うと、MonadicとかApplicativeが混ざったコードを読みやすくするためのPPX拡張です。

ppx\_letは、特定のMonad/Applicativeに閉じず、 ****特定のmodule定義があれば動作します**** 。この辺りの汎用性が高いです。


## ppx\_letで書いてみる {#ppx-letで書いてみる}

先に出た例は、以下のように書き換えられます。

```ocaml
module Let_syntax = struct
  let bind v ~f = function
    | Ok v -> f v
    | Error _ as e -> e

  let map v ~f = function
    | Ok v -> Ok (f v)
    | Error _ as e -> e
end

let%bind v1 = foo v in
let%map v2 = bar v1 in
foobar v1 v2
```

ppx\_letは、対応する型に対して、 `Let_syntax` というmoduleが定義されていることを要求します。基本形として、次のextensionを提供しています。

-   `let%bind`
-   `let%map`
-   `match%bind`
-   `match%map`
-   `if%bind`
-   `if%map`

どういう変換か？は、各構文においては割と自明なんですが、mapとbindの違いがちょっと分かりづらいです。この違いは、 `bind` はlet expression全体をそのまま利用する、 `map` はlet expression全体をmonadに包む、という点の違いです。


## ppx\_letのいい所 {#ppx-letのいい所}

-   コンパイル後にライブラリ依存がない
    -   Jane Street製のppxの中には、コンパイル後にbaseとかcoreを要求するものがあったりするので、場合によっては使いづらいです
-   汎用的
    -   module一個定義すればいいので、monadを書いたらそれをそのままcopyするだけで使えます
-   見た目に一貫性がでる
    -   変数束縛はlet、という形で一貫性がでます
    -   変数束縛が不要な場合は、普通にoperatorを使うほうがスッキリします


## monadを使う場合はppx拡張を使おう {#monadを使う場合はppx拡張を使おう}

ほとんどのアプリケーションでは、何かしらのMonadを使うかと思います。そうでなくとも、optionやresultは多用されると思います。

ひたすらnestしたmatch書いてるなー、とか、operatorが10個とか続いて心がすさんでいると感じたら、ppx\_letを試してみてはいかがでしょうか。少しは心の平穏を得られるかもしれません・・・。
