+++
title = "SKKの辞書サーバーとしてyaskkserv2を使うようにしてみた"
author = ["derui"]
date = 2021-02-23T10:05:00+09:00
lastmod = 2021-02-23T10:05:11+09:00
tags = ["雑記"]
draft = false
+++

久々に４連休となったので、たまには頻度高めにブログを書いてみることにします。

今回は、前回SKKにしたということを書きましたが、それの辞書サーバーについて書いてみようと思います。

<!--more-->


## SKKと辞書サーバー {#skkと辞書サーバー}

SKKを使ったことがない方は、辞書サーバーといってもなんじゃそりゃ？となるでしょう。辞書サーバーとはそのままの意味で、SKKの辞書を提供するためのサーバープログラムを指します。

SKKの実装では、大抵はSKK辞書をインプットメソッド内にメモリとして展開し、それを利用しています。当然ながら、この形式では複数のインプットメソッドがあったら、各々でメモリを消費してしまいますし、管理が煩雑になりがちです。

そのため、SKKのほとんどの実装では、SKKプロトコルというプロトコルにもとづいたサーバーも辞書の一つとして利用できるようになっています。サーバーとして一つにまとめることで、複数のインプットメソッドから同時に利用することもできる、ということです。

[ddskkでの辞書サーバーの設定](https://ddskk.readthedocs.io/ja/latest/04%5Fsettings.html#setting-jisyo-server)


## 辞書サーバー、使う？ {#辞書サーバー-使う}

さて、辞書サーバーを使うといいことあるじゃん・・・と思いたいところですが、実際は中々そうはいきません。なぜかというと、使ってみたり運用してみた限りでは、以下のような問題があります。

-   SKKプロトコルがEUC-JPを前提としていて、UTF-8全盛の今にそぐわないケースが多い
-   実際に複数のインプットメソッドから利用すると、以外と面倒くさいケースが多い
-   そもそもメモリが多くなったので、各々で利用しても問題にならないケースが多い

一個ずつ見ていきます。


### SKKプロトコルの問題 {#skkプロトコルの問題}

SKKが開発されたのは1987年、佐藤雅彦氏によって開発されたのが初版とされています。 [参考](https://github.com/skk-dev/ddskk/blob/master/READMEs/history.md)

当然ですが、1987年当時にはUnicode consortiumすらありません。([Wikipedia](https://ja.wikipedia.org/wiki/%E3%83%A6%E3%83%8B%E3%82%B3%E3%83%BC%E3%83%89%E3%82%B3%E3%83%B3%E3%82%BD%E3%83%BC%E3%82%B7%E3%82%A2%E3%83%A0))なので、日本語を扱える文字コードは、事実上 **EUC-JPとShift-JISの2強** でした。Linuxにおいては、EUC-JPがデファクトスタンダードの地位を確立していた(らしい)ので、日本語のかな漢字変換プログラムであるSKKがEUC-JPを前提としていても、何の不思議もありません。

さて、しかし時は経ち、現代ではUTF-8がデファクトスタンダードとなりました。そうなると困るのは、EUC-JPでしか扱えない、というプロトコルの問題です。これはSKKプロトコルの定義を修正しない限りはなんともならないです。事実、macOSで一番使われていると思われるAquaSKKでも、serverとのやりとりはEUC-JPに固定されています(辞書はUTF-8も扱えます)。

なので、辞書がUTF-8だったり、エンコーディングがUTF-8だったりすると、上手く変換できなかったりと、問題が発生しがちです。


### 複数のインプットメソッドからだとめんどくさい問題 {#複数のインプットメソッドからだとめんどくさい問題}

プロトコルの問題でも上げましたが、辞書と辞書サーバーの文字コード、インプットメソッド内での扱いなどが異なる場合がある、などの事情があります。なので、以外とサーバーをそのまま利用できるケース、というのは少なかったりします。

仕事用のmacOSで、AquaSKKとEmacsで共通の辞書サーバーを使おう、と思ったりしましたが、このへんが上手くいかずに挫折したりしています。


### そもそもメモリが多くなった {#そもそもメモリが多くなった}

1990年くらいのPCは、メモリがMB単位とかあるとそれだけですげー、ってなった時代でした。今は2桁GBがあたりまえです(個人の感想です)。個人所有しているPCも、32GBとか積んでいます。

片や、SKKの辞書は、他のIMEと比較してもかなり小さいほうだと思います。実際に計測してみたら、SKKが配布している辞書を全部統合した辞書(コンパイル後)で、22MBしかありませんでした。

`32 * 1024MB` のメモリ空間があるところに、高々数十MBの辞書をメモリに展開したところで、ほとんど影響がないのは明白でしょう・・・。


## それでも辞書サーバーを使ってみる {#それでも辞書サーバーを使ってみる}

色々問題があるにはある辞書サーバーですが、それでも使ったことがないから使ってみたい、というのは人の性でしょう。ですので使ってみます。

さて、SKKには歴史があるので、当然ながら辞書サーバーも色々な実装があります。ここで挙げるのは蛇足なので、 [Wikiへのリンク](http://openlab.jp/skk/wiki/wiki.cgi?page=%A5%EA%A5%F3%A5%AF%BD%B8#p14)を貼っておきますので、気になる方はこちらから。

Google IME≒mozcを利用して、候補を取得したりする・・・という変わり種もあったりしますが、そこまで変わり種を使いたいわけでもないので、シンプルな辞書サーバーを選択してみます。

実際、速度の面などを考えると、C/C++で作られたサーバーがいいかな・・・と最初は考えました。 [yaskkserv](http://umiushi.org/~wac/yaskkserv/)は、かなりこなれた実装でもあり、かつGentooでも使えるものです。

が、これもまた歴史のあるツールなので、色々内部構造的な問題がある、ということで、作者の方がRustでリライトした [yaskkserv2](https://github.com/wachikun/yaskkserv2)というのを開発されています。

ちょうどFirefoxとかをビルドしている関係上、Rustがマシンに入っているということもあり、これを使うことにしました。(見切り発車すぎる)


## yaskkserv2のビルドとか {#yaskkserv2のビルドとか}

これらは、Emacsの起動時に、対象のプログラムが存在していなければビルドしてインストールするようにしました。ただ、ビルド環境が無い場合は、バイナリを落として展開するようにしています。

```emacs-lisp
(leaf *skk-server
  :after f
  :if my:use-skkserver
  :init
  (let ((server-program (expand-file-name "yaskkserv2"  my:user-local-exec-path))
        (dictionary-program (expand-file-name "yaskkserv2_make_dictionary" my:user-local-exec-path)))
    (cond ((and my:build-skkserver
                (executable-find "cargo")
                (not (executable-find server-program))
                (not (executable-find dictionary-program)))
           (let ((base-path "/tmp/yaskkserv2"))
             (unless (f-exists? base-path)
               (call-process "git" nil nil t  "clone" "https://github.com/wachikun/yaskkserv2" "/tmp/yaskkserv2"))
             (call-process "cargo" nil nil t "build" "--release" "--manifest-path" (expand-file-name "Cargo.toml" base-path))
             (unless (f-exists? server-program)
               (f-copy (expand-file-name "target/release/yaskkserv2" base-path) server-program))
             (unless (f-exists? dictionary-program)
               (f-copy (expand-file-name "target/release/yaskkserv2_make_dictionary" base-path) dictionary-program))
             ))
          (t
           (let* ((target (cond ((eq window-system 'ns) "apple-darwin")
                                (t "uknown-linux-gnu")))
                  (path (format "https://github.com/wachikun/yaskkserv2/releases/download/%s/yaskkserv2-%s-x86_64-%s.tar.gz" my:yaskkserv2-version my:yaskkserv2-version target)))
             (call-process "curl" nil nil t "-L" path "-o" "/tmp/yaskkserv2.tar.gz")
             (call-process "tar" nil nil t "-zxvf" "/tmp/yaskkserv2.tar.gz" "-C" my:user-local-exec-path "--strip-components" "1"))))))
```


### 辞書のコンパイル時の注意 {#辞書のコンパイル時の注意}

yaskkserv2は、独自の辞書形式を利用しているため、SKKの辞書はそのまま利用せず、 `yaskkserv2_make_dictionary` というツールから変換する必要があります。

このとき、引数に渡す辞書の順で、変換候補の順序が概ね決まるような実装になっているため、下手に人名辞書とかを `SKK-JISYO.L` より前にもってきたりすると、変換候補の選択でムキーってなります(した)ので、SKK-JISYO.Lだけは明示的に先頭に指定するのをお勧めします。

```bash
$ yaskkserv2_make_dictionary --utf8 --dictionary-filename <辞書の位置> SKK-JISYO.L <それ以外>
```


### Emacs側での設定の必要性 {#emacs側での設定の必要性}

<https://github.com/wachikun/yaskkserv2#utf-8-dictionary>

yaskkserv2のReadmeでも言及されていますが、UTF-8の辞書を利用する場合には、ddskk側の振舞いをハイジャックして、EUC変換を行わないようにしておく必要があります。これをやらないとそもそも変換できねーです。

わたしのddskkの初期化では、以下のようにしています。ほとんど上記のリンクで言及されている方法と一緒です。これが、他のインプットメソッドと辞書サーバーを共有できなかった理由でもあります。

```emacs-lisp
(cond (my:use-skkserver
       (setq skk-server-host "localhost"
             skk-server-portnum "1178"
             skk-large-jisyo nil)
       (defun skk-open-server-decoding-utf-8 ()
         "辞書サーバと接続する。サーバープロセスを返す。 decoding coding-system が euc ではなく utf8 となる。"
         (unless (skk-server-live-p)
           (setq skkserv-process (skk-open-server-1))
           (when (skk-server-live-p)
             (let ((code (cdr (assoc "euc" skk-coding-system-alist))))
               (set-process-coding-system skkserv-process 'utf-8 code))))
         skkserv-process)
       (setq skk-mode-hook
             '(lambda()
                (advice-add 'skk-open-server :override 'skk-open-server-decoding-utf-8))))
      (t
       (setq skk-get-jisyo-directory (expand-file-name "skk-jisyo" user-emacs-directory)
             skk-large-jisyo (expand-file-name "SKK-JISYO.L" skk-get-jisyo-directory))))
```


## SKKたのしいです {#skkたのしいです}

辞書サーバーを使えたり使えなかったり、という問題はありますが、個人のWorkstationでは問題なくddskkを利用できるようになりました。SandSをがっつり利用するようにしているので、小指とかの負荷はまだそれほどでもないですね。

AZIKにも大分慣れてきて、徐々に拡張を利用できたりするようになってきました。しゃ、ちょ、などの拗音が3キーではなく、2キーで入力できるようになるのはやはり大きいですね。あと、ひらがな入力がダイレクトにできるというのは楽で、いちいちEnterを押さなくていい、というのは、これはこれで親指とかに対して優しいですね。

ライブ変換とかで変換しなくていいところで変換されて、それを再学習させるのにイラッと来たことがある方(自分)とか、一度試してみてはいかがでしょうか？毎回区切りを自分で指定するのは面倒でもありますが、自分で書いている、という手書き気分が味わえるので、作文とかには意外と向いていると思います。

今回は書いていない&試していないですが、Google IMEから候補を取得するようにしたりすると、連文節変換のような勢いで変換することもできる、という話です。(yaskkserv2はデフォルトでこの機能が有効になっています)

それではよい日本語入力ライフを。
