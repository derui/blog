+++
title = "Protocol BuffersとJSONの扱い in OCaml"
author = ["derui"]
date = 2020-01-13T12:27:00+09:00
lastmod = 2020-09-22T12:56:39+09:00
tags = ["日本語入力"]
draft = false
+++

以前の記事で、ProtocolBuffersでOCaml/TypeScript間の定義を作成して色々やっていたのですが、いくつか問題が出てきたので書いてみます。

<!--more-->


## ocaml-protoc-pluginに乗り換えた {#ocaml-protoc-pluginに乗り換えた}

前回は ocaml-protocを使いましたが、[ocaml-protoc-plugin](https://github.com/issuu/ocaml-protoc-plugin)に乗り換えました。理由としては以下となります。

-   標準のprotocにおけるpluginという形での提供
    -   自前で解析していてもいいとは思いますが、他のproductではprotocのplugin形式が多かったので
-   型定義にannotationを付けられる
    -   yojsonとかに変換するのが簡単です


## ts-protoc-gen + protoc標準から、pbjs（protobufjs）に乗り換えた {#ts-protoc-gen-plus-protoc標準から-pbjs-protobufjs-に乗り換えた}

前はprotocに標準添付されているJavaScript実装と、[ts-protoc-gen](https://github.com/improbable-eng/ts-protoc-gen)を組み合わせていたのですが、以下のような問題があったので乗り換えました。

-   Jsonからの変換とかが出来ない
    -   protocの標準では、 **protocolbuffers以外に対するserialize/deserializeがありません**
    -   JSON-RPCを利用しているので、軽く絶望しながら切り替えました（先に調べろと


## 発生した問題 {#発生した問題}

今作っているapplicationでは、Electronとbackend server間をWebsocketでつなぎ、RPCとしてJSON-RPCを利用しています。この構成、面倒ではありますが、割と使い勝手がよいのです。しかし、protoファイルから生成した型を使っていると、困る割にいい解決策が無い問題にあたりました。

その問題とは、 **OCamlでの型定義とProtocolBufferでの型定義との互換性** です。ナンノコッチャですが、要はocaml-protoc-pluginが生成してくれる型と、protocol\_conv\_jsonのでのJSON変換が一筋縄では行かない、ということです。

私は大きく２つの問題にあたりましたが、そのうちの一つを例に上げます。

```protobuf
enum Types {
  Unknown = 0;
  String = 1;
  Number = 2;
}
message Foo {
  Types value = 0
}
```

こんな感じのprotoファイルからOCamlの定義を作成すると、以下のような感じになります（moduleの定義は省略しています）。

```ocaml
open Ocaml_protoc_plugin.Runtime [@@warning "-33"]
module rec Types : sig
  type t = Unknown | String | Number
  val to_int: t -> int
  val from_int: int -> (t, [> Runtime'.Result.error]) result
end
and Foo : sig
  val name': unit -> string
  type t = Types.t
  val to_proto: t -> Runtime'.Writer.t
  val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
end
```

ここでポイントとなるのが、protoファイルにおいてenumと定義した部分と、OCaml版におけるTypes moduleです。OCamlにおいては、Enumを代数的データ型として表すのはごく自然だと思うのですが、問題はProtocol Buffersにおいては、enumは **単なる数値** でしかありません。 `to_int` とかがそれを物語っています。

これに、protocol\_conv\_jsonのannotationをつけてみると、以下のようになります。

```ocaml
open Ocaml_protoc_plugin.Runtime [@@warning "-33"]
module rec Types : sig
  type t = Unknown | String | Number [@@deriving protocol ~driver:(module Protocol_conv_json.Json)]
  val to_int: t -> int
  val from_int: int -> (t, [> Runtime'.Result.error]) result
end and Foo : sig
  val name': unit -> string
  type t = { value: Types.t } [@@deriving protocol ~driver:(module Protocol_conv_json.Json)]
  val to_proto: t -> Runtime'.Writer.t
  val from_proto: Runtime'.Reader.t -> (t, [> Runtime'.Result.error]) result
end
```

annotationが付きました。さて、ここでprotocol\_conv\_jsonが代数的データ型をどう変換するかと言うと、シンプルに **型名** を使います。上の例だと、 `"Unknown"` とかになります。普通に変換すると、enumの名前ではなく値を利用する必要があるため、割と分かりづらいエラーになります。

なお、今回はデータ型の構造も超シンプルだったので、手で変換する部分を書きました。書いた後に、pbjsで生成された実装に、enumの名前を利用して変換できるようにする仕組みを見つけました・・・。ドキュメントはちゃんと読みましょう。


## 異なるシステム間の構造共有は難しい {#異なるシステム間の構造共有は難しい}

OpenAPIとかでもそうですが、こういった構造の共有、加えて当初は想定されていない組み合わせを使うと、色々と問題が起こりがちです。今回は、大人しくProtocol Buffersだけを使って実行するような仕組みにしていたら良かった気もしていますが・・・。

protocolbuffersとOCamlでは、 `oneof` の扱いがどうしてもprotocol\_conv\_jsonでは対応できない、という問題もありました。この辺り、Protoファイルを型定義の共有としてだけ使い、ProtocolBuffers以外の仕組みで使う際に意外とハマるポイントなのでは？と思いました。
proto3では、JSONとの相互変換が仕様としてありますが、protocol buffers自体の要請ではありません。そのため、各言語からみたら、この変換そのものは必須ではありません。

システム間におけるデータ構造をどうするか？というのについては、これからも色々試していきたいと思います。
