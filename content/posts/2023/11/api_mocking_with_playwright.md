+++
title = "PlaywrightでのAPIモッキングをどうやっていくか"
author = ["derui"]
date = 2023-11-04T09:51:00+09:00
tags = ["Playwright"]
draft = false
+++

すっかり年の瀬も近くなりました。でも25℃とかになるのは勘弁してください。

さて、今回は悩ましいなぁ、というお話を書いていこうかと思います。あまりこうやる!という結論が出ない、ということは最初に書いておきます。

<!--more-->


## PlaywrightとAPIモッキング {#playwrightとapiモッキング}

最近E2EというかフロントのITを書くときには基本的に [Playwright](https://playwright.dev/) をファーストチョイスで利用しています。なんでなのかは前書いた気がします。さて、E2EならばAPIやインフラまで全部統合した状態で動作させるべきでしょう。ただ最近は、E2Eそのものはサードパーティが提供するサービス上で管理したりする、というのが増えてきている気がします。Autifyとかああいったやつですね。
Playwrightなどのコードは管理上などの利点はあるものの、非エンジニア以外が書けるか？はやはりまだまだノーだと思いますし、インフラなどの用意も必要ですし。

ITの話に戻ると、そこでは **バックエンドと結合するか否か** というのが問題になってきます。ちなみに今回はバックエンドはサードパーティのAPIを叩くだけのラッパーという扱いで、独自のインフラとかはありません(諸事情でフロントから実行できないので)。普通に考えれば、ITという単位では外部のAPIを叩くというのは避けるべき、となるでしょう。そうなるとモックが必要になるのですが、どういう単位でモックにすべきか？という話になってきます。

> ちなみにモックとかスタブとかspyについて厳密な区別はしてないです。要はダミーを作るかどうか？としています。

-   自分のAPIをモックにする
-   自分のAPIは本物で、外部API部分だけモックにする

大きく上記になるでしょうが、今回はPlaywright側の話なので、モックする境界をフロントエンド〜バックエンドの境界と定めます。さて、ではPlaywrightではどのような方法が取れるのか？というと、大きく以下のような手法があるかと思います。

-   特定の[Route](https://playwright.dev/docs/api/class-page#page-route)でレスポンスを差し替える
-   [routeFromHAR](https://playwright.dev/docs/mock#mocking-with-har-files)を使う
-   mswなど、ブラウザ上で動作するモックサーバーを利用する
-   wiremockなどのservice virtualization toolを使う

他にも色々あるとは思いますが、一旦これらについて考察します。


### 特定のRouteでレスポンスを差し替える {#特定のrouteでレスポンスを差し替える}

一番単純にやるとしたらこれになります。

```typescript
await page.route('/api/**', route => {
  if (route.request().postData().includes('my-string'))
    route.fulfill({ body: 'mocked-data' });
  else
    route.continue();
});
```

-   Pros
    -   標準なのでシンプル
    -   特定のAPIだけモック、というのができる
    -   条件毎にレスポンスの内容を変えるのが簡単
-   Cons
    -   設定がかなり煩雑
    -   下手に条件で分岐しだすと収拾がつかなくなるのがすぐわかる

実際お仕事ではシンプルなこのケースを採用していますが、別途インターフェースでラッピングしたりはしてます。


### routeFromHAR {#routefromhar}

実はこいつが今回の主題です。

```typescript
// from https://playwright.dev/docs/mock#mocking-with-har-files
test('records or updates the HAR file', async ({ page }) => {
  // Get the response from the HAR file
  await page.routeFromHAR('./hars/fruit.har', {
    url: '*/**/api/v1/fruits',
    update: true,
  });

  // Go to the page
  await page.goto('https://demo.playwright.dev/api-mocking');

  // Assert that the fruit is visible
  await expect(page.getByText('Strawberry')).toBeVisible();
});
```

これを実行すると、fruit.harというファイルと、リクエスト・レスポンスも含まれたファイルが作成されます。ちなみにHARは[こんな感じ](https://docs.gitlab.com/ee/user/application_security/api_fuzzing/create_har_files.html)です。Chrome/Firefoxで読み込んで見たりできるやつですね。このHARには、 **urlにマッチする全てのリクエストが記録** されます。なのでAPIを10回とか呼んでいると、それだけで大分エグいことになりますね…。

-   Pros
    -   record→replayということができ、実際に動作させた状態を後で復元できる
    -   harをそのまま指定したらreplayできるので、他のテストケースでも利用しやすい
-   Cons
    -   HARのリクエストとのマッチングアルゴリズムが厳密すぎて、マッチさせるのが難しい
        -   こんなissueもあります <https://github.com/microsoft/playwright/issues/21405>
        -   また、cookie含めたheaderのほとんども保存されるので、ちょっと油断するとrecordしたときの認証情報が普通に流出します。毎回編集するのがとても大変です
    -   特定条件の場合はこれ、みたいなのができないので、再利用するのが結構難しい

個人的に特に問題になるのはcookie/headerまで完全一致していないとreplayできないが、むしろ保存してくれない方がよいのでは…と思ってしまいます。また、recordするためにはそもそも必要なassertionや処理を記述する必要があるため、Playwrightで画面をちょいちょい触って初期のやつを生成…みたいなやつを2回やる必要があったりします。

こちらは個人開発で使ってみましたが、cookie/headerを毎回削除しないとならず、下手にheaderが足りなくなると動かない、とかがあってかなり扱いづらさがありました。認証の存在しないやつならよさそうですが、それ以外だと実際書いてるほど使いやすいわけではない、という気分。


### msw {#msw}

[みんな大好きmsw](https://mswjs.io/docs)です。が、実はその動作原理上、Playwrightだと結構扱いが難しいです。mswは、nodejsモードとbrowserモード、つまり単なるサーバーを立てる場合と、Service Workerでやる場合の二種類があります。で、当然ですが前者はparallelでやる場合は、同じAPIに対して複数mockできるようにしておく必要があります。後者はそこまでならないんですが、今度はPlaywrightが **ブラウザを外部からいじっている** というところになるため、mswにmock responseを差し込むのがとてもめんどくさい、というのが今度は問題になります。

```typescript
import { http, HttpResponse } from 'msw'
import {test} from '@playwright/test'


test('foo', ({page}) => {
  export const handlers = [
    http.get('/resource', () => {
      // 2. Return a mocked "Response" instance from the handler.
      return HttpResponse.text('Hello world!')
    }),
  ]

  // さて、このworkerは一体どこで動くんでしょうか？
  setupWorker(...handlers).start()


  page.goto('...')

});
```

多分普通にやろうとしたら↑みたいになりそうですが、これ当然ですがそのままだと正しく動きません。理由としては前述した通りで、Playwrightは **ブラウザの外** でJavaScriptを動かしているので、ブラウザの外のJavaScript contextでmswのworkerをstartしていることになるからです。ブラウザの中できちんとやりたい場合は、page.evaluateを使う必要があるんですが、オブジェクトとかは持っていけません。
Cypressだと原理が違うんでもうちょっとなんとかなるんですが、Playwrightだと結構怪しかったので、Playwrightでは一旦採用しないことにしてます。多分きちんとやればできるとは思いますが。


### service virtualization tool {#service-virtualization-tool}

ここでは[wiremock](https://wiremock.org/)を取り上げます。他にもいくつかありますが、敷居が低くて、必要十分な機能がありましたので…。

wiremockは主にJUnitとかC#とかのテスト時にAPIモッキングするためのライブラリというかサーバーというかなのですが、standaloneで起動してフル機能を利用することもできます。今回はstandaloneで使います。

<https://wiremock.org/docs/download-and-installation/#standalone-service>
公式がそのままなので↑を見てもらえればすぐ動かせますね。

さて、wiremockを利用することで何ができるのか？というと、これより前に挙げた方法論でできることは大体できます。難しいのはpage.routeで完全にプログラムで制御や生成したレスポンスを返すようにする…とかですが、正直そこまでやるくらいならもうリアルAPIと繋ぐべきな気分がします。
routeFromHARにあるようなrecording/replayもできます。

```sh
# recording開始
$ curl -d @recorder.json http://localhost:8080/__admin/recordings/start

# recording終了
$ curl http://localhost:8080/__admin/recordings/stop

$ cat recorder.json
{
  "targetBaseUrl" : "http://localhost:3000",
  "captureHeaders" : {
    "Content-Type" : {
      "caseInsensitive" : true
    }
  },
  "extractBodyCriteria" : {
    "textSizeThreshold" : "0",
    "binarySizeThreshold" : "10240"
  },
  "repeatsAsScenarios" : false
}
```

こんな感じで、

-   `localhost:3000` にアクセスをプロキシ
-   テキストは全部別ファイルへ
-   同じAPI(POST/PUT/DELETEなど)の繰り返し実行をシナリオにはしない

という条件でrecordingすることができます。recordingされたものは、wiremockにおいてはmappingと呼ばれるファイルに記載されていく感じですね。実際にはAPIアクセス毎にmappingが作成されます。ちなみに同じ内容だったとしても全部違うmappingになるので、結構狙ったときだけやらないと、分量がエグいことになるかなーと思ってます。また、wiremockは非常に高機能で、リクエストの値を一部利用してレスポンスを書き換えたり、ということができます。

とりあえず使ってみた感じでは、

-   Pros
    -   非常に高機能なservice virtualization tool
        -   proxy/browser proxyなども完備
        -   https経由でも普通にproxyできる(準備は一部必要)
    -   余計な情報が保存されず、モックされる内容は非常にシンプルになる
-   Cons
    -   nodejs以外のランタイムが必要になる
    -   mappingの管理をきちんとしないと、大分管理が煩雑になる

proxyがきちんとやってくれるのが非常にありがたいのですが、同じAPIを何回も実行したりしていると、どれがどれだ…ってなりがちなので、そこら辺は作りによって変わるかな？と思います。ただ、standaloneを使いつつ、快適なDeveloper eXperienceのためには、いくつかやらないといけないかなーというのもまたありました。


## 方法論とか関係ない課題感 {#方法論とか関係ない課題感}

さて、ここまで方法論を色々書いてきたんですが、前々から言われているモックそのものの課題はやはり残るなぁ、というのが所感です。どういう課題かというと、 **モックが古くなった** や、 **モックが仕様通りではない** 場合に、どのように対応すべきか？というものです。

大体どっちも同じ話なのですが、簡単に言えば外部APIの仕様(取得できる値の種類とかプロパティが増えたとか)が変わった場合、どのようにmockと差異があるのか？というのを気付きたい、というものですね。恐らく画一的な方法は無いので、recordingをサクっとできるようにしておく、というのがいいとは思います。

が、recordingをいつでもできるようにした場合、そのシナリオで使っていたデータが変更されていて、再度調整…みたいなのがあります。これは単純に追加の対応コストになり、チームできちんと合意が取れていないと、単純に工数増になってしまう…ということになりがちですね。外部APIを使う場合はなおさらなので。そういったものは、どれだけツールを整備したとて残ってしまう問題であり、本質的な解決はなかなか難しいです。

今回はPlaywrightから呼ぶAPIをどうモッキングするか？というところに終始しましたが、モックは適用されるレイヤーも多く、それに対応して利点と対立する課題も多く、考察が絶えないです。個人的には速度と安定のバランスをどうとっていくか？をもうちょっと考察していきたいところです。大体はケースバイケースになっちゃうんですけど。
