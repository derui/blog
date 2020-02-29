+++
title = "hygen.ioでboilerplateを自動生成すると捗る話"
author = ["derui"]
date = 2020-02-29T16:54:00+09:00
lastmod = 2020-02-29T16:54:08+09:00
tags = ["JavaScript"]
draft = false
+++

閏年の閏日ということなので（？）、記事を書いておきます。特別な日にでも書いておかないとアウトプットがないので・・・。

今回は、最近使い始めて結構いい感じになってきた、hygen.ioについてです。

<!--more-->


## hygen.ioとは {#hygen-dot-ioとは}

[hygen.io](http://www.hygen.io/)は、公式で以下のように紹介されています。

> The scalable code generator that saves you time.

簡単に書くと、MavenとかGradleとかで初期構成を自動生成したり、create-react-appとかで生成したりといった、code generatorの一つです。

特徴としては **速度** と **シンプルである** ことで、複雑なDSLを覚える必要は特になく、簡単に使い始められます。また、後述する `inject` という機能のおかげで、自動生成しつつ、その情報を別ファイルに埋め込む、みたいなことが割と簡単です。


### どんなprojectで使われてる？ {#どんなprojectで使われてる}

[ここ](https://github.com/jondot/hygen)を見ると大体わかりそうです。JavaScript界隈での有名企業が入っていたりと、それなりに広く使われているようです。

なお、gulpとかnpm scriptとかMakefileでも出来るんちゃう？という気もしますし、実際出来ると思いますが、code generatorとして特化した機能を提供しているhygenを利用する方が、設定のごった煮になる可能性が低いかな・・・という気がします。


## boilerplateを自動生成してみる {#boilerplateを自動生成してみる}

今個人で作業しているリポジトリでは、Reduxをmoduleという形で利用するとともに、多数のcommandというmoduleを生成する必要があります。ほとんどinterfaceだけは決まっているので、新しいcommandやmoduleを追加する度、同じようなファイルを生成したり、構造に気を使ったり・・・という作業が必要になります。

流石にこれはめんどくさい・・・となってきたので、hygenを利用していろいろ自動生成してみました。

hygen自体の使い方は[公式サイト](http://www.hygen.io/quick-start)を見てもらったほうが良いと思いますので、リンクだけ貼っておきます。今回作ったgeneratorの構造はこんな感じです。

> 実際に使っているのはもうちょっと色々追加されています。

```fundamental
--+ _template
  |-+ module
    |-- help
    |-+ init
    | |-- actions-test.ejs.t
    | |-- actions.ejs.t
    | |-- index.ejs.t
    | |-- inject_reducer.ejs.t
    | |-- inject_import-module.ejs.t
    | |-- inject_action-type.ejs.t
    | |-- reducer-test.ejs.t
    | |-- reducer.ejs.t
    | |-- types.ejs.t
    |-- new-action
```

これを使うと、こんな感じで新しいmoduleを追加したり、追加したmoduleに対して新しいactionを追加したり出来ます。

```text
# moduleの追加
$ npx hygen module init foo-bar
# actionの追加（promptでaction名を入力）
✔ What's name of action? · get-foo

Loaded templates: _templates
      inject: src/ts/modules/foo-bar/actions.ts
      inject: src/ts/modules/foo-bar/actions.ts
      inject: src/ts/modules/foo-bar/types.ts
```

ちょっと長いですが、 `init` generatorについて一つ一つ見てみましょう。 `new-action` generatorは、 `init` で生成されたファイルにinjectしているだけです。

また、実際には `modules/index.ts` というファイルがあり、ここで `combineReducers` とか全Actionをunionしたtypeを作ったりしています。


### 今回のReduxの構成について {#今回のreduxの構成について}

今回、reduxの構成は <https://github.com/erikras/ducks-modular-redux> に書かれている **Ducks** というパターンを若干改造したもの

`modules/<module name>/` というディレクトリの下に、action/reducerが全て置かれており、外部のmoduleに依存しないようにしています。実際に依存しないように出来るかどうかはともかく、現時点では割といい感触です。


### actionsの生成 {#actionsの生成}

action creatorとaction type、action creatorのtest caseの生成です。

```typescript
// actions-test.ejs.t
---
to: src/ts/modules/<%= name %>/actions.test.ts
---
import {actions} from "./actions";

describe("Modules", () => {
  describe("<%= h.changeCase.title(name) %>", () => {
    describe("Actions", () => {
    });
  });
});
```

```typescript
// actions.ejs.t
---
to: src/ts/modules/<%= name %>/actions.ts
---
import {ActionsType} from "../type";
import {ActionTypes} from "./types";

// implememt action. Use command `hygen module add:action [name of action]` to add template into this place.
//#ACTION INSERTION INDICATOR

// Do not delete this comment below.
// prettier-ignore
export const actions = {
};

// exporting all actions
export type Actions = ActionsType<typeof ActionTypes, typeof actions>;
```

```typescript
// types.ejs.t
---
to: src/ts/modules/<%= name %>/types.ts
---
// prettier-ignore
export const ActionTypes = {
} as const;
```

`types.ejs.t` では、 `actions.ejs.t` でactionの型を生成するためと、reducerでswitchするための定数を提供するものになっています。

`actions.ejs.t` において、何箇所か `// prettier-ignore` を付けているのは、prettierでの成形時にコードが崩れてしまうことを防止するために入れています。


### module全体のindex生成 {#module全体のindex生成}

これは基本的に最初に生成されたら変更されないので、特に変わったことはしていません。

```typescript
// index.ejs.t
---
to: src/ts/modules/<%= name %>/index.ts
---
import { Actions as Actions$ } from "./actions";
import { State as State$ } from "./reducer";

export type Actions = Actions$;
export type State = State$;

export { ActionTypes } from "./types";
export { actions } from "./actions";
export { reducer, emptyState } from "./reducer";
```


### 生成時の各ファイルへのinject {#生成時の各ファイルへのinject}

```typescript
// inject_action-type.ejs.t
---
to: src/ts/modules/index.ts
inject: true
skip_if: import.+<%= name %>
after: export type Actions =
---
  | <%= h.changeCase.pascal(name) %>.Actions
```

```typescript
// inject_import-module.ejs.t
---
to: src/ts/modules/index.ts
inject: true
skip_if: import.+<%= name %>
after: \/\/#IMPORT INDICATOR
---
<%_ const pascalName = h.changeCase.pascal(name) _%>
import * as <%= pascalName %> from "./<%= name %>";
```

```typescript
// inject_reducer.ejs.t
---
to: src/ts/modules/index.ts
inject: true
skip_if: <%= h.changeCase.pascal(name) %>.reducer,
after: export const reducer =
---
  <%= h.changeCase.camel(name) %>: <%= h.changeCase.pascal(name) %>.reducer,
```

この3ファイルは、既存のファイルへの `inject` を行うためのtemplateとなっています。 `inject` は、 `after` や `before` といったattributeで指定された正規表現に一致した場合かつ、 `skip_if` に指定された正規表現にマッチするものが存在しない場合に、templateの内容をinjectします。

正規表現によって差し込む位置を決定するのと、原則として行単位のinjectであるため、prettierなどで編集する度に自動でformattingするような設定になっていると、いざinjectするときに **ギャー!!** ってなりかねません（なった）。

なので、自動生成以外でいじらないような場所には、 `prettier-ignore` などを利用してフォーマットされないようにしておくことをオススメします。


### reducerの生成 {#reducerの生成}

```typescript
// reducer-test.ejs.t
---
to: src/ts/modules/<%= name %>/reducer.test.ts
---
import {reducer} from "./reducer";

describe("Modules", () => {
  describe("<%= h.changeCase.title(name) %>", () => {
    describe("Reducer", () => {
    });
  });
});
```

```typescript
// reducer.ejs.t
---
to: src/ts/modules/<%= name %>/reducer.ts
---
import {ActionTypes} from "./types";
import {Actions} from "./actions";

// state of type. Please redefine to what you want.
export type State = {};

export const emptyState: State = {};

export const reducer = function reducer(state: State = emptyState, action:Actions): State {
  switch (action.type) {
    default: return state;
  }
};
```

reducerの生成では、あえてaction typeのcase文を追加するようなことをしていません。実際には可能だと思いますが、reducerはロジックを書く場所なので、自由度を上げるため、あえて自動生成に乗せていません。


## 手を抜きつつ品質を上げるためにgeneratorを使おう {#手を抜きつつ品質を上げるためにgeneratorを使おう}

大体このような構成にするため、4時間くらい試行錯誤しました・・・。ただ、こういう自動生成する系は、何度も反復して利用することで結果的にコストを低減し、品質を向上させていくものです。

まだいくつかしか作っていませんが、boilerplateを書く必要がないというのは、かなり効率が良くなります。今回はTypeScript向けだったのでhygenを利用しましたが、他の言語でも似たようなものはあると思います。

**あー、なんか同じような構造をいっぱい書かないとならんなぁ** って思ったら、一度自動生成を検討してみてはいかがでしょうか。
