+++
title = "OCamlでClean Architectureもどき"
author = ["derui"]
date = 2018-11-04T17:06:00+09:00
publishDate = 2018-11-04T00:00:00+09:00
lastmod = 2020-09-22T11:22:05+09:00
tags = ["OCaml"]
draft = false
+++

このところOCamlでアプリケーションをほそぼそと作っているのですが、その過程でClean Architectureっぽいものを採用してみました。

<!--more-->

作っているアプリケーション自体は、完全に趣味の領域のものなのでまだ公開していません。ただ、OCamlであってもなんであっても、ある程度の規模になったらなんらかの方法論は必要かな、と思い始めました。

-   packageそのものがいっぱいある
-   moduleもいっぱいある
-   どことどこが関連してるかよくわからなくなってくる
    -   これはもしかしたらmodule/packageの分割方法自体が問題か・・・？

ある程度Clean Architectureっぽいことも出来るようになってきたので、自分の知識を整理する上でも書いてみます。


## Clean Architectureとは？ {#clean-architectureとは}

ググってもらうのが一番早いのですが、それは流石に不親切すぎるので・・・。

Clean Architectureは、 <http://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html> が原典とされ、 Robert C. Martin によって提唱されたアーキテクチャです。
Onion Architecture/Hexagonal Architectureなど、過去のアーキテクチャも参考にしながら作成されたものになり、それらの特徴も一部受け継いでいます。

Clean Architectureは、以下のような制約を導入します。

-   ある層は、それより外側の層に依存してはならない
-   ある層は、それより内側の層にのみ依存する

これがClean Architectureにおける唯一の制約です。層としては、基本形として以下を提唱しています。

-   Entities
    -   いわゆるドメインモデルです
-   Use Cases
    -   アプリケーションロジックです。Domain Logicよりは特殊化されていますが、サブシステムとかがないアプリケーションだと、大体がここにロジックがある感じになるそうです
-   Interface Adapter/Gateway/Presenter
    -   UIやData Storeなど、外部との連携を行うための層です。
    -   APIをGatewayとして実装する、UIの情報をPresenterから返す、とかいろいろあります
-   Frameworks and Drivers
    -   Framework specificな処理とかです
    -   APIをFrameworkの機能を利用して作成する、とかであればここになります

ただ、これ以外にも ****層を**** 追加することは可能です。唯一の制約である、層の間にある依存方向を守る限り、層の増減は自由です。


## OCamlでの課題（自分的に） {#ocamlでの課題-自分的に}

OCamlである程度の規模のアプリケーションを作成する場合、恐らくある程度の単位でパッケージを作成する場合が多いと思います。最近は [dune](https://jbuilder.readthedocs.io/en/latest/) を利用すると思いますが、使わない場合であったり、一パッケージに全ファイルを置くのは色々問題があります。

-   module名がめっちゃ長くなる
    -   1ファイル1moduleとかやると、ファイル名もめちゃくちゃ長いですが、そのmoduleを利用するときにすごく面倒になります
-   一般的なモジュール名がかぶる
    -   特に被るのが `Types` とかの名前です
-   1ファイルに複数のmoduleを書くと見通しが悪い
    -   1データ型1module主義とかやると、単純にファイルの中身がかなり長くなります
    -   OCamlerはあまりその辺は恐れないようですが。
    -   この辺はfoldとかをうまく使えばいいのかもしれません

特に、頻繁に使うmodule名が長いと色々だれますし、毎回aliasを書くのもしんどいです。以前よりもmoduleを明示しなければならないケースは少なくなりましたが、一級moduleを利用しているとやっぱりきついです。

パッケージを分ける上での基準も厄介です。大抵は機能とか役割別だと思いますが、結構分けづらい感じになっていったりで・・・。

そこで、パッケージを分ける基準として **Clean Architecture** を使ってみました。


## OCaml on Clean Architecture {#ocaml-on-clean-architecture}

とはいっても、基本的には各層ごとになるようにパッケージを分割するだけです。そうすると、dependenciesの方向制御も簡単になります。私は、 `domain`, `usecase`, `gateway`, `binary` と分けています。こうすると、OCamlの制約とduneの機能で、以下のような利点を自動的に得られます。

> これは現状のサーバー側のアーキテクチャです。クライアント側は同じような別のアーキテクチャを採用しています。

-   domainは基本的に依存はほとんどない
    -   あるとしてもcore的なlibraryや、ppx系統のサポートライブラリくらいです
-   各層では、それより下の層に依存する、というのを強制できる
    -   gatewayはusecase/domainに依存する、というふうに書ける
    -   循環依存を書くとそもそもコンパイルできないので、そういう形でも強制できる
-   依存するパッケージが、一つ下の層だけ書けばいいようになって見通しがいい

現状、presenter/adapter/gatewayはサブパッケージとして作成したものを統合している形です。さて、こういうふうに書くのはいいんですが、Clean Architectureは非常に抽象層が多く、Javaとかで実装する場合でもかなり紛糾する部分です。それをOCamlでどう実装していきましょう？


## 抽象化のやり方（記述時点版） {#抽象化のやり方-記述時点版}

この記事を書いているタイミングでの抽象化のやり方を簡単に書きます。

```ocaml
(* Use Caseを例に取ります *)

(* 基底になるUsecaseのsignatureです。Lwtは全体を通して利用しているので、利用している事自体はあまり気にしないでください *)
module type Usecase = sig
  type input

  type output

  type error

  val execute : input -> (output, error) result Lwt.t
end

(* なにかするUse Case。実際には動詞を使うと思います *)
module Some_use_case = struct
  (* use caseのinput/output/errorの型をまとめて宣言します *)
  module Type = struct
    type input = unit

    type output = string

    type error = unit
  end

  (* このUse Caseのsignatureです。Use caseを利用し、Typeで指定した型を共有します *)
  module type S =
    Usecase
    with type input = Type.input
     and type output = Type.output
     and type error = Type.error

  (* Use Caseの実装です。Sをそのまま利用して、依存するmoduleをFunctorの引数として受け取ります *)
  module Make (C : Repository) : S = struct
    include Type

    let execute () =
      let%lwt condition = C.resolve () in
      let%lwt keymap = R.resolve () in
      let keymap = Key_map.subset keymap ~condition in
      Lwt.return_ok keymap
  end
end

(* 利用するときはこんな感じになる *)

let () =
  let module U = Some_use_case.Make (Repo_impl) in
  U.execute () |> ignore
```

こんな感じに書くと、ユニットテスト時には適当なdummy moduleを渡せばよく、実装自体は気にしない、という形に出来ます。 `Type` として独立したmoduleにしているのは、単にsignatureとFunctorで二回同じのを書きたくなかったからなので・・・。

また、各use case自体は同じインターフェースを強制して、型だけを切り替えればよい、という形にしています。結構なんとかなるし、型だけ見えればいいのであればTypeだけ利用する、ということも出来ます。
Domain層のrepositoryや、gatewayなどで依存を導入することも難しくはないです。

ただ、いろいろ欠点もあって・・・。


## 改善したい点 {#改善したい点}


### 冗長 {#冗長}

Clean Architecture自体がわりかしファイル数が増えたりしていろいろ冗長なんですが、各UseCase毎に上のような書き方は面倒くさいです。ただ、UseCase自体を差し替えることを可能とするためには、このようにしないとならないので・・・。


### Interactor/Input/Outputがうまく設計できていない {#interactor-input-outputがうまく設計できていない}

原典では、UseCaseの **Interactor** というものがあり、request/responseを切り離すことを可能としています。これはデータフローの向きを強制する効果も有ります。上記のような実装だと、request/response/errorを `Type` で宣言しているので、そういったことが出来ない状態です。

ただ、input/outputを分ける事自体が結構面倒、かつinputなどの型をレコード型にしてやったりすればいいだけなので、ここはあまり困っていない感じがあります。


### 依存性の注入がひたすら面倒 {#依存性の注入がひたすら面倒}

OCamlには私が知る限り、JavaとかであるようなDependency Injectionを行うようなライブラリは存在しません。なので、上のような形で作ると、基本的に依存するmoduleをその場で組み立てていく必要があります。

実際に書いてみないと中々実感できませんが、これは **非常に** 面倒です。ぶっちゃけやりたくない。また、内側の層の依存は外側の層から渡す必要があるため、Functorの引数がかなり多くなっていく傾向があります。

```ocaml
(* こんな感じ *)
let () =
  let module A = A_impl in
  let module B = B_impl.Make(A) in
  let module C = C_impl.Make(D_impl)(B) in
  ...
```

SpringとかのDIライブラリがあれば、この辺をうまくやってくれるケースが多いので、そこまで関係ないケースが多いですが・・・。やるとしたら、組みたてたmoduleを返すような関数群を定義したsignatureを作り、その実装で各々のmoduleを組み立てる、という感じでしょうか。ただ、実装でまだ分離がうまくやれていない部分があるのも事実なので、そこらへんがうまく行き始めると、もう少しマシになるかもしれません。


### classベースの方が楽かも？ {#classベースの方が楽かも}

Functorと一級moduleを組み合わせて色々やっていますが、objectベースでやったほうが楽なんでは？と思ってもいます。ただ、OCamlのobjectをゴリゴリに利用したようなアプリケーションは聞いたことがないので、なんとも言い難いですが・・・。


## OCamlでもClean Architecture/DDDは可能 {#ocamlでもclean-architecture-dddは可能}

関数型言語であろうと何であろうと、Clean Architecture/DDDはあくまで考え方や構成法なので、適用できないということはありません。ただ、大抵はAndroid/Swift/Java/C#といったクラスベースの言語で書かれたものが大半であるため、OCamlに適用していくのは結構骨が折れます。

しかし、優れた方法論は、範囲が一緒なのであれば、実装が変わろうとも関係ないはずです。実際、Clean Architectureにしたことで、OCamlでもユニットテストがかなり書きやすくなりました。物凄い型の構成を考えたりして、型を駆使すると、色々とテストしなくていい場面というのが増えるかもしれませんが、結局テストしないとわからないものはあります。テスト容易な実装にしていきやすいClean Architectureは、OCamlでも有用だと思います。

もっとOCamlに習熟したら、こういう手段に訴えなくても、より楽・堅牢な実装をしていけるかもしれないので、より精進していきたいです。
