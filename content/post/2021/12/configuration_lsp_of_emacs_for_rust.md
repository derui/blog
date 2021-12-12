+++
title = "Emacs + LSPでRustを開発するときの設定"
author = ["derui"]
date = 2021-12-12T13:19:00+09:00
lastmod = 2021-12-12T13:19:19+09:00
tags = ["雑記"]
draft = false
+++

気がついたら12月が1/3過ぎていました。ちょっと時間の流れが歪んでいるレベルですね。

最近Rustを書く機会が増えてきたので、ちょっと整理しました。ネタが無いので小ネタです。

<!--more-->


## Emacsでの設定 {#emacsでの設定}

私はRustもOCamlと同じくEmacsで開発するので、当然ながら設定もEmacsになります。

現状はrusticを利用していないので、rust-modeとその他で以下のような感じになってます。

```emacs-lisp
(leaf rust-mode
  :straight t
  :custom
  (rust-indent-offset . 4)
  (rust-format-on-save . t)
  ;; formatの度にbufferが分割するのを避ける
  (rust-format-show-buffer . nil)
  :hook
  (rust-mode-hook . lsp)
  (rust-mode-hool . cargo-minor-mode))

(leaf cargo
  :straight t)

(leaf *rust-analyzer
  :after f
  :if (and my:cargo-path my:rust-analyzer-version)
  :init
  (let* ((cargo-path (expand-file-name "bin" my:cargo-path))
         (server-program (expand-file-name "rust-analyzer"  cargo-path)))
    (unless (f-exists-p server-program)
      (let* ((target (cond ((eq window-system 'ns) "apple-darwin")
                           (t "unknown-linux-gnu")))
             (path (format "https://github.com/rust-analyzer/rust-analyzer/releases/download/%s/rust-analyzer-x86_64-%s.gz" my:rust-analyzer-version target)))
        (call-process "curl" nil nil t "-L" path "-o" "/tmp/rust-analyzer.gz")
        (call-process "gunzip" nil nil t "/tmp/rust-analyzer.gz")
        (f-move "/tmp/rust-analyzer" server-program)
        (message "Success rust-analyzer installation!")))))
```

最後のrust-analyzerについては、後述する lsp-modeで利用するためです。rust-analyzerはnightlyじゃないとインストールできないのと、現在はmanualの方が推奨っぽいので。

ポイント的には、 `rust-format-show-buffer` をnilにしている、という点です。これをやらんと、rustfmtがかかる度にbufferが分割してものすごいストレスがかかります(デフォルトがnilになってるかもしらんけど)。


## LSPの設定 {#lspの設定}

lsp-modeでの設定はrustに閉じた部分だけです。

```text
;; enable proc-macro in rust-analyzer
(lsp-rust-analyzer-proc-macro-enable . t)
(lsp-rust-analyzer-experimental-proc-attr-macros . t)
```

さて、この二つが必要な理由です。

まず、Rustには[マクロ](https://doc.rust-jp.rs/book-ja/ch19-06-macros.html)があります。このマクロはCommonLispなどのmacroexpand(実行時)ではなく、コンパイル時に解決されるものです。ですが、当然ながらLSPはコンパイルしているわけではない(しているときもあるけど)ので、ソース上からはその展開でどのようになるか？は不明瞭です。

macro\_rulesで記述されるようなマクロの場合は、macro\_rulesを頑張って展開したらいけるっぽいのですが、手続型マクロというようなマクロでは、実行してみなければ = コンパイルしてみなければ、どういう型が生成されるのか？までは不明です。

当然ながらそれはコンパイルすることと同義なのですが、今触っているやつはこの手続型マクロがてんこもりなやつなので、これが無いと

-   flycheckでuseしているものがエラーになる
    -   コンパイル時には存在しているので、cargo buildしてもエラーにはならない
-   手続き型マクロで生成された処理がうまくハンドリングできない
    -   attr-macrosがこれにあたります

なので、これらを設定しないといつまで経ってもエラーが消えない、という感じなので導入してます


## その他は設定中 {#その他は設定中}

きちんと書くようなプログラミング言語についてはyasnippetとかも定義しているので、それらも合わせて定義しようかな、というところで、まだやってないです。

Rustでなにをやってんのか、についてはうまくいったら記事にしようかなと思います。


## 終わり {#終わり}

小ネタなのでこんなところで。
