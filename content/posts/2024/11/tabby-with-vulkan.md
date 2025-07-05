+++
title = "tabbyをvulkanで使えるようにしてみた"
author = ["derui"]
date = 2024-11-14T23:26:00+09:00
tags = ["Linux"]
draft = false
+++

暖かくなったり寒くなったりと格好が定まりませんね。

さて、最近tabbyというツールを知ったので、NixOS上で使ってみました。

<!--more-->


## tabbyとは {#tabbyとは}

<https://tabby.tabbyml.com/docs/welcome/>

これです。

> Tabby is an open-source, self-hosted AI coding assistant. With Tabby, every team can set up its own LLM-powered code completion server with ease.

引用すると、self-hostedなAI coding assistantということで、self-hostedなGitHub Copilotといったところでしょうか。特徴として、

-   全体がオープンソース
    -   enterpriseという形でlicenceを発行してはいますが、enterprise向けの内容もrepositoryに入ってます
-   server/frontも全部入り
    -   Ollamaはbackendだけですが、VS Code Extensionやllama.cppを利用したmodel servingなどもincludedです
    -   frontendとしてSPAが用意されていて、補完の回数とかaccept rateとかが見られます

ということでいつもの通りnixpkgsで調べたところ、見つけたので入れてみました。ていうかnixpkgsなんでもありすぎだろう。


## buildが通らない {#buildが通らない}

<https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ta/tabby/package.nix>

ところが、rocmを指定したところ、そもそもビルドが通りません :cry: どうも、tabbyはllama.cppのRust bindingを利用しているようなのですが、cargo buildのタイミングでllama.cpp自体をビルドするようです。このとき、CMakeが必要なんですが、これが足りてませんでした。（手元にRadeonなりがないとどうしても確認ができないので、こういうことはよくある印象です）

ただ、追加しても今度はrocm自体の依存が不足しているようでした。諸々調べると、 **そもそもllama.cppはすでにビルドしているんだからそれ使おうよ** というアプローチが取られていました（それでもbuildは失敗するのですが :thinking:）。


## CPUしか使ってくれない {#cpuしか使ってくれない}

Rocmを切るとbuildは通るのですが、まーCPUだけだと32 coreのCPUですら使い物になるか怪しいくらいの性能しか出ないです。llama.cppは実はvulkan APIを利用したGPU offloadがサポートされているのですが、nixpkgsにmergeされている版だと対応されていません。

こうなってくると、いつものようにoverlayを作成する形になります。

<https://github.com/derui/my-nixos/blob/main/overlays/tabby/package.nix>

ただ、tabbyは通常serviceとして動かすようなものっぽいので、できればserviceも使いたいです。が、nixpkgsのserviceではvulkanを指定することができません。

> acceleration = lib.mkOption {
>
> type = types.nullOr (types.enum [ "cpu" "rocm" "cuda" "metal" ]);
> default = null;
> example = "rocm";
> description = ''
>   Specifies the device to use for hardware acceleration.
>
> -   \`cpu\`: no acceleration just use the CPU
> -   \`rocm\`: supported by modern AMD GPUs
> -   \`cuda\`: supported by modern NVIDIA GPUs
> -   \`metal\`: supported on darwin aarch64 machines
>
> Tabby will try and determine what type of acceleration that is
> already enabled in your configuration when \`acceleration = null\`.
>
> -   nixpkgs.config.cudaSupport
> -   nixpkgs.config.rocmSupport
> -   if stdenv.hostPlatform.isDarwin &amp;&amp; stdenv.hostPlatform.isAarch64
>
>       IFF multiple acceleration methods are found to be enabled or if you
>       haven't set either \`cudaSupport or rocmSupport\` you will have to
>       specify the device type manually here otherwise it will default to
>       the first from the list above or to cpu.
>     '';
>
> };

となると、Serviceもoverlayする感じになります。が、これのやり方が大分わかりません。色々調べてみたところ、公式としては `disabledModules` を利用しろ、とのことでした。

```nix
# disabled original module
disabledModules = [ "services/misc/tabby.nix" ];
```

指定するpathはstoreからの相対pathなどを指定できます。これを指定したあと、moduleを再定義することで、カスタマイズしたmoduleを利用できます。


## tabbyのclient {#tabbyのclient}

いつもの如く、Emacsからしか使わないので、Emacsのtabby用clientを導入しています。

<https://github.com/alan-w-255/tabby.el>

大体はcopilot.elと同様の使い勝手です。vulkanで利用していますが、大体0.3秒位で補完されるので、そこまでストレスではないです。ただ、どんだけresourceを突っ込んでいるかわからないGitHub Copilotとかと比較すると、精度としてはいまいちと感じることが多いです。あくまで補助といったところですね。


## Ollamaをbackendにすることもできる {#ollamaをbackendにすることもできる}

設定をすることで、Ollamaを利用してcompletionとかを行うこともできます。modelの自由度はこっちのほうが圧倒的に高いので、量子化されたmodelを使いたい、とかの場合は検討してみてはいかがでしょうか。NixOSならRocmを有効にしてbuildできますよ。
