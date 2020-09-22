+++
title = "Create React App + TypeScriptにStorybookを追加してみる"
author = ["derui"]
date = 2019-02-23T11:17:00+09:00
lastmod = 2020-09-22T13:01:28+09:00
tags = ["JavaScript", "TypeScript"]
draft = false
+++

タイトルの通り、CRA2 + TypeScriptのプロジェクトに、更にStorybookを追加してみました。

<!--more-->


## 前口上 {#前口上}

いろいろ試すための個人プロジェクトを作って、色々なライブラリであったり、言語であったりを試しています。一応ツールとして利用したいと思って作っていはのですが、永遠に動くようにできないんじゃないかという懸念と戦いつつ実装しています。いつか日の目を見ることを祈りつつ・・・。

Frontendとしては[Electron](https://electronjs.org/)で作っていて、Create React App + TypeScriptでGUIを作っています。今回、これに[Storybook](https://storybook.js.org/)を追加することにしました。


## Storybookとは {#storybookとは}

[Storybook](https://storybook.js.org/)の公式から、Storybookについてを引用します。

> Storybook is a UI development environment and playground for UI components. The tool enables users to create components independently and showcase components interactively in an isolated development environment.
>
> <https://storybook.js.org/basics/introduction/>

Componentのカタログ（showcase）を作り、再利用を促しつつ、生きた例として提供する、という感じでしょうか。


## なぜ追加するのか {#なぜ追加するのか}

なんとなく＋気になるから。

・・・いつもどおりの理由ですが、実際コンポーネントベースの開発をしていると、 ****基底となるコンポーネント**** が欲しくなります。これがないと、同じようなものが量産されるというのを実際に経験してます。また、実際に動くものがあると、話がしやすいとかの効果もあるようです。デザイナーと協業とかしたことないので、デザイナーから見ても嬉しいのか？というのは実感できませんが・・・。

ただ、いきなりプロジェクトに投入するのはどうなんだ？ということで、どうとでもなる個人プロジェクトで試してみようという次第です。


## 追加する {#追加する}

今回使うプロジェクトの前提は以下のとおりです。

-   create-react-appの2.1以降
-   create-react-app公式の方法でTypeScriptを導入している

まずはStorybookを追加します。Storybook公式の手順は `npm` ですが、私は `yarn` を利用しているので、以下はyarn前提です。

```shell
$ yarn add -D @storybook/react
# もしかしたら下のコマンドはいらないかもしれない
$ npx -p @storybook/cli sb init

# TypeScript向けのlibraryを追加します
$ yarn add -D @types/storybook__react
$ yarn add -D @storybook/addon-info @types/storybook__addon-info react-docgen-typescript-webpack-plugin
$ mkdir .storybook
```

さて、これで追加自体はできるんですが、これだけだと動かないようで、[issue](https://github.com/storybooks/storybook/issues/4739)が立てられています。この中で示されている解決策を導入してみます。 `.storybook/webpack.config.js` として以下の内容を追加します。

```javascript
const TSDocgenPlugin = require("react-docgen-typescript-webpack-plugin");

module.exports = (baseConfig, env, config) => {
  config.module.rules.push({
    test: /\.(ts|tsx)$/,
    loader: require.resolve('babel-loader'),
    options: {
      presets: [require.resolve('babel-preset-react-app')]
    }
  });

  config.plugins.push(new TSDocgenPlugin());
  config.resolve.extensions.push('.ts', '.tsx');

  return config;
};
```

`.storybook/tsconfig.json` として以下を追加します。これは、StorybookとCRAが推奨するtsconfigの中身が異なり、かつCRAがtsconfigを推奨設定に自動的に書き換えてしまうため、とのことです。

```javascript
{
    "extends": "../tsconfig",
    "compilerOptions": {
      "jsx": "react",
      "isolatedModules": false,
      "noEmit": false
  }
}
```

`.storybook/config.ts` として以下を追加します。 `const req〜` と `loadStories` の中身がコメントアウトしてあるのは、単純に起動だけさせたかったためです。

```typescript
import { configure } from '@storybook/react';
// automatically import all files ending in *.stories.tsx
const req = require.context('../src/ts/stories', true, /.stories.tsx$/);

function loadStories() {
  req.keys().forEach(req);
}

configure(loadStories, module);
```

package.jsonにscriptを追加します。

```javascript
{
"scripts": {
    "storybook": "start-storybook -p 9001 -c .storybook"
  }
}
```


## 動かしてみる {#動かしてみる}

ここまでの設定をすると、次のコマンドで `http://localhost:9001` にStorybookが立ち上がります。

```shell
$ yarn storybook
```

まだstoryを一つも書いていないので当然ながらエラーになります。なのでstoryを書いてみます。


## Storyを書いてみる {#storyを書いてみる}

`list-item` というコンポーネントがあるという前提で、次のように書くことが出来ます。

```typescript
import { withInfo } from "@storybook/addon-info";
import { storiesOf } from "@storybook/react";
import * as React from "react";

import ListItem from "../components/ui/list-item/list-item";
// tslint:disable-next-line
const styles = require('./list-item.stories.module.scss');

storiesOf("List Item", module)
  .addDecorator(withInfo)
  .addParameters({ info: { inline: true } })
  .add("with text", () => {
    return <ListItem>Text</ListItem>;
  })
  .add("with other component", () => {
    return (
      <ListItem>
        <span style={{ color: "red" }}>Text in span</span>
      </ListItem>
    );
  })
  .add("with class names", () => {
    return <ListItem classes={[styles.base, styles.padding, styles.border]}>Item</ListItem>;
  })
  .add("with other container", () => {
    return <ListItem container="a">Link is container</ListItem>;
  });
```

直前に書いた `yarn storybook` を立ち上げたままにしておくと、勝手に読み込んでリロードしてくれます。


## 導入は簡単、活用は大変 {#導入は簡単-活用は大変}

ひとまずStorybookを導入してみましたが、これをちゃんと活用していくのは結構ハードルが高そうです。基底コンポーネント、Application固有のコンポーネント、とかがきっちり管理されていて初めてうまみがありそうな・・・。

とにかく、しばらく運用してみてからさらなる判断をしていきたいと思います。
