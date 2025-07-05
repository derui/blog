+++
title = "NixOSというかHomeManagerとEmacsを組み合わせる"
author = ["derui"]
date = 2024-10-20T12:52:00+09:00
tags = ["Linux", "NixOS"]
draft = false
+++

一気に秋になったり夏になったりで服装が定まりません。

NixOSでHomeManagerを利用していて、dotfilesとかEmacsの設定ファイルを利用していくにあたって、色々試行錯誤してみました。

<!--more-->


## Pattern.1 Home Managerの設定に全部混ぜるパターン {#pattern-dot-1-home-managerの設定に全部混ぜるパターン}

home-managerには、kittyとかhyprlandとかemacsとかに対してModuleが定義されているので、nix上に全部移植することが一応できます。

```nix
{
  programs.emacs = {
    enable = true;

    config = ''
    <なんか設定>
'';

    # melpaから持ってきたりできる
    packages = emacsWithPackages (epkgs: with epkgs; {
      magit
    });
  };
}
```

kitty/Hyprland用の設定だと、confに書かずにNix上で全部書くこともできます。


### Pattern.1のpros/cons {#pattern-dot-1のpros-cons}

最初はこの構成にしてみたんですが、色々とPros/Consが出てきました。

-   Pros
    -   nixosのrepositoryだけで完結する
    -   pkgsのバージョンなどについても固定するのが簡単（？）
        -   実際にはこれだけではできないものもあるので、あくまでできますよ、という感じ
-   Cons
    -   **dotfilesを他の環境と共有するのが難しい場合がある**

私にとってはConsがかなり致命的でした。仕事で使っているのは支給されたmacOSなのですが、当然ながら色々監視系が入っているので、あまり自由にやりすぎると色々ややこしいことになりかねません。ぶっちゃけnixを入れたからと言って、効率が50%上がりました！とかでもなければ、あんまいれる必要はないかなと。

> nix-darwinなどがあるのも知っていますが、設定を変えても戻されたりするので、正直個人PC以外ではやんないほうがいいと思います


## Pattern.2 pullしてきてはめる {#pattern-dot-2-pullしてきてはめる}

今適用しているのがこれになります。dotfilesは設定が多いのでflakeに、Emacsは色々特殊なのでFlakeにせずに直接設定を入れています。

dotfilesの方では、こんなflake.nixを用意しました。
<https://github.com/derui/dotfiles>

```nix
{
  description = "derui's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # moduleとして利用できるようにしたもの
      dotfile-install =  {home, xdg, ...}: {
          xdg.configFile = {
            "alacritty".source = ./config/alacritty;
            "fish/config.fish".source = ./config/fish/config.fish;
            "fish/conf.d".source = ./config/fish/conf.d;
            "fish/functions".source = ./config/fish/functions;
            "hypr".source = ./config/hypr;
            "mako".source = ./config/mako;
            "nvim".source = ./config/nvim;
            "sway".source = ./config/sway;
            "tmux".source = ./config/tmux;
            "waybar".source = ./config/waybar;
            "kitty".source = ./config/kitty;
            "git".source = ./config/git;
            "starship.toml".source = ./config/starship.toml;
          };

          home.file = {
            ".ideavimrc".source = ./ideavimrc;
            ".npmrc".source = ./npmrc;
            ".bash_profile".source = ./bash_profile;
          };
      };
    in {

    nixosModules.default = dotfile-install;
  };
}
```

本体の方では次のようにして使います。homeの方に刺さないといけないですが。

```nix
home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgsFor.${system};

  extraSpecialArgs = {
    inherit inputs user;
  };
  modules = [
    ./home.nix
    dotfiles.nixosModules.default # これ
  ];
};
```

Emacsの方は、単純にfetchGitしてきたものを、.configに入れています。この都合上、repositoryの方にはorgとorgからtangleした.elの両方を含めています。

```nix
{ inputs, pkgs, ... }:
let
  # ここでGitからfetch
  my-dot-emacs = builtins.fetchGit {
    url = "https://github.com/derui/dot.emacs.d";
    rev = "6fdea3441236e8d26178d29ab691dcee8985c82d";
  };
  # treesitのmoduleはこっちに定義されているのを流用する
  treesit = (pkgs.emacsPackagesFor pkgs.emacs-git).treesit-grammars.with-all-grammars;
in
{
  home.packages = with pkgs; [
    pkgs.emacs-pgtk
  ];

  # Use unstable emacs
  programs.emacs.package = pkgs.emacs-pgtk;

  # installはgitのcheckoutをそのまま設定することで確立する。
  xdg.configFile = {
    # use treesit on lib
    "emacs-local/tree-sitter".source = "${treesit}/lib";
    # load emacs from original place
    "emacs/".source = my-dot-emacs;
    # tempelはuser-emacs-directoryを見るのでこっちにも指しておく
    "emacs-local/templates".source = "${my-dot-emacs}/templates";
  };

}
```


### Pattern.2 のPros/Cons {#pattern-dot-2-のpros-cons}

現状この方式で運用していますが、pros/consは以下のようになっています。

-   Pros
    -   dotfiles/emacsの設定がそれぞれ独立して利用できる
        -   元々emacsはどこの環境でも利用できていたので、nixに依存する必要がなかったです
-   Cons
    -   変更するたびにflake/revの更新が必要
        -   read onlyにされてしまっているため、特にcliのconfig系統の更新がめんどくさいです :cry:
        -   Emacsは試してからpushすることもできますが。

めんどくささがかなり強いんですが、独立性を重視した感じです。


## Nixの自由度を垣間見た {#nixの自由度を垣間見た}

Nixはあくまでtoolであるので、管理方針とかはかなり自由にできる、というのはいい発見でした。（人による再現性はその分失われますが）

とはいえめんどくさいのは変わらないので、なにか方法論は引き続き検討していきたいですね。
