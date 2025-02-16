+++
title = "jotaiを利用したlogicとDIの関係"
author = ["derui"]
date = 2025-02-16T15:12:00+09:00
tags = ["TypeScript"]
draft = false
+++

今年の２月は久しぶりに冬らしい感じですね。やはり昔より寒さに弱くなった気がします。

最近TypeScriptのappを、reduxからjotaiで書き直し終わったので、その過程で考えたりやったことをとりとめもなくまとめて見ようかと思います。

<!--more-->


## 素朴にjotaiを利用するpros/cons {#素朴にjotaiを利用するpros-cons}

> jotaiってなに？は特に書きませんので、 <https://jotai.org/> 公式ドキュメントをご覧ください。

jotaiのsampleだと、以下のような形が紹介されています。

```typescript-ts
// from https://jotai.org/
import { useAtom } from 'jotai'

import { animeAtom } from './atoms'

const AnimeApp = () => {
  const [anime, setAnime] = useAtom(animeAtom)

  return (
    <>
      <ul>
        {anime.map((item) => (
          <li key={item.title}>{item.title}</li>
        ))}
      </ul>
      <button onClick={() => {
        setAnime((anime) => [
          ...anime,
          {
            title: 'Cowboy Bebop',
            year: 1998,
            watched: false
          }
        ])
      }}>
        Add Cowboy Bebop
      </button>
    </>
  )
}
```

つまり、component layerから直接atomを参照する、というやり方です。これのpros/consを考えてみます。

-   pros
    -   依存関係が自明になる
    -   atomの変更時にre-render対象のcomponentが直接的になる
-   cons
    -   atomの構造変更がcomponentに波及してしまいやすい
    -   一つのatomを使いまわしづらい
        -   特にobjectとかになると、全体の要求を満たすためにいらんpropertyが生えがちです
    -   勝手に更新することができてしまう
        -   全体をexportしなければいい話なんですが、大抵はどっかのタイミングでexportしてしまって・・・ってなりがちです（でした）

つまるところ、そのまま利用するだけだと、どうしてもよくある状態管理辛いモードになってしまいそうです。ではどうしていくのがよいのか？というところです。


## jotaiの構成案 {#jotaiの構成案}

jotaiの特色は **reactive** であることと、 **derived/write-onlyなど用法を強制できる** ことだと私は思っています。reactiveを活かそうとすると、関連するreactiveは一箇所にまとめて置きたいところです。しかし、全部まとめてしまうと、一箇所のatomの変更が結果として全体の更新を招くことにもつながりかねません。

実際、atomをderivedとして利用したい場合ってどんな場合でしょう？

-   ユーザーの操作から起動したasyncが完了したら自動的に伝播させたい
-   関連したデータの読み込みが全部終わってから計算したい

大体はここのあたりになるんではないでしょうか。これらってComponentの中においたほうがいいでしょうか？多分ある程度の規模になると、custom hookを作成してまとめることになるでしょう。つまり、 **Atomは基本的にComponentから利用しないほうがよい** と考えます。結局大体一緒ですね。

```text
src - hooks ┯ atom.ts
            ┗ foo.ts

// または
src - atoms - bar.ts
    - hooks - foo.ts
```

みたいな形で、componentからはatomが見えない形にするのが基本形としたいところです。ただ、JavaScriptの世界はOCamlとかと一緒でprivate moduleとかそういった概念はないので、厳密に守らせたいとかであれば、eslintなどでやるのが現実的でしょう。


## logicはatomなのかhookなのか {#logicはatomなのかhookなのか}

よくある言説では、 **hookはlogicである** とされていますが、jotaiと一緒に利用する場合は、正確には **フロント向けのロジック** がhookである、という感じになるかと思います。jotai自体がasyncのhandlingもできるため、SWRなどを利用する必要が大分薄くなるのもありますが、全部のatomをread/writeにして外部に公開するよりは、 **moduleのinterfaceとしてread only/write only atomのみexportする** ほうが管理という面では有利ではないでしょうか。

```typescript-ts

// baseになるatom
const baseInfo = atom({text: ""});

// read only atom
export const upperInfo = atom((get) => {
  return get(baseInfo).text.toUpperCase()
})

// write only atom
export const writeInfo = atom(null, (_get, set, text) => {

  set(baseInfo, {text: text.trim().toLowerCase()})
})
```

baseInfoを露出して利用するところで加工したらいいじゃん、ってのはあるので、加工についてはderived atomでbaseInfoをそのまま返す、っていうのもありだとは思いますが、writeについてはwrite only atomにしばっておいたほうがよいかなと考えてます。pros/consとしては以下となるかなと。

-   pros
    -   書き込みを行うinterfaceが成約されることにより、編集箇所が特定しやすい
    -   derivedをかますことにより、loadingなどを付加することもできる
-   cons
    -   常にwrite onlyとderivedを定義しなければならないため、ボイラープレートが多くなる
    -   single stateに全体を入れた場合、atom全体の定義が巨大になる

redux的にsingle atomに全体を投入するのは、jotaiの思想的にそもそもマッチしていないとは思うので、ここについてはまた色々ありそうです。


## atomのlogicに対するテストとDI {#atomのlogicに対するテストとdi}

さて、atomにlogicをいれるとして、fetchとかそういったものだったり、別途serviceのような外部ロジックを呼び出すとして、どうやってテストを書いていけばよいでしょうか？fetchやrepositoryといったものをjotaiの中で利用している場合、jotaiの仕組み上importしてくるのが一般的です。ただ、JavaScriptのimportは静的な解決になるため、基本的にはinjectionをすることが難しいです。

ただ、UT時に差し替えたいだけなら、jestやvitest（現時点だとvitestをおすすめします）であればmockを利用することができます。Javaとかに慣れ親しんでいると、「interfaceやんなきゃ」とか思いますが、JavaScriptだとmoduleという単位がlogicの単位なので、module自体がconstructorである、と考えることもできます。実際、 `vi.mock` が存在し、普通に利用されていることから、moduleを一つの単位として利用することは理に適っているでしょう。

> Angularのような、独自の思想で構築されているようなlibraryは例外ですが。Angularの世界だと、明示的なDIが存在しています。ただ、とにかく引っかかったときの解決が厄介なので、個人的には良い思い出はないです。

もし利用しているmoduleが、複数の実装をもっていて、置き換えることを想定している場合、テストのときだけresolveを変更することもできます。

```javascript
import { mergeConfig } from "vite";
import { defineConfig } from "vitest/config";
import viteConfig from "./vite.config";

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: "jsdom",
      include: ["src/**/*.test.{ts,tsx}"],
      alias: {
          // testのときだけmock実装に置き換える
        "@spp/shared-domain/voting-repository": "@spp/shared-domain/mock/voting-repository",
      },
    },
  })
);
```

こうすると、mockの定義などを必要とせずにテストを書いていくことができます。当然これは万能ではないので、あくまでもこういう方法もありますよっていうことで。実際のapplicationでの実装を切り替える場合は、vite.configでresolve設定する、とかもできます。


### jotaiに依存するhookのテスト {#jotaiに依存するhookのテスト}

では、jotaiに依存するhookをテストするときはどうしたら良いでしょう？atomをmockしたほうがいいんでしょうか？

個人的には、atomに依存したhook自体のテストは、一種のintegration testとして捉えたほうがいいのではないか、と考えています。それは、

-   atomを正しくテストするためには `Provider` を利用してReactの枠組みで実行する必要がある
-   前述のように分解している場合、そもそもベースになる値を用意できない

ためです。外部のlibraryの実体をmockするのは悪手と言われている（要出典）こともあるので、jotaiを下手にmockしないほうがよいでしょう。hookのテストにjotaiの内部状態まで入って来ますが、ITはもともとそういうものなので、特に問題ないかなと思います。逆にhookを一種の緩衝として利用することで、hookを利用するcomponentについては、hookをmockにしても問題なくなります。ここについてはtrade offとなりますが、関心の範囲としては適当かな、とは思ってます。


## 何を使っても状態管理はしんどい {#何を使っても状態管理はしんどい}

jotaiだろうがzustandだろうがsignalsだろうが、状態というものを管理するのは本質的に辛いお仕事になります。そこにロジックも考えるとなるともう大変です。Reactではhookの登場以来、hookを様々な用途で利用することが基本形になりました。jotaiもhook利用が前提のlibraryですが、hookはcomponentと簡単に密結合してしまうので、jotaiのatomをcomponentで直接触ってしまうのは基本的にしないほうがいいのではないかと思います。

jotaiはむしろlogicと状態を集約して管理することができるというところにして、hookをフロントとのやり取りを行うlayerとして改めて認識することで、管理と開発のバランスが取れたりするんではないでしょうか。個人的にはDIをわざわざ手動でやるめんどくささを、importしているmodule自体が明示的なdependencyであるというところに改めて気づけたので、取れる戦略の幅が広がりそうでした。
