+++
title = "最近知ったOCamlの小ネタ"
author = ["derui"]
date = 2023-04-09T07:57:00+09:00
tags = ["OCaml"]
draft = false
+++

すっかり暖かくなりました。ツツジも咲き出しているので、そろそろまた駒込とかに行こうかなぁ、とか思ってます。

今回は草埋めに近い、最近知った超スモールな小ネタになります。

<!--more-->


## OCamlでまれによくあるパターン {#ocamlでまれによくあるパターン}

OCamlでは、moduleの内容を隠蔽したい場合、 `.mli` ファイルを作る必要があります。が、そのままだと、宣言と定義でまったく同じ内容を二回書いてしまうので、よく↓のようにやります。

```ocaml
(* s_intf.ml *)

module type S = sig
  type t

  val hoge: t -> int
end

(* s.mli *)
include S_intf.S

(* s.ml *)

module Impl: S_intf.S = struct
  (* 実装する *)
end

include Impl
```


## 小ネタ本体：include Xxxを省略できる {#小ネタ本体-include-xxxを省略できる}

上に書いたパターンのうち、 `.ml` 部分ですが、実はこう書けます。(記憶で書いているので、コンパイルが通るかはわかんないですが)

```ocaml
include struct
  type t = int

  let hoge v = v
end: S_intf.S
```

私も最近知ったんですが、OCamlの4.xxのどこかで、includeの直後に  `struct ... end` を書けるようになったので、このような書き方ができるようになったらしいです。地味にボイラープレートだったので、これはこれで結構ありがたいなーという所感です。

OCamlはちょいちょい文法拡張が入ってはいるんですが、過去との互換性を崩さないように、ド派手なものは結構少なかったりするので、ふとしたときには学び直しも大事ですね。
