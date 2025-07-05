+++
title = "Emacsでの補完とかを脱ivy/selectrumした"
author = ["derui"]
date = 2021-06-19T15:49:00+09:00
lastmod = 2021-06-19T15:49:22+09:00
tags = ["Emacs"]
draft = false
+++

久々(約４年振り)に眼鏡を新調しました。といっても注文して決済しただけで、まだ受け取っていないのですが。

さて、今回はEmacsの補完をivyから完全に切り替えたのでその話を書こうと思います。とはいえかなりライトなお話ですが。

<!--more-->


## 補完インターフェースの遍歴 {#補完インターフェースの遍歴}

なんだかんだ、Emacs(Meadow含め)を使いつづけて早1x年が経過してますが、その間に補完インターフェースはその時々のトレンドに乗ってきました。

-   Anything
-   Helm
-   Ivy
    -   Ivy + posframeもやったりしました
-   selectrum

どちらかというと個人的にはこだわりはないので、そのときどきで一番勢いがあるものに乗っかることで楽をしている感じですね。


## 今回の変更先 {#今回の変更先}

ついこの間まではivyからselectrum + consultとなっていましたが、以下の記事を見て、ご他聞に漏れずverticoに変更することにしました。仕事でもそうですが、標準に乗っかるって大事ですね。

<https://blog.tomoya.dev/posts/a-new-wave-has-arrived-at-emacs/>


## selectrumからverticoへの変更 {#selectrumからverticoへの変更}

さて、実際に乗り換えたのはインターフェースだけなので、selectrumからverticoへの移行のみが焦点となりました。

・・・が、そもそもほとんどカスタマイズが不要な状態で(唯一やっていたのはmini-frameくらい)利用していたので、正直ほとんど変更することもなかったです

実際に設定中でもたったこんだけです。

```emacs-lisp
(leaf vertico
  :straight t
  :custom
  ;; 最大20件まで表示するように
  (vertico-count . 20)
  :config
  (vertico-mode))
```

> 個人的には、Interfaceとかはあんまりいじりすぎないようにしています。よほど色がどぎついとかそういうのは弄りますけど。


## mini-frameを利用しないようにした理由 {#mini-frameを利用しないようにした理由}

さて、selectrumを利用していたとき、ivy-posframeを利用していたのと同じ感じで利用できれば、ということで[emacs-mini-frame](https://github.com/muffinmad/emacs-mini-frame)を利用していました。

しかし、これはこれで結構難点がありました。

-   現在の視点に関わらず、常に一定の場所に表示される
    -   ivy-posframeとかだと、カーソルのそばとかに表示できたりします
-   配色の問題だが、borderlessなので一瞬境目を見失う

といったものが日々利用する上でだんだんストレスになっていました。固定位置なのであれば、正直minibufferを見るのと変わらんやん・・・ということもあり、verticoへの移行を期に削除しています。


## migemoるようにした {#migemoるようにした}

今回、orderlessとverticoを導入したことで、emacsの補完システム(実はかなり充実している)を利用する形で、結構お手軽に変更できるようになっています。

<https://nyoho.jp/diary/?date=20210615>

こちらの記事を参考、というかほぼ丸パクリさせていただいて(多少アレンジはしてます)、無事consultでもmigemoることに成功しました。最近はorg-roamでメモを取るようにしているので、ファイル名とかを日本語検索するのが億劫になっていたところだったので・・・。ちなみにmigemoは自作の[migemocaml](https://github.com/derui/migemocaml)を利用しています。

> そういえば、単独でdictを生成できるようにしたのに、まったく記事を書いていないので、これについては後程記事にしようと思います。


## 軽快・快適な補完生活を {#軽快-快適な補完生活を}

現在、Emacsのpgtkブランチを利用することで、 Wayland native + native compileな環境を利用できるようになり、かなりEmacs上が快適になっています。これだけ快適になると、さらにVSCodeとかに移行するモチベーションが無くなるのが困ったところですね。

とはいえ、快適な補完は現代的な生活における必需品だと思います。Spacemacsとかではなく、vanillaのEmacsを利用している方は、是非これらのパッケージを利用してみることをお勧めします。快適ですよ。