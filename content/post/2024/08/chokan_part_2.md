+++
title = "Kanzenという日本語入力の方式を再実装してみた Part.2"
author = ["derui"]
date = 2024-08-15T17:56:00+09:00
tags = ["Rust"]
draft = false
+++

盆の前後が台風という、なかなかな感じですが、元気にやっていきたいところですね。

前回に引き続き、chokanについて書いていきます。今回は辞書で利用しているアルゴリズムと、実装方針について書いていきます。

html: &lt;!--more--&gt;


## 辞書引きのデータ構造 - Trie {#辞書引きのデータ構造-trie}

日本語入力に限らず、なんらかの辞書から対象のエントリーを探すとき、[Trie](https://ja.wikipedia.org/wiki/%E3%83%88%E3%83%A9%E3%82%A4_(%E3%83%87%E3%83%BC%E3%82%BF%E6%A7%8B%E9%80%A0))というデータ構造がよく使われます。

Trieは一般に以下の特徴を持ちます。

-   文字列を表現することに非常に適している
-   同じprefixは共有されるため、メモリ効率がよい
-   2分探索木と比較して、高速である場合がおおい
-   最長一致マッチが自然に表現できる

これらの特徴から、よく辞書の内部表現として利用されています。chokanでも特に理由はないので、これを採用しています。


## Trieの実装 - ダブル配列 {#trieの実装-ダブル配列}

Trieは単なる構造の定義なので、実際の実装としては様々なものが考えられます。文字列に対する構造としては、2重連鎖木（以前migemoを実装したときに触れました）での実装などがあります。

その中でも特筆すべき構造として **ダブル配列** があります。これは `base` / `check` / `next` というものを2本の配列で表現することで、 `O(1)` でのNode間遷移を可能としています。

より詳しい説明はWikipediaやSlideshareなどにありますので、興味があれば探してみてください。

なぜ遷移の時間が少ないものがよいのか？という点については、

-   日本語入力では都度入力に対応するnodeを探す必要がある
-   2重連鎖木などでは、実装においてはポインターを辿る必要がある
-   prefixを辿る度にポインターを辿るのは、どうしても時間がかかる

という、実機における制約があるためです。特に大量（10万単位でのエントリー）のprefixを都度探索することを考えると、高速であるというのは非常に重要な要素となります。


## ダプル配列の難しさ {#ダプル配列の難しさ}

さて、使うだけならいいことづくめに見えるダブル配列ですが、実装してみると **追加・削除がとてもややこしい** というものがあります。そのため、普通はライブラリーを利用するのが普通なのですが、chokanでは **アルゴリズムに関するものは自分で作る** という方針でやっているため、Trieについても自前で実装しています。

<https://github.com/derui/chokan/blob/315c2542db0a117fccd3e0fe111c8e6a73f5070a/libs/trie/src/lib.rs>

上で一通り実装しています。動的な追加はサポートしないとユーザー辞書との結合ができないかな、と思ったので実装しています。が、動的な削除は、その難易度に比べて利用シーンが思いうかばなかったので、実装を見送っています。

ちなみに、ライブラリによっては **静的な構築のみ** サポートしている、というものもあります。これは、初期構築のみであれば、データを辞書順にならべておくことで、動的な追加における決定的な非効率性を避けることができるためです。実際、ベースとなる辞書は10万というオーダーでエントリーが存在していたとして、ユーザー辞書がその規模になることはほとんどありません。また、ベース辞書は配布するのが基本なので、一回生成するだけでよいです。

が、chokanは辞書の構築方法が特殊なので、配布という方法がとれなかったのと、内部的にベースとユーザー辞書を（今は）マージして扱っている都合で、動的な追加が必要となっています。

実際、こんな感じになっています。一部をコメントアウトしているのは、難易度がかなり高かったので、簡単な方に日和った結果です。xcheckというのは、ダブル配列をTrieに適用した元論文から取られています。

```rust
fn move_conflicted(&mut self, node: &NodeIdx, label: &Label) {
    // 移動する対象を確定する
    let detect_to_move_base: (NodeIdx, Vec<Label>);

    // できるだけ遷移先が少ない方を移動する
    {
        let check_idx = self.nodes.base_of(node).expect("should be a base") + *label;
        let conflicted_node: NodeIdx = self
            .nodes
            .check_of(&check_idx)
            .expect("Can not get check")
            .into();

        assert!(*node != conflicted_node, "each node should be different");

        let mut current_labels = self.nodes.find_labels_of(node, &self.labels);
        let _conflicted_labels = self.nodes.find_labels_of(&conflicted_node, &self.labels);
        current_labels.push(*label);

        // conflictしたlabel自体も対象に加えて、移動する方を決定する
        // TODO: ここで自分自身のnodeを動かさないと、自分自身のnode自体がずれてしまう。
        // if current_labels.len() < conflicted_labels.len() {
        detect_to_move_base = (*node, current_labels);
        // } else {
        //     detect_to_move_base = (conflicted_node, conflicted_labels);
        // }
    }

    // 全体が入る先を探索して、移動が必要なものを移動する
    let new_base = self.nodes.xcheck(&detect_to_move_base.1);
    self.nodes
        .rebase(&detect_to_move_base.0, &new_base, &self.labels);
}
```

ちなみに速度ですが、現状ベース辞書でおよそ10万ちょっとのエントリーがありますが、これを構築するのに [AMD Ryzen 7900X](https://www.amd.com/ja/products/processors/desktops/ryzen/7000-series/amd-ryzen-9-7900x.html) で大体 **1分ちょっと** かかります。これを長いととるかどうかですが、実際にユーザー辞書をマージするときは一瞬なので、実用上は問題ないと判断しています。


## next {#next}

辞書関連はデータをどう持つか？というのと、 **どうやって辞書のデータを集めるのか** という、ある意味ではこっちの方が難しい問題があります。次回は辞書のデータについて書こうと思います。
