+++
title = "Cycle.jsでReactのPortalっぽいことをしたい"
author = ["derui"]
date = 2022-12-25T21:57:00+09:00
tags = ["TypeScript"]
draft = false
+++

気付いたらクリスマスの夜なんですけどどういうことですか(困惑)。最近クリスマス = 平日なので一切特別感がなかったんですが、久々に休日がクリスマスになって特別感ありますね？(疑問)

ちょっとCycle.jsと長い戦いを繰り広げていますが、その中で一個やりたいことが多分できたので、軽いネタとして紹介します。

<!--more-->


## Portalとは？ {#portalとは}

もしかしたらPortalってなによ？という方もいらっしゃるかもしれないので紹介しておきます。私が知る限りこいつを一般的に広めたのはReact.jsだと思います。

> さっと探してみたりはしたんですが、2017年くらいのStackoverflowでReactのportalの話題があるくらいなので、コンポーネントライブラリとしてこういうのを追加したのはReact.js・・・で合ってるのかな？

<https://reactjs.org/docs/portals.html#gatsby-focus-wrapper>

詳しくは上記の公式ドキュメントが詳しいですが、要はよくあるモーダルダイアログ、つまりは **全体の上に表示されないといけないもの** を実装するということをシンプルにしてくれるやつです。上記のサンプルがClass baseなコンポーネントなのは結構古いままなんだろうか？


### Portalが使えるうれしさとは {#portalが使えるうれしさとは}

例えばですが、↓みたいな構造のHTMLになってて、モーダルは `#modal-root` ってことに出したいよ・・・っていうことを考えます。

```web
<html>
  <body>
    <div id="root">
      <!-- ここがアプリケーションのルート -->
    </div>
    <div id="modal-root">
      <!-- ここにモーダルとか出したい -->
    </div>
  </body>
</html>
```

よくある、フッターをクリックしたらデザインされたconfirmationを出したい・・・ってのがありますが、React.jsで普通にそれをやろうとすると、結構しんどいです。また、モーダルも大抵はコンポーネントとして作成すると思いますが、それらのモーダルに対してpropsを渡すとき、基本的には **表示するという主体を実行したいコンポーネントの中** にモーダルを宣言したくなります。が、普通にやると、それをやってしまうと `overflow:hidden` とか諸々にひっかかって悲しいことになることがよくあります。

Portalは、 **Componentみたいに扱えるけど、Componentとか違うところにレンダリングする** ということそのものをやってくれます。この恩恵はReact.jsにおいては結構大きいと思います。これがないと、外部のstateを利用しない限り、こういった出しわけができないですし。最近のReactが強烈に推し進めている、Functional Componentの上でも重要な機能だと思います。


## Cycle.jsでPortalを作ってみる {#cycle-dot-jsでportalを作ってみる}

Cycle.jsでは、副作用はdriverとして **扱わなければならない** というのがルールです。PortalはDOMを扱うので、自然とdriverになります。

とりあえずの実装は以下のようになりました。解説は後で。

```typescript
import { Driver } from "@cycle/run";
import { Stream } from "xstream";
import { VNode } from "snabbdom";
import { IsolateableSource } from "@cycle/isolate";
import { div, MainDOMSource, makeDOMDriver } from "@cycle/dom";

// Portalが受け取る = コンポーネントから渡されるSink
export interface PortalSink {
  [k: string]: VNode;
}

// Portalが返す = コンポーネントが受け取るSource
// isolateで諸々区別したいので、IsolateableSourceを継承している
export interface PortalSource extends IsolateableSource {
  DOM: MainDOMSource;
  isolateSource(source: PortalSource, scope: string): PortalSource;
  isolateSink(sink: Stream<PortalSink>, scope: string): Stream<PortalSink>;
}

// Sourceの実装
class PortalSourceImpl implements PortalSource {
  public DOM: MainDOMSource;

  constructor(private _rootDOM: MainDOMSource, private _rootSelector: string, private scopes: string[]) {
    this.DOM = this._rootDOM;
  }

  isolateSource(_: PortalSource, scope: string): PortalSource {
    return new PortalSourceImpl(this._rootDOM, this._rootSelector, [...this.scopes, scope]);
  }

  isolateSink(sink: Stream<PortalSink>, scope: string): Stream<PortalSink> {
    return sink.map((portals) => {
      return Object.entries(portals).reduce<PortalSink>((accum, [key, value]) => {
        accum[`${scope}-${key}`] = value;

        return accum;
      }, {});
    });
  }
}

// Portal driverの実装 makeXxxDriver、というのがCycle.jsにおける慣習なので、それに合わせてます
export const makePortalDriver = (selector: string): Driver<Stream<PortalSink>, PortalSource> => {
  const dom = makeDOMDriver(selector);

  return (sink) => {
    const vnode = sink.map((portals) => {
      const portalNodes = Object.entries(portals).map(([key, portal]) => {
        return div(`.portal-${key}`, [portal]);
      });

      return div(portalNodes);
    });

    return new PortalSourceImpl(dom(vnode), selector, ["root"]);
  };
};
```

さて、これはCycle.jsを触ったことがある人でないと全然わけわからんので、いくつか解説してみたいと思います。なお、この解説は私の理解の範囲で実施するため、正確ではないことを事前にお断りしておきます。ごめんなさい。


### 型定義 {#型定義}

コメントにも書いてますが、Cycle.jsでは、Source/Sinkというものが基本的な単位として定義されています。SourceはComponentのInputであり、DriverのOutputです。同様にSinkはComponentのOutputであり、DriverのInputです。

つまり、Componentからの副作用 = Outputを受け取り、副作用を実施した結果なりをComponentのInputとするもの、というのがCycle.jsにおけるDriverの定義です。

詳しくは↓公式の例を見るとフーンとなると思いますが、公式の例が必ずしもわかりやすいとは限らないので・・・。

<https://cycle.js.org/drivers.html>


### isolate {#isolate}

Cycle.jsでは、isolateという概念が存在します。これは、例えばDOMにおいて `select` みたいな一般的に利用されるセレクタを用いてしまうと、本来操作したいもの以外も操作されてしまう・・・みたいなことが発生しうる問題に対処するためのものです。(私の理解では)

たとえば一番利用されるDOMドライバーでは、これを指定しない場合、 **同じコンポーネントを並べて利用すると、本来想定しない結果になる** というのが、公式の例で示されています。

今回のPortalでは、実際にはこれが無くてもよいかも・・・ってはなったんですが、実際にはないと色々問題になるので追加しています。


### isolateSinkの中 {#isolatesinkの中}

今回のportalでは、一つのComponentから複数のportalを定義することを許容しています。これは、例えばDialogの中でなんかのsuggestionを提供するとか、そういった事例が実際に発生したため、否が応にも対応せざるをえなくなったものです。

具体的にはisolateにおけるscope(まぁDOMとかでselectorが指定されているもんだと思って貰えれば間違いじゃないです)と、Portalに渡されたキーによって、ユニークなDOMを構成しようという試みです。

```typescript
export const Component = () => {
  ...

    return {
      Portal. xs.of({
        foo: xs.of((<div>foo</div>)),
        bar: xs.of((<span>bar</span>))
      })
    }
}
```

↑こんなことができます。この場合、 `portal-foo` というclassと、 `portal-bar` というclassを持つそれぞれ別々のdivが生成されるようにしています。

なんでこんな迂遠な方法を取っているのかというと、Cycle.jsが標準で利用しているsnabbdomでは、fragmentはまだexperimental(実際、利用してみたがよくわからんundefinedエラーが発生したので一旦諦めた)であるため、下手にfragmentを利用すると予期せぬ結果になりがち・・・、というのが大きいです。


### 番外：DOMのisolateはしなくていいの？ {#番外-domのisolateはしなくていいの}

Cycle.jsをすでに利用している方からすると、 **なんでmakeDOMDriverの結果をisolateしてないの？** という疑問が浮かぶかと思います。一体何人がそう思うかは別として。

isolateしない場合の問題は前述した通りなのですが、今回の実装でisolateしていないのには一応理由があります。実はこの実装、バージョン3くらいで、この前の実装ではisolateしたものを利用していました。

が、isolateした実装を通した際、イベントが正しく発火しない、という問題に遭遇しました。正確には正しく発火はしているのですが、Component内でeventを取得するように記述しているはずが取得されない・・・という問題にぶちあたりました。

さしあたって、全体で同一のものを利用するようなセレクタを記述していなかったので、一旦isolateしていないものを利用することでお茶を濁しています。恐らくは、isolateを正しく逆順に適用していけばいけるんじゃないかな・・・と思ってはいるんですが、そこについては未検証です。


## Portalを利用することの利点 {#portalを利用することの利点}

React.jsでは、すでに存在する / しないけど外部で作成できるDOMにレンダリングした状態で、Componentの一部として利用できる、という利点がありました。はたしてCycle.jsではどうでしょうか？

個人的なn = 1の意見では、Cycle.jsでも同様に利点はあります。

Cycle.jsは、React.jsやSolidjs、もしくはReact.js専用のstate managementであるRecoilなどのようなリアクティブとは異なり、 **完全にStreamのみで構成される** ことが特徴です。そういった意味では、RxJSを基盤として利用しているAngularと似通っているかもしれません。

> ただ、Angularをお仕事で利用している身からすると、Angularの方がよりStreamの機能を制約して利用している・・・という気分になります。DIとかありますしね。

また、Cycle.jsの特徴としては、フラクタクルであること、というのが挙げられます。これはState管理などでも特徴として挙げられていますが、isolateなどを利用する場合でも、 **あるコンポーネントは原則としてmainと交換可能** である、ということです。単一コンポーネントの動作確認する、というやつではこれは役立ちます。

Portalを利用できると、あるコンポーネントが、自身に責務の範囲がある状態を、コンポーネントの中に閉じこめられるようになります。これはReactでもAngularでも重要視される事象ですが、Streamのみでstate管理もpropsの受け渡しも行うCycle.jsでは、より大きな意味を持ちます。

最近ではReact.jsでもコンポーネントに閉じて副作用を管理したり(Promiseは副作用ではない!っていう言説も見たことあります。Streamの世界に生きてると区別はなくなりますが、そうじゃないなら区別が必要じゃないのかな？と思ったりしなくもないですが)、AngularでもPageレベルでのstate管理などをしたりすることができます。が、Cycle.jsが提供する標準のstate管理は、ReduxのようにSingle State of Truthなグローバルのstateのみ、となっています。

> これは、コンポーネントローカルな状態についてはStreamを利用したら簡単にできることから、あえてこのような形になっていると思われます。多分。

前述した通り、Cycle.jsではすべてはstreamで表現されるのですが、コンポーネント間を跨いだ状態遷移をやろうとすると、どうしてもルートコンポーネントの責務として表現せざるをえなくなります。これが積み重なると、ルートコンポーネントが筆舌に尽くし難いレベルでstreamを繋ぎ込む必要が出てきて、数千行くらいしかないアプリケーションでも、すぐさま人間が理解できないものができあがってしまいます(実体験)。
Portalを利用して、副作用をDriverとして表現したうえで、Comopnentそれぞれにある程度責務を分散することができると、結果としての見通しは大分よくないます。


## Streamの楽しさと苦しさ {#streamの楽しさと苦しさ}

RxJSを利用したアプリケーションを管理運用している方はすでに身にしみていると思いますが、Streamを利用することによる利点と欠点は、結構両極端に出ることが多いと思います。個人的には、Cycle.jsでひたすら苦しんだことにより、AngularがStreamの扱いでかなり気をつかった実装になっていることに気づきました。

とはいえ、Cycle.jsの利点は、純粋関数(的)なコンポーネントを量産することによって、個々の複雑さを低減したり、テスタビリティを向上したりすることが容易いことだと思ってます。

なんか辛いな・・・と思ったら、ちょっと立ち止まって、それを副作用として切り出せないかを考えてみる、というのは、一つ手段としてありなのではないでしょうか。是非おためしあれ。
