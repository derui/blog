+++
title = "Windows上でOCamlアプリケーションを動かす デバッグ編"
author = ["derui"]
date = 2019-11-11T21:36:00+09:00
lastmod = 2019-11-11T21:36:27+09:00
tags = ["OCaml", "Windows"]
draft = false
+++

ようやく涼しくなってきたと思った瞬間に晩秋になってしまい、秋がなかったなぁ、としみじみと感じてしまいました。

第三回は、Cross Compileできたものの、上手く動かない、というときに役立つデバッグについて書きます。

<!--more-->


## Cross Compileしたバイナリの難しさ {#cross-compileしたバイナリの難しさ}

Linux上でクロスコンパイルしたバイナリですが、実際にこのバイナリを動かしてみると、問題が発生（Segfaultとか）することがあります。

特に最初はWineで動かすと思いますが、エラーの内容がメモリアドレスくらいしか無く、結構色々と辛いです。Windows上で実行してみるのも中々にしんどいです。普通にそのまま実行時エラーで落ちるので。

Visual Studioとかで動かしてみる、というのも手段だと思いますが、ここではあくまでLinux上で解決してみます。


## gdbserverとgdb {#gdbserverとgdb}

gdbには、remoteのgdbと繋げてローカルで実行できる `gdbserver` というツールが存在しています。

Debianであれば、まず以下でmingw向けのgdbserverと、mingwでコンパイルされたtargetをデバッグできるgdbをインストールします。

```sh
apt install mingw32-w64-gdbserver mingw32-w64-gdb-target
```

これを使うと、以下のようにしてdebugを行えます。

```sh
wine /usr/share/win64/gdbserver :3000 sample.exe
x86_64-w64-mingw32-gdb sample.exe

# ここからGDB内
> remote target localhost:3000
# つながると普通の（若干コマンドが成約されていますが）gdbとして使えます。
> continue

Program received signal SIGSEGV, Segmentation fault.
0x0000000000a19d1c in lwt_unix_not_available (feature=<optimized out>) at lwt_unix_stubs.c:107
107     lwt_unix_stubs.c: No such file or directory.
(gdb) bt
#0  0x0000000000a19d1c in lwt_unix_not_available (feature=<optimized out>) at lwt_unix_stubs.c:107
#1  0x0000000000a1b400 in lwt_unix_iov_max (a1=<optimized out>) at windows_not_available.c:16
#2  0x00000000008611ed in camlLwt_unix__entry ()
#3  0x0000000000000001 in ?? ()
```

上記のように、Windows向けにビルドしたバイナリを、Linux上でデバッグできます。OCamlでビルドしたものであれば、上記のようにcaml系統のデバッグシンボルも見えるので、デバッグがはかどります。

今回は短かったですが、この情報が中々見つからず、苦労してしまったので、どこかの誰かのお役に立てばと思います。
