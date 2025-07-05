+++
title = "Ollamaをnixos上で使えるようにしてみる"
author = ["derui"]
date = 2024-11-02T13:46:00+09:00
tags = ["Linux"]
draft = false
+++

やっと秋めいてきましたが、なんか台風がきたりと落ち着かない感じですね。

今回NixOSに移行したことで、色々やっても戻せるという確信が大体ついたので、Local LLMに手を出してみました。

<!--more-->


## Ollamaとは {#ollamaとは}

<https://github.com/ollama/ollama>

簡単に書くと、 **LLMのmodelを切り替えながら統一したinterfaceで実行できる環境** を提供するツールです。元々はLlamaというMetaが出しているmodelを利用するために作られたみたいですが、今では[Model library](https://ollama.com/library)というところからダウンロードして使えるようになっています。

通常だとCPUのみを利用するので、結構速度に課題がありますが、NVidiaやAMDのGPUを利用して高速に実行させることもできます。

特徴としては、 **複数のmodelを同時に実行する** ことができます。メモリさえ許せば、になりますが・・・。


## NixOSでOllamaを使う {#nixosでollamaを使う}

nixなので、Ollamaを利用するだけなら簡単です（ほんとに？）。

```nix
{ pkgs, ... }:
{
  # AMDのCUDA的な立ち位置のrocmを有効にする
  environment.systemPackages = [ pkgs.ollama-rocm ];
  services.ollama = {
    # 設定を有効にする。service == systemdのunitとして起動するようになる
    enable = true;
    # これを指定しないとCPUだけで実行する形になる
    acceleration = "rocm";
    group = "ollama";

    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1100"; # used to be necessary, but doesn't seem to anymore
    };
    rocmOverrideGfx = "11.0.0";
  };
}
```

私は [Radeon RX 7900 XTX](https://www.amd.com/ja/products/graphics/desktops/radeon/7000-series/amd-radeon-rx-7900xtx.html)を利用しているので、rocmを利用することができるみたいだったので、rocmを有効にしています。これだけで、systemdでunitが設定されて、自動的に起動します。 `ollama` のcommandも使えるようになるので、modelをダウンロードすることもできます。

GPUを利用するように設定すると、CPUと比較しても10倍程度高速になります。GPUの消費電力はえげつないくらい上がりますが（一瞬で300Wとかに到達する）、これくらいないと正直待ってる間に他のことができてしまうレベルですね。

ちなみにmodelとしてはgemma2を主に利用しています。providerを都度切り替えるのがめんどくさいので。


## EmacsからOllamaを使う {#emacsからollamaを使う}

私は大体Emacsの上で色々やってますので、Emacsから使えないかを検討する必要がありました。さしあたって調べると、majorなものとしては以下がありそうでした。

-   [ellama](https://github.com/s-kostyaev/ellama?tab=readme-ov-file)
    -   LLMに対するfrontendとして設計されたもの
    -   **chatよりも、特定の作業をさせること** を念頭に置いたinterface
-   [gptel](https://github.com/karthink/gptel)
    -   様々なLLMとchatするためのinterfaceを起点としたinterface
    -   contextの設定とかを色々できるが、基本的にはchat clientである

私としてはchatはめんどくさいので、ellamaを利用しています。ellama自体transientのmenuを持ったりしていますが、個人的に全部入りのmenuはどうせ使わないので、以下のように自前で定義しています。

```emacs-lisp
(transient-define-prefix my:llm-transient ()
  "Menus with LLM"
  [
   ["Code related"
    ("c" "Complete code" ellama-code-complete :transient nil)
    ("a" "Add code" ellama-code-add :transient nil)
    ("i" "Improve code" ellama-code-improve :transient nil)
    ("e" "Edit code" ellama-code-edit :transient nil)
    ("R" "Review code" ellama-code-review :transient nil)
    ]
   ["Generic usage"
    ("s" "Summary selected content or buffer" ellama-summarize :transient nil)
    ("t" "Translate selected content" ellama-translate :transient nil)
    ]
   ["Grammar"
    ("W" "Improve wording" ellama-improve-wording :transient nil)
    ("I" "Improve grammer" ellama-improve-grammar :transient nil)
    ]]
  [["Misc"
    ("*" "Open chat" ellama-chat :transient t)
    ]]
  )
```

使っていてだいぶ癖があるのが、 `ellama-code-add` です。利用すると、ほとんどのケースで先頭から書き直そうとして大変邪魔という・・・。正直使い勝手がわからないというのが現状の感覚ですね。chatは連続することがあるので、transientを切らないようにしています。


## で、Local LLMはどうなの？ {#で-local-llmはどうなの}

正直あんまり使ってないのでなんともですが、置換だと難しいような箇所を変換する、というのが主な感じです。test caseの生成とかについては、生成するために色々頑張るより自分でcopy/pasteして書き直したほうが早いというのがなんともですね。

Emacs上だとcopilotとか使ってても邪魔すぎて（overlayなので）、現時点では切っているくらいなので。実は <https://github.com/bernardo-bruning/ollama-copilot> という、ollamaをcopilotとして（かなり無理矢理）使う、というツールも見つけたので、これを使ってみようともしました。が、Emacsからだと **ollama-copilotを使うためにGitHub Copilotにloginしないといけない** というなんともかんともな感じになってしまったので、今回記事にはしていません。またなんか進捗があれば書こうかなと思います。
