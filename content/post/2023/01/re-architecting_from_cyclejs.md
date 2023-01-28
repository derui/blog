+++
title = "Cycle.jsのアプリケーションをReact.jsにリアーキしてみた"
author = ["derui"]
date = 2023-01-28T11:04:00+09:00
tags = ["TypeScript", "ReactJS"]
draft = false
+++

気付けば一年の十二分の一が終わろうとしています。時の流れは速すぎるぜ・・・。

タイトルにあるとおりなんですが、ちょっと思うところがあったため、どんなもんかとやってみました。

<!--more-->


## リアーキ対象 {#リアーキ対象}

こいつです。

<https://github.com/derui/jira-dependency-tree>


## なぜリアーキしたのか？ {#なぜリアーキしたのか}

このアプリケーションは、元々[cycle.js](https://github.com/derui/jira-dependency-tree)を利用していました。特にそれで問題も無かったんですが、作っていく内にいくつかつらみ？的なものが出てきました。

-   streamが複雑になるにつれ、wire up時の認知負荷が増してきた
    -   これはAngular.jsとかでもそうですが、すべてのデータをStreamでやりとりしようとすると、とてつもなく複雑になっていきます
-   JSXの書き心地がちょっとよろしくない
    -   snabbdomの影響がモロに出ているからですが
-   state管理を考えると、コンポーネント自体が膨らみがち
    -   この辺、恐らく一定のパターンを見出して、ライブラリを実装したりしたら負荷は大分減るとは思いましたが

というあたりでした。特にwire upは、全てがstreamである以上回避策を取ることがとても難しく、main関数があっというまに肥大化するという課題を解決するのが難しかった、というのがあります。他は、私が選択してみたライブラリを利用するのが思ったよりしんどいとかそういう感じですが。


## リアーキしたアーキテクチャというかライブラリ {#リアーキしたアーキテクチャというかライブラリ}

私は個人プロジェクトだとそのときの気分でリアーキしたりするので、今回もサックリとReact.jsにするかー、ということでやることにしました

しかし、Cycle.jsのパラダイムはとても有用だと感じている(特にdriver)ので、そこは活かしたいな・・・と考えた結果、以下のライブラリを選定しました。

-   React.js
    -   まぁこれは。
-   redux-toolkit
    -   実は初めて利用しました。普通に書くより楽でいいですね。
    -   recoilは？という話もあるかもしれませんが、あっちはあっちで結局streamと同じ話が発生しがちだと感じています。どこで何が再レンダリングされるのか？を把握しづらいという点で。
-   react-redux
    -   redux使う以上は。
-   hygen
    -   ボイラープレートがいっぱいできるので、自動生成するために。
-   redux-observable
    -   今回の目玉。RxJSをreduxに持ち込みます
-   vitest
    -   元々viteを利用していたのと、jestはviteとの相性が最悪だったので。
-   testing-library
    -   コンポーネントテストで使います

という感じです。個人的にrecoilとかも触ってるんですが、stateという観点だとreduxがまぁバランスいいよな、という感覚です。今回、redux-observableを利用した理由は簡単で、Cycle.jsのときに作成したDriverをそのまま再利用するためです。


## リアーキの進めかた {#リアーキの進めかた}

ざっくりこんな感じでやりました。所要期間は約一週間くらい(仕事の後も含めて)。

1.  まずhygenでボイラプレートを生成できるようにちょいちょい作成する
2.  簡単なコンポーネントからReact化していく
    -   with テスト
3.  stateが必要なコンポーネントになったら、actions/slice/selectorを作成していく
    -   これもwith テスト
4.  3.で作ったものを使ってコンポーネントを作る
    -   できるだけwith テスト
5.  非同期が必要なactionsに対してepicを作る
    -   これもテスト込み
    -   epicとは、  `redux-observable` で作成された非同期処理を表します。saga的なやつ？
6.  driverをxstreamからRxJSに置き換え
7.  ルートのmoduleで色々wiring

今回はdriverでかなり色々やっていた(d3.jsのレンダリングやイベントハンドリング)ので、それをReactに持ち込むと地獄がまた見えるので、driverという概念はそのまま活かしました。xstreamからRxJSへの書き換えですが、xstreamがミニマルなライブラリで、RxJSが全部入りのやつなので置き換えそのものは特に問題なく進みました。ストリームの概念が若干異なるところはありましたが、そこについても今回は大きな問題になることもなかったです。


## リアーキした結果 {#リアーキした結果}


### コンポーネントの見通しがよくなった {#コンポーネントの見通しがよくなった}

Cycle.jsだと、ある程度の規模になってくると、コンポーネントを取り込む処理自体がかなりの重量になってくるので、直感的な書き方ができるReactの方が、見通しが立てやすくなりました。


### stateに対するテストが書きやすい {#stateに対するテストが書きやすい}

stateに対する更新は、やはりreduxだと書きやすいです。完全に純粋な関数のみで記述していけるので、なんかあったときにサクっと修正できるのは強みです。


### redux-observableは思ったより使い勝手がよかった {#redux-observableは思ったより使い勝手がよかった}

今回初めて使ってみたんですが、これは思ったよりやりやすかったです(仕事でng-effects触っていたからかもしれない)。

例えば、↓のような感じで書けるんですが、これは他のepicとは切り離され、かつ最終的な結果としてActionを流さなければならない、という制約があるので、1actionにつき1epic、みたいなことをしておけば、複雑性がepicの中だけでなんとかなります。

```typescript

const synchronizeIssues: (action$, state$) =>
   action$.pipe(
     filter(synchronizeIssues.match),
     switchMap(() => {
       const credential = state$.value.apiCredential.credential;
       const condition = state$.value.project.searchCondition;

       if (!credential) {
         return of(synchronizeIssuesFulfilled([]));
       }

       return registrar
         .resolve("postJSON")({
           url: `${credential.apiBaseUrl}/load-issues`,
           headers: {
             "x-api-key": credential.apiKey,
           },
           body: {
             authorization: {
               jira_token: credential.token,
               email: credential.email,
               user_domain: credential.userDomain,
             },
             project: condition.projectKey,
             condition: {
               sprint: condition.sprint?.value,
               epic: condition.epic,
             },
           },
         })
         .pipe(
           map((response) => mapResponse(response as { [k: string]: unknown }[])),
           map((issues) => synchronizeIssuesFulfilled(issues)),
         );
     }),
     catchError((e) => {
       console.error(e);

       return of(synchronizeIssuesFulfilled([]));
     }),
   )
```

フロントで必要なものや待ちあわせは、できるだけselectorで集約して管理してあげることで、 `combileLatest` の嵐などになったりせず、コンポーネントの中がそれなりに健全な作りになります。

> とはいえ、やっぱり一定インタラクションが入ってくると、かなり複雑になってきてしまうんですが・・・。


## エコシステムの強さを改めて感じた {#エコシステムの強さを改めて感じた}

Cycle.jsは、そのミニマリストな概念やstreamを前提に置いた処理など、streamを利用するというパラダイムにおいては尖りきっているな、と感じました。が、やっぱりエコシステムの影響は強く、開発ツールや周辺ライブラリの充実具合は、どうしても規模の経済が影響しやすいです。

とはいえ、使ってみたことで、streamに対する観点や勘所といったものがわかってきたり、driverという形で、全体から副作用をどう追い出すのか？といったものも含め、大きな学びになりました。

時間がある人なら・・・というのはありますが、普段触っているものと異なるパラダイムのライブラリとかに触れるということは、大きな学びになると思うので、チャレンジしてみるのもいいんでないかなーと思ったりします。
