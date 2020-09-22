+++
title = "zshからfishに移行してみた"
author = ["derui"]
date = 2019-02-12T22:23:00+09:00
lastmod = 2020-09-22T11:21:11+09:00
tags = ["Shell", "zsh", "fish"]
draft = false
+++

一ヶ月くらい[Eucalyn配列](http://eucalyn.hatenadiary.jp/entry/about-eucalyn-layout)でできるだけ生活していたら、CorneでQWERTYが全然打てなくなっててびっくりしました。ノートPCのキーボードではちょっと引っかかるけど普通なので、Corne用の脳領域が出来たようです。

それは置いておいて、つい最近zshからfishへ移行してみましたので、関連する諸々をメモしていこうかと思います。

<!--more-->

fishや他のdotfilesは以下で管理しています。

<https://github.com/derui/dotfiles>


## 移行の動機 {#移行の動機}

**なんとなく。**

いきなりこう書くのもどうかとは思いますが、実際↑の通りなので。元々はzshを5年くらい使っていましたが、ここ2年くらいはほとんどカスタマイズとかもすることなく、完全に惰性で利用している感じでした。

zshはemacs/vimのようにカスタマイズを極めれば最高なのは確かなんですが、その時間自体を取れなくなってきた、というのが主な理由です。それと、結構前からfish推しの声を聞いてきたので、試してみたいというのもありました。


## 移行プラン {#移行プラン}

zshからfishに移行するにあたり、何が必要か？を洗い出してみました。

-   plugin manager
-   fzf + ghq/historyの連携
-   各種補完

    ・・・めっちゃ少なかった。ので、移行自体はさらっと行けました。


### plugin manager {#plugin-manager}

zshではzplugを利用していましたが、fishでは[fisher](https://github.com/jorgebucaran/fisher)を利用しました。次のような感じでインストールしました。

```fish
# install fisher
if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end

# change location of packages installed by fisher
set -g fisher_path ~/.config/fish/fisher-pkg

set fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..-1]
set fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..-1]

for file in $fisher_path/conf.d/*.fish
    builtin source $file ^ /dev/null
end
```


### fzf + ghq/historyの連携 {#fzf-plus-ghq-historyの連携}

zshでは、どこかから拾ってきたfunctionをそのまま利用していたのですが、fishでも同じようにして探してきました。

探した後で気づきましたが、fisherでpluginをインストールしたらいいやん、ということで、面倒なことをする前にpluginを探してインストールするのがいいと思います。


### 各種補完 {#各種補完}

そもそもzshでもそんなにいじっていなかったので、fishのデフォルトで必要十分でした。


## powerlineの導入 {#powerlineの導入}

fishへの移行ついでに、powerlineに再度チャレンジすることにしました。virtualenvを有効にしている状態が前提になっていますが、以下のようにしてsetupしています。

```fish
# enable powerline if extsts
if test -x (which powerline)
    set _powerline_repository_root (pip show powerline-status | egrep "^Location: " | sed -e 's/Location: \+//')
    set fish_function_path $fish_function_path "$_powerline_repository_root/powerline/bindings/fish"
    powerline-setup
    if test (pgrep powerline | wc -l) -eq 0
        powerline-daemon -q
    end
else
    echo "Powerline not found"
end
```

設定はGithubを確認してもらえるといいんですが、記述時点では次のような感じで表示されています。

{{< figure src="/ox-hugo/1549977071.png" >}}

よくpowerlineの紹介では、一行に全部表示しているような設定が多いんですが、内容によってプロンプトの位置が激しく移動するのが気に入らなかったので、複数行で表示するようにしています。元々zshでも複数行のプロンプトを利用していたこともあり、こっちのほうが違和感ないです。


## 移行してみて {#移行してみて}

zshからfishに移行してみてまだ数日ですが、すでに大体問題なく運用できています。スクリプトの書式がPOSIX標準と異なるとかありますが、そもそもそんなに書かないので、あまり気になりません。Rubyとかを利用している人にとってはむしろ違和感が少ないのではないでしょうか。

移行したてで問題点が見えていない面もありますが、とりあえずfishはおすすめできますので、bashで十分と思っている人も、zsh最高な方も、一度試してみてはいかがでしょうか。
