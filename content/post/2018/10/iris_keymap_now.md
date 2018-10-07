+++
title = "Irisキーボード配列の現状"
author = ["derui"]
date = 2018-10-07T11:43:00+09:00
publishDate = 2018-10-07T00:00:00+09:00
lastmod = 2018-10-07T11:43:41+09:00
tags = ["自作キーボード"]
draft = false
+++

Irisキーボードを作ってから一週間くらい経ちました。その間、色々と試行錯誤して、ある程度決まってきたので、ここで一回紹介しておこうかと思います。

<!--more-->

なお、日頃の入力は全てIrisから行うようにしているので、キーマップ以外は慣れました。小さいは正義。


## Ergodox EZから無くなったキーたち {#ergodox-ezから無くなったキーたち}

[Irisキーボード](https://keeb.io/collections/frontpage/products/iris-keyboard-split-ergonomic-keyboard?variant=8034004860958) は、Ergodox EZよりもおよそ20キー弱少ない、54（または56）キーしかありません。また、改めて自分のErgodox EZのキー配列を見直してみた所、ちょうど無くなったキー部分に次のようなものがありました。

-   カーソルキー
    -   主に日本語入力中の候補選択とかに、org-modeで多用していました
-   Backspace/Enter
    -   作成の都合上、親指部分のキーに2uのキーを使ったので、単純にbackspace/enterのキーが消えました
-   `{}[]` の入力
    -   人差し指内側のキーにそれぞれマッピングしていました

少なくともこれらのキーは、今までと別の場所にマッピングしてやる必要があります。


## マッピング戦略 {#マッピング戦略}

さて、マッピングをしないといけないキーは色々ありますが、いくつか個人的に譲れないものとかがあるので、まずはそれをあげていきます。

-   親指にShiftがある
    -   コレだけは譲れない
-   親指にEnterがある
    -   コレも譲れないと言うか、US/JPどっちにしろIrisだとEnterがあるべき場所にキーがそもそもないので・・・
-   親指にSpaceがある
    -   元々親指で押してたもんですし。
-   アルファベット+基本的な記号部分はQwertyから崩さない
    -   別段ずらす必要はないので
-   GUIキーはデフォルトのlayerに必要
    -   タイル型WMを利用している都合上、コレは必須
-   [蜂蜜小梅配列](http://8x3koume.na.coocan.jp/) を利用する
    -   Ergodox EZでは一つのレイヤーとして実装していたので
-   日本語切り替えはワンタッチで
    -   現状維持。手軽に切り替えられることは効率に直結します

という感じです。記号類は、Ergodox EZの時点でSYMBOLレイヤーみたいなものを作ってそこで入力するようになっていたので、LOWER/RAISEを利用するとしても変わらないかな、と。

では、これらを考慮して設定していったキーマップを解説していってみます。


## レイヤー解説：Default layer {#レイヤー解説-default-layer}

<https://github.com/derui/qmk%5Ffirmware/blob/master/keyboards/iris/keymaps/derui/keymap.c#L31>

特筆すべき点というのはそんなに無いですが、親指に当たるキーは基本的に **Multi Role** になっています。同時押しのときと単独でのクリック時の挙動が違う、ということになります。

-   `SFT_ENT`
    -   同時押しでshift、単独でEnterになるようになっています
-   `M_EISU`
-   `M_KANA`
    -   単独だとかなと英数の切り替えを行います。切り替えは無変換のキーコードを出すようにしています
    -   同時押しだとLOWER/RAISEに切り替えられます。このキーを２つとも押しっぱなしにすると、ADJUSTになります

ここで一番変わっているのは、 `m_kana` と `m_eisu` です。本来であれば `LT()` マクロなどを利用するのですが、 `LTマクロなどは標準のキーコードなどとしかセットで利用できません` 。無変換とかと組み合わせることはできないということです。

ですので、自前で管理しています。こんな感じで。

```c
bool process_record_derui(uint16_t keycode, keyrecord_t *record) {
  static bool enable_layer = false;
  static bool interrupt_in_layer = false;

  if (record->event.pressed) {
    switch(keycode) {
    case M_EISU:
      layer_on(_RAISE);
      update_tri_layer(_LOWER, _RAISE, _ADJUST);
      enable_layer = true;
      interrupt_in_layer = false;
      return false;
      break;
    case M_KANA:
      layer_on(_LOWER);
      update_tri_layer(_LOWER, _RAISE, _ADJUST);
      enable_layer = true;
      interrupt_in_layer = false;
      return false;
      break;
    default:
      if (enable_layer) {
        interrupt_in_layer = true;
      }
      break;
    }
  } else {
    switch(keycode) {
    case M_EISU:
      layer_off(_RAISE);
      update_tri_layer(_LOWER, _RAISE, _ADJUST);

      if (enable_layer && !interrupt_in_layer) {
        /* KC_MHEN equals KC_INT5 */
        layer_off(_HACHIKOUME);
        SEND_STRING(SS_TAP(X_INT5));
        SEND_STRING(SS_TAP(X_LANG2));
        der_init_hk_variables();
      }
      enable_layer = false;
      return false;
      break;
    case M_KANA:
      layer_off(_LOWER);
      update_tri_layer(_LOWER, _RAISE, _ADJUST);

      if (enable_layer && !interrupt_in_layer) {
        /* KC_HENK equals KC_INT4 */
        SEND_STRING(SS_TAP(X_INT4));
        SEND_STRING(SS_TAP(X_LANG1));
        layer_on(_HACHIKOUME);
        der_init_hk_variables();
      }

      enable_layer = false;
      return false;

      break;
    default:
      if (enable_layer) {
        interrupt_in_layer = true;
      }
      break;
    }
  }
  return true;
}
```

tapping\_termなどの恩恵は受けられませんか、これくらいであれば、自前で実装してもまぁなんとかなります。

なお、かな/英数切り替えとレイヤー切り替えが同じキーに割り当たっている都合上、結構いい感じに誤爆するケースもあるので、この辺りはまだ調整の必要があります。


## レイヤー解説：LOWER/RAISE layer {#レイヤー解説-lower-raise-layer}

LOWER/RAISEは、キーマップをほぼ対象にしているだけなので、合わせて解説します。

<https://github.com/derui/qmk%5Ffirmware/blob/master/keyboards/iris/keymaps/derui/keymap.c#L45>

基本方針としては、キーが物理的に不足していて入力できない記号類と、Shift+数値に対応する記号を割り当てています。LOWER/RAISEの両方に同じようなものを指定している理由としては、片方の親指だけに不可がかかるのを防ぐためです。

特に右親指は、Shift/Enterを利用するため、時には非常に忙しいです。その親指にさらに不可をかけるのはちょっと厳しいです。また、左の親指もSpaceを担当しているので結構厳しいです。なので、そのとき空いている親指を利用できるように、こうしています。


## レイヤー解説：HACHIKOUME layer {#レイヤー解説-hachikoume-layer}

<https://github.com/derui/qmk%5Ffirmware/blob/master/keyboards/iris/keymaps/derui/keymap.c#L72>

蜂蜜小梅配列をハードウェアレベルである程度実現するためのレイヤーです。が、ほぼ実装は [以前書いた記事](https://qiita.com/derui/items/060eebf33716d703b90c) と同じです。

キー配列として異なるのは、シフトキーの位置ですが、これはErgodox EZ時点でのEnter/Spaceの位置と合わせるためにこうしています。なお、Irisではどうも.cファイルを分けられない？ようなので、全部１ファイルに収めています。


## レイヤー解説：ADJUST layer {#レイヤー解説-adjust-layer}

<https://github.com/derui/qmk%5Ffirmware/blob/master/keyboards/iris/keymaps/derui/keymap.c#L87>

最後はADJUSTです。このレイヤーは、LOWERとRAISEの両方を有効にした場合に有効になります。ADJUSTでは、基本的にはmodifierキー（Ctrl/Alt/Shift/GUI）とカーソルキーを配置しています。

カーソルキーとセットにすることで、org-modeでも利用できるし、候補選択とかでも利用できます。結局カーソルキーがないと逆に面倒な場面っていうのも多いので。

また、数字キーもホームポジション付近に来るようにしているので、このレイヤーまでフル活用すると、ほぼほぼホームポジションから指を動かすこと無く入力していくことが出来ます。親指をきついのでそんなにやりませんが・・・。


## 課題と展望 {#課題と展望}

ある程度入力しやすくはなってきましたが、まだ課題はあります。

特に、蜂蜜小梅配列時とデフォルト時でかな/英数切り替えの位置が異なる、というのが目下一番の悩みです。かなり親指を忙しいので、何らかの代替手段を考えたいところです。

しかし、Ergodox EZのときよりもスペースを有効活用できている感が強く、間違いなくqmk\_firmwareの機能を有効利用できています。理想のキーマップを目指す旅路はまだまだ果てがなさそうです。興味を持った方はぜひキーボード/キーマップの沼へどうぞ・・・。

本日は以上です。
