+++
title = "GitHub Actionsでrelease processを作ってみた"
author = ["derui"]
date = 2020-11-08T10:17:00+09:00
lastmod = 2020-11-08T10:18:00+09:00
tags = ["OCaml"]
draft = false
+++

私用でいろいろ忙しく、部屋の中がとっ散らかってしまっています。いらないものを整理していくのは大事・・・。

さて、今回はちょっと前につくった、GitHub Actionsを使ったリリースプロセスについてちょこっと書いてみます。

<!--more-->


## GitHub Actionsとは {#github-actionsとは}

<https://docs.github.com/en/free-pro-team@latest/actions/learn-github-actions>

内容については、公式が詳しいのでそっちで。すげー簡単に言うと、GitHubに統合されたCodeBuildみたいな感じです。

> GitHubがMicrosoftに買収されたことが影響しているのか、GitHub Actionsの中身はAzureの仮想マシンを使っているようです。公式ドキュメントに書いていたかと。

GitHub上にあることの利点としては、リポジトリとかの認証がいらず、かつソース上の設定とめっちゃ近いので、コンテキストの切り替えコストが低くなります。


## GitHub Actionsの基本 {#github-actionsの基本}

自分の理解を試すために、ちょっとだけ基本的な概念だけ書いておきます。

Actionsは、 **Event** 、 **Runner** というランタイム的なものと、 **Job** > **Step** > **Action** という階層構造の定義があります。

このEvent/Runner/Jobを合わせて、 **Workflow** と呼ばれます。Github Actionsは、このWorkflowという単位で定義を作ります。

また、 **Job** はデフォルトで並列で動作するようになっています。（なので、これを忘れて上から動くような感じで書いてしまうと、全部一気に動いて大体エラーになる、ということになります）


## 作ったrelease flow {#作ったrelease-flow}

<https://github.com/derui/sxfiler/tree/master/.github/workflows>

こういうのを作りました。tagをpushするといろいろビルドして、最終的にGitHub Releaseを作成するようなフローになっています。

詳細は中身を見てほしいんですが、いくつかハマりポイントがありました。


### Jobごとに異なる環境で動く {#jobごとに異なる環境で動く}

ちゃんとドキュメントを読めば書いているんですが、jobは各々 **完全に独立した環境** で動作します。CodeBuildとかとは設定のレベルが違うので、割と混乱しました。

完全に独立した環境、なので、各々の環境でcloneしてこないとなりません。これもしばらくなんでやろ・・・？と思ってしまった感じでした。あんまりjobを複数使ったり、というのは、シンプルなOSSとかだと無いと思います。


### Dockerは普通に使える {#dockerは普通に使える}

各環境は単独の仮想マシンなので、普通にDockerが使えます。性能も意外と悪くない（2vCPU/7GiB）です。

ただ、私の作ったDockerfileみたいに、めっちゃ重いDockerfileを使う場合は、セオリー通りDockerHubとかにbuild済みのイメージをpushしておくのが良いです。


### job間のファイルやり取りはartifactで {#job間のファイルやり取りはartifactで}

job間は特に関連がないので、個々のJobで出来たものをまとめたりする場合、artifactを使う必要があります。

Releaseを作って、アセットをアップロードする場合は、大抵１つのJobにまとめられると思います。こういう場合はartifactを使う必要があります。


### cacheはjob毎 {#cacheはjob毎}

cacheを利用する場合、基本的にはGitHub公式のActionを使うと思います。このcache、 **Job毎** の定義になったりするみたいでしたので、複数のJobでキャッシュを使いたい場合はこの辺を注意する必要がありそうです。


## 使える場面は使っていきたい {#使える場面は使っていきたい}

企業で使う場合は色々な事情があったり、一極集中を避けようとCircleCIとかを使ったり、というのはあると思います。が、OSSとか個人開発とかで、そういったこだわりがない場合は、GitHub Releaseとかの連携がスムーズ（当たり前）だったり、並列で動かしても特にペナルティが無かったりと、結構優遇されています。

使ったことがない場合は一度試してみると、色々発見があると思います。ぜひ。
