# ═══════════════════════════════════════════════════════════════════════════
#  home/packages.nix  —  command-line tools and programming languages
# ═══════════════════════════════════════════════════════════════════════════
#
#  Rule of thumb: general tools here. A PROJECT's exact versions (Node 22 for
#  one repo, Python 3.12 for another) go in that project's flake + .envrc
#  (direnv loads them on `cd`), or uv / pnpm handle them per project.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── everyday terminal ──
    btop
    fastfetch
    ripgrep # rg
    fd
    jq
    yq-go
    xh # HTTPie-style client
    curlie
    tmux
    wtype # type text from scripts (voice typing uses it)

    # ── JavaScript / TypeScript ──
    nodejs_26 # Active LTS
    pnpm
    bun
    typescript
    typescript-language-server

    # ── Python ── (uv also installs any other Python per project)
    python315
    uv
    ruff
    pyright

    # ── Go, Rust, C ──
    go
    gopls
    rustup # run `rustup default stable` once
    gcc
    gnumake

    # ── containers and Kubernetes ──
    lazydocker
    kubectl
    kubernetes-helm
    k9s
    kubectx
    kind

    # ── infrastructure ──
    opentofu # `tofu`
    ansible
    cloudflared

    # ── databases (clients) ──
    postgresql
    pgcli
    sqlite
    valkey # Redis-compatible; `redis-cli` lives here as `valkey-cli`

    # ── secrets ──
    sops
    age

    # ── security checks (used by your Claude Code setup) ──
    gitleaks
    osv-scanner
    govulncheck
    actionlint
    semgrep

    # ── AI coding tools ──
    claude-code
    gemini-cli

    # ── this config ──
    nixfmt
    nixd # Nix language server (VS Codium, Neovim)
    nix-output-monitor # `nom`: nicer build output
  ];
}
