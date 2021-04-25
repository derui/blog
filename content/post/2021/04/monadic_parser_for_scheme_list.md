+++
title = "Monadic ParserでSchemeのリストをパースする"
author = ["derui"]
date = 2021-04-25T09:07:00+09:00
lastmod = 2021-04-25T09:07:56+09:00
tags = ["Programming", "Scheme"]
draft = false
+++

去年のGWに何をやっていたか全く記憶が無いんですが、今年も特に何もないGWになりそうですね。なんだかなぁ、という気分しかありませんが。

そんな状態ですが、最近チマチマと作っているOCamlでのScheme処理系で、Monadic Parserを作ってみたので、その紹介をちょっとできれば。

<!--more-->


## Monadic parserとは {#monadic-parserとは}

まずMonadic parserとは何か、ですが、あんまり明確な定義は無いというか、名は体を表すというか、そのまんまというか。モナドを利用したparserです。Haskellの[Parsec](https://github.com/haskell/parsec)が有名ですね。

基本的には、

-   関数で構成されている
-   モナド則により合成可能である

という感じかなー、と。理論的な背景はあんまり理解しきれていないので、あくまで私の理解ではありますが。


## OCamlのapplicable let {#ocamlのapplicable-let}

Haskellだと、Monadの記述にとても役立つ、 **do記法** というのがあります。OCamlには長らくそういうのがなく、PPXとかで各ライブラリごとに拡張を書いていたり、ppx\_letのように汎用的な拡張を利用したり・・・というのが必要でした。

が、OCamlの4.08？くらいで導入された `Applicable let` というのを利用すると、do記法と同じような記述を、OCamlらしく記述することができます。

```tuareg
module Nanika_monad = ...

let ( let* ) v f = Nanika_monad.bind f v

let () =
  let* v = Nanika_monad.return v in
  ...
```

applicable letと言っても、なんてことのない関数定義です。 `let*` とかだけではなく、 `let+` みたいなものも定義できます(定義の中身は、定義の実装者次第です)。letが定義できるということで、同時に `and*` のような関数も定義することができます。

これですが、 `>>=` での結合をほぼそのまま変換することができ、逐次処理のように見せることができます。記号で繋げまくっていくのも楽しいですが、後から見たときに処理が明瞭になるので、最近はMonadとかを利用するときはこれを使ってます。


### Applicative ParserではなくMonadic Parserになる理由 {#applicative-parserではなくmonadic-parserになる理由}

Monadic Parserとはよく呼ばれるけど、 **Applicative Parser** というのが無い理由ですが、これはシンプルで、 **Applicableだとパースできないものが沢山ある** から、という理由のようです。

具体的な例は、もっとよく説明しているサイトを参考にするのがよいと思います。私の浅い理解だと、

-   Applicableだと、繰り返しやバックトラックといった挙動を定義することができない
-   前の値を利用する、というようなことができない

ため、そもそもパーサーという目的には機能が足りないのでApplicative Parserというものは事実上作成されない、ということのようです。よりシンプルなパースができればいいのであれば、Applicative Parserとかも作れると思います。


## 作ったもの {#作ったもの}

ソースをベタっと貼ります。

```ocaml
module List_parser = struct
  (* The type of parser *)
  type 'a t = T.data -> ('a * T.data, T.scheme_error) result

  let map : ('a -> 'b) -> 'a t -> 'b t =
   fun f p data -> match p data with Error _ as v -> v | Ok (v, rest) -> Ok (f v, rest)

  let pure : 'a -> 'a t = fun v data -> Ok (v, data)

  let apply fp xp data = match fp data with Error _ as v -> v | Ok (f, rest) -> (map f xp) rest

  let bind : 'a t -> ('a -> 'b t) -> 'b t =
   fun v f data -> match v data with Error _ as e -> e | Ok (v, rest) -> f v rest

  module Infix = struct
    let ( <*> ) = apply

    let ( <$> ) = map

    let ( >>= ) = bind
  end

  module Let_syntax = struct
    let ( let* ) = bind

    let ( let+ ) = apply
  end

  open Let_syntax
  open Infix

  (* Apply [p1] and [p2] sequentially and use right result *)
  let ( *> ) p p2 = Infix.((fun _ y -> y) <$> p <*> p2)

  (* Apply [p1] and [p2] sequentially and use left result *)
  let ( *< ) p p2 = Infix.((fun x _ -> x) <$> p <*> p2)

  let element = function
    | T.Empty_list               -> T.raise_syntax_error "end of list"
    | Cons (v, (Cons _ as rest)) -> Ok (v, rest)
    | Cons (v, T.Empty_list)     -> Ok (v, Empty_list)
    | Cons (v, k)                -> Ok (v, k)
    | _ as v                     -> T.raise_syntax_error (Printf.sprintf "malformed list: %s" @@ Pr.print v)

  let cdr = function
    | T.Empty_list -> T.raise_syntax_error "should be end"
    | Cons _       -> T.raise_syntax_error "not malformed list"
    | v            -> Ok (v, T.Empty_list)

  let zero v = T.raise_syntax_error (Printf.sprintf "empty: %s" @@ Pr.print v)

  let choice p q data =
    let p = p data in
    let q = q data in
    match (p, q) with Error _, Error _ -> T.raise_syntax_error "can not choice" | Error _, Ok v | Ok v, _ -> Ok v

  (* combinator to choice *)
  let ( <|> ) = choice

  let tap f data =
    let p =
      let* v = element in
      f v |> pure
    in
    p data |> ignore;
    Ok ((), data)

  let satisfy p =
    let* v = element in
    if p v then pure v else zero

  let many : 'a t -> 'a list t =
   fun p ->
    let p = (fun v -> [ v ]) <$> p in
    let rec many' accum =
      let* v = p <|> pure [] in
      match v with [] -> List.rev accum |> pure | v :: _ -> many' (v :: accum)
    in
    many' [] <|> pure []

  let many1 p =
    let* p' = p in
    let* ps = many p in
    fun data_list -> Ok (p' :: ps, data_list)

  (* chain one or more repeated operator to result of parser. *)
  let chainl1 : 'a t -> ('a -> 'a -> 'a) t -> 'a t =
   fun p op ->
    let rec chain_rest a =
      let result_of_cycle =
        let* f = op in
        let* v' = p in
        chain_rest (f a v')
      in
      result_of_cycle <|> pure a
    in
    let* a = p in
    chain_rest a

  (* chain zero or more repeated operator to result of parser. *)
  let chainl p op a = chainl1 p op <|> pure a
end
```

使い方としては、おおむね他のparserと同じような形です。大抵のparserは文字列のパースに特化していますが、このparserは **Schemeのリスト構造のパースに特化** しています。

> なお、T.dataとかは、Schemeのデータ構造を表しています。 `Symbol` とか `Number` とかそういうやつが定義されています。

例えば、要素がシンボルかリテラルのいずれかである、という規則は以下のように表現できます。

```ocaml
let symbol = L.satisfy T.is_symbol

let constant = L.(satisfy T.is_number <|> satisfy T.is_true <|> satisfy T.is_false)

let () =
  let f = let p1 = (function T.Symbol s -> s | _ -> failwith "Invalid") <$> symbol in
          let p2 = (fun v -> v) <$> constant in
          L.(p1 <|> p2) data
  in
  f (T.Number "1")
```

`let*` とかも定義しています。ちょっと使うのが書けませんでしたが・・・。


### なんで作ったの？ {#なんで作ったの}

Schemeには `syntax-rules` というマクロ・・・というかパターン言語がありますが、ここがSchemeの中でも個別の構文解析が必要なレベルで複雑そうだったので、Schemeのリストをパースするものを作った方が最終的に楽だな・・・ということで書きました。

あと、monadic parserって使ったことはあるけど書いたことがなかったので、習作ということもあります。色々な記事を参考にしましたけど・・・。


## DSLとしても使えるのでサクっと作れるようになっていきたい {#dslとしても使えるのでサクっと作れるようになっていきたい}

今回、Schemeのリスト用として作りましたが、特定のドメイン領域に対してのDSL、という感じにもできそうです。まぁDSLというか解析する場合だけですけど。

こういうのをサクッと書けるようになると、また経験値が上がっていくと思うので、引き続き精進していく次第です。
