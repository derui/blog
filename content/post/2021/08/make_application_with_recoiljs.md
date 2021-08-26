+++
title = "Recoil.jsを使ってアプリケーションを作ってみた"
author = ["derui"]
date = 2021-08-26T21:37:00+09:00
lastmod = 2021-08-26T21:37:40+09:00
tags = ["JavaScript"]
draft = false
+++

涼しかったのも終わり、相変わらずの厳しい残暑が戻ってきてしまいました。日が出ていないのに36℃とか勘弁して欲しいですほんと。

今回は、ひょんなことからガッと作ったアプリケーションで、Recoil.jsを使ってみたのでその話をしようかと思います。

<!--more-->


## 作ったもの {#作ったもの}

これです。といってもまだ若干イケていないところがあるので、画面とかはないですが。

<https://github.com/derui/simple-planning-poker>

-   複数人で一つのゲームを開催できる
-   全員がカードを選択したらその平均値を表示できる
-   表示し終わったら次のゲームを直ぐに開始できる

カードの選択、show downなどはリアルタイムで同期されます。

今日時点で9daysなので、大体1週間ちょっと(平日の夜 + 土日の日中)ですね。


### なんで作ったん？ {#なんで作ったん}

チームではスクラムっぽいことをやっていて、そのなかで見積もり手法として[プランニングポーカー](https://www.mof-mof.co.jp/blog/column/agile-estimation-planning-poker#:~:text=%E3%83%97%E3%83%A9%E3%83%B3%E3%83%8B%E3%83%B3%E3%82%B0%E3%83%9D%E3%83%BC%E3%82%AB%E3%83%BC%E3%81%AF%E3%80%81%E8%AA%B0%E3%81%8B%E4%B8%80%E4%BA%BA,%E5%9F%8B%E3%82%81%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E5%87%BA%E6%9D%A5%E3%81%BE%E3%81%99%E3%80%82)を利用しています。

で、最初はアナログな手法でやっていたのですが、リモートが長く続くこともあり、 <https://planningpokeronline.com/> というサイトを利用するようになっていました。

で、↑のサイトを使っていたときに、チームの中から(自分が言い出したかもしれん)、 **これってFirebaseを使えば割と簡単に出来るんじゃない？** という話が出ました。

> そういえば、Firebaseって使ったことねーなー。

と思ったので、じゃあやってみんべ、と作ってみました。


## state管理ライブラリの選定 {#state管理ライブラリの選定}

さて、今回はガッと作ろうと決めていたので、フロントは慣れている [React.js](https://reactjs.org/) + TypeScriptを使うことにしました。[react-router](https://reactrouter.com/)とかも使ってます。が、あんまりまともに使ったことがないのでreact-routerはいつも迷いどころ・・・。

ただ、state管理として [Redux](https://redux.js.org/) を使うかどうか・・・というのはちょっと迷っていました。いくらガッと作ると言っても、趣味プログラミングならばちょっとは冒険してみたいところ。

と調べていたら、 [Recoil.js](https://recoiljs.org/) という新しめのstate管理ライブラリを見つけました。

> A state management library for React

と謳っていることもあり、完全にReact専用です。なんといってもHookを前提にしているので、Reactじゃないとそもそも動作しません。Reduxは別にReactに閉じるものでもないことを考えると、汎用性があるわけではないなーとは思ったんですが、まぁ使ってみるか、とやってみました。


## Recoilの基本 {#recoilの基本}

基本的なものは、公式サイトを見るのが一番わかりやすいと思うんですが、簡単に紹介します。

Recoilの基本は、 `atom` と `selector` の二つの概念です。といっても、 `atom = state` で、 `selector = atomから情報を取得したり加工して情報を返す` という区別があります。

```js
const textState = atom({
  key: 'textState',             // ユニークなID。atom/selector全部を通じてユニークでなければならない
  default: '', // デフォルトの値
});

const quotedText = selector({
  key: 'quotedText',             // ユニークなID。atom/selector全部を通じてユニークでなければならない
  get: ({get}) => {
    const text = get(textState);

    return '"' + text '"';
  }
});
```

みたいな感じです(例が思いつかなかった)。recoilは、selector/atomの間にデータフローを作成し、atomが更新された場合はそのatomを利用しているselectorを更新する、という形になっているようです。

また、selectorやatomには、asyncを利用して動的に取得してくるような処理を作成できたり、IDごとに値を保持できるatomなども構成することができます。


### recoilの超注意点 {#recoilの超注意点}

しばらくドハマりしてデバッガとにらめっこすることになりましたが(公式ドキュメントに書いているようないないような・・・)、Recoilを利用するうえでこれを守らなければならないものがあります。

それは、 `useRecoilCallbackの中でuseRecoilValueを利用しないこと` です。これはHookのルールとかにも繋がってくるのですが、最初はよくわからず普通にuseRecoilValueを中で使って、それはそれで謎のエラーが出ていました。


## 実際にRecoilを使ってみた {#実際にrecoilを使ってみた}

さて、Recoilを実際に適用しようとしたときに、ちょうどよく実践的にまとまっている記事を見付けたので、ここを参考にすることにしました。

<https://engineering.linecorp.com/ja/blog/line-sec-frontend-using-recoil-to-get-a-safe-and-comfortable-state-management/>

実際に書いてみた感じでは、以下のディレクトリ以下で `*-atom.ts` となっているものが対象です。

<https://github.com/derui/simple-planning-poker/tree/main/src/ts/status>

実際に作成してみたところでは、以下のようなところが要注意かな、と感じました。

-   atom/selectorのキーは一箇所で管理すべき
    -   ↑のサイトでも書いています
-   useRecoilValueをコンポーネントで直接利用させない
    -   ↑でも書いてます
    -   これをしてしまうと、管理もへったくれもなくなってしまうので、mustで避けるべきです
-   atomはトップレベルで定義しなくてもよい
-   Hookの外から更新したいときは要注意

最初の二つは、参考にしたサイトからの受けうりです。書いてみて確かにそうだな・・・と実感しました。atom/selectorのキーは、重複しているとconsoleに盛大にwarningが出るのでわかりやすいのですが。

useRecoilValueを利用させない、というのは、stateをどう管理しているか、をコンポーネントが知る必要はないということを考えるとまぁその通りです。

ではその他の二つについて、もうちょっと詳しく書いてみます。


### atomはトップレベルで定義しなくてもよい {#atomはトップレベルで定義しなくてもよい}

atomには、 `atomFamily` という亜種があり、これは `IDを受け取ってAPIなどからインスタンスを取得する` という使いかたが想定されています。

```js
const userState = atomFamily({
  key: "userState",
  default: (userId) => userRepository.findBy(userId)
});
```

のように使います。ただ、このstate管理ライブラリ自体が、userRepositoryの実装そのものを知っている必要はありません。普通にテストしづらいし。ということで、こうできます。

```js
const createUserState = (userRepository) => {
  return {
    userState: atomFamily({
      key: "userState",
      default: (userId) => userRepository.findBy(userId)
    })
  };
};
```

こうしても、ちゃんとRecoilを利用しだす前(index.tsとかで)呼びだしていれば、エラーになることなく利用でき、かつ依存性を注入することができます。これはselectorやAction(ここでは、useRecoilCallbackなどを利用するものを指します)でも同じなので、できるだけ実装を直接渡さないようにしました。


### Hookの外から更新したい場合は要注意 {#hookの外から更新したい場合は要注意}

今回、状態そのものを他のユーザーと共有するため、Firebaseの[Realtime Database](https://firebase.google.com/docs/database?authuser=0)を利用しています。そうなると、当然ながら `他のユーザーが更新した内容を受け取る` 必要があります。

Reduxの場合、別に難しいことはなく、middlewareなりを挟めば問題ないし、DispatcherにActionを渡すことができさえすれば、色々な実装ができます。Reactに依存することもありません。

ところが、Recoilの場合はこれをReactの機構を介するのが基本路線となっています。

```typescript
import { inGameActionContext } from "@/contexts/actions";
import { gameObserverContext } from "@/contexts/observer";
import { GameId } from "@/domains/game";
import * as React from "react";
import { useParams } from "react-router";

export const GameObserverContainer: React.FunctionComponent<{}> = () => {
  const param = useParams<{ gameId: string }>();
  const inGameAction = React.useContext(inGameActionContext);
  const observer = React.useContext(gameObserverContext);
  const setCurrentGame = inGameAction.useSetCurrentGame(param.gameId as GameId);

  React.useEffect(() => {
    observer.subscribe(param.gameId as GameId, (game) => {
      setCurrentGame(game);
    });
    return () => {
      observer.unsubscribe();
    };
  }, [param.gameId]);

  return null;
};
```

上はソースから持ってきた例ですが、 **React.useEffectを使え** というのが答えになっています。 `return null` なので、↑のコンポーネントは実際には何もレンダリングしませんが、単にRecoilにデータを反映したい、というだけでReactのコンポーネントを持ち出す必要があります。

一応、UNSTABLEですがatomにもeffectというものが用意されており、これを利用すればいらない・・・と言いたいところですが、上の例だとgameIdが決定するのはreact-routerのIDから、となります。また、state自体がそれを更新するobserverも全部管理する、というのは、動的に増えるような場合に対応しづらい(まぁそういうアーキテクチャを書けばいいだけですが)、というのもあります。

個人的には、State管理のためにReactのコンポーネント利用するのってちょっと筋がよくないんじゃないかなぁ・・・という印象でした。React専用だからいいんだ!って言われてしまえばまぁそうかもしれませんが、テストはしづらいですね。


## Firebaseについて {#firebaseについて}

一応触ったのでfirebaseについてもさらりと書いておきます。今回はdatabase/auth/hostingを利用しましたが、

-   emulatorがかなりよくできていて、ローカルで普通に開発できる
-   ドキュメントも結構しっかりしているので、あまり困らず開発できる
-   構成オブジェクトについてはちょっと気をつける必要はある

という感じで、Firebaseそのものにはそこまで困りませんでした。どっちかというと、KVSにまったく慣れ親しんでいないので、構成を考えるほうがよっぽど難しかったです。


## Reactを触るのであれば触れておいてもいいかもしれない {#reactを触るのであれば触れておいてもいいかもしれない}

まだunstableな機能も多く(結構使いたいものもunstableだったりする)、ちょっと大きめのプロダクションだと導入に躊躇する気もしますが、Reduxとはまた違う書き味・考え方を持っています。

個人的にはReactのHookがかなり無理矢理色々やっている感があるので、それと独立しているReduxの方が好みではあります。が、RecoilはHookの利用を強制してくるので、Hookのルールなどに慣れ親しむには丁度いいギブス的な性質もあるな、と思いました。

> 個人的なRecoilへの感想としては、useStateをグローバルに拡張したものとしてかなり自然で、「顧客が本当に必要だった状態管理やん…」と思ったりしています。

という風に、前述したサイトでは記載されていたりします。私は、そもそもuseStateをglobalに使うという時点で、jQuery時代の悪夢を彷彿とさせるので拒否反応が出てしまうのですが・・・。

どう感じるのは、は利用シーンとかにもよると思うので、実際に触ってみることをお勧めします。
