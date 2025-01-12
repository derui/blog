+++
title = "Ollamaで利用するmodelのcontext sizeを強制的に変更する"
author = ["derui"]
tags = ["Linux", "Ollama"]
draft = true
+++

年末は色々忙しいな、と思っていたら年が明けていました。今年もゆるくやっていきます。ゆるすぎではないかとも思いますが。

<!--more-->


## Ollamaとcontext sizeの悩ましい関係 {#ollamaとcontext-sizeの悩ましい関係}

最近Ollamaを利用して色々試してみていますが、[aider](https://aider.chat/docs/llms/ollama.html)を利用しようとしたところ、全然うまく動作しない・・・という事態に陥っていました。とはいえ２日間くらいですが。

> aiderについてはもうちょっと使い込んでから記事にします。

どうも理由としては、tokenの数がそもそも足りていない模様。さて、色々調べてみると、まずollama自体のFAQに次のように書かれています。

> How can I specify the context window size?
>
> By default, Ollama uses a context window size of 2048 tokens.
>
> To change this when using ollama run, use /set parameter:
>
> /set parameter num_ctx 4096
>
> When using the API, specify the num_ctx parameter:
>
> curl <http://localhost:11434/api/generate> -d '{
>   "model": "llama3.2",
>   "prompt": "Why is the sky blue?",
>   "options": {
>     "num_ctx": 4096
>   }
> }

<https://github.com/ollama/ollama/blob/main/docs/faq.md#how-can-i-specify-the-context-window-size>

なんですが、setしてみても全然動作しません。ちなみにollamaでcontext windowの上限にヒットすると、次のようなログが出るので目安になります。

```text
$ journalctl -u ollama | rg truncating

1月 12 17:03:52 localhost ollama[344466]: time=2025-01-12T17:03:52.836+09:00 level=WARN source=runner.go:129 msg="truncating input prompt" limit=2048 prompt=2861 keep=4 new=2048
```

さて、ここは色々あるようなのですが、 `/set parameter` が効かない、というissueがありました。

<https://github.com/ollama/ollama/issues/6286>

どうもollama上、 **GPUにloadする前にnum_ctxを指定する必要がある** というとこです。あれ、でも上の `/set parameter` って `ollama run` してから＝GPU loadしてからなんでは・・・ :thinking: というのが、set paramaterしても効かない理由ということのようです。

もう一方の、API requestに含める・・・というのは、ツール次第なのでなんともです。実際このcontext window managementは結構息の長いissueとなっているようです。


## とりあえずなんとかする方法 {#とりあえずなんとかする方法}

<https://github.com/ollama/ollama/issues/6286#issuecomment-2418807319>

上記に書いてありますが、 `自分でカスタムしたらいけるよ` とのこと。やって見ましたが大分簡単です。ただ、modelごとに変わってくるので、あくまで私が利用しているmodelでは、になります。

```shell
$ ollama show <model> --modelfile > modelfile
$ echo "\nPARAMETER num_ctx 8192" >> modelfile
$ ollama creata -f modelfile <custom modelの名前>
```

なお、これをやった結果として `num_ctx` が反映されているかどうか・・・がわからないのが如何せんという。なお注意点としては、 **model自体のparameter数 \* num_ctxに比例してGPUのVRAM消費がかあがる** というのがあります。14bのparameterで8192を指定すると、大体 17GBくらい消費します。デフォルトだと13GBくらいです。利用しているGPUに合わせて調整してください。


## 過渡期というか黎明期を見ている感じ {#過渡期というか黎明期を見ている感じ}

issueを眺めていると、OpenAIのAPIだとこうだから・・・に対して、「いやでもそれ概念違うんじゃない？」みたいなやりとりがあったりして、なんというか大変そうだなーという感じです。とにかくいろいろなところが独自性を出そうとして色々出しているところ、一見しては同じそうだけど重要なところがちょっとずつ違ったまま進んでいって合流やアラインが難しくなっている・・・っていうように見えます。

まー色々あっても適応していくしかない一般人としては、どうなることやらというところですね。とりあえずcontext windowを動的に設定できるようになると大変助かるので、issueはwatchしておこうと思います。
