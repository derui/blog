+++
title = "OCamlでFFTを実装してみる"
author = ["derui"]
lastmod = 2019-10-12T11:55:38+09:00
tags = ["OCaml"]
draft = true
+++

WAVから十二音技法に基づく音程を、gnuplot形式で抽出するCLIをほそぼそと作っています。

[wav-pitch-extractor](https://github.com/derui/wav-pitch-extractor)

まだreadmeもない＋完全に自分用の実装なので、仕事であればやらないような、車輪の再実装もやっています。その中で、 `Fast Fourier Transform` 、通称FFTも実装してみたので、その感想を書こうかと思います。

<!--more-->


## FFTとは？ {#fftとは}

まずFFTが何か、簡単に説明します。もっと正確でもっと詳しい説明は色んなサイトに載っているので、そちらを見ていただくとして。 なお、単純にFFTだけで検索すると、 **Final Fantasy Tactics** の方も引っかかってきて、一定以上の年齢層にとって懐かしい気持ちになること請け合いです。

閑話休題。

FFTは上でも書いた通り、 `Fast Fourier Transform` のアナグラムです。日本語だと **高速フーリエ変換** という名前です。 **高速** という修飾があるので、 **フーリエ変換** を高速にやるアルゴリズム、ということです。


### フーリエ変換とは {#フーリエ変換とは}

実際にはフーリエ変換と離散フーリエ変換で別々のものとして扱われているんですが、プログラムでは基本離散フーリエ変換しか扱えないので、以下でも離散フーリエ変換をフーリエ変換として扱います。

フーリエ変換は、端的に言うと **ある複素関数からある複素関数への変換** というものを指します。現実的には、デジタル信号の周波数解析などで使われるのが一般的、とのことです。以下の式で表されます。

\begin{equation}
F(t)=\sum\_{x=0}^N f(x) \mathrm{e}^{-i \frac{2 \pi t x}{N}}
\end{equation}

・・・とだけ書かれても、高卒程度の知識しか無いと、ファッ？ってなってしまいます（なりました）。特に右辺のネイピア数の辺りが鬼門です・・・が、実はここはオイラーの公式というものを使うと、三角関数だけで書けます。オイラーの公式は次のように定義されています。

\begin{equation}
\mathrm{e}^{i\theta} = \cos{\theta} + i \sin{\theta}
\end{equation}

これに関連する特に有名なものとして、[オイラーの等式](https://ja.wikipedia.org/wiki/%E3%82%AA%E3%82%A4%E3%83%A9%E3%83%BC%E3%81%AE%E7%AD%89%E5%BC%8F)があります。と

オイラーの公式を最初の式に適用すると、ある時間の振幅に、オイラー公式で表される周期関数がかけられたものを、全時間分足したものが、ある周波数のスペクトルになる、ということになります。

私の説明は単に現時点での私の理解ですので、より正確な定義などを知りたい場合はより信頼できるサイト・文献をあたったほうがよろしいかと・・・。


### 素朴なフーリエ変換と問題点 {#素朴なフーリエ変換と問題点}

上記の定義に従うと、次のように書けます。

```ocaml
let dft (data : float array) =
  let size = Array.length data in
  let radian = 2. *. Float.pi /. float_of_int size in
  Array.mapi
    (fun index _ ->
      let start = ref Complex.zero in
      Array.iteri
        (fun index' v ->
          let v = {Complex.re = v; im = 0.} in
          let times = float_of_int index *. float_of_int index' in
          let next = {Complex.re = cos (radian *. times); im = sin (radian *. times)} in
          let next = Complex.mul v next in
          start := Complex.add next !start)
        data ;
      !start)
    data

    (* dft [|1.0;2.0;3.0|] *)
```

素朴なので、メモリ使用量がー、とかは気にしていません。なお、数式をプログラムに起こすとき、 \\( \sum \\) はfor loopでの足し算に相当します。

さて、これで一応ちゃんと計算できます。離散フーリエ変換の場合、サンプリング定理というものがあり、実際に正しく計算できる周波数は、サンプリング周波数の1/2以下の周波数に限られます。（グラフにすると、ちょうど真ん中を境にして対象な形になります）

このアルゴリズムの最大の問題は、計算量が \\( O(n^2) \\) である、という点です。扱うデータが小さいものしか無い、というのであれば問題にはなりません。ただ、信号処理はたいてい大量のデータを扱います。例えば44.1khzでサンプリングした信号は、毎秒44100個の信号になります。なので、このアルゴリズムだと2〜3秒くらいの信号でも、処理に数秒とかそういう時間がかかってしまいますし、より大量のデータに対しては実用に耐えられないです。

そのため、現実にはこれを高速化したもの、つまりFFTが使われます。


### FFTの登場 {#fftの登場}

FFTはあくまで総称なので、いくつかのアルゴリズムがあります。有名？なのはCooley-Turky型のFFTアルゴリズムを指すのが一般的です。

このアルゴリズムを適用すると、計算量は \\( O(n \log{n}) \\) まで改善します。 \\( O(n^2) \\) と比べると、指数的に増えていく素朴実装と比較して、線形に増えていくので、データ量が増えても現実的な時間で終わらせられるようになります。

しかし、Cooley-Turky型アルゴリズムは、標本数（最初の式の \\( N \\)）が、2のべき乗でなければならない、という強い制約があります。この制約を回避するシンプルな解決方法は、データを0埋めする、という方法があります。この方法でもいいんですが、結果が素朴実装とずれる、という問題があります。


## 今回の実装 {#今回の実装}

<https://en.wikipedia.org/wiki/Chirp%5FZ-transform#Bluestein.27s%5Falgorithm>

今回、上の **Bluestein's algorithm** と呼ばれるアルゴリズムを実装しました。次のような感じです。

```ocaml

let fft (data : float array) =
  (* make array that has size to align 2-exponential it *)
  let ( ** ) v e =
    let rec loop ret count = if count = 0 then ret else loop (ret * v) (pred count) in
    loop 1 e
  in
  let data_size = Array.length data in
  let padded_size = 2 ** least_exponent_of_2 ((data_size * 2) - 1) in
  let omega i n =
    { Complex.re = cos (Float.pi *. float_of_int i /. float_of_int n)
    ; im = sin (Float.pi *. float_of_int i /. float_of_int n) }
  in
  let a =
    Array.init padded_size
    @@ fun i ->
    if i < data_size then
      let v = {Complex.re = data.(i); im = 0.} in
      let i = omega (-1 * (i ** 2)) data_size in
      Complex.mul v i
    else Complex.zero
  in
  let b =
    Array.init padded_size
    @@ fun i ->
    if i < data_size then omega (i ** 2) data_size
    else if data_size <= i && i <= padded_size - data_size then Complex.zero
    else omega ((data_size - (i - (padded_size - data_size))) ** 2) data_size
  in
  let a' = fft_2_power a and b' = fft_2_power b in
  let r = Array.init padded_size (fun i -> Complex.mul a'.(i) b'.(i)) |> ifft_2_power in
  Array.init data_size (fun i ->
      let omega = b.(i) in
      let r' = r.(i) in
      Complex.mul omega r')
```

いくつか関数が足りないので、このままでは実行できません。雰囲気だけ感じてもらえれば。フル実装はリポジトリにあります。

Bluestein's algorithmの特徴は、 **任意長の信号** を取り扱える、という点です。その分、Cooley-Turky型アルゴリズムより数倍遅いのですが、この任意長、というのが欲しかったので、これを実装した次第です。


## アルゴリズムを再実装する意義 {#アルゴリズムを再実装する意義}

OCamlにはすでに高速なFFTの実装はあります。他の言語でも、既に高速な実装があるので、 **それを利用したアプリケーションを作る** のであれば、間違いなく既存のライブラリを使うべきです。

ただ、あえてアルゴリズムを再実装すると、そのアルゴリズムの理論的な背景や、実装することによる理解の浸透などが期待できます。理論的基礎を知ることで、実際にライブラリを利用する際に気をつける箇所もわかります。

せっかくの個人リポジトリ、こういうことを知ったり実践する場として使ってみるのもオススメです。
