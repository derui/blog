+++
title = "以前作ったtensorflowを使うprojectで2.0 betaを試してみた（動いてない）"
author = ["derui"]
date = 2019-06-30T14:19:00+09:00
lastmod = 2019-06-30T14:20:22+09:00
draft = false
+++

だいぶ前ですが、Tensorflowのメジャーバージョンアップである2.0のbetaがリリースされました。丁度いいので、以前作ったまま放置していたツールを更新してみようと思います。

<!--more-->

以前作ったのはこれです。Qiitaで記事も書きました。

<https://github.com/derui/painter-tensorflow>

<https://qiita.com/derui/items/fe232c87d981d241ae07>
<https://qiita.com/derui/items/9719efa14f44a792362b>

大雑把に言うと、着色済みの画像から線画を抽出するものと、その逆版です。現在ではこういう個人レベルのおもちゃではなく、実際にサービスとして運用されてるものもありますね。


## 1. まず公式サイトを確認する {#1-dot-まず公式サイトを確認する}

2.0-betaをインストールする方法は、公式サイトに載っています。ちゃんと確認しておきます。

<https://www.tensorflow.org/install>

また、今回対象にするものは、GPUが大前提なので、CUDAとかの条件も確認しておきます。このへんがしんどいので、普通はGoogle Colabとかを利用するのが良いかと。私は裏側の学習も兼ねてやっているので、頑張って整えていきます。

<https://www.tensorflow.org/install/gpu>


## 2. CUDAとかを色々用意する {#2-dot-cudaとかを色々用意する}

他のツールは触ったことがないのでなんとも言えませんが、TensorflowはかなりアグレッシブにCUDAのバージョンアップを行っている印象です。実際、2.0-betaでは以下を要求してきました。

> Hardware requirements
>
> The following GPU-enabled devices are supported:
>
> NVIDIA® GPU card with CUDA® Compute Capability 3.5 or higher. See the list of CUDA-enabled GPU cards.
>
> Software requirements
>
> The following NVIDIA® software must be installed on your system:
>
> NVIDIA® GPU drivers —CUDA 10.0 requires 410.x or higher.
> CUDA® Toolkit —TensorFlow supports CUDA 10.0 (TensorFlow >= 1.13.0)
> CUPTI ships with the CUDA Toolkit.
> cuDNN SDK (>= 7.4.1)
> (Optional) TensorRT 5.0 to improve latency and throughput for inference on some models.

私の持っているGPUは GeForce 1060なのでCompute Capabilityは確保できている・・・はず。

CUDAは、(Gentooであれば) `~amd64` キーワードを追加した上でemergeすると10.1が入るので多分大丈夫のはず。cuDNNは、NVidiaのDeveloper Programに参加しないとダウンロード出来ないので注意してください。なお、どちらもdebパッケージが提供されているので、こだわりがなければUbuntuを使うのがおすすめです。

なお、ここではnvidia-dockerのインストールとかは行いません。理由としては

-   direnvでpython環境を分離している
-   Gentooでnvidia-dockerを入れるのしんどい

というのが主な理由です。


## 3. 2.0.0の変更点 {#3-dot-2-dot-0-dot-0の変更点}

Tensorflowは以前はDefine by Run（確か）で、事前に定義した計算グラフを計算していく、という形式しか出来ませんでした。私がいじっていた段階だと、Eager Execution(Define and Run)の導入について議論されていた段階だと記憶しています。

しかもKerasが統合される前だったので、上で挙げたrepositoryでは、基本的にすべてlow level APIのみで構成されていました。ちなみに1.x系の最新だと、特に変更しなくても動いてくれました。


### APIのclean up {#apiのclean-up}

APIの名称、パッケージ、引数の名前、デフォルト値・・・などが諸々変更になっているようです。手動変更は基本的に推奨されていないようです。やりたくもないですが・・・。


### Eager executionがデフォルト化 {#eager-executionがデフォルト化}

現在のAPIからするとこれが一番大きそうです。session.runとかが基本的に不要になっているのに加え、pythonの関数や制御構造を変換するようにしているので、基本的に内部API的なものを触らなくてもよい感じになっています。

tf.condとかあったなぁ・・・。


### Globalの未使用へ {#globalの未使用へ}

1.xの場合、variableをトップレベルで宣言して〜とかが必要でした。global変数は基本的に避けるべき、というプログラミングの基本に則った感じです。


### Keras APIの猛push {#keras-apiの猛push}

Keras API＝高レベルAPIの利用を強くpushしています。Networkを積み上げるだけ、というような場合は十二分だし、色々やってくれるのですが、今回のものはもう結構いじってしまっているので、一旦これは見なかったことにしておきます。


## 4. upgradeの実施 {#4-dot-upgradeの実施}

1.xから2.xへのupgradeは、 [migration guide](https://www.tensorflow.org/beta/guide/migration%5Fguide)が作られています。この中で、upgrade scriptを用意してくれているので、これを流します。実行すると、report.txtというのが出てきます。

```shell
  $ pip install tensorflow-gpu==2.0.0-beta1
  $ tf_upgrade_v2 --intree line_art_painter --outtree line_art_painter_upgraded
  $ wc -l report.txt
518 report.txt
```

中々変換量が多かったですが、基本的にはrenameとかで済んでいます。が、一部自動的に変換できないものがありました。自動的に変換できなかったり、仕様変更に伴う注意が必要な点については、reportが出力されます。

```nil
TensorFlow 2.0 Upgrade Script
-----------------------------
Converted 4 files
Detected 8 issues that require attention
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
File: tflib_old/operations.py
--------------------------------------------------------------------------------
tflib_old/operations.py:8:11: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:13:11: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:38:17: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:42:15: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:63:24: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:64:25: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:86:24: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
tflib_old/operations.py:87:25: WARNING: tf.get_variable requires manual check. tf.get_variable returns ResourceVariables by default in 2.0, which have well-defined semantics and are stricter about shapes. You can disable this behavior by passing use_resource=False, or by calling tf.compat.v1.disable_resource_variables().
```


### tf.contribを使っている系 {#tf-dot-contribを使っている系}

tf.contribは2.0.0からそもそも同梱されなくなるので、使わないようにしましょう。今回、エラーが出たのはもう使っていないsourceだったので、消してしまいました。


### summary系APIの変更 {#summary系apiの変更}

summaryはいろいろ仕様が変更されたようなので、手動migrationが必要です。


### name\_scopeのre-entering廃止 {#name-scopeのre-entering廃止}

nameを指定した場合、一回しかscopeに入ることが出来ない、という感じのようです。eager executionがデフォルトになったことと関係がありそうです。


### compat.v1系統からの書き換え {#compat-dot-v1系統からの書き換え}

`tf.compat.v1` というパッケージに、1.xのAPIが移動されていて、これを（必要であれば）変えていく、という作業が必要です。もっとも、1.xで提供されていたAPIと同等のものがないので、compatパッケージを使っていく、というのももちろんありだと思います。

公式のmigration guideにも、普通にcompatパッケージを使っている例があるので。


## 5. いろいろ書き換え（進行中） {#5-dot-いろいろ書き換え-進行中}

列挙すると多すぎるので、書き換えしようとしているポイントだけ挙げます。

-   keras系統のLayerを利用したAPIに切り替える
    -   training関係（gradientを取得する方法やkeras形式のoptimezerとかに渡すとかが色々違う）や、Eager executionを利用するためにはだいたい必要
    -   ただし、training loop全体を書き換えると分量が多すぎる？ので、model部分に限って書き換えていって、その周辺は必要になってから書き換えていってもいいかもしれない
-   tensorboardへのhookを仕込む
-   Trainerの書き換え
    -   Trainer自体はそのまま使えるかもしれないが、eager executionの場合はあんまり使わない可能性が高い
-   summaryの書き換え
    -   Tensorboard上で画像とかを見えるようにする summary APIが別の形式？になったので、新しい方式に書き換える

特にKeras系統のLayerへの書き換えと、Sessionを利用しない実行形式に書き換えるのは、個人レベルで大分作ってしまっているとかなりのロスになる印象です。簡単にしていればまだいいかもしれませんが、少しライブラリ化とかしてしまっていると、移行コストがかなりかさんでしまう印象です。compatパッケージを恐れず、必要最小限の変更から始めていく、というのが大事かと思われます。

正直、Eager executionを使わないのであれば、1.x系のままで置いておいて、新しいものはKeras APIで作っていく、というのがいいんではないか？という印象です。興味本位だとかなり時間を取られると思うので、やろうとしている方は気をつけてください。

実際に書き換えできたらまた記事にしようかと思います。
