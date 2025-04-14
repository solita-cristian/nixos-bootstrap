{ pkgs, lib, ... }:
{
  home.file.".ssh/allowed_signers".text = "${builtins.readFile ../../users/ssh-keys.txt}";

  programs = {
    git = {
      package = pkgs.gitAndTools.gitFull;
      enable = true;
      userName = "FULLNAME";
      userEmail = "EMAIL";

      aliases = {
        checkout-pr = "!pr() { git fetch origin pull/$1/head:pr-$1; git checkout pr-$1; }; pr";
        pick-pr = "!am() { git fetch origin pull/$1/head:pr-$1; git cherry-pick HEAD..pr-$1; }; am";
        reset-pr = "reset --hard FETCH_HEAD";
      };
      delta.enable = true; # see diff in a new light
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        syntax-theme = "Dracula";
      };
      ignores = [
        "*~"
        "*.swp"
        ".worktrees/"
      ];
      signing = {
        format = "ssh";
        signByDefault = true;
      };
      extraConfig = {
        color.ui = "auto";
        checkout.defaultRemote = "origin";
        format.signoff = true;
        commit.gpgsign = true;
        tag.gpgSign = true;
        gpg.format = lib.mkDefault "ssh";
        user.signingkey = "~/.ssh/github-key.pub";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        init.defaultBranch = "main";
        pull.rebase = "true";
        push.default = "current";
        github.user = "GITHUB_USERNAME";
      };
    };

    gh = {
      enable = true;
      extensions = with pkgs; [
        gh-poi
        gh-eco
        gh-dash
        gh-markdown-preview
        gh-copilot
        gh-f
      ];
    };

    git-worktree-switcher = {
      enable = true;
      enableBashIntegration = true;
      package = pkgs.git-worktree-switcher;
    };
  };
}
