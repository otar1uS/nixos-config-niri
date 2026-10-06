# ═══════════════════════════════════════════════════════════════════════════
#  home/dev.nix  —  developer quality-of-life
# ═══════════════════════════════════════════════════════════════════════════
#
#  Small tools that make the terminal and git nicer every day:
#    delta     colourful, side-by-side git diffs        (git diff, git show)
#    atuin     searchable shell history                 (Ctrl+R)
#    tldr      short, practical examples for commands   (tldr tar)
#    lazygit   git in a friendly terminal UI            (lazygit), uses delta
#    bat       `cat` with colours, in Gruvbox            (bat file.py)
#    gh        lets git log in to GitHub through `gh auth login`
#    lftp      FTP uploads (the clothes-website deploy.sh uses it)
#  plus a few sensible git settings (explained on each line).

{ pkgs, ... }:

{
  # ── delta: pretty git diffs ───────────────────────────────────────────
  programs.delta = {
    enable = true;
    enableGitIntegration = true; # git diff / log -p / show use delta
    options = {
      navigate = true; # in a long diff: n = next file, N = previous file
      line-numbers = true;
      side-by-side = true; # old on the left, new on the right
      syntax-theme = "gruvbox-dark";
    };
  };

  # ── Better git defaults (added to the git settings in home.nix) ──────
  programs.git.settings = {
    push.autoSetupRemote = true; # first `git push` of a new branch just works
    pull.rebase = true; # `git pull` keeps history in a straight line
    fetch.prune = true; # forget branches that were deleted on GitHub
    rerere.enabled = true; # remember how you fixed a conflict, reuse it next time
    merge.conflictStyle = "zdiff3"; # conflicts also show what the code was before
    diff.algorithm = "histogram"; # clearer diffs when code moved around
  };

  # ── gh: GitHub from the terminal, and git's login helper ─────────────
  # After `gh auth login` once, `git push` to GitHub never asks for a password.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "https";
  };

  # ── atuin: shell history you can search (Ctrl+R) ─────────────────────
  # Remembers every command with its folder, time and exit code, in a
  # local database. Nothing is synced anywhere unless you set that up.
  programs.atuin = {
    enable = true;
    enableBashIntegration = true; # replaces fzf's Ctrl+R (fzf's Ctrl+T stays)
    flags = [ "--disable-up-arrow" ]; # the Up arrow keeps working the normal way
    settings = {
      style = "compact";
      inline_height = 20; # opens under the prompt, not full screen
      search_mode = "fuzzy"; # type parts of a command in any order
      filter_mode = "global"; # Ctrl+R in the search switches: all / this folder / ...
      update_check = false; # Nix updates it, not atuin itself
    };
  };

  # ── tldr: examples instead of long manuals ───────────────────────────
  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true; # keeps its example pages fresh
  };

  # ── lazygit: git TUI, with delta for its diffs ───────────────────────
  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      { pager = "delta --dark --paging=never"; }
    ];
  };

  # ── bat: `cat` with colours ──────────────────────────────────────────
  programs.bat = {
    enable = true;
    config.theme = "gruvbox-dark";
  };

  # ── lftp: FTP client, used by the website's deploy.sh ────────────────
  home.packages = [ pkgs.lftp ];
}
