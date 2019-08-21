+++
title = "手動で作るReact + TypeScript環境（2019/8版）"
author = ["derui"]
date = 2019-08-21T22:27:00+09:00
lastmod = 2019-08-21T22:28:09+09:00
tags = ["JavaScript"]
draft = false
+++

最近、React＋TypeScriptの開発環境を作る場合、大抵は[create-react-app](https://github.com/facebook/create-react-app)を利用するケースが多いと思います。

実際、種々のベストプラクティスであったり、単純にアプリケーションを作る方にフォーカスする場合、create-react-appを利用するのがbetterです。ただ、色々な要因でejectせざるを得ない状況に追い込まれると、結構厳しいケースが多いです。実際公式でもejectは非推奨です。

そういうときに備えて（？）、０から環境を作ってみましょう。こういう経験をしておくと、ejectすること無くいろいろすることが出来ます。

<!--more-->

今回作っていって見る環境は、次のような環境です。

-   React + TypeScriptで書ける
    -   TypeScript内では、moduleは相対パスではなく、 `@/hoge` のようにしてアクセスできる
-   TSXで書ける
-   ESLintでlintできる
-   prettierでformatting
-   Jest＋enzymeでユニットテスト
-   webpack-dev-serverでhot reloading
    -   Componentのreloadは色々問題もあるのでやりません


## Reactの導入 {#reactの導入}

まず新しいpackageを作りましょう。ここでは `react-handmade-sample` という名前で作ります。

```sh
$ mkdir react-handmade-sample
$ cd react-handmade-sample
$ npm init
```

次に、React関連のパッケージをインストールします。styled-componentsは趣味なので、無くてもいいです。

```sh
$ npm install react react-dom styled-components
```


## Webpackの導入 {#webpackの導入}

[Webpack](https://webpack.js.org/)は、現時点でデファクトbundlerです。非常に設定量が多いと思われがちですが、必要最小限であれば、意外と量は少ないです。とりあえず必要なので入れます。webpack-dev-serverもついでにいれます。

```sh
$ npm install webpack webpack-dev-server
$ npm install html-webpack-plugin tsconfig-paths-webpack-plugin
```

Webpackは、developmentの場合に使う基本設定と、production時に利用する設定の二通りを用意しますが、とりあえずはdevelopmentの設定だけ記述します。

```js
// webpack.config.js
const path = require('path');

module.exports = function(isProduction) {
  return {
    mode: "development",

    entry: path.resolve(__dirname, "./src/index.tsx"),
    // ファイルの出力設定
    output: {
      //  出力ファイルのディレクトリ名
      path: path.resolve(__dirname, 'dist'),
      // 出力ファイル名
      filename: "index.js"
    },
    module: {
      rules: [
      ]
    },
    resolve: {
      extensions: [".ts", ".tsx", ".js", ".json"],
      plugins: [
      ]
    },
    plugins: [
    ]
  };
};
```

空っぽに近いですが、とりあえず最小限です。


## TypeScriptの導入 {#typescriptの導入}

TypeScriptを書く以上、TypeScriptの導入は避けられません。ただ、webpackを利用するので、TypeScriptを直接入れると言うよりは、[ts-loader](https://github.com/TypeStrong/ts-loader)を導入します。BabelでもTypeScriptを利用できるのですが、Babelの場合、TypeScriptで得られる利点のいくつかを捨てることになります。なので、全体をTypeScriptで書く場合は素直にts-loaderを使うほうがよいかと。

```sh
$ npm install ts-loader tsconfig-paths-webpack-plugin @types/react @types/react-dom
```

tsconfig-paths-webpack-pluginは、[TypeScriptのpathsオプション](https://www.typescriptlang.org/docs/handbook/compiler-options.html)をwebpack内で利用する際に使います。これがないと、TypeScript→JavaScriptしたあとのbundleが動きません。

TypeScriptを使えるように、webpack.config.jsを書き換えます。

```js
const path = require('path');
const TsconfigPathsPlugin = require('tsconfig-paths-webpack-plugin');

module.exports = function(isProduction) {
  return {
    mode: "development",

    entry: path.resolve(__dirname, "./src/index.tsx"),
    // ファイルの出力設定
    output: {
      //  出力ファイルのディレクトリ名
      path: path.resolve(__dirname, 'dist'),
      // 出力ファイル名
      filename: "index.js"
    },
    module: {
      rules: [
        {
          test: /\.tsx?$/,
          use: {
            loader: 'ts-loader',
            options: {
              configFile: "tsconfig.json"
            }
          }
        }
      ]
    },
    resolve: {
      extensions: [".ts", ".tsx", ".js", ".json"],
      plugins: [
        new TsconfigPathsPlugin({ /*configFile: "./path/to/tsconfig.json" */ }),
      ]
    },
    plugins: [
    ]
  };
};
```


## TypeScriptの設定 {#typescriptの設定}

`@/hoge` のようにアクセスできる出来るようにするための設定を含めて、tsconfig.jsonを書きます。tsconfig.jsonは普通にpackage.jsonと同じディレクトリに置いておきます。

```js
{
  "compilerOptions": {
    "sourceMap": true,
    "target": "es2015",
    "module": "es2015",
    "jsx": "react",
    "moduleResolution": "node",
    "lib": [
      "es2019",
      "dom",
      "dom.iterable",
      "esnext"
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    },
    "strictNullChecks": true,
    "strict": true,
    "incremental": true,
    "isolatedModules": true,
    "resolveJsonModule": true,
    "esModuleInterop": true
  },
  "include": [
    "./src/**/*.ts",
    "./src/**/*.tsx"
  ],
  "exclude": [
    "./node_modules",
    "./src/**/*.spec.ts",
    "./src/**/*.spec.tsx",
    "./src/**/*.test.ts",
    "./src/**/*.test.tsx"
  ]
}
```

今回はモダンブラウザだけを対象にするので、ES2015の形式にします。この辺りは各自の事情に依るので、あくまで一例です。

excludeでテストを抜いているのは、こうしないと色々問題があるのでこうしています。testは別ディレクトリに置く場合は、多分無くても大丈夫です。


## webpack-dev-serverの設定 {#webpack-dev-serverの設定}

`webpack.dev.js` として以下のような内容を作ります。

```js
const config = require("./webpack.config.js");

module.exports = Object.assign(config(false), {
  devtool: 'eval-source-map',
  devServer: {
    port: 3000,
    contentBase: 'dist',
    watchContentBase: true,
  },
});
```

もともとのconfig.jsを再利用し、dev-serverの設定を追加します。


## ESLintの設定 {#eslintの設定}

ESLintを導入します。TSLintを使わず、ESLintだけでやっていきます。

```sh
$ npm install eslint eslint_d eslint-config-prettier eslint-import-resolver-webpack eslint-plugin-import eslint-plugin-prettier eslint-plugin-react @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

他にもいろいろ導入しています。この辺りはプロジェクトとか好みとかに依るかと。

`.eslintrc.js` を作ります。parserやpluginの設定、後はtsconfig.jsonやwebpack.config.jsの取り込みを行っています。

```js
module.exports = {
  plugins: ["@typescript-eslint"],
  parser: '@typescript-eslint/parser',
  extends:  [
    'plugin:prettier/recommended',
    "plugin:react/recommended",
    "plugin:import/errors",
    "plugin:import/warnings"
  ],
  env: {
    es6: true,
    browser: true,
  },
  parserOptions:  {
    ecmaVersion:  2018,  // Allows for the parsing of modern ECMAScript features
    sourceType:  'module',  // Allows for the use of imports
    ecmaFeatures:  {
      jsx: true,  // Allows for the parsing of JSX
    },
    project: "./tsconfig.json",
  },
  rules: {
    "import/no-default-export": "error",
    "react/jsx-uses-vars": ["warn"],
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/no-unnecessary-type-assertion": "error",
    "prettier/prettier": ['error'],
  },
  settings:  {
    react:  {
      version:  'detect',
    },
    "import/resolver": {
      "webpack": {
        "config": "webpack.config.js"
      }
    }
  },
}
```


## prettierの追加 {#prettierの追加}

フォーマットは、四の五の言わずprettierを使います。prettier\_dを導入しているのは、Emacsで開発する際に、prettierをそのまま使っているとめっちゃ重いからです。

```sh
$ npm install prettier prettier_d
```

`.prettierrc` はこんな感じで。semiは個人的な好みです。付けていかなくても、prettierが勝手に付けてくれるので、あんまり気にしなくていいです。

```js
{
  "semi":  true,
  "trailingComma":  "es5",
  "singleQuote":  false,
  "printWidth":  120,
  "tabWidth":  2
}
```


## Jestの導入 {#jestの導入}

テストランナーは、だいたいデファクトになったJestを使います。

```sh
$ npm install jest ts-jest @types/jest
```

jestの設定は、個別の設定とかも出来るようですが、とりあえずpackage.jsonを使います。

```js

"jest": {
  "transformIgnorePatterns": [
    "[/\\\\]node_modules[/\\\\].+\\.(js|jsx|ts|tsx)$"
  ],
  "watchPathIgnorePatterns": [
    "node_modules"
  ],
  "moduleNameMapper": {
    "^@/(.+)": "<rootDir>/src/$1"
  },
  "moduleFileExtensions": [
    "ts",
    "tsx",
    "js"
  ],
  "setupFilesAfterEnv": [
    "<rootDir>/scripts/setupTests.ts"
  ],
  "moduleDirectories": [
    "node_modules"
  ],
  "transform": {
    "^.+\\.(ts|tsx)$": "ts-jest"
  },
  "globals": {
    "ts-jest": {
      "tsConfig": "tsconfig.json"
    }
  },
  "testMatch": [
    "**/__tests__/*.+(ts|tsx|js)",
    "**/*\\.spec\\.+(ts|tsx|js)",
    "**/*\\.test\\.+(ts|tsx|js)"
  ]
}
```

ts-jestとtsconfig.jsonを使うことで、pathsの問題とかも解消できます。 `setupFilesAfterEnv` という部分に知らない設定がありますが、これはすぐあとで設定します。


## Enzymeの設定 {#enzymeの設定}

Componentのテストを効率よくやるために、enzymeを追加します。

```sh
$ npm install enzyme @types/enzyme enzyme-adapter-react-16
```

`scripts/setupTests.js` を、以下のような内容で作成します。

```js
import { configure } from "enzyme";
import Adapter from "enzyme-adapter-react-16";

configure({ adapter: new Adapter() });

export default undefined;
```


## npm scriptsの設定 {#npm-scriptsの設定}

最後に、npm scriptsを追加します。

```js
"scripts": {
  "start": "webpack-dev-server --config webpack.dev.js",
  "lint": "eslint 'src/**/*.ts[x]'",
  "test:onetime": "jest --env=jsdom",
  "test": "jest --env=jsdom --watch"
},
```

lint自体は、webpackの設定に組み込んで、webpack-dev-serverを実行している間にも実行することも出来ます。その辺りの設定は難しくないので、必要ならやってみるといいかと思います。


## これは基本設定です {#これは基本設定です}

この辺りは、あくまで基本設定です。CSS moduleを使ったり、SVGをrequireしたりするようにしたり、babelを導入したり・・・と、色々やっていくことは出来ます。

ただ、設定が増えると後で変更しづらくなったり、設定の影響が把握しづらくなったりするので、程々にしておくのがおすすめです。実際、このくらいでも十分に開発していくことが出来ます。時間のあるときにでも、一度０から設定する、というのもいかがでしょうか。
