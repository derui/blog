+++
title = "Excelのページ指定印刷をPowerShellでやる方法"
author = ["derui"]
date = 2019-07-10T15:14:00+09:00
lastmod = 2020-09-22T12:59:07+09:00
tags = ["Emacs"]
draft = false
+++

最近人事／総務からのヒアリングした業務上の問題を解決していく、という社内プロジェクトに参加しています。

その中で、割と調べても出てこなかった事柄をメモしておきます。

<!--more-->


## 要望 {#要望}

今回解決したいのは、次のような問題でした。

-   色々な事情で、Excelから紙で印刷いないといけない
    -   親会社の意向とかいろいろあるようで
-   Excelの数が多い
    -   だいたい社員数くらいある（現状だと300↑）
-   印刷するのが手作業で辛い
-   しかもそういう業務がけっこうある

とにかく問題としては、 `Excelを開く→最初のページだけ印刷する` という業務が多く、かつ時間がかかる、と。電子承認とかそういう方向に行きたいらしいですが、まーいろいろ事情があるようで。


## 方針の検討 {#方針の検討}

とりあえず抜本的ではないが、ある程度作る労力と、結果の省力化に貢献できるものとして、次のようなツールを作ることにしました。

-   Excelマクロの実行が必須
    -   実行しないと正しい状態にならないので・・・
-   Excelの `１ページ目だけ` 印刷できる
-   フォルダ内のExcelを一気に印刷できる
-   任意のフォルダでやりたい


## 困ったこと {#困ったこと}

人事／総務の方々は、ITレベルが様々なので、Windows標準で入っているものを使う、ということで、 `PowerShell` を使うことにしました。

ところが、いろいろ調べて（ググって）みても、 `ExcelからBookを印刷する` というものはあっても、 `指定したページだけ印刷する` ということをやっている人がまずいないっぽいという・・・。

[フォルダ内のExcelを印刷するという回答](https://stackoverflow.com/questions/47602222/printing-all-excel-files-in-a-folder-using-powershell)


## 色々試す {#色々試す}

色々試した所、次のサイトが気づきになりました。

<https://docs.microsoft.com/ja-jp/office/vba/api/excel.workbook.printout>

このページ、Office VBAのヘルプですが、ここに引数が書いてあります。

| 名前             | 必須 / オプション | データ型 | 説明                                                                             |
|----------------|------------|------|--------------------------------------------------------------------------------|
| From             | 省略可能   | Variant | 印刷を開始するページの番号を指定します。 この引数を省略すると、最初のページから印刷します。 |
| To               | 省略可能   | Variant | 印刷を終了するページの番号を指定します。 この引数を省略すると、最後のページまで印刷します。 |
| Copies           | 省略可能   | Variant | 印刷部数を指定します。 この引数を省略すると、印刷部数は 1 部になります。         |
| Preview          | 省略可能   | Variant | True の場合、印刷をする前に印刷プレビューを実行します。 False、または省略した場合、直ちに印刷を行います。 |
| ActivePrinter    | 省略可能   | Variant | アクティブなプリンターの名前を指定します。                                       |
| PrintToFile      | 省略可能   | Variant | True の場合、ファイルへ出力します。 引数 PrToFileName が省略された場合、出力先のファイル名を指定するためのダイアログ ボックスを表示します。 |
| Collate          | 省略可能   | Variant | True の場合、部単位で印刷します。                                                |
| PrToFileName     | 省略可能   | Variant | \_PrintToFile\_がTrueに設定されている場合、この引数は印刷先のファイル名を指定します。 |
| IgnorePrintAreas | 省略可能   | Variant | True の場合、印刷範囲を無視してオブジェクト全体を印刷します。                    |

これをPrintOutに指定すればいいんじゃね！？ということで、こんな感じにしてみました。

```powershell
filter printExcel($StartPage, $EndPage, $FileName) {
    $Excel = New-Object -comobject Excel.Application
    $Excel.Visible = $false   # Excel自体は表示しない
    $book = $Excel.Workbooks.Open($FileName)

    $Missing = [System.Reflection.Missing]::Value
    $OutputFileName = $Missing
    $PrintToFile = $false
    $From        = $StartPage
    $To          = $EndPage
    $Item = 0
    $Collate = $Missing
    $Copies  = 1
    $Preview = $false
    $IgnorePrintAreas = $Missing
    $ActivePrinter = $Missing

    $book.PrintOut.Invoke(@($From, $To, $Copies, $Preview, $ActivePrinter, $PrintToFile, $Collate, $OutputFileName, $IgnorePrintArea))
    $Excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null
}
```

肝は `PrintOut.Invoke` です。PrintOut自体はMethodという実体なんですが、こいつ自体は複数の引数を設定できないようでした。（実際、渡すと引数の数が違うと言われる）

ですが、デバッグしてみると、 `Invoke` というメソッドが追加で生えているのを見つけました。そこからは、COMオブジェクトとかそういうものは、大抵配列を引数で受け取る（lispのapplyとかそういう感じ）ものなので、PowerShell上で配列を使ってみたら、無事動作しました。

ちなみに、ActivePrinterをPDFとかにして、OutputFileNameを指定すると、指定したファイルにPDFが吐かれるので、そういう応用も効く感じです。


## Windows + Officeを扱うときにPowerShellという選択肢 {#windows-plus-officeを扱うときにpowershellという選択肢}

実際には、このツールはXAMLを利用したGUIも付けた状態にしていますが、実作業時間としては半日くらいで作っています。PowerShell自体は、型の明記が出来たり、連想配列が最初からサポートされていたりと、割と使いやすい印象でした。スコープの概念が若干わかりづらかったですが。

ExcelとかWordとかと戦わないといけないが、長く（多分・・・）使わないツール、とかは、PowerShellで書いていくのもいいんじゃないでしょうか。コードなので問題なくGitとかでも管理できます。

大量にあるExcelから指定のページだけをひたすら印刷しないといけない、みたいなときにこの記事が役に立てば。
