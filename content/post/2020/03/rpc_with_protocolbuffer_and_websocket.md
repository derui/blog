+++
title = "ProtocolBufferを使ってWebSocketでRPCをする"
date = 2020-03-15T13:59:00+09:00
lastmod = 2020-09-22T10:42:04+09:00
tags = ["JavaScript", "ProtocolBuffer"]
draft = false
+++

超暖冬だったりコロナウイルス騒ぎだったりと、なんと言うか全く落ち着かないこの頃、いかがお過ごしでしょうか。私は投資信託の金額が乱高下してなんとも言えない気持ちになっているのと、リーマンの再来とか言われてビクッとしている今日この頃です。

そういう世間の流れを一旦見ないことにして、最近やっと動作の確認が取れた、ProtocolBuffer + WebSocketによるRPCの方法を書こうかと思います。

<!--more-->


## さきにまとめ {#さきにまとめ}

ここを見たら後の文は見なくていいんじゃないか疑惑が。

-   gRPCを利用しない場合、ブラウザと双方向でやり取りできるのはWebSocketくらい
-   WebSocketではHTTP/2のようなpathは使えない
-   JSON-RPCのような形式を使うとよい
-   command的なもののEnumはデフォルト値をエラーとして使うといい

以降ではこれについての詳細を。


## gRPCの利点と課題 {#grpcの利点と課題}

ProtocolBufferを利用したRPCというと、[gRPC](https://grpc.io/)がまっさきに出てきますし、ProtocolBufferを使う方の半分くらい（要出典）はこれが目的でしょう。ただし、それはgRPCを利用できる環境があるから、という前提が当然あります。

ではgRPCを利用できる条件とはどのようなものでしょうか。その大前提として、 **HTTP/2** の存在があります。元々HTTP/2のベースであるSPDY自体、Googleが開発していたためでしょう。HTTP/2とHTTP/1.1の違いは次のようなものがあります。

-   HTTP/2はバイナリベース
-   multiplexy
-   Serverからクライアントに対してpushすることが出来る
-   headerの圧縮が必須

gRPCは、これらのHTTP/2が持つ利点を活かして、高パフォーマンスかつ低遅延なRPCを実現しています。

間違いなく次世代のネットワークはHTTP/2ベースになると思いますが、OCamlではHTTP/2を利用する難易度がかなり高いです。また、ブラウザからJavaScriptを利用してHTTP/2接続を利用することも今は出来ません。

いま個人的に作っているツールでは、serverからのpushを必要としているので、HTTP/2が使えない場合、WebSocketを使うしかありません。しかし、WebSocketではgRPCを使うことは出来ません。
(gRPCは、HTTPのmethodやpathを利用して色々行っているため)


## WebSocketでRPCを実現しよう {#websocketでrpcを実現しよう}

改めて、WebSocketは以下のような特徴を持つprotocolです。

-   HTTPからのハンドシェイクをもって切り替える
-   一本のconnectionだけで通信を行う
-   双方向の通信が可能
-   完全に非同期
    -   あるメッセージを待つ、というようなことは出来ない

参考：[WebSocket Protocol仕様の日本語訳](https://triple-underscore.github.io/RFC6455-ja.html)

しかし、JavaScriptでWebSocketを扱うプログラムを書いたことのある方はわかると思いますが、WebSocketは **message** という塊のやり取りしか出来ません。HTTP/1.1のようなpath/methodというようなものを使うことは出来ません。
RPCを実装する上では、そのメッセージがどのcommandに対するresponseなのか？を判別する必要があります。

ではどうするか？となりますが、ここで参考になるのが [JSON-RPC](https://www.jsonrpc.org/specification) です。

JSON-RPC自体、非常にLightな仕様ですが、大事なのが **requestとresponseが完全に非同期である** ということを前提としていることです。この特徴から、WebSocket上でも特に問題なく動作します。ということは、 **JSON-RPCっぽいのをProtocolBufferで実装すればいいんではないか？** という考えが浮かびます。


## ProtocolBufferにJSON-RPCっぽいのを実装する {#protocolbufferにjson-rpcっぽいのを実装する}

では早速protoファイルを作ってみます。

```protobuf
syntax = "proto3";

enum Command {
  UNKNOWN_COMMAND= 0;
  FILER_INITIALIZE = 1;
  FILER_RELOAD_ALL= 2;
  FILER_MOVE_LOCATION= 3;
  FILER_UPDATED= 4;
  FILER_COPY_INTERACTION= 5;
  FILER_MOVE_INTERACTION= 6;
  FILER_DELETE_INTERACTION  = 7;
  KEYMAP_ADD_KEY_BINDING= 8;
  KEYMAP_REMOVE_KEY_BINDING= 9;
  KEYMAP_GET = 10;
  KEYMAP_UPDATED = 11;
}

// common request
message Request {
  string id = 1;
  Command command = 2;
  bytes payload = 3;
}

enum Status {
  UNKNOWN = 0;
  SUCCESS = 1;
  INVALID_REQUEST_PAYLOAD = 2;
  COMMAND_FAILED = 3;
}

message Error {
  int32 status = 1;
  string error_message = 2;
}

// common response. Field `id' must same value of the request.
message Response {
  string id = 1;
  Status status = 2;
  bytes payload = 3;
  Error error = 4;
}

message SomeProcedureRequest {
  string fooBar = 0;
}

message SomeProcedureResponse {
  int32 count = 0;
}

service SampleService {
  rpc someProcedure(Request) returns (Response);
}
```

ポイントはいくつかありますが、特に大事だと感じたのは次の点です。

-   Command(呼び出すprocedureを決定する)の0番目は、エラー扱いにする
-   payloadをbytesにしておく

１つ目の点は、ProtocolBufferの仕様に関わる問題と、WebSocketの特徴にかかる問題を回避するためのものです。ProtocolBufferは、後方互換性のため、設定されていないフィールドには初期値が設定されます。そして、WebSocketのmessageは、text/binary以外の区別はありません。つまり、deserializeしたRequest/Responseが正しいのか？を判定出来ないといけません。
Commandの0番目を不正なCommandと明示的にしておくことで、RequestとResponseを区別することが出来ます。

２つ目の点は、payloadをbytesとすることで、他のmessageをProtocolBufferとして入れることが出来ます。JSON-RPCのparamsに相当します。ただし、正しいRequest/Responseをpayloadに設定するのは、Procedureとそのクライアントそれぞれで実装する必要があります。

Commandを `enum` としているのは、OCamlで代数的データ型として扱いたいのでこうしています。JSON-RPCに倣って `string` としてもいいとは思います。

後は、Request/ResponseのIDを保存し、RequestのIDに対応したResponseにだけ対応する、という実装をすることで、RPCみたいな実装が出来ます。


## この方式の欠点 {#この方式の欠点}

実際にWebSocket上でこの形式のProtocolBufferで通信を行い、それなりの性能も出ています（JSONでやり取りしていた時とあんまり変わらない）が、いくつかの問題が考えられます。

-   deserializeを2回行わないといけない
    -   まず全体をdeserializeした後、payloadをdeserializeする
    -   serializeのときはこの逆
-   型で守りにくい
    -   payloadがどうしても単なるbytesとかTypedArrayとしかならない

型で守りにくい、という点については、ある程度仕組み化してしまうことで軽減は可能です。deserialize/serializeが必ず2回必要、というのを避ける手段は多分ありません。性能という話だと、この辺りがネックになってくると思われます。


## gRPCじゃなくてもProtocolBufferは使える {#grpcじゃなくてもprotocolbufferは使える}

世間的には、 `ProtocolBuffer == gRPC` という感じになっていると思いますが、protoファイルによる自動生成を活用したい、という動機もあるはずです。その場合、ProtocolBufferやその周辺を整えてやることで、色々とうまく使えるんではないでしょうか。

実際、JavaScriptは別格で、OCamlとかJavaだとJSON < ProtocolBufferとなるケースも多いらしいので、フロントが多少遅くなってもトータルで速くなる、という話もあります。

猫も杓子もJSON、というのもいいんですが、たまにはこういうのもいかがでしょうか？（何
