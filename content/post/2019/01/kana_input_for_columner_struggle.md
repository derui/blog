+++
title = "格子配列に適したかな入力を模索する"
author = ["derui"]
date = 2019-01-24T17:44:00+09:00
lastmod = 2019-01-24T17:45:01+09:00
tags = ["日本語入力"]
draft = false
+++

以前の記事で、薙刀配列を利用している、と書きましたが、色々思うところがあり、今は別の可能性を探っています。

<!--more-->

現在色々と提案されているカナ入力方式は、TRON配列を除くと、基本的に **一般的なJISキーボードに合わせて設計されています** 。99%の人は、JISキーボードを利用しているであろうから、その課程は至極当然です。

しかし、Ergodoxを始めとする、通称 **格子配列** とJISキーボードでは、押しやすいキーや指の可動範囲がかなり異なります。人差し指が担当する **TYBN** であったり、小指が担当する **PQ** は使い勝手が変わります。また、JISキーボードのようなRow-struggleなキーボードで押しやすいキー連接は、必ずしも格子配列で押しやすいとは限りません。


## 格子配列の特徴と個人の身体的特徴 {#格子配列の特徴と個人の身体的特徴}

格子配列には、次のような特徴があります。（個人的な感覚ですが）

-   列をまたいで指を移動するのが厳しい
-   同じ列内での移動はやりやすい

また、これは私の身体的特徴ですが、

-   人差し指と小指がかなり短い
    -   格子配列でT/Yに指を伸ばすのに若干気合が必要なくらい
    -   手ごと移動すれば、指の不可は大分減りますが、今度は腕を持ち上げるという負荷がかかります
    -   P/Qは、手ごと移動しないと押せない

という特徴があります。模索している配列では、これらをどう解決していくか？が肝になります。


## シフトの設計 {#シフトの設計}

現在利用しているキーボードであるCrkbdには、そもそも42キーしかなく、親指以外の指に割り当たっているキーは36キーしか存在しません。このうち6キーはCtrlやShiftなので、事実上は30キーが物理的な限界です。

どのみちひらがなだけで50音あるので、必然的に何らかのシフト機構が必要になります。シフト機構にも色々ありますが、大別して次のようなものがあります。

-   前置きシフト
    -   JISかな、新JIS、親指シフト、月配列
-   同時シフト
    -   蜂蜜小梅配列、新下駄配列、薙刀配列、飛鳥配列

他にも色々ありますが、要は **シフトに順序性があるかどうか** が大きな違いです。順序性がある場合、ロールオーバーが可能になりますが、ほぼ同時にキーを押下した場合、意図しない入力になる場合があります。
順序性がない場合、ほぼ同時に押下しても問題ありませんが、その代わりに単打時の誤爆が起こりやすくなります。

また、どのキーをシフトとして利用するか？というのも重要です。

-   小指シフト
    -   JISかな
-   親指シフト
    -   NICOLA、蜂蜜小梅配列、薙刀配列、飛鳥配列
-   人差し指シフト
    -   薙刀配列
-   中指シフト
    -   月配列、新下駄配列

Crkbdに限って言うと、Layer切り替えがかなりの頻度で発生する上、SandS/Enterを親指に割り当てている都合上、これ以上負荷をかけるのはリスクがあります。実際、親指だけ痛くなったことがあるので。そうなると、弱い小指に負荷を与える小指シフトは論外として、人差し指/中指シフトが有力に思えます。
月配列や新下駄配列を利用していても、あまり違和感は無かったので、個人的にも問題はありません。


## 清濁同置と清濁別置 {#清濁同置と清濁別置}

新下駄配列や飛鳥配列では、清濁別置を選択することで、高効率を実現しています。しかしその分記憶負担が大きく、また運動記憶が確立するまでに時間がかかります。

蜂蜜小梅配列や薙刀配列では、濁音を入力する時に清音＋シフトで入力するようにして、記憶負担を抑えて、連想記憶で思い出せるようにしています。新JISでは後置きで濁点を追加する方式です。

最終的には運動記憶に帰着するため、効率だけで言えば清濁別置の方で効率的なのは明らかです。ただ、滅多に利用しない濁音や半濁音も連想無しで覚えなければならないので、滅多に利用しないかなの入力時にはかなりスピードに影響することが想像できます。


## 行段系かどうか {#行段系かどうか}

かな50音を、列＝子音と行＝母音に分解して、2打鍵で入力する方式です。けいならべ、かわせみ配列、Phoenix配列などが該当します。

行段系の利点としては次のような点が挙げられます。

-   記憶負担がちいさい
    -   子音と母音だけ覚えればいい
-   左右交互打鍵にしやすい
    -   大抵は子音と母音をそれぞれの手に配置するため、基本的左右交互打鍵になるケースが多いようです

対して、次のような欠点があります。

-   使用頻度による配置が難しい
    -   規則的になる半面、各指の運動特性に準じた配置とかはかなり難しい

つまり、効率をある程度犠牲にして、連想記憶などで思い出せるようにしたものです。基本的に一文字の入力に2打鍵かかるため、何らかの拡張を施さないと、ローマ字入力とさほど効率が変わりません。

実際に利用してみたところ、確かに記憶はすぐ出来ますが、やはり運動記憶にするまでに時間がかかります。また、どうしても２打鍵必要になるケースが多い、というのが結構気になります。


## 拗音拡張 {#拗音拡張}

最近の配列には、大抵拗音拡張が取り入れられています。拗音拡張を取り入れることで、やゆよの小文字を単独で入力する必要がなくなり、一動作で入力出来る文字数が増え、結果として効率が向上します。

ただ、拡張を取り入れることで、記憶負担の増加もまた避けられないため、各配列で覚えやすくするための工夫を取り入れています。

-   蜂蜜小梅配列
    -   蜂蜜マトリックスという仕組みを起点として構築されている
-   新下駄配列
    -   専用のシフトを割り当て、拗音拡張だけは規則的にしている
-   かわせみ配列
    -   子音＋やゆよの入力で規則的な配置
-   薙刀配列
    -   拗音の最初の文字＋後ろに続く小文字で統一

記憶負担の増加にどう対処するか？というのが肝のようですが、利用できると効率が向上するので、出来れば使えるようにしたいところです。


## 模索している配列 {#模索している配列}

今までの考察を元に、次のような点を満たすような配列を模索しています。

-   T/Yは文字入力で可能な限り利用しない
-   非行段系
-   中指シフト
-   清濁同置
-   可能であれば原則全て一動作で入力

実際に現在試用している配列は次のようなものです。

標準的なQWERTYキーボードの並びを以下のように表現します。このうち、TYには拡張を除いて文字を割り振っていません。

```nil
上段　ＱＷＥＲＴ　ＹＵＩＯＰ
中段　ＡＳＤＦＫ　ＨＪＫＬ；BS
下段　ＺＸＣＶＢ　ＮＭ，．／
```

単打面は次のようになっています。「てにをは」は、「を」を除いて右手に配置されています。

```nil
     小薬中人伸 伸人中薬小
上段 よくるけ、 。てはこひ
中段 のなとかっ ーういしに
下段 すれせたつ さんきもま
```

左右の中指でのシフトは次のようになります。単打面と中指シフト面の関係として、 ****濁点の付く文字はキーに付き一つ**** となっています。

```nil
左中指
上段 　　　　　 　りわらぬ
中段 　　　　　 へちを　そ
下段 　　　　　 ねほ　ふや

右中指
上段 ヴえみ　　 　　　　　
中段 めおをあゆ 　　　　　
下段 　む　ろ　 　　　　　
```

左右の薬指でのシフトは次のようになります。単打面と中指シフト面両方の濁音が入力できます。

```nil
左薬指
上段 　　ぱ　　 　でばごび
中段 ぽ　　ぺ　 べぢ　じぞ
下段 ぴ　　ぷ　 ざぼぎぶ　
げ
右薬指
上段 　ぐ　げ　 　　ぁ　　
中段 　　どが　 　ぇ　　ぉ
下段 ず　ぜだづ 　ぅ　　ぃ

F + J = を
N + J = ・
F + B = ・
```

右手上段＋左手で拗音拡張です。「ぱ」を除いて、濁音の拗音は規則的になっています。

```nil
上段 はしたか　 　よゆや　
中段 な　　まら 　　　　　
下段 ばじだがぱ 　　　　　
```

既存の配列から色々な点をパク・・・参考にしています。

-   中指/薬指での同時シフトは新下駄配列
    -   論理配列もいくらか参考にしています
-   濁音の排他配置、濁点シフトは薙刀配列

まだコンセプトレベルでの調整を行っているので、打鍵評価は行っていません。現状では次の点が気になります。

-   P/Qの位置を使わないようにできないか
    -   毎回手ごと移動している。慣れればなんとかなるのかもしれないが、負荷は結構厳しい。
    -   頻度の低い文字を配置して入るので、使う頻度は少ないが。
-   小指の上下動/人差し指の左右移動を抑えたい
    -   JISキーボードと違い、Nキーを押すため負荷が上がっている
    -   左右移動は、手首をひねる動きになるので、負荷がかかる
-   親指をシフトにするかどうか
    -   親指はlayerキー/Enter/Shift/Space/Altとして利用しているので、これ以上の負荷は結構厳しい（前述）
    -   ただ、低頻度のキーを入力する場合のみに限る、とかならいいかも？

ただ、物理的なキー数とシフト配置の問題から、清濁同置を守りつつ、上記の問題を解決するのはかなり難しいです。後、毎回firmwareをビルド・書き込みをしているので、Pro Microの書き込み回数が心配になります。

早めに打鍵評価を行えるようにしつつ、もうちょっと慣れたらどうなるか？を見ていきたいと思います。


## 配列づくりは難しい {#配列づくりは難しい}

頻度を考慮して配置を考えるというのもそうですが、運指なども考慮する必要があります。また、特殊なシフトなどを実装する場合、評価方法も作らなければならないケースもあります。

正直、他の有名所の配列を使った方がいいと思います。配列切り替えは、運動記憶に落とすために時間がかかるので、最初は実績のある配列を使うほうがいいかなーと思います。

楽しいことは楽しいので、いろいろ考えてみたいと思います。