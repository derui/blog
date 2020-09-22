+++
title = "Windows10 + WSL2で環境を整えた"
author = ["derui"]
date = 2020-08-08T16:20:00+09:00
lastmod = 2020-09-22T10:41:00+09:00
tags = ["Windows", "Emacs"]
draft = false
+++

帰省のイベントである、自分のノートPC（Windows10）に開発環境を整備する時期になったので、今回はVagrantからWSL2を使ったものにしてみました。

見切り発車ですので出来るかどうかは不定です。ではいってみましょう。

<!--more-->


## 不安な点 {#不安な点}

いつもはVagrant上に構築したX11環境で開発していたわけですが、今回はWSL2になるということで、いろいろ考える必要がありそうでした。

-   WSL2ではUbuntu20.04/Debian/SUSEくらいしか使えない
    -   いつもはArchLinuxを使っているので、色々と不安な点が・・・
-   Xserverが必要
    -   Windows上のX serverを入れる必要があります
-   自分のdotfileが使えるのか・・・？
    -   Gentoo/Archlinux用になっているようなものなので、色々厳しそう？


## 今回の要件 {#今回の要件}

以下を目標にします。努力目標は `OPT` がついてます。

-   EmacsをGUIで使える
-   自分のdotfile/.emacs.dを使えている
-   OCaml/opam/Node.jsが入っている
-   `(OPT)` Emacsからmozc\_emacs\_helperを通してWindows上のGoogle日本語入力を使えている
-   `(OPT)` EmacsからWindowsの方のブラウザとかを使える

Emacsとterminalだけで大体生きてるOld typeなので、これくらい出来ればだいたい何とかなります。


## WSL2のインストール {#wsl2のインストール}

いつものごとく画像はありませんがご容赦を。以下の手順でWSLを有効にします。なお、前提としてWindowsのOS versionがMay Update以降である必要があります。お気をつけて。

> アップデートが必要なことを忘れていてだいぶ時間を食ったのは内緒です

インストールと更新方法は、Microsoftの公式ドキュメントが詳しいのでそっちを見ましょう。

<https://docs.microsoft.com/ja-jp/windows/wsl/install-win10>

一応手順を書いておきます。

1.  PowerShellを管理者権限で開く
2.  `dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart`
3.  `dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart`
4.  再起動する
5.  またPowerShellを管理者権限で開く
6.  `wsl --set-default-version 2`
7.  なんかURLが表示されるので、アクセスしてWSLのkernel updateを入手してインストールする
8.  Windows StoreからWSLのディストリビューションをダウンロードする（今回はUbuntu 20.04を選択）
9.  Windows Storeからダウンロードしたディストリビューションを起動する
10. しばらく待つ（数分程度）
11. UNIX username/passwordを入れる。Windows usernameと同じにしとくのが無難な模様

これでいけるはずです。WSLにアクセスする時は、Windows TerminalとかcmdとかPowerShellとかお好きなもので `wsl` と打てば、デフォルトで設定されているディストリビューションに対してアクセスできます。


## WSLにいろいろインストール {#wslにいろいろインストール}

WSL2は普通のLinuxなので、色々設定をしていきます。ただ、WSL2は若干特殊な環境なので、systemctlは使えないものと考えるのが良さそうです。

timezoneはだいたい初期状態で問題なさそうでした。

```sh
$ sudo apt install git vim build-essential python3-venv direnv golang fish fzf emacs x11-xserver-utils x11-xkb-utils opam autoconf
## dbusが動いていないので、systemctlに頼らない方法で設定していく
# ja_JP.UTF-8からコメントを外す
$ sudo vim /etc/locale.gen
$ sudo locale-gen
$ sudo update-locale ja_JP.UTF-8
# 105を選択→国でJapaneseを選択→基本的にはそのまま
$ sudo dpkg-reconfigure keyboard-configuration
# 個人的に必須なのでghqを入れる
$ go get github.com/x-motemen/ghq
# 後でEmacs 27を入れるので、一回消す
$ sudo apt uninstall emacs
$ python3 -m venv ~/.virtualenv
# <dotfileなどなどをインストール>
```


## X serverのインストール {#x-serverのインストール}

次に、GUIのEmacsを使えるように、X serverをWindows側にinstallします。ここではVcXsrvを使います。

<https://sourceforge.net/projects/vcxsrv/>

難しいことはなく、ダウンロードしてinstallしてください。Chocolateyとかhomebrewを使っている場合はそちらからインストールするのもいいかと。


## DISPLAY環境変数の設定とxhostの起動 {#display環境変数の設定とxhostの起動}

WSL2は、物理的に異なるマシンであるのとほぼ変わらないので、母艦のマシンとは異なるIPが振られています。そのため、母艦のX serverと通信するために、DISPLAY環境変数を動的に設定する必要があります。また、母艦のxhostをWSLから使うことで、動的に許可を行えるようにします。

<https://w.atwiki.jp/ntemacs/pages/69.html>

ここを参考にして、以下のようになりました。

```sh
# WSL_DISTRO_NAMEにDistributionの名前が入っているので、これが設定されていたらWSLの内部と判断する
if [[ "$WSL_DISTRO_NAME" != "" ]]; then
    cd '/mnt/c/Program Files/VcXsrv'

    export DISPLAY=127.0.0.1:0.0
    WSLENV=DISPLAY ./xhost.exe + $(ip -4 a show eth0 | grep -oP '?(<=inet\s)\d+(\.\d+){3}')

    export DISPLAY=$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf):0.0

    # VcXsrvの起動時にuse native OpenGL・・・みたいなオプションを有効にしておく必要がある
    export LIBGL_ALWAYS_INDIRECT=1
fi
```

こいつを `.profile` に追記します（.profileなのは、私のdotfilesにおける設定の都合上です）。

試しにWSLからxevとかxeyesとかを起動して、ちゃんと起動できれば成功です。


## Emacsのビルド {#emacsのビルド}

Emacs 27では、目玉機能の一つとして、native json（Cで実装されたJSON library）を使うことが出来ます。LSPとかを使う時、JSONを処理する速度で10倍くらい速度が違うので、こいつがあるかないかは重要なのです。

> 記事の作成時点では、27.1がRCになっているので、いずれビルドしなくても良くなるかなーと思います。

```sh
$ sudo apt install libgtk-3-dev libjson-c-dev libjpeg-dev libgnutls28-dev libgif-dev
$ mkdir work && cd work
$ git clone --depth=1 https://github.com/emacs-mirror/emacs.git
$ git switch emacs-27
$ ./autogen.sh && ./configure --with-json --without-makeinfo --without-xpm --without-tiff && make -j6
# 確認
$ ./src/emacs --version
```

最終的にmake installするかどうかは好みかなーと思います。


## Nodejsのインストール {#nodejsのインストール}

nodejsは、aptからインストールせずにnodenvを使ってインストールしてみます。デスクトップではnodebrewを使っていて特に困っていないのですが、たまには新しいものも使ってみます。

なお、nodenvはanyenv経由でインストールします。anyenvはもう設定できてる前提としときます。

```sh
$ anyenv install nodenv
# 新しいセッションで
$ nodenv install 14.7.0
$ nodenv global 14.7.0
# 新しいセッションで
$ npm install -g yarn
```


## opamとかのインストール {#opamとかのインストール}

は、上で終わっています。opamの設定とかは省略です。


## 日本語入力について {#日本語入力について}

このままだと、Emacs上で日本語入力が出来ない状態（まぁあんまり困らないケースもあるかと思いますが・・・）です。

WSL1上でGoogle日本語入力を使う方法としてはこちらに情報がまとまっています。

<https://w.atwiki.jp/ntemacs/pages/50.html>

WSL1の情報がどれだけ流用できるのか？が不明ですが、xhostの設定とかは動くようなので、もしかしたら動く？かもしれません。安牌なやり方としては、普通にaptでmozcを入れる、というのもあります。特に設定を共有できることにこだわりはないので、こっちにする可能性が高いです。


## とりあえず作業ができるようになりました {#とりあえず作業ができるようになりました}

一通り導入が終わったので、後はlspが動くかとかを確認していく感じになります。開発環境はWSL2、環境の作り捨てはVirtualBox、というように棲み分け出来そうなイメージが出来てきました。

とりあえず使ってみてまた書けることがあれば書こうと思います。
