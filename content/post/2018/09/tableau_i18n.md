+++
title = "Tableauを多言語化して、と言われたときにできること"
author = ["derui"]
date = 2018-09-06T17:46:00+09:00
publishDate = 2018-09-06T00:00:00+09:00
lastmod = 2018-09-11T22:20:07+09:00
tags = ["Programming", "Python"]
draft = false
+++

この半年くらい、Tableauをよく触っています。そんな中、今まで国内だけで使っていたTableau Workbookを国外でも利用したい、という話が出てきました。

そんなときにできることをまとめてみます。

<!--more-->

以下のような方に参考になれば。

-   Tableauのワークブック/シートがそれなりにある
-   日本語ガッツリだったものを国外でも利用する必要に迫られた


## Tableauでの多言語化 {#tableauでの多言語化}

まず、Tableau自体は多言語化されています。

-   Measure name/メジャーネームとか
-   合計とか

ですが、 **ラベル系については一切サポートがありません。** シート名、ダッシュボード名とかもありません。実際にフォーラムでも同じような質問を見つけましたが、そこでは以下のような解決策が示されていました。

1.  各Labelを計算フィールドにする
2.  言語を表すパラメータを作る
3.  計算フィールドの中で、パラメータの値（＝各言語）毎にラベルを定義する
4.  これを全部に対して適用する

・・・シートが1つ2つならまぁいいかなって思わなくもないですが、私がもっているのは30シート/10オーバーのDatasourceだったので、とてもじゃないですが参考にできませんでした。


## 一括で変換したい {#一括で変換したい}

フォーラムの中では、それ以外にも案が示されていて、その中で一番有望なのが **XMLを直接書き換える** という方法でした。

Tableauの `.twb` 拡張子は、エディタで開いてみると単なるXMLになっています。これを直接書き換えればいいやん、というある意味単純な話です。これしかない！って感じで、この路線で進めてみました。


## こぼれ話：TableauのAPIクライアント {#こぼれ話-tableauのapiクライアント}

コミュニティで作られているものですが、tableau\_toolsというライブラリがあります。

[tableau\_toolsのリポジトリ](https://github.com/bryantbhowell/tableau%5Ftools)

これの中にも、Workbookをよしなに書き換えてくれそうなものがあったので、最初はこれを使ってみました。ただ、私の目的にはそぐわなかったので、利用しませんでした。どちらかというとTableauのAPIを叩くほうが主眼のライブラリだったんで、それも仕方ないかな、と。


## Tableau Workbookの構造 {#tableau-workbookの構造}

XMLをいじるには、まず構造を知る必要があります。実際に翻訳で書き換えていった中で、結構色々と知ることができました・・・。

Tableau Workbookは、大きく以下のような構造になっています。翻訳で利用しなかった部分は省略してます。

```xml
<!-- Workbookのrootエレメント -->
<workbook ...>
  ...
  <datasources>
    <!-- データソース。パラメータもデータソースです。パラメータは、captionがなくってnameがParametersで固定です。 -->
    <datasource name="Parameters">
      <!-- nameはTableauの計算フィールドとかで利用するときの名前です。captionは、「名前の変更」をしたときに設定されるやつです -->
      <column caption="foo" name="[parameter 1]">
        <!-- 「別名」から設定されるものです。membersもセットになっている・・・かもしれません。
             パラメータの場合は少なくとも必要でした。
        -->
        <aliases>
          <alias key="0" value="foo" />
          <alias key="1" value="bar" />
        </aliases>
        <members>
          <member alias="foo" value="0"/>
          <member alias="bar" value="1"/>
        </members>
      </column>
    </datasource>
    <!-- PostgreSQLとかのDatasourceだと、nameはtableauが生成した値で、captionには画面側で利用する値になっています。 -->
    <datasource caption="foo" name="...">
      <column caption="a" name="original">
        ...
      </column>
    </datasource>
  </datasources>
  <worksheets>
    <!-- 各ワークシートです。nameがWorksheetとIDとほぼイコールなので、変更する場合は結構大変です -->
    <worksheet name="worksheet1">
      <style>
        <!-- 軸のstyleに関する設定です。element="axis"の中を見ると大体わかります -->
        <style-rule element="axis">
          <format attr="title" value="軸" />
        </style-rule>
        <!-- 凡例のstyleに関する設定です。いくつかある場合は複数になるようです。
             valueをいじるだけでいいパターンと、formatted-text/runを追加する必要があるケースがありましたが、
             formatted-textも設定しておくのが正のようです。
        -->
        <style-rule element="legend-title-text">
          <format ...>
            <format value="凡例" ...>
              <formatted-text><run>凡例</run></formatted-text>
            </format>
          </format>
        </style-rule>
      </style>
    </worksheet>
  </worksheets>
  <dashboards>
    <!-- ダッシュボードです。worksheetと同じく、nameがIDです -->
    <dashboard name="dashboard">
      <!-- ダッシュボードでの配置を管理しているもののようです。
           翻訳では、この中のnameが、変更後のworksheetと同様になる必要があります。
      -->
      <zones>
        <zone name="worksheet1" ...>
        </zone>
        <zone name="worksheet2" ...>
        </zone>
      </zones>
    </dashboard>
  </dashboards>
  <windows>
    <!-- tableauデスクトップとかで下に表示されているものの一覧です -->
    <!-- class=dashboardはダッシュボード、class=worksheetはワークシートです。
         ここのnameは、必ず<worksheet>や<dashboard>と一致させる必要があります。
    -->
    <window class="dashboard" name="dashboard">
      <viewpoints>
        <!-- dashboardの場合だけ（多分）翻訳が必要です。ここのnameは、他の<workspace> 要素と一致している必要があります。 -->
        <viewpoint name="worksheet1" ...>
        </viewpoint>
      </viewpoints>
    </window>
    <window class="worksheet" name="worksheet1">
    </window>
  </windows>
</workbook>
```

今回必要だったのは以下の部分でした。

-   ワークシートのタイトル
-   ダッシュボードのタイトル
-   データソースの各名称
-   エイリアス
-   凡例

こいつらを、なんとかして整合性を保ちつつ変換していけば、一括で翻訳することができます。


## 翻訳の方針 {#翻訳の方針}

実際に翻訳する場合、JavaのpropertiesでもRailsでも何でも、基本的にはIDと訳をセットにして扱うと思います。しかし、前述した構造の中で、表示名とIDが一致している困った要素がいくつかあります。

-   `<alias>`
-   `<member>`
-   `<worksheet>`
-   `<dashboard>`

alias/memberはあんまり困りませんが、worksheet/dashboardはIDと表示名が一致している上、複数ヶ所を書き換える必要があるので大変です。

今回は、次のような方針にしました。

-   alias/memberはcolumnのname属性にマッチしたら漏れなく書き換える
-   軸、凡例は元になるworkbookの `worksheet名/titleのvalue` をキーにする
-   columnはdatasource直下のものだけ書き換えればOK
    -   worksheet直下にもあるんですが、書き換えても変更がなかったので、今回は外しています
-   worksheet/dashboard自体の名前は元になるworkbook上の `name属性` をそのままキーにします


## 何で実装するか {#何で実装するか}

現在のプロジェクトだと、JavaかPythonしか使えないので、Python3 + [ElementTree](https://docs.python.jp/3/library/xml.etree.elementtree.html) で実装することにしました。脆弱性はありますが、自前で作ったXMLにやられるってのはそれは・・・ってことで。

以下のようなソースになりました。仕事で作ったコードなので、実コードではなく、ある程度削っています。が、やっている事自体はElementをiterして辞書から探して属性をsetする、というだけです。

```python
import pathlib
import xml.etree.ElementTree as ET

import click
import yaml


@click.command(help="Extract column names for initial translation")
@click.option("-o", "--output", type=str, default="", required=True, help="Name of output file")
@click.argument('workbook_file')
def extract(output, workbook_file):
    """
    Extract column names of workbook to be useful for base of translation.
    """

    workbook_path = pathlib.Path(workbook_file)
    tree = ET.parse(str(workbook_path))

    # properties代わりになるファイルの構造
    names = {"datasources": {}, "aliases": {}, "axis-title": {}, "legend-title": {}, "worksheets": {},
             "dashboards": {}}
    for datasource in tree.getroot().find("datasources").iter("datasource"):
        # データソースのcolumnを取り出して、データソースのcaption毎に詰めます

    for column in tree.getroot().iter("column"):
        # aliasを取り出して、aliasのname毎に詰めます

    for worksheet in tree.getroot().iter("worksheet"):
        # worksheetを取り出して、worksheet自体のname、軸のタイトル、凡例を
        # worksheetのname毎に詰めます

    for dashboard in tree.getroot().iter("dashboard"):
        # dashboardを取り出して、dashboardのnameのマッピングを作ります

    # 書き出し
    output_file = pathlib.Path(output)

    with open(str(output_file), "w") as stream:
        yaml.dump(names, stream=stream, default_flow_style=False, allow_unicode=True)


@click.command()
@click.option('--debug', is_flag=True, help="Debug output")
@click.option("-d", "--dict_file", type=str, default="", help="Use specofied dictionary instead of default dictionary")
@click.option('-l', '--locale', type=str, help="the locale to translate tableau workbook to")
@click.argument('workbook_file')
def translate(debug, locale, dict_file, workbook_file):
    """
    Translate labels and columns in workbook to specified locale.
    """

    workbook_path = pathlib.Path(workbook_file)
    trans_dict = {}
    dict_file = pathlib.Path(dict_file)
    with open(str(dict_file)) as f:
        trans_dict = yaml.load(f)

    tree = ET.parse(str(workbook_path))

    root = tree.getroot()
    for datasource in root.find("datasources").iter("datasource"):
        # datasource毎にcolumnのcaptionを置換していきます

    for column in root.iter("column"):
        # aliasとmemberを置換していきます

    for worksheet in root.iter("worksheet"):
        # worksheet毎に、軸と凡例のvalueを置換していきます

    # worksheet/dashboardの名前変更をします。
    # その後、viewpointで設定されているworksheet/dashboardの名前を置換します

    output_file = pathlib.Path(workbook_path)
    output_file = output_file.with_suffix(".{}{}".format(locale, output_file.suffix))
    tree._setroot(root)
    tree.write(str(output_file))


@click.group()
def cli():
    pass


def main():
    cli()


if __name__ == "__main__":
    cli.add_command(translate)
    cli.add_command(extract)
    main()
```


## 多言語化って難しい {#多言語化って難しい}

今回は分量も多く、置換するポイントが多かったので自作しました。ミスするとTableau Desktopがinternal errorを吐いて止まるので、中々厳しいです。

Tableau自体がこのような機能をサポートしてくれないかな？というのはちょっと思いますが、おそらく多国籍企業だと最初っから英語で作る、とかなんでしょうね・・・。

なかなかニッチな話題でしたが、どなたかの役に立てば。
