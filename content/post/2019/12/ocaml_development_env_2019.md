+++
title = "OCamlの開発環境2019末"
author = ["derui"]
date = 2019-12-03T08:29:00+09:00
lastmod = 2019-12-03T08:29:30+09:00
tags = ["Emacs"]
draft = false
+++

この記事は[株式会社オープンストリームアドベントカレンダー](https://qiita.com/advent-calendar/2019/opst)の3日目の記事です。

年の瀬ということで、いい感じに部屋が冷えてきてちょうどよいです。さて、 ~~あまりネタがない~~ 今回はOCamlの開発環境について書こうかと思います。

<!--more-->

以前にも書いたんですが、ちょっとした更新とか、結構大きな更新とかがあったので、まとめということで。


## Package Manager {#package-manager}

[opam](https://opam.ocaml.org/) （OCaml Package Manager）でどうぞ。現状、過去から受け継がれているとかで無い限り、これを使わない理由は皆無になりました。

version 2.0からは、ローカルのパッケージを簡単に追加できるようになっているので、このパッケージが更新されない・・・とかにも対応することが出来たりします。

Windowsへのクロスコンパイルなどの用途でも利用できるものなので、まー大人しく使っておきましょう。なお、Windows用のバイナリ、version 2.1で公式対応される？かもしれません。現状は大人しくUnix系で使いましょう。


## ビルドツール {#ビルドツール}

<https://github.com/ocaml/dune>

新規に始める場合は基本的にduneを使っておきましょう。OMakeとかocamlbuildとかMakefileとか色々ありますが、とりあえず始めるという分にはこれを使っておくのが良いかと。

OMakeとかMakefileとかを使うと、なんでduneがそういうコンパイルをしているのか、とかppxの動き方、とか色々わかったりしますが、割とズブズブにならないとあんまりうまみが無いと思います。新し目のduneはwatch機能もあるので、とりあえず裏で動かしっぱなしにも出来ます。


## 補完 {#補完}

<https://github.com/ocaml/merlin>

四の五の言わずに使いましょう。現代的なプログラミング環境には必須です。


## Editor {#editor}

先に断りとして、筆者はOCamlのプログラムを書く時は[Emacs](https://www.gnu.org/software/emacs/)しか使っていません。まーEmacsを使ってると言うと色々言われたりしますが、そこは気にしない方向で。


### Major mode {#major-mode}

<https://github.com/ocaml/tuareg>

Tuareg modeほぼ一択でしょう。ocaml modeでもまぁ問題ないと思います。


### 補完package {#補完package}

<https://company-mode.github.io/>
<https://github.com/sebastiencs/company-box>

現時点では、company-modeを使っておくのが安牌でしょう。company-boxを使うと（Emacs 26以降限定で）、見た目もいい感じに出来ます。


## LSP {#lsp}

<https://github.com/emacs-lsp/lsp-mode>
<https://github.com/emacs-lsp/lsp-ui>

今年一番の更新は、OCamlにもlspを使うようになった点です。TypeScriptと同レベルとか期待するのは、供給されているリソースとかいろいろ鑑みれば、そんなことあるわけ無いと判断できるはずです。ちなみに現在利用している <https://github.com/jaredly/reason-language-server> も内部でmerlinを使っていますし、merlin自体もlspを提供するかどうするか？というIssueが立っていたりするので、将来的にはmerlinだけでよくなる可能性もあります。


## formatter {#formatter}

<https://github.com/ocaml-ppx/ocamlformat>

最近はこれに任せています。formatについては結構いろいろいじれますし、デフォルトでも慣れれば問題ありません。EmacsとかVimの拡張も用意されているので、エディタで変更したらすぐ適用、みたいなことも簡単です。ocp-indentというのも使っていましたが、個人の開発であればこれでいいでしょう。

なお、linterは特にありません。OCamlのwarningでだいたい必要十分です。


## Test tool {#test-tool}

<https://github.com/mirage/alcotest>

最近はalcotestを使っています。この関連のpackageは結構色々ありますが、OUnitかこの辺りが汎用的でいいんではないかと。ppx\_expectとかppx\_inline\_testとかも併せて使えますが、それらは中々セットアップが面倒だったりするので、個人的にはあまり使わないです。

ppx\_inline\_testは、module化してmliを書いたりすると以外と書きづらいテストを書きやすくしてくれるんですが、細かめにmodule化しておけば割となんとかなるので、現在はそんな感じで凌いでいます。


## Documentation generator {#documentation-generator}

<https://github.com/ocaml/odoc>

ocamldocという、コンパイラに付属している同様のツールもありますが、デフォルトで生成されるフォーマットがいい感じだったりと、生成したい場合はこれを使う機会が多いです。


## 来年も色々あるかな {#来年も色々あるかな}

さて、色々と紹介しましたが、実際にはppxも開発ツールに挙げようとしましたが、ちょっとそれは避けました。その代わり、現実に私が利用しているツールを挙げています。

開発環境を改善していくことは、開発効率だったりを高める手っ取り早い方法ですし、色々な要素に触れるチャンスでもあると思います。たまには時間を取って、自分の開発環境を見直してみてもいいんじゃないでしょうか。

明日は・・・決まっていないですが、多分誰か書いてくれるでしょう。
