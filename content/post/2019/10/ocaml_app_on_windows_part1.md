+++
title = "Windows上でOCamlアプリケーションを動かす パッケージ編"
author = ["derui"]
date = 2019-10-21T22:31:00+09:00
lastmod = 2019-10-21T22:31:03+09:00
tags = ["OCaml"]
draft = false
+++

今回から何回かに分けて、今取り組んでいるOCamlのcross compileについて書いていきたいと思います。おおよそ三回位を予定しています。

第一回は、OCamlのcross compile事情について書きたいと思います。

<!--more-->


## Cross compileとは {#cross-compileとは}

Cross Compileの正式な定義はいまいち判然としませんが、ここでは _あるプラットフォーム上で、別のプラットフォームの実行ファイルなどをコンパイルする_ という定義にします。つまり、Linux上でWindowsのバイナリをコンパイルする、という感じです。


## OCamlのcross compile事情 {#ocamlのcross-compile事情}

2019/10の時点で、一定以上の普及率かつ、上記の定義におけるCross complieを最も簡単に行える言語は、間違いなく **Golang** であることは論を待たないと思います。これは、Golang自体がlibc aware（というか再実装していた気がする）、かつ、デフォルトで各architectureへのコンパイルが可能な環境が整っているためです。この点から、マルチプラットフォームなCLIとかを作る時にGolangがファーストチョイスになっているのでしょう。

同じような感じで、 **Rust** もCross compileは簡単な部類だと思われます。（ここでは、シングルバイナリかどうか？というのは主題ではないので無視しています）

これらの言語の共通点は、どちらもシステムプログラミングを主眼に置いた言語、ということも設定に影響していると思います。

翻ってOCamlですが、これらと比較すると中々厳しいです。何故厳しいのか？を考えてみると、以下のような点が挙げられそうです。

-   OCaml自体、複数のプラットフォーム向けのバイナリを出力するようにできていない
    -   OCamlはすでにだいぶ歴史のある処理系であり、2010年代に生まれた言語と背景が異なるので如何ともしがたい点もあります
-   OCamlのユーザー内でニーズがない
    -   最近になってニーズが出てきた・・・というよりも、Golangのこのfeatureないの？みたいな声が上がって来た感じです
-   ライブラリがWindows/Linux両対応していないケースが多い
    -   OCamlのユーザーベースはLinuxが多い（偏見）なので、Linuxのみ対応しているライブラリが多いです
    -   ただ、ネットワーク周りは、Mirageの成果もあって、Pure OCamlで大体なんとかなります
-   OPAMをwindowsで動かすのが超難易度
    -   ・・・というよりも、2.0.5現在対応していません
    -   このため、Windows上でネイティブコンパイルすること自体も難しいです（近い将来出来るようになりそうですが

こういう実態から、 **OCamlのみでCross compileは出来ない** というのが結論です。では諦めるしか無いのか？OCamlでマルチプラットフォームなアプリケーションを作るというのは夢物語なのか？


## ocaml-cross-windows {#ocaml-cross-windows}

しかしここで救いの手が。OCamlが好きな人々や、OCamlをマルチプラットフォーム（ここではWindows）で使いたい人々によって、[ocaml-cross-windows](https://github.com/ocaml-cross/opam-cross-windows) というリポジトリが運用されています。主にLinux上でMingwを利用して、Windows向けのバイナリをコンパイル出来るように工夫されています。

これが自動的にopam-repositoryからmirrorされて自動的にアップデートされていく・・・のであればいいんですが、そうは問屋がおろしません。

公式のopamから、ocaml-cross-windows向けにportingするのは、ドキュメントに従っていけば意外と簡単なんです。ただ、例えばppxを利用していたりすると、ocaml-cross-windows上のpackageとopam公式の両方を入れないと動かなかったり、その逆もあります。また、最近のstandardである[dune](https://github.com/ocam/dune)を利用していないpackageの場合、色々と対応しないといけなかったりと、中々自動では難しいです。

しかし、現時点では非常に有力な選択肢です。このシリーズでは、これを使っていくことにします。


## アプリケーション用のrepositoryという選択肢 {#アプリケーション用のrepositoryという選択肢}

ocaml-cross-windowsは、コミュニティによって運営されているため、足りないpackageがあれば、Pull Requestを出すのが正道です。・・・ただ、今やりたいのは、自分のアプリケーションをコンパイルしたいのです。そのためには、dirty hackも辞さない感じです。

となると、アプリケーション用のopam repository、という選択肢も上がります。単純にocaml-cross-windowsをcloneしてremoteと名前を変えれば、一応形になります。

> 当然、本来であればコミュニティに還元するのが自分のためにもなります。私も後で行うつもりですが・・・。

実際にocaml-cross-windowsから作って、自分が必要なpackageを追加しているのが、下のリポジトリです。

<https://github.com/derui/sxfiler-repo-windows>


## packageは用意できた {#packageは用意できた}

ので、次はOCamlとOPAMを使ってCross compileする環境について書きたいと思います。
