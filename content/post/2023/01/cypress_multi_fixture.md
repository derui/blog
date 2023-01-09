+++
title = "Cypressで複数のfixtureを利用するtips"
author = ["derui"]
tags = ["TypeScript"]
draft = true
+++

あけましておめでとうございました。当の昔に年は明けてますが、改めまして。

Cypressで色々やろうとしてみたところ、以外と動かなくてハマってしまったので、メモっておこうかと思います

<!--more-->


## やりたいこと {#やりたいこと}

Cypressには、 [fixture](https://docs.cypress.io/api/commands/fixture) という機能があります。簡単に言えば、指定したファイルを読み込んでその中身を取得できる・・・という機能です。Playwrightとかだと手書きしないといけないですが、Cypressはディレクトリ構造とかまで決められている代わりに、組み込みで提供されてます。

```typescript
cy.fixture('users').as('usersJson') // load data from users.json
cy.fixture('logo.png').then((logo) => {
  // load data from logo.png
})
```

上記のように、 `cy.fixture` を利用することでできます。まぁシンプルですね。

さて、これだけならとてもシンプルな話で終わるのですが、例えば次のようなシナリオを考えると、これはそのままでは動作しません。

-   msw.jsでresponseのモックをしたい
-   条件によって利用するfixtureを変更したい
    -   条件はrequestの中身だったりするので、msw.jsの仕組みの中で判定とかしたい

という感じです。擬似コード的なものとしては、次のようにしたいよ、という感じですね。

```typescript
cy.mockAPI({
  "http://localhost:3000/hoge": post(["simple", "changed"], {
    "simple": async (req) => {
      const json = await req.clone().json();

      return json.input_value === "test";
    },
    "changed": async (req) => {
      const json = await req.clone().json();

      return json.input_value === "changed";
    },
  }),
})
```

mockAPIというのは自作したAPIで、まぁ対象のURLにアクセスされたときにどのfixtureでモッキングするのか？というのを定義するためのDSLです。正直洗練できてはいないのですが、個人で利用するだけなのでまぁいいかな、というところ。


## Cypressでやってみると起こること {#cypressでやってみると起こること}

Cypressは、Playwrightなどのasync/awaitを大前提にしたFrameworkよりかは、webdriverと同様に、  **async/awaitを意識せずに同期的に書ける** ことが重視されていると感じます。

> 過去、async/awaitが存在していない時代、コールバック地獄になっていたときは、このように同期的に処理できるAPIは画期的でした。今はもうasync/awaitが一般的になってしまいましたが。

さて、しかしこれはこれで困ったことになることに気付きました。前述した  `cy.fixture` ですが、こいつはPromiseを返すようで返していません。型としては  `Chainable` という型が返されます。  `then` とかが使えるのでPromiseLikeなのかな〜と思ったりしますが、 **そうではありません** 。

例えば以下の例はどうなるでしょうか？

```typescript
Promise.all(["a", "b"].map((fixture) => cy.fixture(fixture))).then(console.log);

// => ???
```

現在の一般的？な知識を前提にすると、fixtureの中身の配列・・・が返却されそうですが、答えは  `undefined` (だったか空配列)が表示されます。  `cy.fixture` にthenで繋いだとしても、結果は同じになります。

これがなんで発生するのか、を考察すると、CypressはPromiseを露出させずに同期的に実行するため、Promiseを別途解決する仕組みを持っていると推察されます。cy.xxxを実行する度に、そのpromiseをqueueに入れるなどして、順番に解決されるようにしている感じでしょうか。そうなると、Promise.allのようなPromise APIを直接実行すると、Cypressが用意している機構ではなく、ランタイム側で直接処理されるため(Cypressの方も最終的にはランタイムで処理されるんですが)、順序がズレる、という事態が発生していると考えられます。


## Promise.all的なことをやりたい {#promise-dot-all的なことをやりたい}

さて、実際Promise.all的なことをやりたい場合はどうしたらよいでしょうか、となったので色々試したり調べたりしましたが、結果としては以下のようにすると動くことが確認できました。

```typescript
// fixtureを保存するためのmapを用意しておく。別にobjectでも配列でもなんでもいい
const fixtures = new Map<string, unknown>();

// cy.fixtureの結果をそれぞれ保存する
['path-a', 'path-b'].forEach((fixture) => {
  cy.fixture(fixture).then((body) => {
    fixtures.set(fixture, body);
  });
});

// cy.wrapでfixturesをwrapして、実行順序を担保する
cy.wrap(fixtures).then((fixtures) => {
  const handler = rest('http://localhost:3000/hoge', async (req, res, ctx) => {
    let fixture: unknown;
    const body = await req.clone().json();

    if (body.foo == 'a') {
      fixture = fixtures.get('path-a');
    } else {
      fixture = fixtures.get('path-b')
    }

    return res(
      ctx.status(200),
      ctx.set("content-type", "application/json"),
      ctx.body(JSON.stringify(fixture))),
    );
  });

  msw.worker.use(handler);
});
```

キモは  `cy.wrap` になります。cy.wrapしないでやると、空のfixturesにアクセスするだけになるので、悲しいことになりかねません。(実際には同一参照を見ているので、最終的には動くかもしれませんが、タイミング問題が発生する可能性も高くなります)

cy.wrapをすることで、Cypressの枠組みの中で実施されている順序制御の中に組み込むことができます。これをしないと、非同期処理をせずに進んでしまいます。


## 標準のasync/awaitを使うことの善し悪し {#標準のasync-awaitを使うことの善し悪し}

地味にハマりました。以前のCypressでは、PromiseLikeだったらしく、Promise.allにそのまま渡せばできたらしいのですが、今は仕組みが変わっており、動かなくなった、という経緯らしいです。

仕事の方では、Playwrightを選定していて、そっちではasync/awaitを利用することが大前提になっています。現代のJavaScriptでは、async/awaitが一級市民になっているため、下手に内部でラップして同期的に書くことができる、というAPIとの相性が相対的に悪くなっているかな・・・という感覚があります。

無論、毎回awaitしまくらないといけない、というめんどくささはあるんですが、awaitって打つことを省略する必要性はどこまであるんだ・・・？という疑問も湧くようになってきたのは確かです。とはいえ、CypressのDeveloper Experienceが圧倒的に良い、というのは否定できず、どこに力点を置くのか、という問題でしか無いな、とも思ってます。

ともあれ、CypressでPromiseを利用したいとか待ちあわせを実施したい、とかでは、  `cy.wrap` のご利用を検討してみて下さい。


## 実際どうか？ {#実際どうか}

とりあえずマウントはできるようになったのですが、正直コンポーネントベースでのテストは、UIライブラリでもない限りはそこまで必要ないかも・・・と思ってきた次第です。

Cycle.js的には、設定が面倒なのと、結果として **Sinksから流れるのが確認できない** というのが結構痛いです。流れていることを確認するためには、結局一段階ラップしたコンポーネントを都度作成しないといけないので、その手間よりだったら全体をテストした方が早くない？と思いました。

また、Cypressの設定側としても、component test用とE2E用とで複数用意する必要があります。正直そのコストは今の規模だと賄えない感じがしてます。Angular/React/Vueとかの、標準でサポートが入っているフレームワークを利用しているのならば、かなり楽なのかもしれませんけども。

とはいえ、久々にこういうツールを触っているのは楽しくもあったので、いい経験でした。数少ないCycle.jsユーザーの参考になれば。