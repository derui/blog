+++
title = "自作キーボードを作ってみた：注文編"
author = ["derui"]
date = 2018-09-11T22:13:00+09:00
lastmod = 2020-09-22T11:21:48+09:00
tags = ["自作キーボード"]
draft = false
+++

個人的には2年くらい前から [Ergodox EZ](https://ergodox-ez.com/) を使ってきました。セパレート式に目覚めたのはこれが契機で、自宅も仕事場もErgodoxに統一しています。ただ、不満がないかというとそうでもなく、よりよいキーボードを探していました。そんなとき、半年くらい前から自作キーボードが非常に賑わって来ていることに気づきました。これはムーブメントに乗るしか無い！と半年遅れくらいで乗ることにしました。

<!--more-->


## Ergodoxの不満 {#ergodoxの不満}

自作するにも、まずErgodox自体の不満である点をあぶり出す必要があります。最近の使い方を鑑みると、次のような不満がありました。

-   でかい。持ち運びはかなりきつい
-   Kinesisもそうだったが、親指に役割が過剰
    -   一番強いと言っても、本来の可動範囲と違うので、やりすぎると親指だけ痛くなったりする（実体験
-   人差し指内側のキーが基本死んでる
-   一番下の段のキーは基本使ってない

など、使っていくうちにどんどんデッドキーが多くなっていきました。それと、個人的にもqmk\_firmwareの挙動に慣れてきたりして、レイヤーを使いこなせるようになってきたことが大きいです。


## 自作候補 {#自作候補}

色々ありますが、以下のような選定基準にしました。

-   キー配列は格子
-   親指部分が独立している
-   親指部分に機能が集中しすぎていない
-   でもSandSはやりたいのである程度欲しい
    -   親指にshiftが無いと色々と効率がだだ下がりします

見つけた範囲だと、以下のキーボードがドンピシャのようでした。

-   [crkbd](https://pskbd.booth.pm/items/869375)
    -   Helixベースのため薄い
    -   3行6列。かなりミニマル
        -   個人的に数字を結構多用するので、ないときついんじゃないかって思う
    -   かなり理想的
        -   irisよりも注意事項が少ない印象
-   [iris](https://keeb.io/collections/keyboard-pcbs/products/iris-keyboard-split-ergonomic-keyboard?variant=8034004860958)
    -   ほぼ理想形（多分）
        -   親指部分を 1u 2個と2u 1個で選択可能。ただ、実際に打っている感じだと、この場所で上下を打ち分けるのは結構しんどい可能性が高いです
    -   ビルドログが豊富
    -   若干分厚いが、Ergodox EZよりもずっと小さい

今回は、丁度在庫が復活したので、Irisを組んでみることにしました。crkbdの方も、在庫が復活したら買う予定です。限度額が余ってれば。


## 注文内容 {#注文内容}

Keeb.ioでだいたい注文しました。

-   PCB Kit
-   プレート
    -   若干高かったですが、ステンレスにしました。初心者なのに大丈夫か？って思わなくもない
-   [ProMicro](https://keeb.io/products/pro-micro-5v-16mhz-arduino-compatible-atmega32u4) × 2
-   [TRRS Cable](https://keeb.io/products/trrs-cable?variant=8131954704490)
    -   コイルしてるのにしてみました

キーキャップは、参考サイトにあった [ジェイダブル](https://www.jw-shop.com/mswitch-key.htm) から買いました。変に凝ったら素で **10k円** いってしまった・・・。なお軸は赤軸です。軽い＋リニアなのがいいのです。

工具類とUSBケーブルはAmazonで揃えました。

-   はんだごてとコテ台
    -   [白光 ダイヤル式温度制御はんだこて FX600](https://www.amazon.co.jp/gp/product/B006MQD7M4/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
    -   [白光(HAKKO) こて台 633-01](https://www.amazon.co.jp/gp/product/B000TGNWCS/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
    -   定番っぽいのでこれに。こういうので奇をてらってもなんにもならないので・・・
-   はんだ
    -   [goot 両面プリント基板用はんだ SD-61](https://www.amazon.co.jp/gp/product/B0029LGAKW/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
    -   0.8mmのものがちょうどいいらしいのでこれに
-   ニッパー
    -   [goot ニッパー YN-10](https://www.amazon.co.jp/gp/product/B001VB37RK/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
    -   ドライバーとかはあったんですが、なぜかニッパーがなかったのでこれで。鋼線切断能力が1.3mmということで、Pro Microの足も切れるはず
-   その他
    -   [エポキシ系接着剤](https://www.amazon.co.jp/gp/product/B003SJI5RU/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
        -   モゲ防止に
    -   [3M しっかりつくクッションゴム 8x2mm 台形 22粒 CS-04](https://www.amazon.co.jp/gp/product/B00V5MQQIC/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
        -   クッションに
    -   [ユニバーサル基板](https://www.amazon.co.jp/gp/product/B074YFS6MV/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
        -   はんだ付けの練習用に
    -   [マグネット式のUSBケーブル](https://www.amazon.co.jp/gp/product/B074DFF8TB/ref=od%5Faui%5Fdetailpages00?ie=UTF8&psc=1)
        -   モゲ防止 + 持ち運び用
        -   1Mはないと部屋で使う時足りないので
    -   これ以外にも、テスターや絶縁テープなど購入しています

総計で **30k円** くらいいってます。Ergodox EZよりは安いと言えば安いけれども・・・


## 届いたら {#届いたら}

ビルドログをあげようかと思います。蜂蜜小梅配列を使う都合上、LEDは一切付けませんので、どっちかというと配列の話になるかも？
