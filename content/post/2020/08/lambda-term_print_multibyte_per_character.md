+++
title = "lambda-termでmulti byteを一文字ずつ表示する"
author = ["derui"]
date = 2020-08-01T11:34:00+09:00
lastmod = 2020-09-22T12:53:45+09:00
tags = ["OCaml"]
draft = false
+++

気づいたら８月になっていました。今年の梅雨はかなり長かったですね・・・。過ごしやすいのは結構なんですが、野菜が高くなるのでこれも困ります。

今回は、OCamlでTUI（Terminal-based User Interface）を作る際の鉄板ライブラリである [lambda-term](https://github.com/ocaml-community/lambda-term) を使ったときに、multi byteを表示出来なかったのを解消したので、備忘録として書いておきます。

<!--more-->


## やりたかったことと起こっていたこと {#やりたかったことと起こっていたこと}

やりたかったこととしては、

-   一文字ずつ表示したい
-   各文字にstyleを当てたい

lambda-termでは、 `LTerm_draw.draw_string` と `LTerm_draw.draw_char` という２つの関数があります。こいつらは字面の通り、stringやcharをレンダリングします。

使い方はこんな感じです。実際にはcontextが必要なので、widgetの中とかで行う感じです。

```ocaml
let str = Zed_string.of_utf8 "foo" in
let style = LTerm_style.none in
LTerm_draw.draw_string ~style ctx 0 0 str;
LTerm_draw.draw_char ~style ctx 0 1 @@ Zed_string.get 0 str
```

これで表示自体は出来るんですが、 `LTerm_draw.draw_char` を使っていった時に、色々と気になる問題がありました。それは、multi byte（ここでは日本語）を表示しようとした時に、なぜか表示されない、ということでした。


## 解決 {#解決}

備忘録なのでさっさと行きますが、原因は `LTerm_draw.draw_char` のcolumn指定の誤りでした。

`LTerm_draw.draw_char` のシグネチャは、以下のようになっています。

```ocaml
val draw_char: ?style:LTerm_style.style -> LTerm_draw.context -> int -> int -> Zed_char.t -> unit
```

さて、Zed\_charですが、こいつは [zed](https://github.com/ocaml-community/zed) というライブラリが提供しているmoduleです。こいつはunicodeを保持していて、保持している文字の幅も持っています。 `Zed_char.width` で取得できます。

`LTerm_draw.draw_char` の挙動ですが、基本的にはterminalのascii 1文字を1columnとして描画します。ただ、 `Zed_char.width` が1より大きい場合は、1より大きい分だけSizeHolderというダミー文字で埋めるようになっています。

この挙動がわかっていなかったので、multi byteを1columnずつずらして表示しようとすると、一つ前に表示したmulti byteを消したのと同じ状態になってしまっていました。

実際、multi byteを考慮した上で `LTerm_draw.draw_char` を使う場合、以下のようにする必要があります。

```ocaml
let str = Zed_string.of_utf8 "テストfoo" in
let style = LTerm_style.none in
Zed_string.fold (fun ch index ->
    LTerm_draw.draw_char ~style ctx 0 index ch;
    index + Zed_char.width ch
  ) 0 |> ignore
```

わかってしまえば納得ですが、中々ドキュメントだけでは分かりづらいことなので、誰か（主に自分）の役に立てばと思います。


## 結び {#結び}

今回のやつは、実際にはもうだいぶわからんかったので直接ソースを読んで挙動を使う把握しました。

わからなかったらソースを読める、というのはやはりOpenSourceの強みだなぁと実感した次第です。
