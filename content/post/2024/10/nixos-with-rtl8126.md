+++
title = "NixOSでRTL8126のNICを使えるようにした"
author = ["derui"]
date = 2024-10-14T20:05:00+09:00
tags = ["Linux", "NixOS"]
draft = false
+++

３連休がNixOSのセットアップで溶けました。どういうことなの。

New PCでNICが使えなかったのを、強制的にNixに習熟することでなんとかしてみました。

<!--more-->


## そもそもどういう状態だったのか {#そもそもどういう状態だったのか}

New PCはRyzen 9950XとX870のチップセットを利用しているんですが、今回マザーボードは[MAG X870 TOMAHAWK WiFi](https://jp.msi.com/Motherboard/MAG-X870-TOMAHAWK-WIFI)を利用しました。なんか７、８年ぶりくらいにMSIのマザーボードとなりました。

で、このマザーボードに乗っているNICが `Realtek® 8126-CG 5G LAN` という蟹さんことRealtekのNICなんです。ここまでならいいのですが、よく見ると **5G LAN** という不穏な文字があります。ようやく最近2.5GのLANが一般化したところですが、5GのLANなんて一般家庭で見たことありません。

<https://www.cnx-software.com/2024/06/18/realtek-rtl8126-5gbps-ethernet-pcie-and-m-2-adapters/>

多分商品としてはこいつなのですが、 **2024/06/18** という日付がさらに不穏です。

はい、NixOSのstable/unstableにあるKernelでは、このNICが使えませんでした・・・。 😢

> ちなみにインストールはどうしたのかというと、こういうときのためにUSBのGigabit ethernet（３，４年くらい前のやつ）を用意してあります。前回Gentooいれたときは2.5GのLANで同じ目に合いました。学習してない。

また、今回NixOSに全面的に切り替えた、ということで、そもそもこういうときにどうすべきか、の方針がなかなか立てられませんでした。


## 色々調べる {#色々調べる}

とりあえずいろいろ調べました。まず対象のNICに対するドライバーは公式から提供されています。

<https://www.realtek.com/Download/List?cate_id=584>

が、ここからのdownloadではsessionが必要です。こういう形式はNixでどうやればいいのか未だにわからんのでスルー。RTL8126自体はこのdriverで動く、というのは見かけました。

<https://forum.odroid.com/viewtopic.php?f=171&t=48523>

Edgeを走るFedoraの最新Betaですら入っていない、という絶望的な話題を見つけて震えました 😓 Linux 6.12で入りそう、という話を見て嘘やろ・・・となりました。

<https://discussion.fedoraproject.org/t/rtl8126-no-driver-on-fedora-41-beta/133250>

正直desktopだし、最悪USB NICでしばらく生活したらいいか・・・と思ったとき、次のrepositoryを見つけました。

<https://github.com/openwrt/rtl8126>

OpenWrtってなんぞや？と見てみると、組み込み向けのLinux Operation systemということでした。組み込み向けのdriverとかも色々ありそうでした。

さて、このrepositoryの眺めてみると、GPL2.0でRealtekの署名がしてあります。これを完全に信用するというわけではないですが、downloadできるsourceと比較してみると差分が存在しません。ということは、GPL2.0なので再配布している、ということでしょうか（Linuxのmainlineにいれる時点でそうなるはずですなので、mainlineに入るんでしょう）。

・・・じゃあこれをbuildしてmoduleに突っ込めばいいんでない？ということで、Nixでbuildしてみることにしました。


## nixでのdevice driverのbuild {#nixでのdevice-driverのbuild}

さて、こうなってくるとGooglingしてもなかなか出てきません。いくつか調べた感じでは、kernel開発をする、という記事は見つけました。

<https://blog.thalheim.io/2022/12/17/hacking-on-kernel-modules-in-nixos/>

ちなみに日本語での記事はほぼありませんでした。Edgeなhardwareに対してNixOSをいれる酔狂な人間はそういませんしね。

```shell
# Get development environment for current kernel
$ nix develop ".#nixosConfigurations.<hostname>.config.boot.kernelPackages.kernel"

$ KERNELDIR=$(nix build --print-out-paths ".#nixosConfigurations.$(hostname).config.boot.kernelPackages.kernel.dev")
```

こんな感じにすると、flakeで定義しているkernelのバージョンに対してmoduleのbuildを開始することができます。が、そもそもnix developとかnix-build自体がややこしい、というくらいなので、なかなかここからpackage作成に繋がりません。

ということで、nixpkgsから似ているpackageを探して流用することにしました。今回参考にしたのは同じRTL系列のものです。

<https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/rtl88x2bu/default.nix>

結論から言うと、kernel moduleはむしろ一般的な `make` だけで完結することがほとんどなので、 `stdenv.mkDerivation` だけで済むことがわかりました😂。一歩前進です。


## 通らないbuild {#通らないbuild}

いくつかMakefileの変更について試行錯誤をしたところ、makeが実行されるところまで来ることができました。しかしここで想定していない事態が。

実はRealtekのdriver、ダウンロードページには次のように書いてあります。

> 5G Ethernet LINUX driver r8126 for kernel up to 6.4

・・・up to 6.4？（今6.11.1。Gentooの影響で最新安定版を使っている）Linuxは互換性を重視している印象ですが、 **ABI** を重視しているのであって、ソースの互換性まではあまり気を使っていないということがよくわかりました。

発生していた差分は、大きく２つです。

-   `ethtool_eee` という型が、 `ethtool_keee` という名前になっていた
-   `ethtool_kee` のいくつかの型がu32の配列になっていた

最初は簡単な置換で良かったんですが、２個めに対する方針が課題でした。もともとu32だったのが、u32の配列になったというところで、今目の前にあるsourceでそこがどのようになるのか、全然わからないからです。とはいえethtoolの仕様とかdriverを読み解くとかすると、何日かかるかわかりません。

ここで、ABIは変わらないであろうということを考えると、 **配列の先頭が維持されるだろう** という希望的観測で編集することにしました。仮になんかあってもrollbackできるし、ということで。

結果としてのpatchは以下のようになっています。これでbuildは通りました。

<https://github.com/derui/my-nixos/blob/main/pkgs/kernel/rtl8126/ethtool_type_change.patch>


## package化してからのbuild {#package化してからのbuild}

```nix
{ lib
, stdenv
, fetchFromGitHub
, kernel
,
}:

stdenv.mkDerivation {
  pname = "rtl8126";
  version = "${kernel.version}-unstable-2024-06-23";

  src = fetchFromGitHub {
    owner = "openwrt";
    repo = "rtl8126";
    rev = "7262bb22bd3a20dfb47124c76d6b11587b3c5e78";
    hash = "sha256-SsmgsaGzOaRZl9RuUDbVnw+xr2AmC32FXEOgQpZSel8=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;
  makeFlags = kernel.makeFlags;

  prePatch = ''
    substituteInPlace ./Makefile \
      --replace-warn /lib/modules/ "${kernel.dev}/lib/modules/"
  '';

  patches = [
    ./ethtool_type_change.patch
  ];

  installPhase = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}/kernel/net/ethernet/"
    cp $NIX_BUILD_TOP/source/r8126.ko "$out/lib/modules/${kernel.modDirVersion}/kernel/net/ethernet/"
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Realtek rtl8126 driver";
    homepage = "https://github.com/openwrt/rtl8126";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
```

最終的にはこんな感じのdevationになりました。installやflagの渡し方とかは、元にしたパッケージがそのままになっています。さて、こいつをmoduleとして利用する必要があります。
moduleとして利用するためには、 `boot.extraKernelModules` に追加する必要があります。

今回のドライバーは自作パッケージと同様の扱いなので、callPackageしてから持ってきます。

```nix
{ lib, pkgs, inputs, config, user, ... }:
let
  linuxKernel = pkgs.linuxKernel.packages.linux_6_11;
  myKernelModules = import ./pkgs/kernel { inherit pkgs linuxKernel; };
in
{
  boot.kernelPackages = linuxKernel;
  boot.extraModulePackages = [ myKernelModules.rtl8126 ];
}
```

こんな感じです。（importとかにpkgsとかを渡すやり方でうまいやり方が未だにわかりません。ここでもpkgsを渡さないと動かなかったので渡してます）

ここまでやったら、 `nh os switch .` なりしてからrebootしました。


## 認識＆動作した:+1: {#認識-動作した-plus-1}

もともとはr8169で動かそうとしていて、知らないchipsetだからメンテナーに連絡してね、という悲しいメッセージだったのが、きちんと認識されました。

恐る恐るLANケーブルを差してみると・・・きちんとIPを掴んで通信ができました！最大800Mbbsとか出たので、きちんと動いているようです。


## 必要に駆られることの必要性 {#必要に駆られることの必要性}

今回、必要に駆られたので、今までやったことがないことを大量にインプットして実行しました。

-   Nixでのpackage作成
-   Nixでのdevice driverのpackage作成
-   そもそものdevice driverの中身
-   patchの適用の仕方
-   自作packageをmoduleの中で利用する方法
-   kernelのversionを変更してそれを利用する方法

Nixは学習曲線が急という話でしたが、色々と苦労する中で、１日強で実現することができました。人間必要に駆られると結構できるもんだ、と思います。

（まぁ休みで予定もなかったのでたっぷり時間が使えたということも大きいですが）

NixOSにしてから色々書き換えているので、次はEmacsについて書こうかと思います。
