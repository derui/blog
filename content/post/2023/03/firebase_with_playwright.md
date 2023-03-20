+++
title = "firebaseをうまいことplaywrightから使う"
author = ["derui"]
date = 2023-03-20T12:58:00+09:00
tags = ["TypeScript", "firebase", "playwright"]
draft = false
+++

すっかり春っぽい陽気になったりならなかったりですが、いかがお過ごしでしょうか。なんで旅行にいくときだけ嵐のパターンが多いのか。

さて、相変わらずTypeScriptとばっかり格闘しているのですが、そのなかで若干の知見というかなんというか・・・を得たので、簡単に記事にしてみます

<!--more-->


## なにをしたいのか {#なにをしたいのか}

まぁタイトルにあるとおり、[playwright](https://playwright.dev)を使ってEnd 2 End テストを書きたいんです。要件としては↓みたいな感じ、と自分で勝手に決めてます。

-   できるだけ並列に出来る術を探す
-   firebaseのemulatorと繋ぎ、mockは使わない
-   productionコードにはできるだけ手を入れない

前まで触ってたJIRAのツリー表示アプリでは、firebaseを純粋なhostingとして使っていたのと、APIのmockとしてmswを使ったりしていたので、2・3番目が成立できない感じでした。今は別アプリの大規模リファクタリングを敢行しているんですが、そっちはauthやrealtime databaseを利用しているため、どうしてもemulatorとの接続が必要になります。

> playwrightを採用したのは、お仕事でも使ってるからでもあるんですが、今回のアプリは、  **複数のブラウザ** を同時に扱わなければならないため、frameベースであるcypressでは多分実現が超むずい感じになるのがすぐ見えたためです。Cypressがwebdriverベースだったらできたかもしれませんが。


## playwrightで複数のページを扱う {#playwrightで複数のページを扱う}

まずこれができないと、今回のアプリのE2Eができません。これについては、公式ドキュメントにもヒントがあったりしますが、  `fixture` を使うことで実現できます。

↓みたいなfixtureを作ると、きちんと終了時に掃除までしてくれます。

```typescript

export const test = base.extend<{ newPageOnNewContext: Page }>({
  newPageOnNewContext: async ({ browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();

    await use(page);

    await page.close();
    await context.close();
  },
})
```

`browser.newContext` は、簡単に言えば新しいincognito/privateなBrowserを用意できるやつです。これをやらないと、authが共有されてウギャーってことになるので。


## firebaseのデータ初期化 {#firebaseのデータ初期化}

さて、firebaseなんですが、私はできるだけデータを流用したくない(並列に実行する、ということを目指す以上、前後に依存を持たせるのはアンチパターン)のです。

UT/ITだと、 [@firebase/rules-unit-testing](https://www.npmjs.com/package/@firebase/rules-unit-testing)というライブラリがあって、こいつが都度都度異なるdatabaseへの接続をサポートしてくれたりして、他のテストで被らないようにできる・・・みたいな素敵なことができます。

**が！！**

実際にemulatorでauthを使う場合、これは当然ながら使えません。CIのときだけtestingEnvironmentを作ることは避けたいのもそうなんですが、  **authと壊滅的に相性が悪いです** 。なぜかというと、firebaseのauthはproject単位で存在しているのですが、emulatorはproject毎にしか立ち上げることができないから、です。(私の理解上)

つまり、authで作成したuidをdatabaseに保存して〜とかをする場合は、そもそも別のnamespaceを利用したりはできませんし、sign upを各々のtest caseで実施することもできません。本来は並列で実行したかったんですが、この制約と、nsを変更することの難易度から、  **現状並列実行は諦めてます** 。


### 起動時のfirebaseへのインポート {#起動時のfirebaseへのインポート}

emulatorは、起動時に  `--import <directory>` を指定することで、exportしたものを取り込んで初期化することができます。これをやると、前回の状態を再現したり、それなりに作った初期データを配布したり、ということも可能になります。

が、これもEnd2Endではとても使いづらいことがわかりました・・・。

なんでかというと、 **起動時** にしか指定できないので、起動した後には **再インポートすることはできない** のです。もしやりたければ、都度emulatorの起動からやり直す必要がありますが、かなりヘルシーではないやりかたになる上、結局直列なのは変わりません。


### REST APIでの初期化 {#rest-apiでの初期化}

さて、ここでREST APIの登場です。firebase自体のREST APIも利用できるんですが、  **一部emulator専用のAPIが存在します** 。主にauthですが。

<https://firebase.google.com/docs/reference/rest/auth?hl=ja#section-auth-emulator-clearaccounts>

↑のAPIを実行することで、authに追加された全てのアカウントを初期化することが出来ます。これによって、何度でも同じメアドでのアカウント登録が可能になります。しかし当然ですが、都度uidが変わるため、realtime databaseなどに登録されたデータも初期化する必要があります・・・。

realtime databaseについては、emulator用のAPIなどはないのですが、PUTするのに加えて、bodyとしてお望みのJSONを渡すことで、全体を初期化することが可能になります。

<https://firebase.google.com/docs/reference/rest/database?hl=ja#section-put>

これを合わせて、次のようなfixtureを作成しました。

```typescript
export const test = base.extend<{ resetFirebase: () => void }>({
  resetFirebase: async ({ request }, use) => {
    await use(() => {});

    const firebaserc = JSON.parse(fs.readFileSync("./.firebaserc"));

    await request.delete(`http://localhost:9099/emulator/v1/projects/${firebaserc.projects.default}/accounts`, {
      headers: { authorization: "Bearer owner" },
    });

    await request.put("http://localhost:9000/.json?ns=local-default-rtdb", {
      data: JSON.parse(fs.readFileSync("./misc/ci/database_export/local-default-rtdb.json")),
    });
  },
})
```

試した感じでは、emulatorに対してはauthorizationとか渡さなくても動きました。authの方は無いと動かないのですが。なお注意点としては、  **projectはfirebasercに書いてあるもの** を指定する必要がある、ということです。最初ベタ書きにしてまずいことに後で気がつきました・・・。
realtime databaseの方は、nsを指定することで、対象のnsを初期化できます。このときのnsは、productionコードで渡しているprojectId + `default-rtdb` となる模様です。私は  `local` で用意しているのでそのまま使ってますが。


## playwrightの方が色々できてなんとかなる {#playwrightの方が色々できてなんとかなる}

とりあえず二つのfixtureを組み合わせて、複数のブラウザからログインし、realtime databaseで更新されていることを確認し・・・みたいなことができるようになりました。たぶんcypressだと仕組み上出来ない感じがするので、こういったこともできるplaywright推しが強くなった感がします(まぁplaywrightの方が大分新しいのでアレなんですが)。

惜しむらくは、firebaseを利用したEnd2Endでは、事実上並列実行が不可能である・・・という点です。が、これについてはある程度諦めやすい(ケースを絞ったり、一つのシナリオを長くしたり)ので、まぁこれはこれでいいかな、といったところです。結構色々調べて時間を使ってしまったので、誰かの参考になれば幸いです。
