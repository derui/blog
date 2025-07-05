+++
title = "TypeScriptで超シンプルなDIコンテナっぽいのを作ってみた"
author = ["derui"]
date = 2022-04-03T13:57:00+09:00
lastmod = 2022-04-03T13:57:10+09:00
tags = ["TypeScript", "Emacs"]
draft = false
+++

最近は(も)OCamlばっかり書いていましたが、最近また趣味側でもTypeScriptを書き始めました。

がーっと作ったので、ちょっと設計がいまいちというかそのまますぎた部分があったので、それのリファクタをやってるんですが、その過程で超シンプルなDI Containerを作ったので紹介します。

<!--more-->


## ReactでのDependency Injection {#reactでのdependency-injection}

DI = Dependency Injectionは、依存性逆転の原則でも利用されるように、詳細と宣言を分離するテクニックで、現代的なプログラミングに限らず、あらゆるところに出現します。

が、TypeScriptではこれをやる標準的な手段がありません。まぁJSでもないんですけど。そうなると、思い思いの実装になっていきますね。色々手段はありますが、例えば以下のようなものがあると思います。


### Contextを利用する {#contextを利用する}

<https://ja.reactjs.org/docs/context.html>

ReactのContextを利用することで、インターフェースの詳細を受け渡すことができます。React的な利用方法では、例えばThemeとかそういうものを利用したり、グローバルな状態(ログイン状態とか)を共有したり・・・とかに利用されます。

設計上の想定としては、あくまでグローバルな状態を渡すために利用する・・・という想定のようですが、依存というのもグローバルな状態といえば状態なので、これに入れていいんじゃないかな、と。

```typescript
function App() {

  return (<ImplContext.Provider value={new Impl()}>
       <Index/>
    </ImplContext.Provider>);
}


function Index() {
  const impl = useContext<ImplContext>()

  return (<div>{impl.do()}</div>)
}
```


### 関数の引数に渡す {#関数の引数に渡す}

関数の引数に、その関数で利用するすべての依存をobjectで渡す、という形も取れます。このケースだと、例えばfactoryに依存を渡して実装を生成するような場合、この手段を取ることができます。

とはいえ、これはこれで依存を全部明示しなければならず、かつネストしたコンポーネントについてのfactoryとかがあると、依存が多くなってしまい、結果としてメンテナンス性がよくなくなってしまう、という場合があります。

今回やっているリファクタリングでは、元々この方式を利用していましたが、かなり膨らんでしまっていたところを何とかしようとしています。


### コンストラクタに渡す {#コンストラクタに渡す}

Javaとかでおなじみのコンストラクタインジェクションです。interfaceをclassでimplement、とかやる場合にはこれがしっくりきます。


## DI Containerの不在 {#di-containerの不在}

<https://angular.jp/>

Angularの場合、システムとしてDI Containerを提供しているため、classベースであることが前提ではありますが、JavaのSpring的な形でコンストラクタインジェクションを行うことができます。

> Angular2とかの時代、これ自体黒魔術とか言われるレベルだったことがあります。Angularになってからどういう感じなのかな・・・。

しかし、ReactJSでは当然そんなものありませんし、一般化されたものもなさそうでした。

そこで、超シンプルなDI Containerというか依存の管理と取得をできるものを作ってみました。


## どんなのよ {#どんなのよ}

論より証拠。実際の実装を貼ります。

```typescript
type Bean<T> = {
  name: string;
  bean: T;
};

export interface DependencyRegistrar<S = { [k: string]: any }> {
  register<K extends keyof S>(name: K, bean: S[K]): void;

  resolve<K extends keyof S>(name: K): S[K];
}

class DependencyRegistrarImpl<S> implements DependencyRegistrar<S> {
  constructor(private beans: Bean<any>[] = []) {}

  register<K extends keyof S>(name: keyof S, bean: S[K]) {
    const registeredBean = this.beans.find((v) => v.name === name);

    if (registeredBean) {
      return;
    }

    this.beans.push({
      name: name as string,
      bean,
    });
  }

  resolve<K extends keyof S>(name: K): S[K] {
    const bean = this.beans.find((v) => v.name === name)?.bean;

    if (!bean) {
      throw Error(`Not found bean that is name of ${name}`);
    }

    return bean as S[K];
  }
}

export const createDependencyRegistrar: <T>() => DependencyRegistrar<T> = () => {
  return new DependencyRegistrarImpl();
};
```

実際に使うときは、こんな風に使います。

```typescript
type Dependencies = {
  foo: Foo;
  bar: Bar;
  foobar: FooBar
}

const registrar = createDependencyRegistrar<Dependencies>();
registrar.register("foo", new Foo())
registrar.register("bar", new Bar())
registrar.register("foobar", new Foobar(registrar.resolve("foo"), registrar.resolve("bar")))
```

この実装の利点としては、

-   `type Registrar = DependencyRegistrar<Dependencies>` みたいにエイリアスにして短くできる
-   依存のwiring自体はユーザーに委ねるので、よけいな黒魔術をやる必要がない
-   一部の依存だけ設定して〜というのが簡単
    -   objectでやってもいいけど、型のマッチとか色々めんどくさいときもあるので
-   resolve/registerでそれぞれkeyと型が解決される

最後のは、例えば上の例だと、 `foo` に対して `Bar` の実装を入れようとしたら型エラーとして報告されるので、実行してあれー？ってなることを防ぐことができます。

課題としては、あくまで名前で解決するので、型で解決、みたいなことはできないです。が、正直Springとかも実体は名前ベースでの解決だし、型ベースで頑張ろうとしてcrypticになるくらいなら、これくらいシンプルでもいいんじゃないかなって思います。

実際に依存を解決するときは、registrarをfactoryに渡したりコンストラクタに渡したりしてあとは御自由に、という形にできます。必要な場所だけregisterすればいいので、mockの定義とかも難しくありません。


## シンプルなものでも十分使える {#シンプルなものでも十分使える}

ざっと関数に渡していた依存をregistrarに切り替えましたが、特に問題なく利用できました。実際には、コンポーネントから利用する処理はContextでDIしてます。ContextにDIする実装の詳細をインスタンス化する際に、このregistrarに依存するようにしているので、コンポーネントはregistrarの存在を知らない、という状態になっています。

実際は、あらゆる型を渡すことができるので、useXxxとかのhook実装を設定して、componentから利用することもできたりはするはずです。

が、正直どこのコンポーネントからでも利用できるようにするとパワーが強すぎるので、これくらいでいいかなーと思います。

こんな感じにシンプルなものでも、わりと実用に耐えそうだったので、下手に再利用を考えすぎるよりも、30分でさくっと作ってさくっと捨てられるようなものにするというのもありではないでしょうか。
