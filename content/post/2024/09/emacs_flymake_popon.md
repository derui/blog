+++
title = "Flymakeでのlint結果などの表示方法"
author = ["derui"]
date = 2024-09-16T10:46:00+09:00
tags = ["Emacs"]
draft = false
+++

暦の上では秋ですが、ほんとに秋が消えつつあるなぁと実感しています。つまり暑い。

今回は、最近悩んでいるemacs上でのlint結果などをどう表示するか？というのを書いていこうかと思います。

<!--more-->


## Flymake本体での提供 {#flymake本体での提供}

FlymakeのDefaultは、 echo areaへの表示になります。が、Eglotなどと利用していると、echo areaは大変和やかになっているため、表示されなかったりします。なのでさすがにdefaultはないかな、となります。

Flymakeの1.36からは、 `flymake-show-diagnostics-at-end-of-line` というoptionができています。これを指定することで、 **flymakeのdiagnosticが、行末に表示されるようになります** 。

> <https://www.reddit.com/r/emacs/comments/1dqh339/flymake_adjustments/>
>
> Redditで紹介されていました。

私はmasterに近いversionを常用しているので、これを試してみました。が・・・、これはなかなか微妙という判定をせざるをえませんでした。理由としては、

-   overlayで実装されているため、 **編集している文字と被るとガタガタが激しい**
-   errorやwarningが長い場合、 **入力の都度ガタついてしまう**

ということで、正直利用できませんでした。eslintからのerror/warningが大抵長いというのも一つ理由になりそうではありましたが、それでも入力の感覚が悪かったです。


## sideline {#sideline}

<https://github.com/emacs-sideline/sideline>

[lsp-ui](https://github.com/emacs-lsp/lsp-ui#lsp-ui-sideline)にあるsidelineというものを、汎用的にしたpackageとして、sidelineというものができていました。で、これを利用したflymake向けのpackageもありました。

<https://github.com/emacs-sideline/sideline-flymake>

見た目については、GitHubを見てもらった方がよいですが、これも試してみました。

が・・・、よく考えたらlsp-modeを利用しているときに真っ先に切ったのがsidelineであったことに、導入してから気付きました。sidelineは見映えはするのですが、overlay実装であるため、本質的にflymakeにある設定と同様の課題が生じます。

しばらく使ってみたのですが、2つくらいerror/warningが表示されてしまうと、やはり編集の体験がよろしくなかったため、これも断念しました。


## popon {#popon}

<https://codeberg.org/akib/emacs-popon.git>

最近見付けたのですが、poponというpackageがあります。poponは、

> Popon - "Pop" floating text "on" a window

という機能を提供するpackageです。実装自体はoverlayなんですが、これをflymakeに適用した [flymake-popon](https://codeberg.org/akib/emacs-flymake-popon)というものを利用してみています。

```emacs-lisp
(eval-when-compile
  (elpaca (popon :type git :url "https://codeberg.org/akib/emacs-popon.git"
                 :ref "bf8174cb7e6e8fe0fe91afe6b01b6562c4dc39da"))
  (elpaca (flymake-popon :type git :url "https://codeberg.org/akib/emacs-flymake-popon.git"
                         :ref "99ea813346f3edef7220d8f4faeed2ec69af6060")))

(with-low-priority-startup
  (load-package popon)
  (load-package emacs-popon-flymake)

  (add-hook 'flymake-mode-hook #'flymake-popon-mode))
```

こんな設定でお試し利用しています。

-   defaultだとposframeを利用しているので、編集中のがたつきなどはない
-   cursorの **上** に出るので、編集時に邪魔になりにくい

というところで、利用できそうでした。ただ、cursorの移動に伴って移動してしまうのがちょっとうっとうしいのが玉に暇でしょうか。


## 自分にとって理想的な表示は難しい {#自分にとって理想的な表示は難しい}

flymake/flycheckなどもそうですが、自分にとって理想とする表示というのは、究極自分自身で創らないといけないというのはあると思います。

が、実際自分で作るのは色々大変なので、packageを利用したくなります。現時点では一旦満足していますが、また変ったら書いていこうと思います。
