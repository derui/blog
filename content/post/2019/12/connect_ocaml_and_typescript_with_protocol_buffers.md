+++
title = "OCamlとTypeScriptをProtocal Buffersでつないでみる"
author = ["derui"]
lastmod = 2019-12-21T15:05:54+09:00
tags = ["OCaml", "TypeScript", "ProtocolBuffers"]
draft = true
+++

気づいたら来週で今年の業務も終わりということに気づきました。今年もいろいろ・・・あったか？

今回は、最近色々と辛くなってきたので、初めてProtocol Buffers・・・というかProtocol Buffers languageを利用して、サーバー側＝OCamlとクライアント側＝TypeScriptで型定義を共有していきたいと思います。

<!--more-->


## Protocol Buffersとは {#protocol-buffersとは}

もう[公式](https://developers.google.com/protocol-buffers/docs/overview)を見ていただくのが早いと思いますが、一応自分の言葉で説明します。既に知ってるわ！という方はすっ飛ばしてください。

Protocol Buffersとは、ザックリ言うとデータ構造を効率的にシリアライズするための仕様です。gRPCで利用されるデフォルトのシリアライズフォーマットであること、Googleが長年利用していることで有名です。単にProtocol Buffersとだけ言うとあくまでシリアライズの仕様だけですが、Protocol Buffers languageという、各種言語向けのプロトコルを生成するための言語がセットになっています。

今回の目的はこのProtocol Buffers languageです。OCamlにはgRPCの実装は存在しませんし、今回はgRPC自体不要です。


## なぜProtocol Buffers languageを使うのか？ {#なぜprotocol-buffers-languageを使うのか}

Protocol Buffers languageは、プログラミング言語に依存しないデータ構造の定義用言語です。こういったものはあるようで意外とありません。個人的に使った（と言えるかどうかは・・・）ことがあるのはCORBAくらいです。

より一般的にはIDLと呼ばれる言語ですが、最近はAPIの隆盛から、OpenAPIがこの役割を果たしていることが多い印象です。REST APIを作成する場合は、OpenAPIを使うのがベターな選択でしょう。

ただ、今回は **データ構造だけ** 欲しいのです。そもそも通信方法がWebsocket + JSON-RPC、という形になっているので、OpenAPIが使えないということもあります。また、Protocol Buffers language自体はgRPCに対する注目の高まりもあり、色々な言語に対してコンパイラが提供されているというのも、今回選択した理由になります。


## protoファイルからコンパイルする方法 {#protoファイルからコンパイルする方法}

さて、基本的にprotoファイル（protocol buffers languageのファイル拡張子から、protoファイルと呼ばれます）から定義やスタブを生成する際、protocというコンパイラが必要になります。公式のリポジトリでは、メジャーな言語については追加で何か追加すること無く、実装を生成できるようになっています。

<https://github.com/protocolbuffers/protobuf>

・・・しかし、OCamlはマイナー言語ですので、基本Googleが関わるprojectには含まれていません。Protocol Buffersのコンパイラは、拡張を書くことで、生成先の言語を追加できるようになっています。TypeScriptもこのpluginがあります。

<https://qiita.com/yugui/items/87d00d77dee159e74886>

OCamlでは、 <https://github.com/issuu/ocaml-protoc-plugin> というリポジトリで公開されている拡張を利用することで、protoファイルからOCaml用の定義を生成することが出来ます。
TypeScriptでは、<https://github.com/improbable-eng/ts-protoc-gen> を使うのが良いかと思います。これもpluginです。

protocは、これらのpluginを、CLIに渡されたパラメータから判断して呼び出しを行います。TypeScriptの場合は `--ts_out` というパラメータを使った時、 `protoc-gen-ts` というpluginを呼び出す、という実装になっているようです。
OCamlでも同じようにして生成できます。


## 実際に使ってみた {#実際に使ってみた}

<https://github.com/derui/sxfiler>

自分で実験用に作っているツール上で使ってみました。
