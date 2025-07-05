+++
title = "NixOSに入門してみた"
author = ["derui"]
date = 2024-10-13T11:13:00+09:00
tags = ["Linux"]
draft = false
+++

一気に凉しくなって、いきなり着るものに困っています。極端ですな(２回目)。

最近PCを新調しまして、そのなかでNixOSに興味がでたので入門してみました。

<!--more-->


## NixOSとは {#nixosとは}

<https://nixos.org/>

トップページにどーんと書いていますが、

> Declarative builds and deployments.

を実現することを目的としたLinux distributionです。技術的には、Nixというbuild tool及び同名のDSLを利用して、 ****OS全体を宣言的にしてやろう**** という、かなり狂気を感じる方法を取っています。

> Nix is a tool that takes a unique approach to package management and system configuration. Learn how to make reproducible, declarative and reliable systems.

実際進めていくと、色々理想と現実とのGapが見えてきそうなのはやる前からわかってましたが、純粋関数型のbuild、と聞くと、日頃ビルドに苦しめられている開発者としては琴線に触れるものではないでしょうか。

installにあたっては、すでに色々と地雷を踏んでいただいている先人の資料を参考にさせていただきました。NixOSは、 ****準備が足りないと何もできない**** ってのは本当だったので、事前に仮想マシンで構築できるかどうかを検証したほうがよいです。
<https://zenn.dev/asa1984/articles/nixos-is-the-best>


## Nixとその周辺ツール {#nixとその周辺ツール}

Nixが全体を構成する最重要ツールですが、Nix周辺のエコシステムでは、他にも重要なツール・拡張機能が存在しています。

-   Flakes
-   Home Manager
    -   <https://nix-community.github.io/home-manager/>

大きく書くとこの２つになります。Flakesはnix自体の拡張、Home Managerはコミュニティ主導でのツールになります。詳しい使い方とかは公式を見ていただくのがよいかなと。

特にnixは、それぞれ全く構成が異なるため、manualがあっても試行錯誤が前提となっています。


## NixOSのインストール {#nixosのインストール}

<https://nixos.org/manual/nixos/stable/#sec-installation>

に従ってやりましょう。なお、私はGentooのときからの癖で、minimal installationを常時選択しています。Gentooと比べると、最初にKernel configurationがないだけ大分楽やなぁ、と思ってしまうくらいには楽ですね。

正直インストールは単なる準備で、rebootしてからが本当のinstallになります。ここまでで事前にnixの構成を作っていない場合は、rebootしてしまうと何もできないので、できるだけここで完了させておくことを推奨します。


### インストールするときにflakesを利用する {#インストールするときにflakesを利用する}

すでにGitHubとかに上げてあり、かつFlakesを利用している場合、以下のようにしてFlakeから直接インストールすることができます。

```shell
$ nixos-install --root /mnt --flake "github:<owner>/<repo>#<config>"
```


## Nixとの戦い {#nixとの戦い}

NixOSは、 **なにか変更したい** == Nixの編集、となります。そのため、Nix言語及びツールへの習熟は嫌でも高まるという、いいんだか悪いんだか、というループが構成されています。

ただ、前述したように、NixOSの設定構成は千者万別ですので、基本的には断片をなんとなく理解して、自分の設定に当てはめていく、という厳しい作業が必要になります。

<https://github.com/derui/my-nixos>

私のNixOSの設定はすべてここにあります。適宜コメントなどは入れていますので、参考になれば。


### 大事なこと {#大事なこと}

<https://search.nixos.org/>

何も言わずにこのサイトをbookmarkしましょう。option/packageを探すときに最初に見る場所になります。・・・とはいえ、結局よくわからなくてsourceを見る機会も多いのですが。


### Emacsとかの管理 {#emacsとかの管理}

home-managerを導入していると、EmacsなどのDotfilesもNixでまとめて管理することができます。他のリポジトリで管理しつつFlakeとして取得する・・・ということもできますので、ここは好みかなと。

私は全部一個にぶち込みたい人なので、まとめて管理しています。管理する中でTipsなどもできたのですが、ここはまた別の機会に。


## とりあえず入門できました {#とりあえず入門できました}

今この記事は、新マシンにインストールしたNixOS上で書いています。実はsystemdを利用したシステムは宗教上の理由で利用していなかったのですが、利用するだけならやっぱり楽だよねえ、というのは実感してます。

ただその分、blackboxが大きすぎることの不安は変わらないので、ここはNixで管理できるというところがありがたいです。以前のGentooだと、基本的に再現を諦めるOr秘伝のタレ状態を引き継ぎ続ける、ってなってたので。

けして万人に進められるようなディストリビューションではないですが、設定ファイルだけなんとかしたい、みたいなときにも対応はできるので、Nixだけでも見てみてはいかがでしょうか。

個人的には、Haskellとかで苦しんだ経験があれば、Nixも多少は理解しやすいかな、と思います。動的に色々変わるのでマジわからなくなるのは困りものですが。
