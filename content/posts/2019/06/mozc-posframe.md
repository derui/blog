+++
title = "mozcの候補をposframeで表示するEmacs拡張を作った"
author = ["derui"]
date = 2019-06-07T09:54:00+09:00
lastmod = 2020-09-22T12:59:34+09:00
tags = ["Emacs"]
draft = false
+++

最近家に帰ってからめっきりプログラミングをしなくなってしまいました。いろいろやることがあると同時並行では難しいですね。

さて、今回はmozcの候補表示pluginを作ってみたというお話です。

<!--more-->

<https://github.com/derui/mozc-posframe>

mozcの候補表示は、標準で存在する Echo Areaへの表示、overlayでの表示のほか、 [mozc-popup](https://github.com/d5884/mozc-popup) という拡張があり、大抵はこれを利用している方が多そうです。私もこれを利用していました。

（Emacs上での日本語入力にfcitxとかを利用している人は対象外です。そういう人のほうが多いんだろうか・・・）


## mozc-popupの利点 {#mozc-popupの利点}

mozc-popupを利用していたのは、やはり利便性を重視してのことでしたが、特に以下の点がキーだったと思います。

-   変換位置と候補が近い
    -   overlayでもだいたい一緒ですが
-   実績あるpopup.elの利用
    -   Spacemacsから入った人は知らないかもしれない、auto-completeで熟成したpopup表示に特化したlibraryです
    -   この結果、標準のoverlayよりも高速でした


## だんだんででくる問題点 {#だんだんででくる問題点}

mozc-popupを利用する前は、mozc + popupという組み合わせで長年使っていましたが、最近色々と問題が見えるようになってきました。

-   org-modeとpopup.elの相性が悪い
    -   新しい拡張を作ることにした最大の契機
    -   特に多数の折りたたみがあるときに顕著で、表示までの時間や、表示の崩れが非常に激しかった
-   popup.elの更新頻度
    -   一時代を築いたpopup.elですが、companyが台頭してからはだいぶ表舞台から消えてしまった感があります
    -   その仕組み上も複雑で、メンテナンスが困難だという話も


## child frameという潮流 {#child-frameという潮流}

Emacs 26から、frameに大きな拡張が入り、child frameと呼ばれる形態が可能になりました。端的に言うと、frameをfloating windowとして扱うことができる、というものです。

すでに様々なライブラリで利用されており、名実ともにEmacs26の目玉機能となっています。（個人の観測範囲では）

-   <https://github.com/sebastiencs/company-box>
-   <https://github.com/emacs-lsp/lsp-ui>

しかし、あくまでframeを扱うものであるため、そのままだとpixel単位での操作が必要となり、非常に煩雑です。WIN32 APIでwindow作っていた時代になった気分です。それをラッピングしたlibraryが、 [posframe](https://github.com/tumashu/posframe) です。


## mozc + posframe {#mozc-plus-posframe}

前述したmozc-popupの問題は、つまるところoverlayでの表現に限界があった、ということに尽きると思います。overlayはあくまでtextのpropertyでしかないので、複数のoverlayが設定された場合、その時時で異なる問題が出るであろうことは想像に難くありません

PCで日本語を入力する場合、大抵はIMEを使うかと思います。Windows/macOS/Linux いずれも、候補表示そのものは **独立したWindow** です。つまり、Child frameをこの用途に使うと丁度いいんじゃないか？というのは前々から考えていました。

すでにあるだろうと探してもなかったので自作することにしたわけですが。


## mozc-popupとの比較 {#mozc-popupとの比較}


### Pros {#pros}

-   org-modeやそれ以外でも、候補表示の時間がほぼ一定
    -   調整の余地はありますが
-   表示崩れがない
    -   これがposframeを利用する最大の利点です
    -   独立したframeを表示しているだけなので、複数のoverlayが設定されることに起因する問題から開放されています


### Cons {#cons}

-   install方法が煩雑
    -   melpaとかに入っていないので、どうしてもstraight.elとかが必要です
-   Emacs26以上 + GUIでないと動かない
    -   個人的に、端末上で利用するのはもはや趣味の領域でしかないと思ってます
    -   描画性能もほとんどの場合GUIツールキットの方が早いし、ChildFrameは性質上GUIでしか動きません
    -   端末しかない？諦めてVimった方が幸せになれるかと・・・


## ありがとう、mozc-popup {#ありがとう-mozc-popup}

mozc-posframeは、mozc-popupのソースを7割くらい流用しています。mozc-popupがなければ、そもそもmozc-posframeを作ろうと思ってなかったと思います。

まだmozc-posframeは若干のバグや性能向上の余地がありますが、すでに常用できるものになっている（というか常用してる）と思うので、よければ利用してみてください。
