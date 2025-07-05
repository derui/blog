+++
title = "あえてAZIKの拡張を無効化するという選択肢"
author = ["derui"]
date = 2021-07-11T11:02:00+09:00
lastmod = 2021-07-11T11:03:00+09:00
tags = ["雑記"]
draft = false
+++

今週はワクチン接種とwelcomeランチで、とてつもなく久し振りに何日か連続で部屋のある地域から出ました。すっかりリモートに順応してはいますが、やっぱりリアルで会話すると、人間は五感で会話しているんだなぁ、ってのがよくわかります。

以前AZIK + SKKを利用している、という記事を書きましたが、今回はちょっとそれから色々アップデートをかましたので、それについて書きます。

<!--more-->


## AZIK + SKKの問題 {#azik-plus-skkの問題}

大分AZIK自体には慣れたのですが、あんまり一貫性のない拡張は利用せず、必要最低限の拡張だけを利用するようにしています(覚えられないとも言う)。

しかし、やはりSKKと利用していると色々な問題があり・・・。

-   SKKの標準で利用するキーとバッティングする
-   sticky keyとの相性がよろしくない
    -   これは後述します
-   SKKを利用していない環境のAZIKと少しずつ異なっているので、体を合わせるのが結構大変

この中でも、sticky keyが色々問題がありました。なのでちょっとそれに対して深掘ります。


## SKKのsticky keyで利用されるキー {#skkのsticky-keyで利用されるキー}

さて、SKKの実装には大抵sticky shiftを実現するためにsticky keyを定義できるようになっています。

> 少なくとも、私が利用しているddskkとAquaSKKには存在しています

これをどのように設定しているのか？を調べてみると、以下のような感じが多そうでした。

-   セミコロン
-   変換・無変換キー
-   F + Jなどの同時押し

このうち、私が試したことがあるのはセミコロンと変換・無変換キーです。同時押しは、かな入力であればよいと思いますが、SKKで要求される頻度でそれを行うと、まず間違いなく打鍵数がとても増えてしまいます。


### 変換・無変換キーと親指Enter/SandS {#変換-無変換キーと親指enter-sands}

私の利用しているキーボードは、今も変わらず [crkbd](https://shop.yushakobo.jp/products/corne-chocolate) ですが、このような系統ではEnter/Spaceを親指に割り当てたうえで、レイヤーの切り替えも親指で行うのが大勢となっています。それに加えて、SandSを長いこと利用しているので、それも設定しています。また、日本語・英数の切り替えも親指です。そうすると、親指が担当する機能というのは・・・

-   レイヤー切り替え
-   Enter
-   Space
-   SandS(実際にはSandEnterも設定してます)
-   Alt/Command
-   日本語・英数切り替え

・・・というくらいまで拡張されています。普通のUSやJISキーボードであればSpaceとかAltしかないと思いますが、このキーボードでは親指がかなり酷使されます。よく、親指はタフな指なので〜みたいな言説がありますが、実際には親指は支持するための指であり、タフでありますが運動性は高くありません。また、支持が目的であるため、キーボードにおいては他の指と力の入れかたが異なります。そのため、親指に機能を割り当てすぎると、今度は親指の負担が大きくなりすぎる、という問題になります。

ちょうど、無変換にsticky keyを設定してしばらく運用してみたのですが、親指があまりに動きすぎるため、手もブレるし痛みもでやすい、ということがわかったため、これは却下しています。


## SandSでやればいいんじゃないの？ {#sandsでやればいいんじゃないの}

SandSを設定しているからsticky keyは使っていない、というのも見ましたが、これはあくまで一般的なキーボードを利用しているケースです。↑にあるように、親指に多数の機能が割り当てられているときに、SKKの頻度でSandSをやってしまうと、これまた親指の酷使になります。


## じゃあどうするのか {#じゃあどうするのか}

ここでの問題は、AZIKにおいては促音「っ」を入力するためにセミコロンが潰されている、という点にあります。

> ＡＺＩＫでは「っ」の入力は常に「；」キーを使います。「あっ、ピカッ」などという入力がとても楽になります。
>
> <http://hp.vector.co.jp/authors/VA002116/azik/azikinfo.htm>

さて、実際に色々文章を入力していると、このような文章を入力する機会はかなり少ないです。正直、このくらいなら `xtu` で入力しても問題ない・・・。AZIKでは、これで潰した元々の促音入力である `tt` `kk` `pp` `ss` などに拡張が割り振られています。しかし、これらの拡張は利用頻度を考えると相当少なく、かつ促音を単独キーで入力するときと、結果として打鍵数は同一です。

そこで、以下のようにしてみました。

-   セミコロンはsticky keyにするので、AZIKの定義から削除
-   `tt` `ss` `kk` `pp` などの拡張を削除

結果としては大分シンプルですが、AZIKそのものよりもローマ字入力との互換性が向上したのと、セミコロンというsticky keyに最適な場所を利用できるため、体感的な効率としてはかなり改善しています。そもそもddskk上のAZIKはオリジナルと変わっているので、むしろ拡張しない側にもっていくのは簡単でした。

ddskkだとこんな感じで設定できます。

```emacs-lisp
(add-hook 'skk-azik-load-hook
          (lambda()
            ;; azikから追加された各種拡張を、SKK寄りに戻すための追加設定
            ;; 「ん」をqに割り当てるのは、ただでさえ負荷の高い左小指を酷使することになるので、元に戻す
            ;; qの役割を元に戻したので、「も元に戻す

            (setq skk-rom-kana-rule-list (skk-del-alist "q" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "[" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist ";" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "vh" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "vj" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "vk" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "vl" skk-rom-kana-rule-list))

            ;; 促音はもともとのローマ字と同様に入力できるようにする
            (setq skk-rom-kana-rule-list (skk-del-alist "tt" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "kk" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "ss" skk-rom-kana-rule-list))
            (setq skk-rom-kana-rule-list (skk-del-alist "pp" skk-rom-kana-rule-list))

            ;; Xで辞書登録する場合があるので、この場合でもちゃんと破棄できるようにする
            (setq skk-rom-kana-rule-list (append skk-rom-kana-rule-list
                                                 '(("!" nil skk-purge-from-jisyo)
                                                   ("q" nil skk-toggle-characters)
                                                   ("[" nil "「")
                                                   (";" nil skk-sticky-set-henkan-point)
                                                   ("vh" nil "←")
                                                   ("vj" nil "↓")
                                                   ("vk" nil "↑")
                                                   ("vl" nil "→")
                                                   ("vv" nil "っ"))))

            (setq skk-rule-tree (skk-compile-rule-list
                                 skk-rom-kana-base-rule-list
                                 skk-rom-kana-rule-list))))
```


## 常にオリジナルがよいとは限らない {#常にオリジナルがよいとは限らない}

AZIKはローマ字入力と互換性をとりつつ、同士異鍵だったりを解消している、よいバランスだとは思います。ただ、個人的には拡張が余計に感じる点が多々あったので、今回の修正は対応の手間のわりには、個人的な違和感が大分軽減されました。

無理に自分に違和感のあるものを取り入れ続けなくてもいいんだな、というのがあらためてわかったと思います。でもAZIK自体はおすすめなので、一回オリジナルを試してみることをオススメしやす。