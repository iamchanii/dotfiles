---
name: managing-agent-skills-nix
description: >
  Manage agent skills (SKILL.md bundles) declaratively in this dotfiles repo via agent-skills-nix +
  Home Manager. Use whenever the user wants to add, remove, enable, disable, list, or browse agent
  skills — including adding new skill sources, changing sync targets, updating flake inputs, or
  applying the config. Trigger even on terse asks like "스킬 추가해줘", "이 스킬 빼줘", "어떤 스킬
  쓸 수 있어?", or any mention of agent-skills-nix, SKILL.md, the catalog, or ~/.claude/skills.
---

# Managing Agent Skills (agent-skills-nix)

This dotfiles repo manages agent skill bundles (dirs containing `SKILL.md`) declaratively with
[agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix). Edit Nix config, then rebuild —
never hand-edit `~/.claude/skills` (it is a generated symlink tree into the Nix store).

## Files

| File | Role |
|------|------|
| `flake.nix` | Flake inputs: `agent-skills` module + skill-source flakes (`flake = false`) |
| `home/agent-skills.nix` | `programs.agent-skills` config: sources, skills, targets |
| `home.nix` | Imports `inputs.agent-skills.homeManagerModules.default` and passes `inputs` via `extraSpecialArgs` (lets source `input = "..."` strings resolve) |

Host: `Chanhees-MacBook-Pro` · user: `chanhee`. Sources currently wired: `obsidian`
(kepano/obsidian-skills), `anthropics` (anthropics/skills), both `subdir = "skills"`.

## Apply / inspect commands

Run from the repo root (`/Users/chanhee/workspaces/dotfiles`):

```bash
make build    # dry build — catches eval/build errors without applying
make switch   # build + sudo darwin-rebuild activate (applies the change)
make check    # nix flake check
make update   # nix flake update (refresh ALL inputs / flake.lock)
```

> Note: `nix run .#skills-list` does **not** work here — this flake only exposes
> `darwinConfigurations`, not the upstream apps. Use the eval command below instead.

**List the full catalog (all discoverable skill IDs across all sources):**

```bash
nix eval --json '.#darwinConfigurations.Chanhees-MacBook-Pro.config.home-manager.users.chanhee.programs.agent-skills.catalog' --apply builtins.attrNames
```

**Currently enabled skills:** read the `skills.enable` list in `home/agent-skills.nix`.

## Recipes

### Add / remove a skill (existing source)
Edit `skills.enable` in `home/agent-skills.nix`. Confirm the exact ID with the catalog eval first,
then `make switch`.

```nix
skills.enable = [
  "defuddle"
  "pdf"          # add
  # "json-canvas"  # remove by deleting the line
];
```

### Enable all skills from a source
```nix
skills.enableAll = true;                  # every skill, every source
skills.enableAll = [ "anthropics" ];      # every skill from listed sources only
```
`enableAll` and `enable` compose — `enable` adds on top of whatever `enableAll` selects.

### Add a new skill source
1. Add a flake input in `flake.nix` (skill repos are plain trees, so `flake = false`):
   ```nix
   my-skills = { url = "github:owner/repo"; flake = false; };
   ```
2. Add a source in `home/agent-skills.nix` (`input` must match the flake input name):
   ```nix
   sources.my-source = { input = "my-skills"; subdir = "skills"; };
   ```
3. `nix flake update my-skills` to pin it, then add IDs to `skills.enable`, then `make switch`.

   (Use `path = ./local/dir;` instead of `input` for a local source — no flake input needed.)

### Enable / disable a sync target
Targets sync the bundle into agent dirs; all default to disabled. `claude` is currently enabled.
```nix
targets.claude.enable = true;   # ${CLAUDE_CONFIG_DIR:-~/.claude}/skills
targets.cursor.enable = true;   # ~/.cursor/skills
```
Names: `claude` `cursor` `codex` `opencode` `copilot` `windsurf` `antigravity` `gemini` `agents`.

## Options reference

### `sources.<name>`
| Option | Type | Default | Meaning |
|--------|------|---------|---------|
| `input` | str? | null | Flake input name (mutually exclusive with `path`) |
| `path` | path? | null | Local source dir |
| `subdir` | str | `"."` | Subdir under the root holding SKILL.md dirs |
| `idPrefix` | str? | null | Prefix discovered IDs, e.g. `"openai"` → `openai/pdf` (avoids cross-source collisions) |
| `filter.maxDepth` | int? | null | Recursion depth: `1` = direct children only, `null` = unlimited (capped at 100) |
| `filter.nameRegex` | str? | null | Regex on the skill's relative path to restrict discovery |

### `targets.<name>`
| Option | Type | Default | Meaning |
|--------|------|---------|---------|
| `enable` | bool | false | Sync this target |
| `dest` | str | per-target | Destination; supports runtime shell vars (e.g. `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills`) |
| `structure` | enum | `symlink-tree` | `link` \| `symlink-tree` \| `copy-tree` |
| `systems` | [str] | `[]` | Restrict to listed systems; empty = all |

`structure`: `symlink-tree` = `rsync -a` (keeps symlinks); `copy-tree` = `rsync -aL` (dereferences);
`link` = one symlink to the store bundle (no shell-var expansion in `dest`).

### `skills.explicit.<id>` (advanced — custom SKILL.md / bundled binaries / rename)
| Option | Type | Default | Meaning |
|--------|------|---------|---------|
| `enable` | bool | true | Include this explicit skill |
| `from` | str | — (required) | Source name to pull from |
| `path` | str | `<id>` | Relative path under the source's `subdir` |
| `rename` | str? | null | Install under a different ID |
| `packages` | [package] | `[]` | Symlink these pkgs' binaries into the skill dir |
| `transform` | fn? | null | `{ original, dependencies }: str` to rewrite SKILL.md |
| `meta` | attrs | `{}` | Metadata override |

`transform` receives `original` (raw SKILL.md) and `dependencies` (markdown table generated from
`packages`, or `""` if none). Default when only `packages` is set: `dependencies + original`.

```nix
skills.explicit."jq-helper" = {
  from = "my-source";
  path = "helper";
  packages = [ pkgs.jq ];                       # adds ./jq symlink + deps table
  transform = { original, dependencies }: dependencies + original;
};
```

### Top-level extras
- `excludePatterns` (`[str]`, default `[ "/.system" ]`): rsync excludes. Root-level `.system` is kept
  out so agents (e.g. Codex) can manage their own system skills. Set `[]` for full declarative control.
