+++
title = "ctypesをduneで使っていく方法"
author = ["derui"]
date = 2020-10-07T21:25:00+09:00
lastmod = 2020-10-07T21:25:30+09:00
tags = ["OCaml"]
draft = false
+++

気づけば10月、今年ももう3ヶ月を切っていることにびっくりです。

今回は、OMakeをビルドシステムとして使っていたツールをdune対応した時に困ったことがあったので、それについて書こうと思います。

<!--more-->


## 発端 {#発端}

<https://github.com/derui/okeyfum>

このリポジトリですが、6年くらい前にノリだけで作ったツールです。もともとは [OMake](http://omake.metaprl.org/index.html) というビルドシステムを使っていました。しかし、OMakeが事実上の開発休止になり、このリポジトリ以外ではocamlbuildを使っていたりしました。そして現代は、事実上dune一択状態になりました。

そこで、暇を見つけてdune対応しようとしたとき、ctypesを使っていたために、色々とビルドが通らないようになってしまいました。


## ctypesとは {#ctypesとは}

ちょっと脱線して、OCamlにおけるctypesというライブラリについて紹介しておきます。

<https://github.com/ocamllabs/ocaml-ctypes>

どういうライブラリかは、最初の一文を見れば大体わかります。

> ctypes is a library for binding to C libraries using pure OCaml. The primary aim is to make writing C extensions as straightforward as possible.
>
> The core of ctypes is a set of combinators for describing the structure of C types -- numeric types, arrays, pointers, structs, unions and functions. You can use these combinators to describe the types of the functions that you want to call, then bind directly to those functions -- all without writing or generating any C!

元々OCamlからCのライブラリを使ったりする場合は、FFIの仕組みをつかって自分でstub（OCamlではC bindingをこう呼びます）を書く必要がありました。これはかなり辛く、ミスるとGCにかからないメモリリークが発生したり、segfaultしたりが頻発します。

ctypesを使うことで、stubを作成せずに、OCamlのソース上でDSLを使ってC bindingを書くことができます。これは非常に楽で、かつ安全であるため、現在ではFFIを使う場合はほとんどの場合でこれが使われていると思います。


## 困ったこと {#困ったこと}

ctypesの機能の一つとして、Cで定義された定数をOCamlのソースとして出力できるCのプログラムを作成できます。Cの定数はほとんどの場合 `#define` で定義されているため、その環境でCのプログラムをビルドしないと、正しい値を取得することが出来ません。

上掲のリポジトリから抜粋しますが、以下のような感じでCのプログラムを吐き出せます。

```ocaml
let () =
  print_endline "#include <linux/input.h>";
  print_endline "#include <fcntl.h>";
  print_endline "#include <linux/uinput.h>";
  Cstubs.Types.write_c Format.std_formatter (module Okeyfum_c_type_description.Types)
```

`OKeyfum_c_type_description.Types` というのが、Cから取得してくる定数の名前と型をDSLで定義したモジュールです。

さて、このソースからOCamlで利用できる定数を出力するためには、以下の手順を踏む必要があります。

1.  上のOCamlから実行ファイルを作る
2.  1.で作成した実行ファイルを実行し、出力を一時ファイルに出力する
3.  2.で出力したCファイルをコンパイルする
4.  3.で作成したCプログラムを実行し、OCamlソースを出力する
5.  4.で出力したモジュールをメイン側で利用する

結構長いですが、依存関係を定義できるのであればめんどいだけです。しかし、duneでこれをやろうとすると中々分かりづらく、色々と調べたり他のライブラリを参考にしたりしました。


## 解決したduneファイル {#解決したduneファイル}

```tuareg
(library
 (name okeyfum_c_type_description)
 (modules Okeyfum_c_type_description)
 (public_name okeyfum.c_type_description)
 (libraries ctypes))

(executable
 (name generate_types)
 (modules Generate_types)
 (libraries ctypes ctypes.foreign ctypes.stubs okeyfum.c_type_description))


(rule
 (targets ffi_ml_types_stubgen.c)
 (action
  (with-stdout-to %{targets}
    (run ./generate_types.exe))))

(rule
 (targets ffi_ml_types_stubgen.exe)
 (deps ffi_ml_types_stubgen.c)
 (action (run %{cc} -o %{targets} %{deps} -I %{lib:ctypes:.} -I %{ocaml_where})))

(rule
 (targets okeyfum_c_generated_types.ml)
 (deps ffi_ml_types_stubgen.exe)
 (action (with-stdout-to %{targets}
           (run %{deps}))))

(library
 (name okeyfum_c)
 (public_name okeyfum.c)
 (modules Okeyfum_c_generated_types)
 (flags (:standard -w -27-9))
 (libraries ctypes ctypes.foreign okeyfum.c_type_description))
```

さて、肝になるのは、３つの `rule` stanzaです。これが、手順の1〜4を表現しています。取得したい定数などによっては、 `%{cc}` のところで色々と設定する必要があります。

最初と最後にlibraryを定義していますが。このライブラリはメイン側で使われます。c\_type\_descriptionが定義を、c\_generated\_typesが実体となり、これを組み合わせて利用します。わかってしまえばなるほどとなりますが、意外と時間がかかりました・・・。


## duneでちょっと凝ったことをやる {#duneでちょっと凝ったことをやる}

duneは、OCamlプログラムやライブラリを作成するのに特化しているため、ctypesのようにFFIを使ったりするときには、ちょっと変わった書き方をする必要があったりします。

最近では滅多に無いでしょうが、FFIを書かなければならない時に参考に出来たら幸いです。

> 関数を使うだけの場合は、こんなめんどくさいことはしなくても大丈夫です
