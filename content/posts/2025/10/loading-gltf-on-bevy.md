+++
title = "bevyでgltfを読み込むときに.metaファイルが要求されて困るとき"
author = ["derui"]
date = 2025-10-13T14:02:00+09:00
tags = ["programming"]
draft = false
+++

たまには超小ネタです。


## Bevy触ってます {#bevy触ってます}

ちょいちょい中断しつつですが、[bevy](https://github.com/bevyengine/bevy)というゲームエンジンを触っています。なんというか現代的なゲームエンジンを触るのは実は初めてなんですが、Direct3Dで・・・みたいな時代とは隔世の感がありますね。そもそも古すぎか。

やりたいことのためにWASMで動作するように作っているのですが、 `glTF` ファイルを読み込ませようとしたら、 `.gltf.meta` という謎のファイルが要求されてエラーになって困ったことになりました。ちなみにglTFファイルとは、WebGLの標準フォーマットとのことです。

> <https://knowledge.shade3d.jp/knowledgebase/gltf%E3%81%A8%E3%81%AF>


## 解決 {#解決}

<https://github.com/bevyengine/bevy/issues/10157>

困ったときは公式のissue、ということで探したらありました。どうもbevy_assetsの機能で、metadataを確認することでより適した処理にできる、とかそういうもののようです。ちなみに生成するためには **一回起動したらいいよ** 、とのことですが、WASMの場合そもそも書き込むっつってもどこに？となってしまいます。

```rust
app.add_plugins((
    DefaultPlugins
        .set(AssetPlugin {
            // これを追加する
            meta_check: AssetMetaCheck::Never,
           ..default()
        }),
))
```

issueにあったやり方とは違いますが、meta_checkを無効化するとOKです。私がやりたい範囲ではglTFはほぼ使わないので、これで特に問題なさそうでした。
