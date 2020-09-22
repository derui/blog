+++
title = "関数型と手続き型の違い"
author = ["derui"]
date = 2018-09-18T23:46:00+09:00
lastmod = 2020-09-22T11:21:51+09:00
tags = ["Programming", "雑記"]
draft = false
+++

ふととあるところで、 **関数型に書かれていない** みたいな記述を見つけました。このときなんかモヤっとしたんですが、うまく言語化出来なかったので、ちょっと書いてみます。

<!--more-->


## まず始めに観測する {#まず始めに観測する}

**関数型** とか **手続き型** と言いますが、一体どういう基準で話しているかは、書き手・話し手に依存するようです。ただ、ある程度一貫しているのは

-   関数型という場合、多くの場合は関数がファーストクラス
-   手続き型という場合、低レイヤーな言語で書かれているようなものを指しているケースが多い
-   稀に、関数型言語と手続き型言語という感じでの使い方もされる様子
    -   関数型言語としてはHaskell/Lispなど
    -   手続き型言語としてはC/昔のJavaなど

くらいのようです。私の観測範囲が狭すぎるのであれですが・・・。


## 関数型の書き方とは？ {#関数型の書き方とは}

Java7から8になったタイミングでよく言われたのは、 [Project Lambda](http://openjdk.java.net/projects/lambda/) によって導入されたLambda式でした。私もご多分に漏れずよろこんで使っているわけですが。ただ、これはJavaという言語が関数を言語のファーストクラスにした、という意味ではなく、単純にあまりに冗長だった無名インターフェースを簡単に書けるようにした糖衣構文です。

例えばこういうのが

```java
Thread thread = new Thread(new Runnable() {
        @Override
        public void run() {
            ...
        }
    });
```

こうなります。

```java
Thread thread = new Thread(() -> {...});
```

どう見ても後者の方が圧倒的に短いです。ですが、これは単に `() -> {}` が、 Runnableインターフェースの `run` メソッドの実装として扱われているだけです。IntelliJとかであれば、RefactorだったかSourceから、糖衣構文にした場合としない場合にそれぞれ変換できますので、やってみるとわかりやすいです。

同じくJava8で入った `Stream` は、このLambdaを使い倒して貰おうというのが明白なインターフェースをしています。大抵、このStreamとLambdaを組み合わせて書いたものを関数型的というケースが多いようです。


## 何がモヤッとするのか {#何がモヤッとするのか}

一応今までに [Haskell](https://www.haskell.org/) や Common Lisp、 [OCaml(公式が表示されなかったので日本版)](http://ocaml.jp/) を触っていますし、OCamlは今も継続して使っています。Javaは仕事で大量に書きましたし、JavaScriptも大量に書いています。C/C++も普通に使っていました。それぞれ、関数型言語と言われたりオブジェクト指向言語であったり、手続き型（C++はあれですが）言語と言われていたりします。

そんな中でモヤっとするのは、 **見た目だけで関数型かどうかは決まらないのに、スタイルで語るのはなんか違うのでは無いか** と最近思ったりするからです。試しにやってみるとわかりますが、Stream + Lambdaで調子に乗ってベタ書きすると、すぐに再利用不可かつ、for文で書くよりも可読性の悪いものが出来上がります。


## 関数型と手続き型の狭間 {#関数型と手続き型の狭間}

では実際に、私の思う手続き型と関数型の違いをコードにしていってみます。ここでは私が一番Loveな言語であるOCamlを使います。

```ocaml
let () =
  let num = ref 12345 in
  let buffer = Bytes.make 5 ' ' in
  for i = 5 downto 1 do
    let n = !num mod 10 in
    let v =
      match n with
      | 1 -> '1'
      | 2 -> '2'
      | 3 -> '3'
      | 4 -> '4'
      | 5 -> '5'
      | _ -> assert false
    in
    Bytes.set buffer (pred i) v;
    num := !num / 10
  done ;
  print_string (Bytes.to_string buffer)
```

`12345` という数字を `"12345"` という文字列にするのを、ものすごく冗長に、かつrefや副作用バリバリで書いてみました。OCamlにはwhileもありますが、ここではforを使いました。OCamlでforを使ったのは初めてです。

さて、どこからどう見ても冗長ですし、何をやっているか分かりづらいです。まずは手続き型でも関数型も関係なく、まとまった処理を切り出していきましょう。

```ocaml
let () =
  let int_to_char = function
    | 1 -> '1'
    | 2 -> '2'
    | 3 -> '3'
    | 4 -> '4'
    | 5 -> '5'
    | _ -> assert false
  in

  let num = ref 12345 in
  let buffer = Bytes.make 5 ' ' in
  for i = 5 downto 1 do
    let n = !num mod 10 in
    let v = int_to_char n in
    Bytes.set buffer (pred i) v;
    num := !num / 10
  done ;
  print_string (Bytes.to_string buffer)
```

一番大きい処理を関数にしました。この辺りは、関数型も手続き型も変わらないと思います。これだけで大分スッキリしましたが、まだまだ手続き型と言った風情です。もう少し関数に切り出していきましょう。

```ocaml
let () =
  (* 追加 *)
  let last_digit num = num mod 10 in
  let drop_last_digit num = num / 10 in
  let int_to_char = function
    | 1 -> '1'
    | 2 -> '2'
    | 3 -> '3'
    | 4 -> '4'
    | 5 -> '5'
    | _ -> assert false
  in
  let num = ref 12345 in
  let buffer = Bytes.make 5 ' ' in
  for i = 5 downto 1 do
    let n = last_digit num in
    let v = int_to_char n in
    Bytes.set buffer (pred i) v ;
    num := drop_last_digit !num
  done ;
  print_string (Bytes.to_string buffer)
```

ある程度意味のある感じに切り出してみましたが、 `Bytes.set` とnumの更新部分が邪魔をして、現在の構造だとこれ以上は難しそうな感じです。Cとかだとだいたいこんな感じで止まるケースが多いかと思います。（再帰を使う場合は別ですが）しかしOCamlは、純粋関数型言語の極北であるHaskellと同等の表現力があります。やりたいことを更に分解していってみます。まず、numの更新部分が邪魔です。つまるところ、各digitに分けていければいいだけなので、こうします。

```ocaml
let split_to_digit num =
  let rec loop num buffer =
    match num with
    | 0 -> buffer
    | _ -> loop (drop_last_digit num) (last_digit num :: buffer)
  in
  loop num []

(* split_to_digit 12345 => [1;2;3;4;5] *)
```

再帰関数が出てきました。OCamlとかでは、forやwhileの代わりになるのは基本的に再帰関数になるのでしょうがないです。forループで一桁ずつ分解する代わりに、一気に各桁をリストにしてしまいます。これを使うと、上の例がこうなります。

```ocaml
let () =
  let last_digit num = num mod 10 in
  let drop_last_digit num = num / 10 in
  (* 追加 *)
  let split_to_digit num =
    let rec loop num buffer =
      match num with
      | 0 -> buffer
      | _ -> loop (drop_last_digit num) (last_digit num :: buffer)
    in
    loop num []
  in
  let int_to_char = function
    | 1 -> '1'
    | 2 -> '2'
    | 3 -> '3'
    | 4 -> '4'
    | 5 -> '5'
    | _ -> assert false
  in
  let num_list = split_to_digit 12345 in
  let buffer = Bytes.make 5 ' ' in
  (* forループを、List.iteriに関数を適用するように変更 *)
  List.iteri
    (fun i n ->
       let v = int_to_char n in
       Bytes.set buffer i v )
    num_list ;
  print_string (Bytes.to_string buffer)
```

なんだか全体としては長くなりましたが、本質となる部分は `List.iteri` だけになりました。 `List.iteri` は、第一引数にインデックスとリストの一要素を受け取る関数を、第二引数にリストを受け取り、リストの末尾まで関数を繰り返し実行するような関数です。

こうなると、 `buffer` に値を設定していく、ということ自体がなんか邪魔です。せっかく各桁ごとに既にリストになっているので、これを有効利用しましょう。List.mapを使ってみます。

```ocaml
let () =
  let last_digit num = num mod 10 in
  let drop_last_digit num = num / 10 in
  (* 追加 *)
  let split_to_digit num =
    let rec loop num buffer =
      match num with
      | 0 -> buffer
      | _ -> loop (drop_last_digit num) (last_digit num :: buffer)
    in
    loop num []
  in
  let int_to_char = function
    | 1 -> '1'
    | 2 -> '2'
    | 3 -> '3'
    | 4 -> '4'
    | 5 -> '5'
    | _ -> assert false
  in
  let num_list = split_to_digit 12345 in
  (* List.iteriでやっていたことをList.mapとstringの結合でやるように変更 *)
  let char_list = List.map int_to_char num_list in
  let string_list = List.map Char.escaped char_list in
  print_string (String.concat "" string_list)
```

List.mapで書き直してみました。bufferとしてBytes（mutableなstringです）を使う必要がなくなり、全体的に副作用がなくなりました。JavaでのStream + Lambdaとかでも、メソッドチェインなどを使ってこんな感じ（List.mapをメソッドチェインしたりして）にしてたりします。でもこれ、本質的には手続き型な感じがします。最終的にやりたいことは、単純に **数値を文字列にしたい** だったはずです。それを読み解くには、全部読まないとなりません。これだと最初の例とあんまり変わってませんし、List.mapを使っていてもこれは関数型とは呼べないなぁと感じます。

ではどうするか？ということですが、これを私の思う関数型に一気に書き換えてみます。

```ocaml
let () =
  let ( & ) f g v = f (g v) in
  let remainder num = (num / 10, num mod 10) in
  let split_to_digit num =
    let rec loop num buffer =
      match remainder num with
      | 0, 0 -> buffer
      | rest, digit -> loop rest (digit :: buffer)
    in
    loop num []
  in
  let int_to_char = function
    | 1 -> '1'
    | 2 -> '2'
    | 3 -> '3'
    | 4 -> '4'
    | 5 -> '5'
    | _ -> assert false
  in
  let num_to_string =
    let int_to_string = Char.escaped & int_to_char in
    let join = String.concat "" in
    join & List.map int_to_string & split_to_digit
  in
  print_string (num_to_string 12345)
```

こんな感じになりました。OCamlには関数合成の演算子がデフォルトで定義されていないため、 `(&)` として定義しています。何を変えたか？というと

-   `last_digit` と `drop_last_digit` は、結局商と剰余がセットでわかればいいだけなので、remainderとして再定義
-   List.mapを複数回実施していたのを、関数を合成して一回で済むように
-   `String.concat ""` というのにも意味のある名前を定義
-   最終的に全部を合成

あたりです。int\_to\_charの部分を `Char.chr` を使ったりすればもっと短くなりますが、とりあえずコレくらいが今の限界です。上記の特徴からまとめてみると、私の思う関数型っぽさとは、 **小さい関数を合成して処理を組み立てる** ことにあると思います。

意味のある小さい単位を組み合わせることで、更に意味のある大きな単位を作っていくことをしていくと、小さい単位は再利用が効くようになっていきます。大きな単位は、再利用が効かないこともありますが、小さい単位の組み合わせ毎に意図のある名前を付けていくことが、可読性も上げられるはずです。


## まとめ {#まとめ}

関数型に書く、ということは、細かい単位にも名前をつけていき、それを組み合わせていく、というスタイルになっていくと思います。単にmap/filter/foldなどを使うだけでは、その処理はまだ関数型では無いケースが大半だと思います。

ただ、関数型もやりすぎるとわけがわからなくなるケースが多いので、ケースバイケースです。手続き型も同じで、不適切/過剰な関数型よりも、適切に処理が区切られたfor文とかの方がよっぽど読みやすいケースもあります。

何が言いたいかと言うと、あんまりそういうスタイルにこだわらなくていいんじゃない？ってことです（ <span class="underline">まとまらない</span> ）
