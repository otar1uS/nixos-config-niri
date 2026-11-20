# ═══════════════════════════════════════════════════════════════════════════
#  home/dev.nix  —  git and developer quality-of-life
# ═══════════════════════════════════════════════════════════════════════════
#
#    delta     colourful side-by-side diffs        (git diff, git show)
#    atuin     searchable shell history            (Ctrl+R)
#    tldr      short examples for a command        (tldr tar)
#    lazygit   git in a friendly screen            (lazygit)
#    bat       `cat` with colours                  (bat file.py)
#    gh        GitHub CLI and git's login helper   (gh auth login once)
#    herdr     terminal multiplexer for AI agents  (Super+T)

{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Otari Pkhovelishvili";
      user.email = "opkhovelishvili@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true; # first push of a new branch just works
      pull.rebase = true; # straight history on `git pull`
      fetch.prune = true; # forget branches deleted on GitHub
      rerere.enabled = true; # reuse how you fixed a conflict
      merge.conflictStyle = "zdiff3"; # conflicts also show the original
      diff.algorithm = "histogram"; # clearer diffs when code moved
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true; # n / N jump between files
      line-numbers = true;
      side-by-side = true;
    };
  };

  # After `gh auth login`, git push/pull to GitHub never asks for a password.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "https";
  };

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [ { pager = "delta --dark --paging=never"; } ];
  };

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ]; # Up keeps its normal job
    settings = {
      style = "compact";
      inline_height = 20;
      search_mode = "fuzzy";
      filter_mode = "global";
      update_check = false; # Nix updates it
    };
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.bat.enable = true;

  programs.herdr = {
    enable = true;
    settings.onboarding = false; # as on Fedora
  };

  # npm can't install globally into the read-only Nix store, so global
  # packages (vercel, ...) go to ~/.npm-global (on PATH, see home/shell.nix).
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';

  home.packages = [ pkgs.lftp ]; # FTP deploys (clothes-website's deploy.sh)
}
