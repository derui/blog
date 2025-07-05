+++
title = "filebaseのrealtime databaseでテストする"
author = ["derui"]
date = 2021-09-27T21:08:00+09:00
lastmod = 2021-09-27T21:08:57+09:00
tags = ["JavaScript"]
draft = false
+++

もう9月も末で、涼しくなってきたなぁと思ったらいきなり暑くなったりと、季節があっちこっちいきますね。これも温暖化の影響でしょうか。

今回も小ネタで、最近やったfirebaseのrealtime databaseでローカルのテストをやる方法をサラッと書いてみます

<!--more-->


## Realtime databaseをローカルで動かす {#realtime-databaseをローカルで動かす}

Realtime databaseのテスト手法にはいくつかあると思いますが、基本的にはローカルで動作するemulatorを利用します。

<https://firebase.google.com/docs/emulator-suite?authuser=0>

β版とはいえ、かなりしっかりできている印象で、少なくともローカルでテストするレベルであれば必要十分です。さすがに実Databaseに比べると、レイテンシーがなさすぎて(そりゃそうだ)、実際にpublishして動かしたときに **アレ？** ってなる可能性もありますが。

さて、このemulatorですが、firebaseコマンドで初期化するときに選択しているか、configで追加したら、後は以下のコマンドを叩くだけで起動します。

```shell
$ npx firebase emulators:start
```

デフォルトでは `localhost:4000` で起動し、 `localhost:9000` とかでrealtime databaseが起動します。この状態でも、databaseには繋げることができるので、やろうと思えばテストを書けます。


## `emulators:start` の問題 {#emulators-start-の問題}

しかし、emulators:startにはいくつか問題があります。

そのなかでも大きな問題は、 **backgroundでの起動ができない & テストに同期して落とすとかできない** という点です。まぁそりゃそうなんですが。


## `emulators:exec` を使おう {#emulators-exec-を使おう}

そんなときに役立つのが、 `emulators:exec` というコマンドです。このコマンドは、引数で渡されたコマンドを実行する前後でemulatorのstart/stopをきちんとやってくれる、one-pathなemulatorの起動を提供してくれます。

なので、

```shell
$ npx firebase emulators:start npm run test
```

のように書けば、テストが開始する前にemulatorが立ち上がって、テストが終了するとemulatorが終了します。

また、引数に渡したコマンドがwatchとかであれば、watchを `C-c` とかで落とすまでずっと立ち上がりっぱなしになるので、ずっとテストしてられます。


## realtime databaseを使うIntegration test {#realtime-databaseを使うintegration-test}

こんな塩梅のボイラープレートを書く必要があります。RulesTestEnvironmentは、 [@firebase/rules-unit-testing](https://www.npmjs.com/package/@firebase/rules-unit-testing) で提供されている便利ツールです。firebaseと結合したテストを書く場合はこれを使っておくのがよさげかと思います。

```typescript
let database: any;
let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-project-1234",
    database: {
      host: "localhost",
      port: 9000,
    },
  });
  database = testEnv.authenticatedContext("alice").database();
});

afterAll(async () => {
  testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearDatabase();
});
```


## 若干の課題 {#若干の課題}

多分私の書いてるソースがどっかおかしいんだと思いますが、実行されるタイミングとか順番によっては、うまくデータが初期化されていなかったりなんだりします。これは原因を探っているところではありますが、基本的にはかなりの速度で動作してくれるので、ある程度の数のテストがあっても問題はなさそうです。


## databaseもテストしていきましょう {#databaseもテストしていきましょう}

RDBMSと違って、構造を事前に定義したりしなくても使えるぶん、realtime databaseへの保存・削除・取得がただしく動作するのか？はきちんとテストしておかないと、かなりわけのわからないことになります(戒め)。せっかく提供してくれているものがあるので、どんどん活用していきましょう。
