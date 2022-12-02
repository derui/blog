+++
title = "Cypressのcomponent testをcycle.jsのコンポーネントでも使えるようにしてみた"
author = ["derui"]
tags = ["AWS", "TypeScript"]
draft = true
+++

あれ？もう12月？ってくらいに早く一ヶ月が過ぎていきました。もう師走ですね。

最近Cypressを色々触り初めているのですが、その中でcycle.jsのコンポーネントテストもできるようにしてみました。

<!--more-->


## Cypress {#cypress}

さてまずCypressについてですが、Seleniumに端を発する(多分)、E2Eテストツールです。[Cypress Cloud](https://docs.cypress.io/guides/cloud/introduction)ってのもあるようで、こちらで収益を確保している様子ですね。

<https://docs.cypress.io/>

個人的には、業務でも以前Capybaraなどを利用して作成したこともあるんですが、Cypressというか最近のツールは非常によく統合されていて、Cypressだと

-   各種フレームワークに最初から対応
-   フレームワーク毎の設定ファイルとかも最初から用意可能
-   scaffoldが充実している
-   watchがデフォルトで有効であり、ソースを編集したら自動的に再実行してくれる
-   E2Eだけでなく、component単位でのテストも可能

昔のこういったテストツールは、あくまでSelemiumのラッパーというだけだったり、フレームワーク **だけ** を提供している感じでしたが、Cypressとかは環境ごと提供してくれています。これによって、非常に体験よくテストを書いていくことができます。

> まだCIにintegrationしたりはしていないので、そこらへんの感想はまだですけども

さて、そんな充実のCypressですが、さすがにCycle.jsというマイナーなフレームワークは対応してくれてません。まぁそりゃそうでしょう。ですが私が今やっているやつはCycle.jsなので、それを使えるようにしたいところ。


## Cycle.jsのコンポーネントをCypressにマウントする {#cycle-dot-jsのコンポーネントをcypressにマウントする}

前述しましたが、Cypressには[コンポーネントテストを実行するサポートがあります](https://docs.cypress.io/guides/component-testing/overview)。これを実行する動機としては、独立したUIコンポーネントだったり、組み合わせて利用するとかなりしんどい系統(例えばautocompleteやツールチップとか)をテストするときに利用する想定だと思います。

今触っているプロジェクトだと、結構複雑さが高いものがあり、それについて使ってみようかなぁ、といったところになります。余談ですが、Cycle.jsの全てのコンポーネントは、外部の存在を前提にできないため、 **原理的にはすべてのコンポーネントが単独でテスト可能です** 。これは、DI設定とかに大きく依存するAngularや、contextの設定やhooksとかに依存するReactと比較したときに、Cycle.js特有の強みになるものだと思ってます。

> まぁ、その分streamとの戦いにはなるんですが。

Cypressのコンポーネントテストだと、まずはコンポーネントをCypress上にマウントするのがスタート地点になります。

```typescript
import Button from './Button'

it('uses custom text for the button label', () => {
  // ↓これ
  cy.mount(<Button>Click me!</Button>)
  cy.get('button').should('contains.text', 'Click me!')
})
```

Cypressからは、著名なフレームワークについてはこのmountが提供されているので、ユーザー側はcommandとして登録することができます。しかしCycle.jsではここが無いので、まずこれを作らないとスタート地点に立てません。

これ厄介なのが、Cycle.jsにおけるDOMドライバーについてです。DOMドライバーはできるだけ自動的に差し込みたいのです。テストにおけるindex.htmlの構成とかIDとかは一箇所に留めたいので。しかし、Cycle.jsでの起動関数である  `run` の型定義的にそのようになっておらず、そのままだとdriver部分とcomponent自体の型定義が合ってないぞ、と怒られます。

```typescript
interface Sources {
  DOM: DOMSource;
  props: Stream<{value: string}>
}

interface Sinks {
  DOM: Stream<VNode>;
  value: Stream<string>;
}

const main = function main(sources: Sources): Sinks {
  // sinksをとりあえず返す
}

// DOMは自動的にmountしたいのでこうしたいが、そのままだと、第二引数でDOMがないぞーって怒られる。
cy.mount(main, {
  props: xs.of({value: "foobar"})
});
```

探したらライブラリもあったんですが、まぁ書けるだろーと思って書いてみたのが↓になります。SourceはDOMが必須にはしてありますが、Driverはそれを前提としない、最終的にmountの中でDOMを渡すから問題ないようにする、という感じがポイントになってます。

```typescript
const mount = function mount<D extends Drivers>(
  component: (source: Sources<D> & { DOM: DOMSource; state?: any }) => any,
  drivers: D
): void {
  const dispose = run(component, {
    ...drivers,
    DOM: makeDOMDriver("#root"),
  });

  Cypress.once("test:after:run", dispose);
};
```

正直もっと頑張って型パズルを解くこともできたとも思いますが、とてもじゃないですがここに時間をかけることは本質的ではないので、anyとかで潰す作戦を取ってます。特にrunした場合、sinksはどうでもよくなってしまうため、潰しても実用上はなんの問題もないです。


## 実際どうか？ {#実際どうか}

とりあえずマウントはできるようになったのですが、正直コンポーネントベースでのテストは、UIライブラリでもない限りはそこまで必要ないかも・・・と思ってきた次第です。

Cycle.js的には、設定が面倒なのと、結果として **Sinksから流れるのが確認できない** というのが結構痛いです。流れていることを確認するためには、結局一段階ラップしたコンポーネントを都度作成しないといけないので、その手間よりだったら全体をテストした方が早くない？と思いました。

また、Cypressの設定側としても、component test用とE2E用とで複数用意する必要があります。正直そのコストは今の規模だと賄えない感じがしてます。Angular/React/Vueとかの、標準でサポートが入っているフレームワークを利用しているのならば、かなり楽なのかもしれませんけども。

とはいえ、久々にこういうツールを触っているのは楽しくもあったので、いい経験でした。数少ないCycle.jsユーザーの参考になれば。
