+++
title = "最近のEmacs設定"
author = ["derui"]
date = 2022-03-01T22:54:00+09:00
lastmod = 2022-03-01T22:54:21+09:00
tags = ["Emacs"]
draft = false
+++

あれ？もう三月？という程度には時間の流れが早くて色々ビビってます。

最近仕事の方に時間が割かれがちなので、ちょっと埋め草的にEmacsの設定を紹介してみます。

<!--more-->


## company→corfu {#company-corfu}

長いこと利用していた [company-mode](https://github.com/company-mode/company-mode)から、[corfu](https://github.com/minad/corfu)に完全移行しました。理由は特になくって、company-modeの機能をそこまで利用していないし、もっとライトウェイトなものでもいいなー、と思っていたところで見付けました。

> Corfu enhances completion at point with a small completion popup. The current candidates are shown in a popup below or above the point. Corfu is the minimalistic completion-in-region counterpart of the Vertico minibuffer UI.

corfuの冒頭を引用すると↑のようになります。completion-at-point-functions、通帳capfsのインターフェースを利用した補完インターフェース、だけしか提供していません。
company-modeでは、company-backendとかで追加する必要がありました。corfuは、独自ではなく、あくまでEmacsの補完インターフェースに沿ったものである、ということが特徴ですね。

この作者が作成したパッケージとして、同じようにミニマルな [vertico](https://github.com/minad/vertico)などがあり、こちらも利用しています。

今の設定はこんな感じです。

```emacs-lisp
(leaf corfu
  :straight (corfu :type git :host github :repo "minad/corfu")
  :require t
  :custom
  (corfu-cycle . t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto . t)                 ;; Enable auto completion
  (corfu-auto-delay . 0.01)                 ;; Enable auto completion
  (corfu-count . 15)                        ;; show more candidates
  (corfu-auto-prefix . 3)
  (corfu-max-width . 150)               ;; max width of corfu completion UI
  (corfu-commit-predicate . #'my:corfu-commit-predicate)   ;; Do not commit selected candidates on next input
  (corfu-quit-no-match . 'separator)
  (corfu-separator . ?\s)
  (corfu-preview-current . t)    ;; Disable current candidate preview
  ;; (corfu-preselect-first nil)    ;; Disable candidate preselection
  (corfu-echo-documentation . nil) ;; Disable documentation in the echo area
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin
  :bind
  (:corfu-map
   ("SPC" . corfu-insert-separator))
  :preface
  ;; from https://github.com/minad/corfu/wiki
  (defun my:corfu-commit-predicate ()
    "Auto-commit candidates if

  1. A \".\" is typed, except after a SPACE.
  2. A key is typed after corfu-complete
  3. A selection was made, aside from entering SPACE.
  "
    (cond
     ((seq-contains-p (this-command-keys-vector) ?.)
      (or (string-empty-p (car corfu--input))
          (not (string= (substring (car corfu--input) -1) " "))))

     ((equal last-command #'corfu-complete)
      (or (string-empty-p (car corfu--input))
          (not (string= (substring (car corfu--input) -1) " "))))

     ((/= corfu--index corfu--preselect) ; a selection was made
      (not (seq-contains-p (this-command-keys-vector) ? )))))
  :config
  (corfu-global-mode))
```

`corfu-auto` ってのを設定して、自動で表示されるようにしていますが、その代わりにprefixを3としています。これはなんでかというと、↑の設定だと、company-modeみたいにドット `.` で区切る、みたいな真似ができないからです。その代わりに、orderlessを利用した検索ができるので、そこはトレードオフになっています。実際、lspを使っていたりすると、1文字とかで表示されても非常にうざったいことになったし、1文字だけで検索すること自体がほぼありえなかったので、これでもわりと困りません。困る場合はゼロとは言いませんが・・・。


## auto-buffer-save-enhanced → super-save {#auto-buffer-save-enhanced-super-save}

auto-buffer-save-enhancedが、メンテナンスされていない状態が非常に長くなっており、さすがに気になってきたので、切り替えました。いくつかありましたが、一番利用されていそうな [super-save](https://github.com/bbatsov/super-save)を利用しています。

ただ、super-saveだと、auto-buffer-save-enhancedで便利だった、 **現在表示していないバッファも自動で保存する** というがデフォルトでできない・・・というのがありました。

> [PR](https://github.com/bbatsov/super-save/pull/20)はでています。

そこで、PRを参考にして、以下のような設定にして使っています。

```emacs-lisp
(leaf super-save
  :straight (super-save :type git :host github :repo "bbatsov/super-save")
  :custom
  ;; auto save when idle
  (super-save-auto-save-when-idle . nil)
  :config
  (defun my:super-save-command ()
    "all-buffer version 'super-save-command'"
    (let ((buffer-to-save (buffer-list)))
      (save-excursion
        (dolist (buffer buffer-to-save)
          (set-buffer buffer)
          (when (and buffer-file-name
                     (buffer-modified-p (current-buffer))
                     (file-writable-p buffer-file-name)
                     (if (file-remote-p buffer-file-name) super-save-remote-files t)
                     (super-save-include-p buffer-file-name))
            (save-buffer))))))
  ;; adivceで再定義する
  (advice-add 'super-save-command ':override #'my:super-save-command)

  (super-save-mode +1)
  (add-to-list 'super-save-triggers #'ace-select-window)
  (add-to-list 'super-save-triggers #'ace-window))
```

idleで保存されると、snippetsとか使うときにひじょーに邪魔になることがわかっていたので、あえて定義していません。その代わり、PRを参考にして、super-save-commandをadviceで上書きしています。本当はもうちょっといいやりかたしたらいいんですが、動くのでまぁこれでいいや、ってやってます。

実は、再起動したりすると上手くtriggersの設定が反映されないこととかあるんですが、とりあえずはこれで動いていますし、不便も感じていないです。


## kind-icon {#kind-icon}

corfuを利用するようになって、ちょっとだけ困ったというか、見栄えが気になったのがアイコン部分ですが、これについては[kind-icon](https://github.com/jdtsmith/kind-icon)を利用することで解消できました。

こちらも特に不満なく利用できています。all-the-iconsよりも軽量なのでこれまたいいかんじです。


## modus-theme {#modus-theme}

長いことgruvboxを利用していましたが、心機一転で、emacs28から標準添付されるようになる[modus-theme](https://github.com/protesilaos/modus-themes)を利用しています。

{{< figure src="/ox-hugo/20220301_22h33m53s_grim.png" >}}

見た目は↑みたいな感じです。コントラストが結構はっきりしていて、アクセントもきつすぎず薄すぎず、ちょうどいいです。また、かなり広範囲のfaceに渡って設定が入っていて、 **え、ここもあるの** みたいなfaceになったりしてちょっとびっくりしたりもします。


## ときたまパッケージを更新するのも大事 {#ときたまパッケージを更新するのも大事}

最近は、上記に加えてconsultとか、ミニマルなものを組み合わせて利用する形が多いです。anything/helm/ivyのような、 **すべての箇所で統一した補完インターフェース** というわけではないですが、Emacsの標準インターフェースをできるだけ利用するようにしたり、faceに独自性をあえてつけないことで、逆に一貫した見た目を提供したりできています。また、検索もorderlessが通底して広く利用されていることで、ほとんどの箇所で同じような補完を利用できますので、これまた意外と操作感もおおきく変わりません。

> embarkのような、操作感というか概念が大きく変わるようなものがあると、それはそれで慣れないのですが

もちろん、company/ivyを利用するという選択も全く問題ないですし、逆に小さいパッケージだとできないことができたりもします。それらを考えて構成していく、というのも一興だと思うので、組み合わせを探ってみるのもいいんじゃないでしょうか。

VSCode使ってるとかだとそういうこともできませんが。
