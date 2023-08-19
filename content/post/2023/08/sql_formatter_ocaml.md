+++
title = "OCamlでSQL formatter を作ってみた"
author = ["derui"]
date = 2023-08-19T13:51:00+09:00
tags = ["OCaml"]
draft = false
+++

台風だったり暑さだったり、気象の振れ幅が大きくなってきてるなー、と思ったりしてます。でも古気候学とか噛じってると、さらに昔はもっと激烈だったんだろうなぁ、と思ったり思わなかったり。

さて、題名の通りなんですが、やっとこさ形になったのでこの記事を書こうと思います。

<!--more-->


## モチベーション {#モチベーション}

<https://github.com/derui/ocaml-sql-format>

Initial commitが5/31なので、大体この記事を書いている段階だと三ヶ月弱経過した形になります。まずなんで作ろうと思ったのかというと、とてもシンプルです。

-   そういえばFormatterって作ったことなかった
-   最近OCaml書いてないから書きたかった
-   SQL formatterってあんまり見ない(ような気がしたけど探したら結構あった)のでやってみよう
-   ついでに仕事でも使うし

という感じで決定しました。大抵SQLのフォーマットって、ググって出てきたWeb toolに放り込んで…というのが多いですよね。最近のChatGPTだったりで、入力したものが学習されたり漏れうる、と考えると、あまりやりたくないところです。今の会社だとバリバリ個人情報を調べたりするんで、そのフォーマットごときでリスクを負いたくもないですし。モチベーションはそんな感じなので、どういう感じで作っていったかを思い出しながら書いていこうかと思います。


## lexer/parserライブラリ {#lexer-parserライブラリ}

今回は当然OCamlを使ったのですが、SQLをパースするというのが一番の力仕事になることはわかりきっていました。また、最近はUnicodeがデフォルトですし(マレに絵文字を検索せんとあかんこともある)、スタンダードなocamllexよりは、よりモダンなものを使ってみたいものです。

Sedlex - <https://github.com/ocaml-community/sedlex>

ということで、今回はSedlexを利用してみました。前々から使おうかなーと思ってたんですが、機会がなかったのでちょうどよかったです。Sedlexは、ppxを存分に利用したocamllexの代替として利用できるlexer generatorとなってます。特徴は↑を見てもらった方が早いので、こんな感じに使えるよ？というのを示そうかと

```ocaml
let letter = [%sedlex.regexp? 'a' .. 'z' | 'A' .. 'Z' | 0x0153 .. 0xfffd]

let rec token buf =
  match%sedlex buf with
  | letter -> Letter (Sedlexing.Utf8.lexeme buf)
  | eof -> Eof
```

ocamllexで地味にペインだったのが、tuaregとかだと完全にはサポートされきってないので、フォーマットだったりなんだったりが微妙になったり補完がききづらかったり、という問題がありました。
sedlexはppxベースなので、すべて完全なOCamlソースとして扱える、というのが利点ですね。拡張の中だと補完は効かないんですが、まぁエラーはわかりやすいです。

parser generatorとしては[menhir](http://gallium.inria.fr/~fpottier/menhir/)一択です。現状ocamlyaccを選択する理由はございませんので、もしocamlyaccしか使ったことがない方は使ってみることをオススメします。


## テストと自動生成の仕組み {#テストと自動生成の仕組み}

formatterという決定論的なツールを作るのと、フォーマット前後の結果が重要なツールなので、テストも最初から考えとくことにしました。とはいえ、相性が最もよいのはexpectation testであることは想像がついていたので、[ppx_expect](https://github.com/janestreet/ppx_expect)を利用してます。

が！それだけだととてもめんどくさいです。現状100ファイルくらいあるのですが、全部に同じようなことを書いていくのは正直やってられないです。また、SQLはキーワードの数が正気か？ってくらい多いので、それに対応するlexer generatorの設定も死ぬほど多いです。これらを全部手書きしていたら時間がいくらあっても足りないので、いくつか自動生成ツールを作成しました。

-   キーワードからsedlexのフォーマットに変換する
-   ast/printer/parserのデフォルトテンプレートを作成する
-   SQLからのテストの生成

これらがあることで、大体一個のsyntaxを作成するのに小さければ5分〜10分、大きいものでも30分程度で量産できるようになりました。テストも、SQLを変更して再生成→promoteという流れを作ることができました。予想通りexpectation testはバチっと嵌ったので、こういう系統ではオススメです。


## SQLのパースの苦しみ {#sqlのパースの苦しみ}

さて、一番苦しんだのはSQLをパースするためのgrammerを記述するところです。今回参考にしたのは三つあります。

-   <https://ronsavage.github.io/SQL/sql-2003-2.bnf.html#data%20type>
-   <http://teiid.github.io/teiid-documents/13.1.x/content/reference/r_bnf-for-sql-grammar.html#parseBasicDataType>
-   <https://www.sqlite.org/lang.html>

上から、 **ISOにおける定義** 、 **teiidというツールにおけるBNF** 、 **SQLiteにおけるsyntax diagram** となってます。最終的にはsqliteのを基本にしつつ、teiidを参考に、ISOのものを標準との比較資料として使いました。

パースは合計3回書き直しています。最初はISOのものを参考にしてたのですが、超絶な分量(約1000P)かつ、LRではそのまま記述できない再帰や、括弧が曖昧になってしまい解決できないケースが存在するっぽく、私の知識ではどうにかできませんでした…。
teiidのものはもうちょっとシンプルになっているのですが、同様に式における括弧が曖昧になってしまうようでした。括弧については、LRでは非常にやりづらいもので、if-then-elseと同様に解決しづらいものとして扱われています。

最終的にsqliteのものを利用したのは、必要十分な量、かつダイアグラム上曖昧になる部分が少ない、というところで参考にしてます。一部そのままだと書き下せない部分があったので、そこはteiidのものを利用してます。

```text
SQLiteはシンプルかつ十分な性能…的な立ち位置なので、merge文などは実装されていません。個人的にもmerge文を使うケースはそんな無かったので、一旦ここはスキップしてます。
```


### menhirのnew syntax {#menhirのnew-syntax}

若干話は逸れますが、menhirにはold syntaxとnew syntaxってものがあります。

old syntaxはこんな感じです。yacc系列を利用したことがある方には見覚えがある形です。

```ocaml
rule:
| token { Foo }
```

対してnew syntaxはこんな感じです。

```ocaml
let rule :=
  | token; {Foo}
```

なんかletとか付いてて、OCamlっぽい見た目になってますね。他にも色々ショートカットがあったり、  `option` を利用する場合に変換結果をOCaml codeで返せたりと、old syntaxよりもかなり使い易いです。が、最初に出たのが2019年くらいっぽいんですが、そこからずっとexperimentalのままみたいです。ご利用は計画的に。


## フォーマットのやりかた {#フォーマットのやりかた}

SQLのフォーマットは、基本的にはわかりやすく、AST単位でのprinterというmoduleを定義してます。が、ここがまた厄介で、普通にやると定義が無限に循環してしまい、実行することができない、というケースがありました。いくつか試行錯誤したところ、利用するときに関数をgenerateしつつ、それぞれの処理をmoduleで定義する、というのに落ち着きました。

```ocaml
(* Intfの中身 *)
module type PRINTER = sig
  type t

  val print : Format.formatter -> t -> option:Options.t -> unit
end

module type GEN = sig
  type t

  val generate : unit -> (module PRINTER with type t = t)
end

(* printerの定義 *)
open Types.Ast
open Types.Literal
open Intf

module type S = PRINTER with type t = ext column_name

(* PRINTERがprinterの定義、GENが他のprinterを利用するための定義  *)
module Make (V : GEN with type t = ext identifier) : S = struct
  type t = ext column_name

  let print f t ~option =
    match t with
    | Column_name (v, _) ->
      let module V = (val V.generate ()) in
      V.print ~option f v
end
```

実際にprinterを相互にwiringするのはこういう形になります。

```ocaml
let column_name () =
  Column_name.(
    (module Make (struct
      type t = A.ext L.identifier

      let generate = identifier
    end) : S))
```

generateにidentifierってのが渡ってますが、こいつは関数ですので、必要にならない限りはmoduleの生成がされません。他にもやり方は色々あるとは思いますが、first class moduleを利用するのがシンプルじゃないかなーと思ってます。


### columnのアラインなど {#columnのアラインなど}

この記事時点では、create tableなどにおけるカラムのアライン(一番長い名前に揃える)は実装していません。やった方が見栄えはいいよねぇ、とは思ったんですが、

-   AST毎に異なるprinterが存在し、かつ外側のASTが切り替わる場合、どのようにして最長というものを表現するかが決めきれなかった
    -   というか、全部のidentifierを見ないと最長が決められない
-   わりとこういったものは多いが、最終的にデフォルトが変わったりするケースも多い
    -   ocamlformatでも、昔はmatchの各caseがalignされたりしましたが、デフォルトが変わりました。理由としては意味の無い差分ができてしまうから…ということのようです

ということで実装していません。なんとなく処理の想像自体はついているんですが。ただ、SQLは圧倒的に書くより読む方が多く、かつわりと一発勝負なものが多かったり、差分としてあまり表現されない(BIで使うものとか)もあるので、いずれやろうかなぁ、とは思ってます。


## 設定ファイル {#設定ファイル}

設定ファイルはtomlを使ってます。理由はあんまないっちゃないんですが、yamlは色々課題がある、jsonは人間が読み書きするもんじゃない、今時iniファイルもなぁ、ということでtomlにしました。

super ini fileとしても使えますし、階層構造もわかりやすい(個人の感想です)ので、やっぱそういう意図を持って設計されただけあるなぁ、という感じです。OCamlでもきちんとライブラリが揃ってるので、利用は簡単です。


## パフォーマンス {#パフォーマンス}

他にあまり似たものが無いんですが、selectでのcolumn数 `10,000,000 = 一千万` でやってみましたところ(SQLとしては288MBくらい)、大体13秒くらいでした。ただしメモリを10GB前後食います。ここまで巨大なものをフォーマットする時点で大分狂っているようにも思いますけど。それ以外は一桁下がる毎に大体1桁下がり、2.5MBくらいのファイルになると300ms程度です。一般的なユースケースとしては問題の無い感じではないでしょうか。やっぱOCaml速いですね。

ファイルサイズが100KBくらいになると、cacheを加味して20msくらいで全部終わったりしてます。

```text
なお実行環境はRyzen 7900X + .M2 SSDです。
```

ということで、パフォーマンスという観点でも、基本的なユースケースでは問題ないんじゃないでしょうか


## 感想 {#感想}

プラガブルなformatterだったりを作っているところは大変だなぁというのがよくわかりました。eslintとかgofmt、clippyとか作成している人達は大変だと思います。

gofmtくらい強権的(悪い意味ではなく)だと、議論が発生する余地すらないのでどうでもよくなりますが、SQLは方言だったりもあり、それぞれの主張が全部違っていてとてもカオスです。実際スタイルガイド的なものもいくつか目を通しましたが、ほぼ同じものはなく、大体全部違っていました。特にselectするときのカンマの位置とか。

そういったものをカスタマイズできるように作ることもまぁ面白いところではありますが、フォーマッタが強権的になることで自転車置き場議論を強制的に終わらせる、ってのはやっぱ一定重要なんだなぁ、と感じました。

ちなみにこのツール、利用する場合は自分でビルドしないと無理です。また、シングルバイナリ的なものも作るのがめんどくさいです。OCamlがRust的に各プラットフォーム向けにビルドできると絶対広まると思うんですけどねぇ(広まらない)。
