+++
title = "React.js + recoilをSolid.jsで置き換えてみた"
author = ["derui"]
date = 2022-06-19T15:41:00+09:00
lastmod = 2022-06-19T15:41:29+09:00
tags = ["JavaScript", "TypeScript"]
draft = false
+++

最近は仕事の方が色々とあって、またもや気付いたら6月も後半になっていました。最近時間の流れがマッハすぎて困ります。

今回は、いつもの実験プロジェクトにて、 [Solid.js](https://www.solidjs.com/)を触ってみたので、感触とかを書いていこうと思います。

<!--more-->


## SolidJSとは {#solidjsとは}

最近話題のアイツです。

ロゴだとSOLIDJSとなっていますが、リポジトリだとsolid、organizationはsolidjsとなっていて、いったいどれが正しい名前なんだ？となりますが、この記事の中では  `SolidJS` で統一していきます。

さて、SolidJSは、公式からの引用だと以下のようなライブラリとのことです。

> Solid is a declarative JavaScript library for creating user interfaces. Instead of using a Virtual DOM, it compiles its templates to real DOM nodes and updates them with fine-grained reactions. Declare your state and use it throughout your app, and when a piece of state changes, only the code that depends on it will rerun.

ざっと掻い摘んで取り出すと、

-   UIを作るための宣言的ライブラリ
-   Virtual DOMの変わりに生DOMを直接利用する
-   更新は木目細かいreactionで行う
-   状態を宣言することで、適切なコードだけが再実行される

というような特徴を持つ、ということです。React.js/Angular/Vueに代表されるコンポーネントライブラリと比較すると、Virtual DOMを利用せずに生DOMを直接利用する、というのが最も大きな差異でしょうか。

```text
最近、Virtual DOMに伴う複雑さやパフォーマンス劣化に対する揺り戻しとして、以前とは違うアプローチで生DOMを触るライブラリが増えた気がします。[[https://svelte.jp/][Svelte]]なんかも同じような感じですし
```

SolidJSは生DOMを適切に利用することができる結果として、数あるフレームワークの中でもほぼ最速([ベンチマーク](https://rawgit.com/krausest/js-framework-benchmark/master/webdriver-ts-results/table.html))を謳っています。


### Reactive {#reactive}

SolidJSは、最初からstate managementも含まれており、総称してreactiveと呼んでいます。リアクティブというと[RxJS](https://rxjs.dev/)を思いだして「うっ、頭が・・・」となる人もいると思いますが、SolidJSのreactiveは、RxJSよりかなりシンプルでバランスが取れていると感じます。

-   Fluxと同様に単方向データフローである
-   Observableはサブ概念であり、signalという概念が大前提となっている
    -   hot/coldや、Observableが切り替わる、とかは気にしなくてよく、認知負荷が大分下がってます
-   operatorなどはなく、純粋にJavaScriptだけで記述できる


## React + recoilを置き換えてみる {#react-plus-recoilを置き換えてみる}

<https://github.com/derui/simple-planning-poker/tree/to-solidjs>

さて、話よりもまずソースを見た方がわかりやすいとは思いますのでリンクを貼っておきます。詳しめの感想は以下に。


### コンポーネント {#コンポーネント}

コンポーネントについては、SolidJSは独自の構文を利用せず、JSXをそのまま利用しています。これは、既存の資産をフル活用することができ、かつReact.JSなどで十二分にテストされてきているという利点もあります。

大体は `React.FunctionComponent` とかを  `Component` に置き換えていく簡単なお仕事です。コンポーネントにだけ関して言うと、いくつかReactとは違いがあります。

-   `className` は `class` でいい
-   `classnames` を使っていたら、 `classList` にそのまま置き換えられる
-   `onChange` の挙動は生DOMに従っているので、 `onInput` とかと適切に使い分ける

Reacterな人は、結構3つめで引っかかるのではないでしょうか(ちょっと引っかかった)。

さて、 **コンポーネントは** わりと簡単に置き換えられるのですが、もっとも理解に時間がかかったのは、 `props` の扱いです。

SolidJSでは、 **基本的にpropsをdestructuringできません** 。これをやると、最初のレンダリング以降更新されないコンポーネントが簡単に作れます。

```text
SolidJSのコンポーネント = 関数は、 すべて一回しか呼び出されません。それ以降はreactiveによる動的な更新がSolidJSによって自動的に行われます
```

```typescript
const {name, value} = props;

return (<div>
  <span> {name} </span>
  <span>{value} </span>
  </div>
  )

// ↑NG  ↓OK
return (<div>
  <span> {props.name} </span>
  <span>{props.value} </span>
  </div>
  )
```

これは、propsが単純なオブジェクトではなく、プロキシオブジェクトになっていることに由来します。([参考](https://www.solidjs.com/guides/rendering#props))

もしどうしてもdestructuringしたい場合は、 `splitProps` というのがあるので、これを利用することになります。ただ、後述するreactive対応を考えると、それはそれでコストかな・・・という感じもします。


### Hook {#hook}

最もよく利用されるHookについては、提供されている4つの基本reactiveがそのまま対応します。

-   `React.useState` → `createSignal`
-   `React.useEffect` → `createEffect`
-   `React.useMemo` → `createMemo`

createResourceについては、今回結局使わなかったので・・・。


### reactiveへの対応 {#reactiveへの対応}

これに一番時間を使いました。理解が進めばあぁなるほどね、となるのですが、理解していない間は、「なんでこれが動かないんや・・・」っていう悩みと共にソースを眺めることになります。

特に最初悩んだのは、以下のようなソースでした。

```typescript
function Comp(props) {
  const [count, setCount] = createSignal(0);

  const isFirst = count() === 0;

  return (<div>
    <span>{isFirst ? "not counted" : "counting"}</span>
    <span>{count()}</span>
    </div>
  )
}
```

さて、これがonclickとかで `setCount(count() + 1)` とかされた場合、isFirstは切り替わるでしょうか？

・・・答えは、 **切り替わりません** 。なんでかというと、isFirstは最初に呼び出された時点から変更されない = 定数状態なので、reactiveであるcount()を使っていたとしても反応しません。

これを防ぐには、上の例でいうと `isFirst` を関数にするか、テンプレートの中に押し込める必要があります。テンプレートの中に押し込めば、SolidJSのコンパイラがうまいことやってくれる可能性があがります。

が、基本的には  **関数にする** のをおすすめします。classNameを動的に決定する、といった場合も、テンプレートの中に書くとどうしてもごちゃついてしまいます。関数にしとけば、 `className()` とかで実行できますし。


### recoilからの置き換え {#recoilからの置き換え}

ここは当初の想定よりもはるかに楽でした。recoilにある `atom` はほぼそのままcreateSignalに、 `atomFamily` はcreateResourceとすることも可能ですが、createMemoを使っても別段問題ありません。

また、testabilityはSolidJSの方が上でした。SolidJSは色々なところにプロキシオブジェクトを利用することによる利便性と、それに伴う制約がありますが、 recoilは(当時) **Reactのテンプレートの中でしか動かない** という、中々にしんどい仕組みがございました。

そのため、テストを書く度に大量のボイラープレートが必要になったり、トリッキーな書き方が必要だったりしましたが、SolidJSは `createRoot` でラップするだけで済むので、state周りのテストは書き易いです。


### ロジックの編集 {#ロジックの編集}

・・・は、ありませんでした。元々Clean Architecture的な作りかたをしていたのと、Contextによる依存性注入をしていて、recoilへの依存は持っていなかったので、selectorとかの修正そのものはありましたが、actionとして分離していたUseCaseとかはほぼ無修正で問題なく動きました。

このへんは、多少手間がかかっても詳細を分離していたことが役に立ったな、という印象です(あんまり綺麗にいったことがないので)。


### react-routerの置き換え {#react-routerの置き換え}

このアプリケーションは一応web appなので、routingを使っていました。SolidJSでも、公式でrouterを公開しています。

<https://www.npmjs.com/package/solid-app-router>

大体の使用感は、react-routerと一緒ですが、認証が必要な系統を使うときにまたコツが必要でした・・・。

認証していないときに強制的にsigninに遷移させて、認証したら戻る、みたいなのは普通にやりたくなると思います。solid-app-routerでは、これをやるために  `navigate` という関数と、 `Navigate` というコンポーネントの両方を提供しています。

今回でいうと、navigate **ではなく** `Navigate` を利用する必要がありました。これもまたreactiveによります。

```typescript
function PrivateGuard() {
    const { authenticated } = useSignInSelectors();
    const location = useLocation();
    const navigate = useNavigate();

    if (!authenticated()) {
        navigate("/signin", { replace: true, state: location.pathname });
    }

    return <Outlet />;
}
```

最初は↑のように書いてました。まぁReactとかだとよくある感じだと思います。さて、これで実際 `/foo` にアクセスすると、どうなるでしょうか？なお、useLocationはlocationのreactiveなので、自動的に追跡されます。

・・・答えは、 **デフォルトのlocationが使われる** です。なんでかというと、このnavigateは、レンダリングの時に一回だけ呼び出され、そのまま固定されます。結局navigateは一度しか実行されない制御フローになっているためです。

これは、最終的には以下のように落ち着きました。

```typescript
const PrivateRoute: Component = () => {
  const { authenticated } = useSignInSelectors();

  const navigateToSignin = (args: { location: Location }) => {
    return `/signin?from=${args.location.pathname}`;
  };

  return (
    <>
      <Show when={!authenticated()}>
        <Navigate href={navigateToSignin} />
      </Show>
      <Show when={authenticated()}>
        <Outlet />
      </Show>
    </>
  );
};
```

(authenticated()は、認証されているかどうか？を表すreactiveです)

つまり、

-   reactiveを含む定数は関数に閉じ込める
-   テンプレートではリアクティブか関数だけを使う

というのを徹底すること、というのが、SolidJSでの重要な作法である、という感じでした。


### viteへの移行 {#viteへの移行}

SolidJSは、基本的にvite推しのようで(内部でrollupを利用しているので、一応今のプロジェクトは動くのは知っている)、viteに移行しました。

個人的には、色々勝手にやってくれるけどブラックボックスになっている・・・ってやつよりは、自分で全部書かないといけないけど把握できる方が好みなので、ここはまたエコシステム次第かな、とも思いつつ。

とはいえ、開発をするにあたっては非常に楽なのは確かだったので、学習用途か実践向けか？で変わってくるもんかなーという想像です。仕事でやるんだったらviteでいいや、感はありました。

ただし、移行の過程で、swc/esbuildがJSXの処理について **Reactしか対応していない** という絶望を味わいました。tscを直接利用するのはもう遅すぎてやってられないのでどうしようかな・・・となりました。

とりあえずは、babel(without 型チェック)を使ってます。これはこれでそれなりに速いので、今のプロジェクト規模くらいならまぁ大丈夫かな、というところで。


## 移植してみての感想 {#移植してみての感想}

大分reactiveに苦戦はしましたが、なんだかんだロジックとかの修正は必要なかったので、ほぼ修正はstate management周辺と、コンポーネントの調整に終始しました。

本来はlazy componentとかも使ってみた方が色々楽だとは思いましたが、とりあえずそこまでのサイズでもないので、一つにまとめてあります。

-   recoilよりも素直にreactiveな処理を書ける
    -   ギリギリに近いレベルで整えられたreactiveは、シンプルかつ必要十分かな、と思いました
    -   createStoreというのもあります。こっちはちょっと使いかたが違いますが、contextとして提供したくはない、さらに裏側にあるグローバルな状態、という感じかなと
    -   コンポーネントの中で使うsignalとかは、useStateに慣れていればまぁすぐわかるかなと
-   非同期の扱いが制約されている
    -   非同期を扱うときはcreateResourceで、みたいな話になっている。createEffectで副作用として非同期を・・・みたいなことはあんまり意味がない
-   制御フロー用途のコンポーネントが以外といい感じ
    -   Reactだと、三項演算子とかで事前に作っておいたコンポーネントを差し替える、という動的なものをよくやります
    -   が、SolidJSはそもそものレンダリングフロー自体が異なるため、それも宣言的に書いた方が結局は見通しがよくなる印象でした
-   注意しないとreactiveの沼にはまる
    -   devtool的なものはまだない(個人的にはあんまり使ったこともないですが)ので、結構な規模になってきて「動かないぞ・・・」ってなったときの追跡が結構難しかったです
    -   とはいえ、これは慣れで大体なんとかなる印象でした

実際やってみた感じだと、速度は十二分ですし、Reactが後付けで追加してきたHookなどの概念も整理されているといった、後発の利点を生かしている感じがありました。若干、CSSTransition的なものが少なかったり、transitionを表現するのが難しいといった、こういったライブラリによくある悩みはありますが・・・。


## 軽量かつ必要十分なライブラリです {#軽量かつ必要十分なライブラリです}

Reactで気にしないといけない系統のパフォーマンスや、DOMと微妙に異なる挙動など、Reactを使っていてうーんちょっとなーとなっている方は、一回使ってみると新しい世界が開けるかもしれません。

また、AngularでRxJSやReactive Formに苦しめられている方は、reactiveってこんなシンプルでもいいんだ、というまた別系統のリアクティブに触れられるかなーと思います。Vue3系列は触ったことないのでわかりませんが。

久し振りに新しいフレームワークに触れてみましたが、色々騒がれているのも納得な使い易さでした。ぜひ一度触れてみてはいかがでしょうか。


## 補足：参考にした資料 {#補足-参考にした資料}

ぶっちゃけ本家サイト以上に参考になるものはありませんでしたので、本家サイトにいきましょう。
