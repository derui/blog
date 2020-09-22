+++
title = "Enzymeの代わりにtesting-libraryを使うようにしてみた"
author = ["derui"]
date = 2020-04-05T13:47:00+09:00
lastmod = 2020-09-22T12:55:40+09:00
tags = ["JavaScript"]
draft = false
+++

いろいろコロナの影響が出てきましたが、いかがお過ごしでしょうか。会社でも東京勤務は基本的に在宅となりました。

今まで、ReactとかのIntegration testには[enzyme](https://enzymejs.github.io/enzyme/)を使っていましたが、[Preact](https://preactjs.com/)に切り替えた際に課題が多発したため、なんとかして解決してみました。

<!--more-->


## Preact + Enzymeの課題 {#preact-plus-enzymeの課題}

Enzymeは元々jsdomとセットで利用していたのですが、 `React -> Preact` に切り替えたとき、仕様の違いによってテストが動かなかったです。

主な違いとしては、

-   Preactではshallow renderingが出来ない
-   Portalで色々問題がある
    -   これはReactでも色々あるみたいなので、Preactに限ったことではないですが
-   React/Preactでeventの扱いが全く異なる

といったあたりです。特に既存のtestでshallow renderingを多用しており、大抵は動くのですが、 `React.createPortal` を使っているところが全滅でした。


## testing-library {#testing-library}

`React.createPortal` および Preactの `createPortal` ですが、いずれも **libraryの管理範囲外のDOMにrenderingする** というcomponentを構成します。

React.jsの場合、EnzymeのAdapter側でかなり色々やって対応しているようですが、Preactの場合、 **Componentを完全にrenderingする** というそもそもの仕様から、対応が無理っぽいです。ちゃんと見ていませんが、third partyがlibraryの内部実装に依存している、というのはあまりよろしくないように感じます。

また、よく考えると、jsdomとはいえ実DOMにrenderingするということは、もう **それはIntegration Testじゃないのか？** という意見を見て、 **( ﾟдﾟ)ﾊｯ!** となりました。そんな折に見つけたのが、[testing-library](https://testing-library.com/)です。

公式によると、testing-libraryは次のようなソリューションを提供するlibraryです。

> The Solution
>
> The Testing Library family of libraries is a very light-weight solution for testing without all the implementation details. The main utilities it provides involve querying for nodes similarly to how users would find them. In this way, testing-library helps ensure your tests give you confidence in your UI code.

Enzymeなどのtesting libraryが、component library（React/Vue/Angularなど）のinstance、component instanceという実装を直接さわるという機能を提供していることに対するcounter partという感じでしょうか。確かに、最終的には全部DOMとしてrenderingされないと、ユーザーからアクセスできません。eventの発行も、propsのevent handlerを直接発行するというのはユーザーは行えないはずです。

`testing-library` は、各component libraryに対しても同様のAPIを提供することで、どのcomponent libraryを利用しているかの影響を減らし、実世界と同様のoperationでテストすることを可能にします。


## 使ってみよう、testing-library {#使ってみよう-testing-library}

testing-libraryは、Jestと一緒に利用することで、jsdomのsetupとかをしなくてもテストを書けるようになっています。

```shell
$ yarn add @testing-library/preact preact jest jest-environment-jsdom
```

簡単なテストケースを書いてみます。

```js
import {h} from "preact";
import {render, fireEvent} from "@testing-library/preact";

const Component = ({onInput}) => (
    <div data-testid="container">
      <input data-testid="input" onInput={(e) => onInput(e.target.value)}>
    </div>
);

test("render component", async () => {
  const queries = render(<Component onInput={(v) => console.log(v)} />);

  const element = await queries.findByTestId("input");
  expect(element).toBeDefined();

  fireEvent.input(element, {target: {value: "foo"}})
})
```

`render` からは、[queries](https://testing-library.com/docs/dom-testing-library/api-queries)と呼ばれる関数群が返されます。このqueriesは、 `@testing-library/preact` からもexportされていますが、それとの違いは **containerとなるDOM要素を指定する必要があるかどうか** です。
queries関数の種類は、公式ページに定義が書いてあります。

testing-libraryでは、classやidというような属性でqueryすることを推奨せず、 `data-testid` という属性を利用することを推奨しています。（optionで利用する属性を変更できます）
data属性は、元々プログラムから利用することを念頭に置かれているため、test用途でも当然使えます。また、class名の変更やDOMの構造に影響されづらいこともあり、テストが壊れづらいというのも利点です。


## portalを使う場合のテスト {#portalを使う場合のテスト}

ReactやPreactでは、モーダルダイアログのようなものをそれぞれのAPIでコントロールするため、portalという仕組みを提供しています。しかしモーダルダイアログは、その仕様上React/Preactの管理外のDOMを必要とします。また、portalを利用してrenderingされたものは、管理外のDOMに対してrenderingされるため、enzymeとかでもテストがしづらいです。

```js
import {h} from "preact";
import {createPortal} from "preact/compat";
import {render, fireEvent, findByTestId} from "@testing-library/preact";

const Component = ({onInput, element}) =>
      createPortal(
          <div data-testid="container">
            <input data-testid="input" onInput={(e) => onInput(e.target.value)}>
          </div>,
        element
      );


test("render component", async () => {
  const element = document.createElement('div');
  render(<Component onInput={(v) => console.log(v)} element={element} />);

  const element = await findByTestId(element, "input");
  expect(element).toBeDefined();

  fireEvent.input(element, {target: {value: "foo"}})
})
```

createPortalを利用したcomponentをrenderでDOMに対してrenderingした場合、 `render` から返ってくるqueryではなく、 `@testing-library/*` からexportされているqueryを使う必要があります。しかし、全体を通して特定のAPIに影響されていないことが見て取れると思います。


## componentのtestを良くしていこう {#componentのtestを良くしていこう}

testing-libraryを使うと、propsの `onXxx` を実行して〜というのはイレギュラーである、というのがよくわかります。かなり深いcomponentにあるinputを取り出すのはいいのか？という意見もあると思いますし、個人的にも最初はいまいちピンときませんでした。ただ、結局inputのonInputとかと繋がっていないと意味がない、ということを考えると、 **Custom componentを一つでも含んでいるComponentのテストは、Integration Testなんだ** と考えるに至りました。

無論、現在Enzymeを使っていて問題になっていない、とかtesting-libraryと意見の相違がある、というのであれば、無理して使う必要はないと思います。ただ、なんかcomponentのpropsを取得したりすることに違和感を感じる方は、一回触ってみてはいかがでしょうか。
