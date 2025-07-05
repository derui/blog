+++
title = "reduxにおけるactionのパターンを考える"
author = ["derui"]
date = 2023-05-07T09:56:00+09:00
tags = ["TypeScript", "Redux"]
draft = false
+++

気付いたらGWが終わってました。どういうことなの？GWではひたすら草毟りしてました。

GWも終わりなので(？)、ちょっと最近思うReduxのActionについて書き連ねていこうかと思います。

> 最近プライベートでTypeScriptしか書いていないから、そろそろ別の書きたい。

<!--more-->


## 事前知識：fluxとは {#事前知識-fluxとは}

Redux・・・というライブラリというか、Flux architectureに基づくライブラリなどでは、基本的にはなんらかの副作用はActionのdispatchをもって起動するもの、とされるかと思います。

> <https://www.freecodecamp.org/news/an-introduction-to-the-flux-architectural-pattern-674ea74775c9/>
>
> fluxとは？は↑が図解入りでまとまっていました。

このパターンを提唱したのがMeta社(当時Facebook)であり、最初に実装されたライブラリがReduxだった・・・と記憶しています。それから色々出たり、やっぱ複雑/面倒すぎる!ってなって色々生まれたりしていますが。パターンの発展形として、 **selector** というものが挟まるパターンもあります。Redux-toolkitや、若干後発である[NgRx](https://ngrx.io/guide/store)も導入していますね。(最初はreselectってやつだった記憶)

flux architectureは、global stateという、フロントにおいてはすぐさまカオスになる部分に対して、以下の制約を掲げることで解決を図ったアーキテクチャである、ということが言えるかと思います。

-   状態の変更方法を一つに留めることで、絡みあった状態を管理しやすくする
-   single source of truthとして、状態が存在する箇所を一箇所に閉じた

必ずしも万能である・・・というわけではありませんが、一定以上の規模になり、状態を変更する複雑さが級数的に上がってしまうと、もはや管理が破綻してしまうことを考えると、大抵のケースで有効ではないか、と思えます。

> 古き良きjqueryでDOMに色々状態を書き込みまくっていて、それが10万行くらいの規模になると、もはや何やってんのかわかんなくなったことがあります。


## ReduxにおけるActionの定義 {#reduxにおけるactionの定義}

Actionは、componentがなんらかの副作用(≒ここではcomponent外部のstateの変更、が副作用)を発行する唯一の手段、となります。componentは自分が責任を持てないstateについては編集できず、stateの編集は唯一用意されたflowのみが行える・・・というのがflux architectureの根幹になりますので。

さて、このActionsですが、色々と派閥があるように感じます。どういう派閥があるの？はここでは語りませんが(ぉぃ)、私としては、基本的には次のように作成することが多いです。

```typescript

// × 画面側がどうするのか？は知らないのでこうはしない
const clickHogeRegistrationButton = createAction<string>('clickHogeRegistrationButton')

// ○ 基本的にはこっち
const registerHoge = createAction<string>('registerHoge')
```

コンポーネントから設計なり実装していると、その必要性に駆られて「あー、ここclickしたらあの状態を変えないと・・・」ってなって、画面側の都合でActionを追加しがちになります。別にそれでもいいっちゃいいんですが、このActionの大事なポイントは、 **UIなんてどうでもいいstateがUIの言葉に依存する** ことかな、と思います。ここらへんが派閥な感じですが、色々見ていると、あくまで **ユーザーの行動をActionとする** というのが大半かなぁ、と思ったりします。わりとreduxなりの経験が浅いメンバーなどのコードレビューをしていると、画面しか知らない情報を元にした名前にしてて、このaction何？って会話になることが多い印象です。


## 今回の話：非同期が絡む場合のAction {#今回の話-非同期が絡む場合のaction}

今回の主題ですが、Actionをdispatcherがハンドリングする中で、どうしてもAPI実行やらなんやらで、非同期の呼び出し結果をもって初めてstateの更新ができる・・・というパターンがあります。この場合、失敗と成功を **Actionとして** 区別したいので、下のように書くことが多いです。

```typescript

// 基点になるAction。コンポーネントはこれをdispatchするのみ。
const openHogeList = createAction<string>('openHogeList')

// こっちは非同期処理から再発行されるもの
const openHogeListSuccess = createAction<Hoge[]>('openHogeListSuccess');

// こっちも。失敗したときはこっち
const openHogeListFailure = createAction<string>('openHogeListFailure');
```

このパターンのわかりやすいところは、例えばトーストなりなんなりで表示するための情報管理を・・・ってやるようなときに、action名で正規表現とかでマッチングするのがとても簡単です。また、非同期でやらないといけないやつかどうか・・・みたいなことがわかりやすいです。また、裏側でどのように非同期を解決するのか？という実装の詳細自体は隠蔽できています。React.jsだと、loadingの状態をコンポーネント自身に持たせて・・・みたいなのがreduxを利用するとやりづらいので、結果的に上記のようなAction体系を採用することもままあります。

欠点としては、本来的には画面から叩いてほしくないActionかどうか・・・っていうのがわかりにくいです。eslintなりでカスタムルールを書けば縛れるでしょうが、現状のJavaScriptにおけるmodule可視性上、回避不能です。exportしないと、そもそもreducerとかで使えないし。

それと、本質的には非同期かどうか？についてはActionは一切知らないのが理想(できるかどうかは別問題)だと思っているので、これを書くことで、結果的に実装の詳細がコンポーネント側に漏れている・・・とモヤることが度々あります。気にするな？まぁそれも一つなのですが。現実あんまり気にしてないし。

> ReactだとuseSWRとかそういったものを使う、というのも一つ主流になっているようです。個人的にはcomopnentがsmartすぎると、結局はgod component化していきやすいかなぁ、と感じているので、必要になるまではsmartにしたくないんですが。あと、これを使ったとて、globalな状態管理ライブラリが不要になる、ということではありません。
>
> <https://swr.vercel.app/ja>


### NgRxでSuccess/FailureのActionが不要になる場合 {#ngrxでsuccess-failureのactionが不要になる場合}

わりと長い間、前述のパターンで書いていますが、NgRxを利用しているメンバーから、 **このパターン別にいらなくない・・・？** という話がありました。ちなみにReduxだと、↑使わないと、loading管理とかがとても辛みが出るのでオススメできないです(selectorとかでloadingの情報を取ろうとしたら、stateから取ってくるしかないため)。

NgRxのチュートリアルを眺めていると、Angularではコンポーネントからのサービス呼び出し、というのが極当たり前の用に実行できます。なんでもInjectionできるからそりゃそうなんですが。そうなると、結果としてコンポーネントの中から、successに相当するものを発行することができるし、ローディングの状態管理についてもコンポーネントでできるから別にいらなくない？ということかな、と理解できました。

> <https://ngrx.io/guide/store/walkthrough>
> ↑上記の最後にあたりに、BookServiceをngOnInitの中で呼びだし、結果をActionsとしてdispatchしているのが見えます。

これはFluxの純粋性が云々を置いておくと、なるほど現実的かな、と思ってます。React.jsはFunctional Componentがデフォルト状態になって久しいですが、Angularはclass component以外が存在しない(多分。よくわかってないです)ため、componentに状態を持つことの難しさがどこにもありません。loadingの状態管理もcomponent側の都合として持たせられますし。


### とはいえ必要になるケースはありそう {#とはいえ必要になるケースはありそう}

ですが、やはりUI上の要件次第では、やはり必要かな、と思ったりします。例えばある行動が基点で読み込みが必要になるのですが、その際に基点になったコンポーネントの **外** についてもloadingなりの管理が必要になった場合、前述のパターンでは対応できません。いやAngularなら全部持てるからできるよ、というのはわかるんですが、仕事でやっているAngularの方でも、pageなりが全部持ちすぎてもはや何がどういう形でstreamを巡っているのか全くわからない・・・という状態を幾度となく見ているので、個人的には懐疑的です。

Success/Failureのようなパターンを利用する場合、reducerが複数あったとしても、そのそれぞれに独立して追加することができるため、不要なreducerはノータッチで構いませんし、reducerの仕組み上テストも瞬時に書くこともできるでしょう。Angularのコンポーネントテストは、ほんの数個依存があるだけですぐ地獄が見えるのでやりたくないです。

> Standalone Componentがデファクトになったらどうなのか？はわかりませんが。


## もうちょっと構造化されたAction {#もうちょっと構造化されたaction}

実際、ユーザーが画面からやるのがAction、という定義にすると、Success/FailureといったActionsは実装上側の都合によるもの・・・とも言えます。それを元にすると、以下のような構造を作ってもいいのかな？とぼんやり考えたりしてます。

```text
src ┣ actions
          ┣ users  // component≒userから実行されるaction
          ┣ apis   // なんらかの非同期処理によって発行されるAction。usersが基点になる
```

usersの方はシンプルなActionだけを実装します。apisにあるactionsは、原則としてepicなりobservableなりsagaなりthunkなりからだけ発行されるのが期待されます。reducerは全部見えないとわけわからんので、全部見ます。

apisにあるactionsは、ほとんどのケースで元になるactionがあるはずなので、それをベースにしてこんな感じのヘルパーを提供してあげれば、そこまでボイラープレート感もないかな？と。

```typescript
const HogeApi = createApiActions<Hoge[], string>(openHoge.type);

// HogeApiの中身はこんな感じ =>
/**

   HogeApi.success == createAction<Hoge[]>("openHogeSuccess")
   HogeApi.failure == createAction<string>("openHogeFailure")
 */
```

これならeslintのカスタムルールもそこまで複雑にはならないかな？という感じもします。とはいえ実装もなんもしていないから、実際ワークするか？は別問題ですが。


## 所変われば品変わる、はFluxも一緒 {#所変われば品変わる-はfluxも一緒}

仕事だとNgRx **も** 採用しているところにいたりして、やはりfluxというものはアーキテクチャでしかなく、その中でどのように構成するのか？は色々あるなぁ、と勉強になりました。個人的にはAngularの全部のせ感がどうにも合わないので、個人プロジェクトで採用することは多分そこまで無いですが・・・。

Reduxが出たときから、このAction周辺はボイラープレートボイラープレート言われていましたが、そこら辺はテンプレート使えばそこまで辛いわけでもないし(私は[hygen](https://www.hygen.io/)使うことが多いです)、どっちかというと最終的には管理面の話になってくるなぁ、と思います。

selectorの話とかも書こうと思いましたが、紙面が尽きてきたのでこの辺で。

> 紙面なんてないだろ、というのは野暮
