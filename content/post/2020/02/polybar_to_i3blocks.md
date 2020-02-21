+++
title = "polybarからi3blocksに乗り換えてみた"
author = ["derui"]
date = 2020-02-21T16:01:00+09:00
lastmod = 2020-02-21T16:01:13+09:00
tags = ["Linux"]
draft = false
+++

今年の冬は本当に暖冬で、今から今年の夏が心配です。水不足的な意味で。

時事ネタは置いといて、最近デスクトップのbarをpolybarからi3blockに移行したので、なんで移行したのかとかを書いておこうかと思います。

<!--more-->


## i3blocks {#i3blocks}

[i3blocks](https://github.com/vivien/i3blocks)は、その説明にあるとおり、text-baseなstatus barです。[polybar](https://github.com/polybar/polybar)もだいたい同じような感じですね。これらの違いを個人的にあげてみます。

-   polybar
    -   feature rich
    -   設定ファイルでだいたい何でもやる
    -   組み込みで結構な量のmoduleがある
-   i3blocks
    -   本体機能は必要最小限
    -   組み込みのmoduleはほぼ無い

i3blocksは、組み込みmoduleとかがほぼない代わりに、moduleから返された結果を表示するだけ、というシンプルな形式に割り切っています。そのため、複雑化しやすい（個人の意見です）polybarよりも設定ファイルがシンプルになります。


## polybarから乗り換えた理由 {#polybarから乗り換えた理由}

polybarは、その組み込みmoduleが多いことも相まって、コンパイル時の依存が多いです。出来るだけ依存を少なくしたいのと、利用しないmoduleが多かったというのもあり、他のstatus barを検討していました。

i3blocksは1.4まではデフォルトでmoduleを用意していましたが、1.5で大きく変更され、i3blocks本体は最小限で、moduleは全て[i3blocks-contrib](https://github.com/vivien/i3blocks-contrib)に分割されています。(blockletと読んでいるようです）。このため、必要なものを自分でさっくり作るなり、必要なscriptだけを取得するとかが簡単です。

また、色とかもmodule内で出力することで個別に変更できるため、別ファイルにまとめておいて読み出す、とかもできます。configにまとめるのとどっちがいいか、というのはありますが・・・。


## i3blocksの設定 {#i3blocksの設定}

```conf
color=#8fa1b3

[title]
command=~/.config/i3blocks/scripts/title.sh
interval=persist

[uptime]
label=
command=uptime | sed 's/.*up \([^,]*\),.*/\1/'
interval=60

[memory]
label=
command=~/.config/i3blocks/scripts/memory.sh
interval=1

[load average]
label=
command=echo "$(uptime | sed 's/.*load average: \(.*\)/\1/' | cut -d, -f1)/$(grep 'processor' /proc/cpuinfo | wc -l)"
interval=1

[date]
label=
command=echo " $(date '+%Y/%m/%d %H:%M(%a)')"
interval=1

[power]
label=
command=~/.config/i3blocks/scripts/power.sh
interval=persist

[separator]
```

実際に使っているconfigです。polybarと違い、各moduleの設定は同一で、違うのはcommandとかintervalの中身だけ、という統一感がいい感じです。

各command内は、シンプルにbash scriptを呼んでいるだけです。polybar同様、実行さえ出来ればPythonでもrubyでもなんでもOKです。


## これからの課題 {#これからの課題}

polybarの方が優れていたのが、電源周りのmoduleが用意されており、それが結構使い勝手が良かったことです。i3blocksは当然デフォルトでは用意されていないので、自分でいろいろやることになります。

`interval=persist` という設定を入れると、そのスクリプトを起動しっぱなしにしても大丈夫になるので、それを利用しています。一応動作はしているのですが、もうちょっとなんとかならんか・・・というところで止まっています。

デフォルトで用意されている（battery included）ことを拒絶した以上、自分で解決する必要があるのはそのとおりなので、もうちょっと試行錯誤してみようと思います。i3wmを利用している方は一回試してみると、また新しい何かが見えるかもしれませんよ？
