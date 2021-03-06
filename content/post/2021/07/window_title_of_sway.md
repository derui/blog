+++
title = "swayでwindowのタイトルを出したい"
author = ["derui"]
date = 2021-07-07T20:37:00+09:00
lastmod = 2021-07-07T20:37:42+09:00
tags = ["Linux"]
draft = false
+++

7月も半ばに差し掛かりつつありますね。今年はオリンピックのために4連休なので、このタイミングで小旅行に行く予定です。

今回も大分ライトな話題で、swayに今利用しているアプリケーションのタイトルを出したいという話です。

<!--more-->


## swayとswaybar {#swayとswaybar}

[sway](https://github.com/swaywm/sway)には、swaybarという最上部にあるbarを表示するためのアプリケーションが付属しています。これは[i3](https://i3wm.org/)にあるi3barとほぼ同様の機能を提供しています。

・・・が、このswaybarには一つ不足している機能があり、 **アプリケーションのタイトルを表示する** という機能が無いのです。

<https://manpages.debian.org/experimental/sway/sway-bar.5.en.html>

個人的に、 <https://github.com/takaxp/org-onit> を利用して時間を計測するようなワークフローになっているため、タイトルが出ていると非常に助かります。

> モードラインに出せば？という意見もあると思いますが、モードラインはすでに色々な情報で一杯なので、これ以上増やしてもなー、というのがあります


## swaybarの代替探し {#swaybarの代替探し}

swaybarの代替としては、自前でスクリプトを書くというのもありますが、代替もあります。

その中で一番使われている(と思う)のが、waybarです。

<https://github.com/Alexays/Waybar>

swayのみならず、wlrootをベースとしたcompositerで利用できるようになってます。

こいつだと、タイトル以外にも、色々と表示させることができますし、カスタマイズ性もかなり高いです。というわけで、これを使ってみることにしました。


## waybarのカスタマイズ {#waybarのカスタマイズ}

さて、waybarには二つの設定ファイルがあります。一つはwaybar自体の挙動 = 表示する位置やモジュールの種類、位置や設定を設定するためのJSON、そしてスタイリングをするためのCSS、という設定ファイルがあります。

```js
{
  "layer": "top",
  "modules-left": ["sway/workspaces", "sway/mode"],
  "modules-center": ["sway/window"],
  "modules-right": ["temperature", "memory", "clock"],
  "sway/window": {
    "max-length": 50
  },
  "memory": {
    "interval": 10,
    "format": "{used:0.1f}GiB/{total:0.1f}GiB"
  },
  "clock": {
    "interval": 5,
    "format-alt": "{:%4Y/%2m/%2d  %H:%M:%2S}"
  },
  "temperature": {
    "hwmon-path": "/sys/class/hwmon/hwmon1/temp1_input",
    "critical-threshold": 80,
    "format": "{temperatureC}°C"
  }
}
```

設定ファイルはこんな感じにしています。temperatureのところは個々人で違いますが、私の場合はCPUの全体的な温度となっています。これ以外にもGPUの温度を出したりもできるはずです。

CSSですが、これはかなり巨大なので、 <https://github.com/derui/dotfiles/blob/master/waybar.style.css> を参照してもらった方がよいかと・・・。ちなみに、変更点としてはbar全体の高さやフォントの設定くらいです。


## カスタマイズしていきましょう {#カスタマイズしていきましょう}

せっかくlinuxやswayを利用しているのであれば、かなり自分の好みに合わせて変更していくことができます。これはMac/Windowsにはない利点です。当然ながらそのためには色々調べたりしないといけないですが、その結果として自分のやりやすいようにできていけば、それはそれでよいんではないでしょうか。

ちなみに私は結構デフォルトで満足してしまう(最近はデフォルトでも十分なケースが多い)方ですが、やりづらい場所はできるだけ改善していきたいなぁ、と思ってます。