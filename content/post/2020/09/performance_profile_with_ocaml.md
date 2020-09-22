+++
title = "OCaml製プログラムでperformance profileをする"
author = ["derui"]
date = 2020-09-22T09:14:00+09:00
lastmod = 2020-09-22T09:14:47+09:00
tags = ["OCaml"]
draft = false
+++

OCamlで作ったソフトウェアをチューニングしようとprofilingしようとしたら、4.09.0で gprof 対応が削除されていました。

<https://github.com/ocaml/ocaml/pull/2314>

これはこれで困ったので、Linuxでのprofiling方法を調べたのでメモります。

<!--more-->


## 何を使うのか？ {#何を使うのか}

Linuxでperformance profiling、特にCPU cycleを見る場合、perfというプログラムを使うのが一般的なようです。

kernelの内部構造まで踏み込んだ英語記事
<http://www.brendangregg.com/perf.html>

使い方がまとまった日本語記事
<https://qiita.com/k0kubun/items/b094c4b9bd4fe0027a48>


## 使い方とduneでのフラグ付け {#使い方とduneでのフラグ付け}

使い方自体は、OCaml本体でも紹介されていますだ、以下のように実行してevent traceを取得し、reportを見る、という感じです。

```shell
# record
$ perf record --call-graph=dwarf -- program arguments
# report
$ perf report
# 上だとめっちゃ長くなってしまうので、簡略化する
$ perf report -n -g folded
```

また、 [FrameGraph](https://github.com/brendangregg/FlameGraph) というスクリプトを使うと、Chromeのdevtools的なgraphを生成することもできます。

ただ、perfを使う上での前提として、対象プログラムでデバッグシンボルを有効にする必要があります。OCamlの場合、 `ocamlc` や `ocamlopt` に `-g` オプションを付けてビルドする必要があります。

・・・が、duneは色々やってくれてるので、最近のduneを使っている場合は、 `--profile=dev` を指定してビルドするだけです（デフォルトのprofileがdevなので、指定しなくてもいいです）。実際に `-g` オプションがついているかどうかは、duneに `--display=short` を付けて実行するとよくわかります。


## 他のprofiling手法 {#他のprofiling手法}

OCamlでは、どっちかというとmemory profilingの手法が多く見つかるので、CPU cycleのプロファイルを取る方法をメモりました。ただ、この記事を書こうとしたらもっと網羅的な記事が見つかったので、こっちでいいやん・・・ってなりました。

<https://github.com/ocaml-bench/notes/blob/master/profiling%5Fnotes.md>

ただ、内容がちょっと古い（gprofのやり方とかを書いてるので）ため、4.09.0以降のOCamlでprofilingを取得しようと思った時の参考になれば。
