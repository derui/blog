+++
title = "QMKでかな配列を使いつつ英字も入れられるようにする"
author = ["derui"]
date = 2024-06-02T14:59:00+09:00
tags = ["Keyboard"]
draft = false
+++

そろそろ梅雨が近くなってきました。毎年あるものではありますが、ジメジメするのは嫌ですね。

今回も小ネタですが、個人的に結構困っていたので、いい加減に対処してみました。

<!--more-->


## 困りごと {#困りごと}

私は基本自作キーボードを利用していて、qmk_firmwareを利用している、というのが前提になります。かな配列についてもqmk上に実装していますが、これには環境に左右されないというメリットがあるのですが、同時に以下のようなデメリットもあります。

-   IMEとの連動がほぼできない
    -   かな入力かどうか？という状態をキーボードで持ってしまっているため、一時的な英字入力などがほぼできません
    -   そのため、英字を一時的にいれたい、という場合には毎回IMEの切り替えが必様になってしまいます

macOSのライブ変換でも、WindowsのIMEでも、この問題は発生するため、仕事で必要になる英字混りの文章を打つのが結構めんどくさいなー、と思っていました。

> まぁ、仕事ではQWERTYを使えばいいやん、というのが現実解だとはわかっていますが・・・

今回、やっとこの問題を解消したので、簡単に方法を書き連ねてみます。


## 基本的な方針 {#基本的な方針}

実装にあたり、以下を実現することを前提としました。

-   IME自体の切り替えなどは不要
-   一時的に英字を入力でき、再度かなの入力ができる
-   できるだけQWERTYと操作感を変えないようにする
-   SandSと親和性がある形にする

まぁつまりは一般のキーポードでの入力とあまり変らないようにする、というところですね。


## 実際の実装 {#実際の実装}

方法自体はいろいろあると思いますが、ここでは実装したソースを抜粋して紹介します。

```c
bool process_record_ng(uint16_t keycode, keyrecord_t *record) {
  enum ng_key key = ng_keycode_to_ng_key(keycode);

  /* サポートできないキーの場合は無視する */
  if (key == N_UNKNOWN || (ng_is_alphabet_mode() && key != N_SFT)) {
    return true;
  }

  /* 押された場合は、単にbufferに積むのみとする */
  if (record->event.pressed) {
    ng_update_buffer_pressed(keycode);

    // shiftキーの場合は設定を記録しておく
    if (key == N_SFT) {
      ng_unset_alphabet_mode();

      if (keycode == M_ENTER) {
        ng_shifted_by_enter();
      } else if (keycode == M_SPACE) {
        ng_shifted_by_space();
      }
    } else if (ng_is_cont_shift()) {
      /* 連続シフトのときに他のキーを押下すると、英字モードに入る */
      ng_unset_cont_shift();
      ng_set_alphabet_mode();

      register_code(KC_LSFT);
      tap_code(keycode);
      unregister_code(KC_LSFT);
    }

    return false;
  } else {
    /* キーがおされていない場合は何もしない */
    if (!ng_is_key_pressed(key, key_buffer)) {
      return false;
    }

    /* releaseされた場合、現在のバッファと一致するものを強制する */
    seq_definition_t* def = ng_find_seq_definition(key_buffer, false);
    ng_update_state_released(keycode);

    if (!def && key != N_SFT) {
      return false;
    }

    /* Do not send string if shift key is released and other sequence already sent */
    if (key == N_SFT) {
      // シフトキーが単体で離されたら、最後に押されたshiftキーに対応する処理を返す
      if (ng_is_alphabet_mode()) {
        ng_unset_alphabet_mode();
      } else {
        tap_code(ng_shifted_key());
      }

      return false;
    }

    send_string(def->sequence);
    /* send_string_shifted(def->sequence); */

    return false;
  }
}
```

同時シフトを前提とした実装ですが、雰囲気は伝わるかなと。左右のシフトキーは、それぞれSandS対応されており、Space/Enterが割り当てられています。この実装では、次のような形で英字入力ができるようになります。

-   Space/Enterを押しっぱなしアルファベットで英字モード
    -   最初に入力される文字は大文字になる
-   再度Space/Enterを押下するまではそのまま英字が反映される

この挙動は、一般的なIMEの操作に合わせてあるので、とくに切替を必要としない、はずです。（現在Linuxが基本、かつIMEが使えない状況なので、多分大丈夫、という感じです）

全体の実装は以下にあります。

<https://github.com/derui/qmk_firmware/tree/master/keyboards/lily58/keymaps/derui>


## かな入力の辛さ {#かな入力の辛さ}

正直速度だけを求めるのであれば、QWERTYを使っておくのが一番問題がないのですが、かな入力をやっていこうとするとどうしたって制約の多い環境であります。

ただ、そこに対して工夫する、というのもまた楽しめるところだとおもいます。
