+++
title = "改めてQEMUを使って仮想マシンを起動してみる"
author = ["derui"]
date = 2024-10-05T16:19:00+09:00
tags = ["Linux"]
draft = false
+++

一気に凉しくなって、いきなり着るものに困っています。極端ですな。

昔から知っていましたが、よく思い返してみると触ったこともなかったので、QEMUをきちんと触ってみました。

<!--more-->


## そもそもQEMUとは {#そもそもqemuとは}

> QEMU is a generic and open source machine emulator and virtualizer.
>
> <https://www.qemu.org/docs/master/about/index.html>

とあるように、emulatorとvirtualizer、つまり仮想化をするためのソフトウェアです。QEMU自体はとても昔から開発されており、Windows/macOSを含めてmulti platformで展開されています。

最初はCPU emulationのために作られた、という話があるため、古今東西のCPUを指定して仮想マシンを起動することができます。


## 最初の仮想マシン {#最初の仮想マシン}

なんらかの方法でqemuをインストールしたら、とりあえずcommandを実行してみましょう。

```shell
$ qemu-system-x86_64
```

起動すると、Windowと共に真っ黒な画面が表示されるはずです。QEMUはdefaultではSeaBIOSというOSSのBIOS実装を利用して起動するので、マザーボードに電源だけいれた、という状態ですね。これだけだと意味がないので、なんかisoを入れてみましょう。

```shell
$ qemu-system-x86_64 -cdrom ubuntu.iso
```

見おぼえのあるubuntuのinstallerが起動します。なんか適当に選んでみましょう。

起動してみると、起動した瞬間にkernel panicしているはずです。QEMUは、指定がないとmemory/CPUも設定されていない（！）ので、このままでは何もできません。このあたり、大体いい感じの設定がbattery includedされている最近の風潮とは一線を画しています。


## CPUとmemoryの設定 {#cpuとmemoryの設定}

CPUとmemoryがないとなにもできないので、追加してみましょう。

```shell
$ qemu-system-x86_64 -m size=4096 \
  -smp 8 \
  -cdron ubuntu.iso
```

`-m` でmemoryの量を指定できます。基本的にMB単位での指定です。 `-smp` で、仮想マシンで利用するCPUの数を指定できます。


## networkの有効化 {#networkの有効化}

当然ですがNICなんてものは最初から入っているわけではないので、NICについても指定する必要があります。QEMUのnetworkにはuser mode networkというemulation modeがあり、大抵はこれで用が足ります。

```shell
# localhost:2222を22と接続する
$ qemu-system-x86_64 \
  # network deviceを追加する
  -device virtio-net-pci,netdev=unet \
  # netdevでdeviceに対する設定を追加する
  -netdev user,id=unet,hostfwd=tcp::2222-:22 \
      -m 4096 \
      -smp 10 \
      -cdrom ubuntu.iso
```

`hostfwd` を指定すると、port forwardingができるので、guestとSSHで繋いで～というのがお手軽にできます。設定しておくと捗りますよ。

ちなみにこの設定だけで、wgetとかcurlとかは大体動作します。ただ、pingは何もしない状態だと許可されていないので、必要ならsysfsで許可する必要があります。以下が参考になります。

<https://www.qemu.org/docs/master/system/devices/net.html#using-the-user-mode-network-stack>


## storageを追加する {#storageを追加する}

さて、いざインストール・・・というところで、storageがないぞ？となるかと思います。storageも当然ないので、作る必要があります。

qemuに同梱されている `qemu-img` を利用することで、QCOW形式などQEMUで利用できるblock deviceを作製することができます。VirtualBoxなどを利用したことがある方は、 `.qcow2` とかの拡張子を見たことがあると思いますが、あれになります。

```shell
$ qemu-img create <file path> <size>

# nixos.qcow2を10GiBのサイズで作る
# k/m/g でそれぞれ指定できる
# -fで指定しないとRAW formatで作られるので、指定された容量がそのまま割り当てられる
$ qemu-img create -f qcow2 nixos.qcow2 10g

# 利用するときは -hda などに渡すことで、block deviceとして利用できる。
$ qemu-system-x86_64 -hda ./nixos.qcow2
```

`-hda` に渡すと、大抵は `/dev/sda` として認識されますので、あとはpartedやfdiskで料理できます。


## UEFIで起動する {#uefiで起動する}

さて、なにがしかをinstallしていると、最近のdistributionはUEFIでの起動が前提になっているケースが多いでしょう。そうなると、ここまでの設定だと動きません。UEFIはUEFIの設定が必要になります。

[OVMF](https://github.com/tianocore/tianocore.github.io/wiki/OVMF)というOSSのUEFI実装があり、これが広く使われています。これを次のように利用します。

```shell
# UEFIの設定変更などはここに入るので、専用にcopyしておく
$ cp <path of ovmf/OFMV_VARS.fd .

# UEFIはbiosではないので、 -bios オプションは利用しなくてよい
$ qemu-system-x86_64 \
      -drive if=pflash,format=raw,file=/usr/share/edk2-ovmf/OVMF_CODE.fd,readonly=on \
      -drive if=pflash,format=raw,file=./OVMF_VARS.fd \
      -enable-kvm \
      ...args
```

OVMF.fdだったりしますので、ファイル名やパスは、ご利用のdistributionを参照下さい。 `OFMV_VARS` 的なファイルは、 **UEFIの設定変更** が入るため、基本的には個人毎にcopyしておくのが推奨です。


## QEMUで使い捨ての自由なemulation環境を {#qemuで使い捨ての自由なemulation環境を}

QEMUはKVMなども利用することで、準仮想化をすることができます。NVMeとかのemulationもできたり、GPUの利用などもできます。使ったことのないsoftwareの素振りや、完全に分離された作業環境が必要なときなどにいかがでしょう。

ちなみに、CLIからやるのは一般的ではないので、大抵はvirt-managerとかから利用することになります（私は使ってないですが）。

さて、いきなりなんでこんな記事を書いたのかというと、次の記事へ繋げるため、という感じになります。
