+++
title = "Angularのチュートリアルにngrxでstate管理を追加する"
author = ["derui"]
date = 2019-01-27T16:51:00+09:00
lastmod = 2019-01-27T16:51:16+09:00
tags = ["JavaScript", "Angular", "Programming"]
draft = false
+++

諸事情（主に会社の事情）で、AngularとState管理について評価する必要が出ました。ただ、今までそもそもAngularを触ったことがなかったため、[Angular公式のTutorial](https://angular.io/tutorial/)をやることにしました。このTutorialが結構な分量なので、これにstate管理を追加すると丁度いいんでは？ということでやってみました。

<!--more-->


## Angular CLIのインストール {#angular-cliのインストール}

まずはAngular CLIをインストールします。基本的にglobal installを推奨しているようですが、global installはめんどくさい時もあるので、今回はlocal installでなんとかならんかやってみます。

```shell
$ yarn add -D @angular/cli
$ yarn ng new angular-tutorial --directory . --force
$ yarn ng serve --open
```

一回CLIだけをaddしてから、無理やり上書きするというパワープレイでいけます。ここからは、Tutorialを普通に進めます。


## Tutorialをやる（HTTP以外） {#tutorialをやる-http以外}

Tutorialを進めていきます。集中してやれば、大体2〜3時間で終わるくらいのボリュームです。ただ、今回はstate managementをやるのが目的なので、HTTPが絡むような部分はstubにしておきます。

とりあえずTurorialが完了しただけの状態が以下のリポジトリです。masterブランチがその状態です。

<https://github.com/derui/angular-tutorial-ngrx>

では、これにngrxを追加していってみましょう。


## ngrxとは {#ngrxとは}

Angularを表す **ng** と、RxJSを表す **rx** がくっついているのでだいたい想像がつきますが、RxJSを前面に出したAngular用のstate management libraryです。公式ページでは次のように表現されています。

> Store is RxJS powered state management for Angular applications, inspired by Redux. Store is a controlled state container designed to help write performant, consistent applications on top of Angular.

簡単に私の理解で言うと、RxJSのReactiveを利用したRedux的なパターンを提供するライブラリ、といった感じでしょうか。上に書いているように、Reduxにinspireされたとあるので、Single source of truthが念頭に置かれています。

Angular向けのstate managenentには、他にも[Akita](https://github.com/datorama/akita)などもあります。秋田出身としては、こっちの方が色々と気になります。が、今回はngrxを使っていきます。

ngrxには、Reduxとほぼ同じ概念である **reducers** 、 **actions** 、 **store** と、独自の概念として **selectors** と **effects** が主要なcomponentとなっています。


### selectorsについて {#selectorsについて}

今回のTutorialに追加する場合では、effectsは恐らく使わないですが、selectorsは使ってみたいと思います。ngrxのstoreでは、store全体の取得は基本的に行わず、selectorで特定の値だけを取得する、というのが基本のようです。

公式ドキュメントでは、次のように書かれています。

> Selectors are pure functions used for obtaining slices of store state. @ngrx/store provides a few helper functions for optimizing this selection. Selectors provide many features when selecting slices of state.
>
> <https://ngrx.io/guide/store/selectors>

react-reduxにある `mapStateToProps` を一般化した感じです。実際の使い方は、以降のソースで出てきます。


## ngrxを適用する {#ngrxを適用する}

ではまずngrxを追加しましょう。実戦で利用する場合、Schematicを追加してgenerate出来るようにしておくのが良さそうです。今回は学習が目的なので、必要最小限にとどめます。

```shell
$ yarn add @ngrx/store
```


## reducer/action/selectorを定義する {#reducer-action-selectorを定義する}

action/reducer/selectorを定義します。今回は次のstateについて、それぞれ一つのファイルにまとめましょう。heroesは、単にネストしているだけなので気にせず。

-   heroes
    -   allHeroes
    -   searched
-   messages

さっくり実装してみたソースはこんな感じです。

```typescript
// store/app.state.ts
import {Hero} from '../hero';

export type AppState = {
  heroes: HeroState;
  messages: MessageState;
}

export type HeroState = {
  allHeroes: Hero[];
  searched: Hero[];
};

export type MessageState = {
  messages: string[];
};
```

```typescript
// store/heroes.action.ts
import { Action } from "@ngrx/store";

export enum ActionTypes {
  Save = "Heroes Save",
  Search = "Heroes Search",
  Add = "Heroes Add"
}

export class Save implements Action {
  readonly type = ActionTypes.Save;

  constructor(public payload: { id: number; name: string }) {}
}

export class Add implements Action {
  readonly type = ActionTypes.Add;

  constructor(public payload: { name: string }) {}
}

export class Search implements Action {
  readonly type = ActionTypes.Search;

  constructor(public payload: { term: string }) {}
}

export type Union = Save | Add | Search;
```

```typescript
// store/heroes.reducer.ts
import { ActionTypes, Union } from "./heroes.action";
import { HEROES } from "../mock-heroes";
import { HeroState } from "./app.state";

export const initialState: HeroState = {
  allHeroes: HEROES,
  searched: []
};

export function heroesReducer(state = initialState, action: Union) {
  switch (action.type) {
    case ActionTypes.Add: {
      const id =
        state.allHeroes.reduce((acc, v) => (acc.id < v.id ? v : acc)).id + 1;
      const copied = Array.from(state.allHeroes);
      copied.push({ id, name: action.payload.name });
      return { ...state, allHeroes: copied };
    }
    case ActionTypes.Save: {
      const copied = state.allHeroes.map(v => {
        if (v.id !== action.payload.id) {
          return v;
        }
        return { ...v, name: action.payload.name };
      });
      return { ...state, allHeroes: copied };
    }
    case ActionTypes.Search: {
      const searched = state.allHeroes.filter(v =>
        v.name.startsWith(action.payload.term)
      );
      return { ...state, searched };
    }
    default:
      return state;
  }
}
```

```typescript
// store/heroes.selector.ts
import { createSelector } from "@ngrx/store";
import { AppState, HeroState } from "./app.state";
import { Hero } from "../hero";

const selectHeroes = (state: AppState) => state.heroes;

export const selectAllHeroes = createSelector(
  selectHeroes,
  (state: HeroState) => state.allHeroes
);

export const selectSearched = createSelector(
  selectHeroes,
  (state: HeroState) => state.searched
);

export const selectHero = createSelector(
  selectAllHeroes,
  (state: Hero[], props: { id: number }) => state.find(v => v.id === props.id)
);
```

```typescript
// store/messages.action.ts
import { Action } from "@ngrx/store";

export enum ActionTypes {
  Add = "Messages Add",
  Clear = "Messages Clear"
}

export class Clear implements Action {
  readonly type = ActionTypes.Clear;
}

export class Add implements Action {
  readonly type = ActionTypes.Add;

  constructor(public payload: { message: string }) {}
}

export type Union = Clear | Add;
```

```typescript
// store/messages.reducer.ts
import { ActionTypes, Union } from "./messages.action";
import { MessageState } from "./app.state";

export const initialState: MessageState = {
  messages: []
};

export function messagesReducer(state = initialState, action: Union) {
  switch (action.type) {
    case ActionTypes.Add: {
      const copied = Array.from(state.messages);
      copied.push(action.payload.message);
      return { messages: copied };
    }
    case ActionTypes.Clear: {
      return { messages: [] };
    }
    default:
      return state;
  }
}
```

```typescript
// store/messages.selector.ts
import { MessageState, AppState } from "./app.state";
import { createSelector } from "@ngrx/store";

const selectRoot = (state: AppState) => state.messages;

export const selectMessages = createSelector(
  selectRoot,
  (state: MessageState) => state.messages
);
```

reduxでreducer/actionを書いたことがあれば、特に悩むことはない感じだと思います。Actionは最初っからunionにしておくと、payloadが使えない！？みたいなどうでもいいエラーと戦わなくてもいいのでおすすめです。


## moduleを追加する {#moduleを追加する}

app.module.tsに、ngrxのstoreを追加します。これをしないと、そもそもstoreをDI出来ません。

```typescript
// app.module.ts
import { BrowserModule } from "@angular/platform-browser";
import { NgModule } from "@angular/core";
import { FormsModule } from "@angular/forms";
import { StoreModule } from "@ngrx/store";

import { AppComponent } from "./app.component";
import { HeroesComponent } from "./heroes/heroes.component";
import { HeroDetailComponent } from "./hero-detail/hero-detail.component";
import { MessagesComponent } from "./messages/messages.component";
import { AppRoutingModule } from "./app-routing.module";
import { DashboardComponent } from "./dashboard/dashboard.component";
import { HeroSearchComponent } from "./hero-search/hero-search.component";

import { appReducer } from "./store/app.reducer";

@NgModule({
  declarations: [
    AppComponent,
    HeroesComponent,
    HeroDetailComponent,
    MessagesComponent,
    DashboardComponent,
    HeroSearchComponent
  ],
  imports: [
    BrowserModule,
    FormsModule,
    AppRoutingModule,
    StoreModule.forRoot(appReducer)
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {}
```


## serviceかstore直接か {#serviceかstore直接か}

ngrxのstoreは、componentに直接DIして利用することが出来ます。ただ、この場合

-   storeの内部がcomponentに露呈する
-   想定していないactionの呼ばれ方をする

storeの内部がcomponentに露呈してしまうことの問題は、Redux+Reactでcontainer以外のコンポーネントでstateを直接触ってしまうことと同じ問題を生むと思われます。つまり、想定していない場所でのstate参照＝依存を生んでしまいます。

ngrxの場合は、原則observableであるということもあり、不要なsubscriptionが発生する可能性、つまりstoreの変更でどこがどう動くか？の把握が難しくなることも考えられます。
まぁ、serviceを介してobservableを返しても同じ感じはしますが。serviceから返される方が、一層分抽象層をはさむ分、stateの構造変化とかにも強くなるかと思います。

ただ、Angularにおけるcomponentは、ReactのComponentとは扱いが異なるような気がします。
Reactのcomponentは基本的にFunctionalに作っていくケースが多いですが、Angularはすべてclassですし、DIが最初から有効なので、Propsでのバケツリレーも不要です。今回のチュートリアルのような構成の場合、propsで受け渡すことも出来ません。

まぁ、このへんはいろいろ正解のないケースであることもしばしばあるので、一回componentでは直接storeを参照しないようにしてみましょう。


## serviceでstoreを使う {#serviceでstoreを使う}

HeroServiceでStoreを使うように書き換えていきます。基本的には、事前に定義しているselectorを使ってデータを取得したり、dispatchしたりという感じです。

```typescript

// HeroService
constructor(private messageService: MessageService, private store: Store<AppState>) {}

getHeroes(): Observable<Hero[]> {
  this.messageService.add("HeroService: fetched heroes");
  return this.store.pipe(select(selectAllHeroes));
}

updateHero(hero: Hero): Observable<any> {
  this.store.dispatch(new SaveHero(hero));
  return of();
}
```

updateは本質的に非同期になりそうですが、 `store.dispatch` の戻り値がvoidであるため、原則dispatchの処理が終わったら〜という処理は書けません。もし処理途中の表現が必要なのであれば、stateに状態を表すpropretyをはやして、それをselectすることになるかと思います。

component側では、内部に持っていたりしたstateを、serviceから取得したObservableを見るように書き換えていきます。component側は量が多いので、リポジトリを見てください。
概ねやっていることは、asyncにしたりobservableに合うように書き換えているというような具合です。


## やってみての感想 {#やってみての感想}

Angularを初めて触り、ngrxの適用までをやってみました。いくつかどうやるの？っていうのが残っています。いくつかはAngularの知識が無いためわからない、という可能性が非常に高いです。

-   非同期で更新して、成功したら遷移、みたいなのはどうやる？
    -   stateに成否を表すpropertyを作って、それをsubscribeしていろいろやる？
    -   effectでも基本的に出来ない気がする
-   データの一時的な編集はどうやるのがベター？
    -   Formみたいな項目があったので、やる方法自体はある？
-   storeをcomponentで利用するケースの考察
    -   ngrxのサイトでは基本的にcomponentから直接利用していた
    -   Reactでいうcontainer componentを使うより、DIするのがAngularの基本？

ただ、AngularはAll in oneなライブラリなので、全体を通して一貫性を重視しているように思います。
generateをポコポコ打ってサラサラ書けば出来る、というのはあくまで入り口でしかないです。
しかし、開発している間も大体同じようにして出来ますし、コマンドを提供しているので、人によってルールが違う、というのも起こりづらそうです。

React/Vueとも違う感じですが、全体がTypeScriptで出来ているため、Reactのように型定義と合わないとかが原理的に起こらないですし、設定ミスを排除しやすいのも、企業向けに感じます。

今回はngrxでしたが、前述のAkitaだとまた違う概念だったり、Effectsを使ってみたりと、Angularのstate周りは色々あるので、自分に合うものを探してみるのもいいんではないでしょうか。
