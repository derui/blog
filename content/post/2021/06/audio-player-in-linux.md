+++
title = "Linuxで音楽を聞く時に使っているもの"
author = ["derui"]
date = 2021-06-13T00:00:00+09:00
lastmod = 2021-06-19T15:25:40+09:00
tags = ["Linux", "雑記"]
draft = false
+++

大分前に購入していたけど、ほとんどやっていなかった[shapez.io](https://store.steampowered.com/app/1318690/shapezio/?l=japanese)というゲームを久し振りにやったら、ずっと黙々とやってしまいました。これは時間が溶ける系統や・・・。

さて、今回もライトな話題で、Linuxでの音楽鑑賞をどうやっているか、について書いてみようと思います。

<!--more-->


## GUI or CUI {#gui-or-cui}

まず、Linuxでのプレイヤーとしては、CUIベースかGUIベースか、に大別されます。

-   CUIベース
    -   mplayer
    -   [mpv](https://mpv.io/)
-   GUIベース
    -   [smplayer](https://www.smplayer.info/ja/info)
    -   celluloid
    -   [VLC](https://www.videolan.org/vlc/index.ja.html)
    -   ...など

CUIベースであるmplayer/mpvは、他のplayerのバックエンドとして利用されている(smplayerやcelluloidといったものは、mplayer/mpvのフロントエンドです)ので、実際には本当にインターフェースがCUIなのかGUIベースなのか、という違い程度だと思います。


### Spotifyとかは？ {#spotifyとかは}

私は基本的にオールドタイプなので、ストリーミング(有料会員ならオフラインにダウンロードとかできるらしいですが)で聞く、というのは基本的にやってません。購入した楽曲は手元に置いておきたい、という感じですね・・・。

Youtubeとかで見つけても、その後には楽曲をあらためて別サイトで購入したりするのが私にとっては一般的です。


## 楽曲の保存 {#楽曲の保存}

基本的に全ての楽曲はNASに保存しています。ちなみに使っているNASは二代目で、以下を使っています。

<https://www.synology.com/ja-jp/products/DS218>

これに、WesternDegitalのNASむけHDDを組み合わせて利用しています。

LinuxとはNFSで接続できるので、まー特に問題ありません。Windowsとの相互運用も問題ないので、普通にWindows機とのファイルのやりとりにも利用しています。


## 何を利用しているのか {#何を利用しているのか}

私は上記に書いたプレイヤー全部を利用したことがありますが、現状は以下のような形に落ち着いています。

-   音楽をディレクトリごととかで再生する
    -   mpv
-   動画や、頻繁にシークする音楽ファイルを再生する
    -   celluloid
-   プレイリストを見たい
    -   celluloid

mpvでもシークはできるんですが、どうしても視覚的に直感的ではないため、シークが頻繁におこなわれるものとしてはcelluloidを利用しています。あと、動画とかを一気に見たりする場合は、プレイリストとして常に表示できるGUIの方が便利です。

> まぁ、最近は動画についてはストリーミングでしか見ていないので、ほとんどcelluloidは使っていないのですが・・・。


## なぜCUIを利用するのか {#なぜcuiを利用するのか}

私が思うCUIの楽さ加減としては、

-   tmuxとかのターミナルマルチプレクサと併用すれば、裏で流しっ放しにできる
-   ディレクトリ内を一括で入れたりするのが簡単
    -   ファイル数が多すぎると、コマンドラインの最大長を超える可能性もありますが
-   GUIが無いのでとても軽い

という点です。私の環境ではWMとしてswayを利用しているので、GUIを起動するとどうしても邪魔になりやすい、というのがあります。

> floating windowは、場所をずらしたり調整したり、後邪魔になったときに避けないといけないので、あんまり利用してません。


## 他の人はどうやってるんだろう {#他の人はどうやってるんだろう}

最近はもう基本的にストリーミングサービスを利用している、という方が大半だとは思います。私は今でも専用のメディアプレイヤーにmp3なりを突っ込んで聞いている、という人なので、基本的にはオフラインで聞けることを優先しています。

ストリーミングを利用している人の場合、基本的にはそのサービスのクライアントを利用するんだと思いますが、それって無駄に重いし邪魔じゃない？という思いもあります。機会があれば聞いてみようかなー、と思います。(私の周辺はみんなオールドタイプなので)