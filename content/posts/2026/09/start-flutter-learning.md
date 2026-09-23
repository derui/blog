+++
title = "Flutterを触り始めてみた"
author = ["derui"]
date = 2026-09-23T11:32:00+09:00
tags = ["programming"]
draft = false
+++

今年の夏は、記憶の感じではこの10年くらいで一番涼しい夏だったんではないでしょうか。35℃行く日が少ないだけで涼しいってのもどうなんだ？と冷静に思いますけども。

今まで触ってこなかったものの一つにAndroidというかスマホアプリがあるのですが、ちょうど節目を迎えたことと、ちょうどいい題材を見つけたのでチャレンジしてみることにしました。


## 最初から最難関、Nixでの環境構築 {#最初から最難関-nixでの環境構築}

せっかくなのでFlutter × dartでやっていきます。

さて、何はともあれ開発環境・・・なんですが、いかんせん私の環境はNixOSです。いろいろ有志の方が研究しているものの、どうも直近のAndroid SDKは、 **SDKのdirectoryを弄り倒す** という、nix側からすると狂気の行為をするようです。

<https://github.com/NixOS/nixpkgs/issues/355045#issuecomment-2466910779>
local.propertiesだといったぞ？とか

<https://github.com/tadfisher/android-nixpkgs/issues/91>
そもそもandroid-studioが使えないぞ・・・とか。nix storeは完全immutableが基本なので、そこに書き込もうとするのはすでにどうしようもありません。事前に全部定義したらいい、ってのがnix wayではあるんですが、SDKとimageとemulatorを・・・とか全部事前に用意するのはなかなかというかだいぶ辛いです。

ちなみに私は、local.propertiesまでは行ったんですが、Gradleのエラーで **読み込み専用のところに書き込めない** ってエラーをみて、諸々諦めました :angel: Android Studioを使わない、とかならいいんでしょうが、Gradleで出るのはもはや如何ともしがたいと判断しました。となるとどうなるんですか・・・？なんですが、Android SDKは基本的にhome directoryの下に増えますので、純粋Nixな人は許せないかもしれません。私はhome directoryの下については流石に実利を取ってるので、これで進めることにしました。なおこのエラーはFlutterを利用するgradleの設定というかプラグインがこういう仕様になっているようです。ただ、 `flutter` コマンドからなら普通にできたので、これは気にしないようにしたほうがFlutterではよさそうです。

なお、この場合Android SDKについてはandroid-studioから入れるか、sdkmanager / android CLI から入れるか、とする必要があります。私はandroid-studioから入れました。


### emulatorの起動 {#emulatorの起動}

本家NixのWikiにもこう書かれております。

> View the Android wiki page for more info, but you can set up emulators in Android Studio, run them from there, then target the emulator in VSCode when running your flutter code. Otherwise, you can Nixify or even manually add your emulators as stated in the Android wiki page

<https://nixos.wiki/wiki/Flutter>

純Nixifyな手順だと、emulatorすら別枠の起動・・・・ってなるのですが、やってみるとまーしんどいです。しんどいですし、いうて手順を書くのとほとんど変わらないこと、前述のとおりSDKについてflake.nixで管理しないのであればそもそも・・・っていうところから、私は横着してandroid-studioから起動してます。

ただし、Android SDKのcmdline-toolsがnixifyされていない都合上、事前に `steam-run` とかを利用してimageのダウンロードとAVDの作成、まではやっておくのがよさそうでした。一応ここまでやってSDKのpathを通した状態で、Android Studio上でemulatorの起動は確認できました。ただ、Flutterのアプリを投入したらきれいに起動せず・・・。


### ミニマムアプリが動くことの確認 {#ミニマムアプリが動くことの確認}

Flutterが生成するミニマムのアプリケーションを動かしたい・・・のですが、なんでかそのままだと起動した瞬間に死にます。 `Android Studio` から起動している場合は、該当するログは `Android Studio` 上から確認できます。Linuxの場合、Linuxを用意しておくと、いい感じにhot reloadで確認できるため、非常にはかどります。


## Flutterの基礎をまなぶ {#flutterの基礎をまなぶ}

<https://docs.flutter.dev/learn/pathway>

いい感じの基礎中の基礎、というところです。dartは正直、まあJavaなり触ったことがあれば雰囲気で70%くらいわかるな、というのが肌感でした。ちょっと定義の仕方が独特ですが、constructorとかの書き方でなんとなく把握できますね。


### レイアウト {#レイアウト}

Flutter + Materialはお手軽にいい感じのものができますが、結構ここはクセがあるな、という感覚です。React.jsとかAngularとかの、現状ほぼ一般的になったHTMLのスタイルというよりは、MFC（古い）とかのようにlayout blockをおいて配置していく、というかたちになります。まあdivにstyle当ててるようなものだとは思いますけども。

触ってみた感じ、超頻出として以下があります。

-   Row/Column
    -   これがないと、そもそも複数並べられませんので必須
-   Expanded/Flexible
    -   スマホだと固定というよりは弾力的 / fillがほとんどなので、これも頻出
-   Padding
    -   Marginは基本なくてPaddingがほとんど、というところのようです
    -   親でPadding決めた中で、子はどう配置されるか知っていてはいけない、というのは、まあCSSでもそんな感じが基本なので、メンタルモデルとしては大きくズレていないかなと思います

逆にいうと、大半はこれらを組み合わせていくとできちゃう、というのが本体かなと。


#### Container/SizedBox/Flexible/Expanded... {#container-sizedbox-flexible-expanded-dot-dot-dot}

やってて最強に混乱したのがここです。もう言葉じゃ理解が追いつかないので、ひたすら構成をいじったり資料を見たり・・・、ということでなんとなく理解しました。

-   `Container`
    -   イメージ的にはまさに `div` です。指定されない限り **サイズが確定しない** ので、HTMLでの常套手段たる `width: 100%` よろしく、 width/heightに `double.infinity` を指定したりするといい感じになります
    -   Containerを置いたら、 **どうfitさせたいか** でinfinityとかを指定するイメージかとは。fitさせなくていいんなら、逆にContainerを利用しなくていいし、Expandedで十分です。
-   `Expanded`
    -   `Row` や `Column` といったコンテナの内部では、 **Containerは利用できません**
    -   利用すると絶望のエラー祭りとの戦いが始まります。余裕で1-2時間溶けます。というか溶けました
        -   具体的にはOverflowが頻発します。Overflowするときれいにエラーになるので、このへんは特に注意です


#### 文字列のalignment {#文字列のalignment}

HTML/CSSでもレイアウトコントロールが凶悪なtextですが、Flutterでもやっぱり凶悪でした。なにが一番凶悪化というと、 **\*CJKが混じらない文字列と混じる文字列でglyphのサイズが異なる** 様子で、その影響で、 `Row` で並べていたりするのを中心揃えにしようと思っても、数pxのズレが発生します。これがCJK混じりの文字列の場合は、Renderingの過程で揃えられるので、高さは歪ではありますが、きちんと揃います。

すっごいなんともではありますが、レイアウト時にはできるだけ同じ文字列の中に入れつつ・・・とやるのが良いかとは思います。


### Routing {#routing}

Android（昔の知識）では、Activityとかなんとかで、このroutingというかtransition周辺が地獄だった・・・というのは聞いたことがありましたが、Flutterでもやっぱり同じようなものがありました。具体的にはmenuを構築したときに循環する・・・というところですね。どうしてもmenuは中央集権的にならざるを得ないのですが、それを各pageのappBarで参照して・・・ってやるとすぐさま循環参照になっちゃいます。

これについては、ReactRouterとかのroutingよろしく、内部的なURLを作成して、同様のメンタルモデルを利用できる[go_router](https://pub.dev/documentation/go_router/)が、Flutterでのほぼ標準の様子です。flutter.devが作成しているということなので、まあ長いものには巻かれておきましょう。

```dart
final _routes = GoRouter(
  children = [
    GoRoute(
      path: "/",
      builder: (context, state) => const HomePage()
    ),
    GoRoute(
      path: "/:id",
      builder: (context, state) => const DetailPage(id: state.pathParameters['userId'])
    ),
  ]
);
```

雰囲気はこんな感じになります。Router系統や、SpringBootとか、とりあえず最近広く利用されているものを利用されているのであれば、ほぼ同様のsyntaxやメカニズムは触ったことがあるはずなので、「あーなるほどこういうことね」ってなりやすいのは、きちんと過去のプラクティスが反映されているな〜と思います。


### Riverpod {#riverpod}

<https://riverpod.dev/>

状態管理などは、ある程度のサイズ感になってきたら、ほぼRiverpodが標準とのことなのでこれを入れます。で、LLMとかでまとめたときの罠なんですが、Riverpodは3.0から、 **Code generationがopt-inに変わってます** 。なので、 `riverpod_generator` を入れないと、そもそものサンプルなどが動きません。

ただ、確認したところ、generatorを使わなくてもほぼ同様の表現が可能になっているので、わざわざgenerationというstep/commitという処理の必要性を鑑みると、生で書いてもほぼ分量・明瞭さは変わらない印象でした。ちゃんと公式ドキュメントを読みましょう。


#### AsyncNotifer {#asyncnotifer}

LLMとかに頼ろうとすると100%この辺でつまづきそうでした。Riverpod 3では、この辺に大幅にテコ入れが行われている様子で、 **それまでと大きくメンタルモデルが変わっている** 感じがあります。

```dart
class HogeAsyncNotifier extends AsyncNotifier<Hoge> {

  @override
  Future<Hoge> build() {
    // HogeのinstanceをFutureで返す
  }

  Future<void> updateFoo(Foo foo) {
    // fooの更新処理を行う
  }
}

class Foo {
  ...
}
```

Riverpod2は正直あんまよくわかってませんが、上記のような構成でやります。Signal/jotaiとかを触ってた方であれば、「logicを一箇所に集中できるんやな」と思えるかと思います。jotaiだとここも細分化する必要が、とかありましたが、notifierの場合はそういったものをしなくてもview modelの表現がしやすいな、と感じます。最大の注意点は、 **自分自身をupdateの中で参照してはならない** という、そりゃそうだってやつなのですが、ここを油断すると速攻でこのルートに入ります。というか入って謎の無限ループとなりました。 methodの中では、 `AsyncValue state` を参照することを心得たほうが良さげです。


#### Listに対するnotifierの考え方 {#listに対するnotifierの考え方}

モバイルアプリを考えているとき、あんまり編集画面とかで待ってる印象はないなー、というのが最近の感覚ではないかと思います（人による）。待つとしても明示的なアクションなどを持って・・・ってなりそうですね。注文ボタンだけにindicatorが入ってたりするのが典型例かと思います。

これらはUXに大きく絡んでくると思いますが、例えば明示的な保存がない場合などは、

-   今いじったものは一時的に保存されている
-   非同期的に保存・同期が行われる。保存が失敗した場合は後で同期する or 破棄

みたいな動線が多そうです。Todo Itemを追加している間とかは、一個一個保存！ってやるよりはもっとカジュアルに追加したいですね。そんな場合、List自体をNotifierにしてしまうと、ここで必要な **追加している最中** って状態をview modelでうまくハンドリングできるようになるかと思います。多分。


### Stateful Widgetの初期化 {#stateful-widgetの初期化}

多分初心者はみんなつまづきそうですが（ひっかかった）、 **Stateful Widgetの値はStateからアクセスできます** 。なんで同一のconstructorを定義しなければならないんじゃ、めんどくさいと思った人、仲良くしましょう。

```dart

class Sample extends StatefulWidget {
  final int value;

  const Sample({
    super.key,
    required this.value,
  });

  @override
  State<StatefulWidget> createState() {
    // state自体は特に何もしない
    return _SampleState();
  }
}

class _SampleState extends State<Sample> {
  _SampleState();

  @override
  Widget build(BuildContext context) {
    // widgetはStateのgenericsで指定したクラスへの参照。
    return Text("${widget.value}ですね");
  }
}
```

さて、では逆に考えると、なんでcreateStateで返すところにlogicを追加してはならないのでしょうか？これについては中身を見なければならないので推測ですが、 `createState` はinstance化される初回にだけ呼び出されるため、そこにロジックがあると適切に実行されない場合がある・・・というところではないでしょうか。buildは都度実行されると考えるとそうなりそうな気がします。


## 触ってみて {#触ってみて}

初めてFlutterを触ってみましたが、

-   dartはまあわかる。わからんときもあるけど
-   Reactとかのcomponentベースの感覚があれば、基本的にはbuilding blockを組み合わせるだけ
    -   ちょっと装飾したいな〜ってなってもPadding/style/decorationでどうとでもなるのは、CSSでうーん、ってなるケースと比較して圧倒的に体験がいい
-   emulator/desktop appでも変わらない体験はつよい
-   DXとしてはviteを超える（個人的な見解）
    -   auto-HWR の欠点は、「今いじってる最中なのにhot reloadされてエラーになる」ってところだと思ってますが、Flutterは自分でtriggerする形なので、これで、ってなったら改めて反映できるのが強いです
    -   保存したらのほうが楽じゃない？って場合も、保存してからreload、ってのがワンアクションになってさえいればどうでもいいかと

というところでした。懐古趣味ではないですが、これを最初のプログラミング体験として得ちゃうと、 **バックエンドとかに興味を持つ** ってのはそりゃ無理があるわな、というのは思いました。ガンガンいじって体験・見た目を作っていけるのは非常に楽しいですし、APIがないんならもうどうとでもなりますし。とはいえギリギリGUI世代からすると、長い間の編集を経て思ったとおりに動く、みたいなAPI系統にあるカタルシスもいいもんやで？というのもまた。MFCとかでも作るのは辛かったんだよ・・・（ドキュメントが複雑 / なさすぎて）。

とりあえず形になるところまで作ってみようとは思うので、また思いついたことがあったら書こうかなと思います。
