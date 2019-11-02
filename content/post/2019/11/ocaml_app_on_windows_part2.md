+++
title = "Windows上でOCamlアプリケーションを動かす ビルド環境編"
author = ["derui"]
date = 2019-11-02T10:10:00+09:00
lastmod = 2019-11-02T10:10:52+09:00
tags = ["OCaml", "Windows"]
draft = false
+++

歓迎会と送別会が連チャンになったらだいぶグロッキーになってしまい、睡眠を削って生活するのはもう無理だなぁと思いました。十分な睡眠によるパフォーマンス向上をなめてはいけない・・・。

さて、第二回は実際にCross Compileを行うための環境について書きたいと思います。

<!--more-->


## ビルド環境の選定 {#ビルド環境の選定}

まずOCamlプログラムのクロスコンパイル・・・というかWindows向けのビルド環境をどうするか？です。Windows向けにビルドする場合、次のいずれかが主要な選択肢になります。

1.  Linux上でMinGWをインストールし、Windows向けのバイナリをクロスコンパイルする
2.  Windows上でOCaml/OPAMをインストールし、Windows向けのバイナリをネイティブコンパイルする

Windows上でコンパイルする場合、OCaml/OPAMそれぞれをビルドするか、もしくは配布されているバイナリを展開する方法があります。この内、自前でビルドする方法は後述するとおり結構厳しいです。一応チャレンジしてみましたが、敢え無く爆砕しました・・・。

と、いうことで、Linuxでのクロスコンパイルに一縷の望みを託してみます。


### Windows上のOCamlについて {#windows上のocamlについて}

OCaml本体は、実はWindows環境上でもちゃんとコンパイル・実行できるようになっています。（MSVC/Cygwinのいずれかが必要です）また、OPAMもWindows上でビルドできるようになっています・・・が。

OPAMをMinGWでビルドしてしまうと、 `opam init` が上手く動作しない、という問題が発生します・・・。これはOPAMでも認識されている問題です。このため、OPAMをWindows上で動かす場合、OCaml本体もCygwin向けにコンパイルする必要があります。

しかし、Cygwinでコンパイルしてしまうと、Cygwin1.dllというdllを同梱しないと動作しなくなります。Cygwin1.dllはライセンス的にも結構厳しいため、できれば付けたくありません・・・。


## Linux上でのクロスコンパイル環境 {#linux上でのクロスコンパイル環境}

OCamlプログラムを、Linux上でWindows向けにコンパイルする方法は、 **MinGWでコンパイルされたOCamlコンパイラでコンパイル・リンクする** という形になります。本来、Linux上でMinGWを利用してコンパイルされたバイナリは、Windows環境またはWineでしか動きません。

ここで前に紹介した[ocaml-cross-windows](https://github.com/ocaml-cross/opam-cross-windows)が効いてきます。このリポジトリでは、Windowsバイナリを生成でき、Linux上で実行可能なOCamlコンパイラを提供してくれています。ただ、ocaml-cross-windowsでは、Debianとかを推奨？している雰囲気があります。しかし私の利用しているDistributionはGentoo・・・。

と、いうことで、こういうときはDockerに頼ります。Debianのベースイメージから、クロスコンパイル環境を整えます。


## クロスコンパイル用のイメージを作成する {#クロスコンパイル用のイメージを作成する}

```text
FROM debian:bullseye

RUN apt update \
    && apt install -y --no-install-recommends opam gcc-mingw-w64-x86-64 gawk m4 git ca-certificates \
    && rm -rf /var/cache/apt/archives \
    && opam init -n --disable-sandboxing \
    && opam switch install 4.08.0 \
    && opam repository --all add windows git://github.com/derui/sxfiler-repo-windows \
    && eval $(opam env) \
    && opam install -y conf-flambda-windows \
    && opam install -y ocaml-windows64 \
    && opam install -y ocaml-windows

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

`entrypoint.sh` の内容は、opamを利用できるようにしているだけです。ここでのポイントは、aptでopamを入れることで色々楽していることと、64bit向けのMinGW環境を導入していることです。gawkを入れているのは、地味にこれがないとOCaml自体のコンパイルに失敗するためです。

↑のようなDockerfileからimageをビルドし、 `dune build -x windows` のようにすると、Windows向けのバイナリがビルドできます！・・・上手く行けば。

> 記事の時点においては、OCamlプログラムのビルドには、duneを使っておくのが無難です。ocaml-cross-windowsの仕組みに対応しているので、面倒なことせずに動きます。


### 番外：Linux向けのコンパイル環境 {#番外-linux向けのコンパイル環境}

上ではクロスコンパイル用のimage生成でしたが、Linux用のバイナリ生成でも色々と気にする必要があります。割と有名？な問題として、Linux向けのバイナリは大抵動的リンクを利用しているため、libcとかのバージョンが異なると稀に動かないとか、実は動的リンクしているものがあって動かない、みたいなことがあります。

そのため、[musl](https://www.musl-libc.org/)を利用するのが一般的です。この場合、muslがデフォルトのlibcとして使われている[Alpine Linux](https://alpinelinux.org/index.html)のコンテナを使うのがベターです。ただし、muslを使ったとしても、duneはデフォルトで共有ライブラリを動的リンクするようなビルドを行うので、明示的に設定を行う必要があります。

```tuareg-dune
(env
 (prod
  (flags (:standard -ccopt -static))))
```

注意として、今回のようなWindows/Linux環境向けのバイナリを一つのOCamlソースからビルドする場合、ビルドするソースと同じディレクトリにあるduneに直接静的リンクのオプション（上に書いてある `flags` ）を書いてはいけません。

なぜなら、Windows向けにビルドするときは、そのオプションを使うことが出来ないため、固定してしまうとクロスコンパイル時にエラーになります。そのため、上のようなduneファイルをopamファイルがあるディレクトリに配置することで、

```text
dune build --profile prod
```

のように書いた場合のみ、静的リンクを行うことが出来るようになります。これは地味にハマったポイントなので、duneのドキュメントはよく読むことをオススメします。


## クロスコンパイルは始まりに過ぎない {#クロスコンパイルは始まりに過ぎない}

前段までで、 **一応** Windowsで実行可能なバイナリを生成することが出来ました。ただ、OCamlプログラムのWindows用バイナリ生成は始まりに過ぎません。ここからが厳しいです。何が厳しいのかというと・・・。

-   そもそもWindowsを想定していないpackageがありえる
-   クロスコンパイルをするcompilerが想定されていない
    -   これはpackageというかOCaml自体の仕組み的にそうなっている

などがあり、色々とpackageを利用していると、だいたいどこかでsegmentation fault祭りが始まります。運が悪いと起動した時点でsegmentation faultになってしまったり・・・。

次回はそういう場合に必要だった、クロスコンパイル環境でのデバッグ方法について書きたいと思います。
