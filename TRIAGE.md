# jdx/mise Discussions triage

Working notes for triaging old, unanswered GitHub Discussions in jdx/mise.

**This file lives only on the `triage` branch.** It is never part of a PR — PR branches are cut from
`remote/main`, which does not contain it. Updates are made by amending the single commit on `triage`
and force-pushing.

**Scope policy:** old discussions only. New `#10xxx`-era discussions are left alone — maintainers
and other contributors pick those up. **Closed discussions are out of scope entirely.**

**Resolved entries are deleted from this file**, not archived here; the compact history lives in the
`mise-discussions-triage` memory. Anything below is either **still open** or a **lesson that must not
be relearned**.

---

## Standing directive — 2026-08-01

**Every defect this write-target work turned up is to be fixed.** The user said so explicitly and
asked that it not be forgotten, so the candidate list below is a work queue, not a set of options.
Shipped so far: #11571, #11575, #11609, #11633. **In flight:** #11917 (a `conf.d` drop-in becoming
the write target) — same theme, found later, not one of the ids below.

**Nothing in the queue below has been re-measured since 2026-08-09.** Verify each against current
main before acting on it; several neighbouring write-target defects have shipped since.

### Candidate queue

> **Re-measure before proposing anything from this table.** Swept 2026-08-20/21 against the current
> release: **A1, D1 and D2 were already fixed**, and A2 had changed shape — the panic it describes
> was gone and only an asymmetry was left, which is what #12207 became. Three dead entries out of
> the five checked. Entries here were measured in July and early August; upstream has moved. The
> cost of checking is one command, and the cost of not checking is a PR body that describes
> behaviour nobody has any more.

| id | what | evidence | blocked on |
|---|---|---|---|
| ~~**A1**~~ | **Dead — re-measured 2026-08-21 on 2026.8.9: fixed.** In a HOME holding `mise.toml`, `mise set` now appends to it; no `.config/mise/config.toml` is created. Original entry: `$HOME/mise.toml` is read but is never a write target; `use` and `set` create a new file instead. At the `$HOME` level `first_config_file` returns `.config/mise/config.toml` (it precedes `mise.toml` in `LOCAL_CONFIG_FILENAMES`), that is the global config, and the `!is_global_config` guard then skips **the whole directory** | measured on v2026.7.18 (Linux + Windows): with both files present `mise config ls` lists both, yet from `~/work/proj` both commands create `~/work/proj/mise.toml`; remove the global config and `~/mise.toml` is chosen immediately; an intermediate `~/work/mise.toml` is chosen normally | ready — same line, now inside `nearest_local_config_file` (#11571) |
| ~~**A2**~~ | **Superseded — #12207.** Re-measured 2026-08-21: the panic below is long fixed on both Windows and Linux (2026.8.3 still aborts, 2026.8.9 errors cleanly). What survived was the asymmetry with `mise set`, which is what #12207 fixes. Original entry: `--path`/`--file` pointing at a **non-existent directory**: `mise use` panics in `config_file::init` ("Unknown config file type"); `mise set --file` instead writes an **extension-less file** named after the directory. Two commands, one input shape, two different wrong answers | measured on v2026.7.18 and unchanged on the #11575 branch; noted in that PR body as pre-existing | ready |
| **B1** | **Refactor only — measured 2026-08-21, no observable divergence.** `use`/`unuse` agree on the target for the plain case, `--env staging`, and the case where `.mise.staging.toml` and `mise.staging.toml` both exist. Structurally still two resolvers; without a user-visible difference this is a hard sell after #11853. Original entry: `unuse`'s target ladder is a second implementation of `use`'s. Not a drop-in: its default arm searches the *loaded* configs for the tool and returns early via `config_file::parse` (`unuse.rs:170-180`), which `resolve_target_config_path` cannot express. Same "duplicated resolvers drift" class as #11571 | code reading only | ready |
| **B2** | `config_file_from_dir`'s name is a lie — after #11575 it is only ever asked about the cwd. Fold the rename into B1 | code reading only | B1 |
| **B3b** | `use`/`unuse` declare `value_hint = FilePath` although both accept directories (`set` uses `AnyPath`). Dropped from #11577 after measuring that `value_hint` never reaches `mise.usage.kdl`, so it changes no generated output — possibly inert entirely, since completions come from the kdl | measured | verify it does anything first |
| **C3** | `mise fmt` reformats configs that config loading excludes — verified for both a relocated `MISE_CONFIG_DIR` and `MISE_IGNORED_CONFIG_PATHS` (`go="1.26"` → `go = "1.26"`). Defensible for a formatter; probably a docs sentence, not code | measured | — |
| ~~**E1**~~ | **Done — #12176, merged 2026-08-20.** `status` became `exit_status` at the four sites zsh reaches (three in `assert.sh`, `as_group` in `style.sh`); `e2e/shell/test_zsh_assert_helpers` guards it. The three sites left alone are bash-only. See its review round below. Original entry: `e2e/assert.sh` is sourced for zsh tests (`run_test:147`) but is not zsh-safe: `quiet_assert_succeed`, `quiet_assert_fail` and `run_with_timeout` all declare `local status`, and `status` is read-only in zsh — the helpers print `read-only variable: status` and capture nothing, so an assertion reports `expected '3.0.0' to be in ''` while the thing under test actually passed | measured — cost #12117 a CI round; all four pre-existing zsh e2e tests use **zero** assert helpers, which reads like the same discovery made silently before | ready — rename the variable; test-only, no product code |
| ~~**E2**~~ | **Done — #12218, merged 2026-08-21.** Not the design decision recorded here: the history shows a regression from #8920. See its section below. Original entry: Under `--no-hook-env`, **bash alone applies mise's env at activation**: `activate.sh:82` calls `_mise_hook` outside the `__MISE_HOOK_ENABLED` block, while zsh/fish/pwsh keep theirs inside. Either bash leaks under a flag documented as "without actually modifying the environment", or the other three leave the shell unconfigured. Same "one shell differs" tell that found #12089 | measured in WSL on the released build: bash `--no-hook-env` → the tool is ON-PATH immediately after activation; zsh and fish → not on PATH; all three ON-PATH without the flag. pwsh from source reading only, unmeasured | **design call — ask in a Discussion/issue first**, do not PR blind (#11883 was closed on design) |

**D1/D2 — found 2026-08-09 while verifying #413's `sub-N:` claim. Measured on v2026.8.3 linux-x64.**

| id | what | evidence |
|---|---|---|
| ~~**D1**~~ | **Dead — re-measured 2026-08-20: fixed.** `mise ls-remote node@sub-2:lts` lists 22.x. Original entry: **`mise ls-remote <tool>@sub-N:<alias>` panics.** `mise ls-remote node@sub-2:lts` → `called Option::unwrap() on a None value`, `src/toolset/tool_request.rs:592`. `version_sub()` does `orig.chunks.0[i].single_digit().unwrap()`, and an **alias** base (`lts`) parses into a non-numeric chunk, so `single_digit()` is `None`. `ls-remote` does not resolve the alias before calling it; `use`/`install` do | measured: `sub-2:lts` panics, **numeric base `sub-1:24` works** (lists 23.x). Same file also unwraps at `:585`, `:586`, `:597` |
| ~~**D2**~~ | **Dead — re-measured 2026-08-20: fixed.** `mise latest node@sub-2:lts` returns 22.23.2. Original entry: **`mise latest <tool>@sub-N:…` rejects a spec every other command accepts.** `mise latest node@sub-2:lts` **and** `node@sub-1:24` → `invalid version`, while `mise use --dry-run node@sub-2:lts` and `mise install --dry-run node@sub-2:lts` both resolve it to `22.23.2`, and `[tools] node = ["lts", "sub-2:lts"]` resolves correctly in config | measured, all on the same binary |

~~**D3**~~ — **`go.set_gopath`'s deprecation message points at something that does not exist.**
Found 2026-08-09 while answering #1638; **fixed in #11799 (draft)**. `settings.toml:1081` read
`deprecated = "Use env._go.set_goroot instead."`, wrong twice over: it names **`set_goroot`** as the
replacement for a **`set_gopath`** setting, and `env._go` is not a thing — the env directives are
`file`, `module`, `path`, `source`, `venv` (`src/config/env_directive/`), and `env._go.set_goroot`
occurred exactly once in the whole repo, in that string. There is **no replacement setting**: #1638
is jdx's own design doc and says GOPATH should not be managed by mise at all, so the new text says
that and points at `[env]`.

**Correction to what was first recorded here:** the note said this string is "the one place a user
is sent when the setting warns at them". **It is never printed at all.** `warn_deprecated_now`
(`settings.rs:374-380`) only emits when `deprecated`, `deprecated_warn_at` **and**
`deprecated_remove_at` are all present, and `[go.set_gopath]` has only the first. The warning users
actually see is `go.rs:181-183` inside `verify()` — install time, which is exactly what #1638 asked
for (*"not all the time—but when installing a new go version"*) — and it carries no guidance.
**Arming the standard path was considered and rejected**: it would warn on every settings load,
against that stated intent, and the removal version is a maintainer call. The #815 reply was edited
on 2026-08-09 to correct the same mistake.

D1/D2 are reachable from **documented** syntax — `docs/configuration.md` advertises `sub-2:lts` and
`sub-0.1:latest`. D1 is the more serious of the two: a panic, not an error.

**C1 and C2 are closed as not-defects.** C1 is under "Checked and found sound" below; C2 (should an
explicit `--path` honour the ignore filters?) was answered by #11609: yes, and it warns.

**One small candidate from the #5517 reply**, a papercut rather than a defect:
`backend_arg.rs:329-335` builds "Did you mean?" from a 0.8-threshold fuzzy match over
`REGISTRY.keys()` plus aqua ids, so `mise use cargo` is offered `argo` / `cargo-make` and never
`rust`. A curated component→toolchain hint (`cargo`/`rustc`/`clippy` → `rust`, `gem` → `ruby`) would
close it. **Do this as a suggestion, not a registry alias** — an alias would mean "I asked for cargo
and got all of rustup", reintroducing the surprise #9608 deliberately turned into an error.

## Where to start next

**Scope re-pointed to the OLDEST end on 2026-08-09 (user's decision): finish the old discussions
before returning to newer ones.** The band walk had been climbing *upward* from `#5260`; that was
working the wrong direction.

### The map, measured 2026-08-09

`#413`–`#5989`: **912 open**. Fetched with `discussions(first:100, orderBy:{field:CREATED_AT,
direction:ASC})`, paginated.

| range | open | what it is |
|---|---|---|
| **`#413`–`#3499`** | **108** | 2023-01..2024-12, rtx era. Q&A 60 / General 27 / Ideas 14 — the "Troubleshooting and bug reports" category **did not exist yet**. Expect stale support questions, not defects |
| **`#3500`–`#5259`** | **566** | where the bug category begins: **295 Troubleshooting/bug reports**, 113 Ideas, 105 Q&A. **This is where the defect yield is** |
| `#5260`–`#5880` | 197 | already worked — closed out bar the residuals below |
| `#5880`+ | 38 | newer than anything worked |

**677 open below `#5260` have never been triaged.** Only **5** of the oldest 108 have zero comments
(#608, #1204, #1616, #1638, #2338); in `#3500`–`#5259` **38 bug reports have zero comments**, the
strongest single lead list in the whole backlog.

#### Band `#3500`–`#5259` progress — 2026-08-14

**5 remain** that are open, zero-comment, unanswered and unlocked — down from 40. The count moves
faster than the replies do because a lot of it turns out to be already-fixed.

The 5 left are not "not yet looked at": every one has been investigated and the finding recorded
below. They are held back because **each needs something this account cannot do alone** — none is
waiting on work here.

| still owed | why it is held |
|---|---|
| #5113 crates.io, #5004 Homebrew `usage` dep, #4971 verified publisher, #4533 nodejs.org, #3781 vscode-python | **outside mise**: jdx's crates.io/marketplace accounts, Homebrew's formula, nodejs.org, or microsoft/vscode-python. Findings are measured and ready; the action is not mise's |

**#3866 (pypy) and #4894 (patching) are done** — #11846 and #11850 merged and both replies are
posted, verified 2026-08-14.

**Cleared earlier in the band (all four posted 2026-08-10):** #4813 when #11832 merged, #4789 when
#11831 merged, plus #4801 (outputs-only task) and #4633 (env presets). **The user's instruction on
#4801 was to leave out any discussion of whether it would be implemented** — answer with the
workaround and nothing about roadmap. That shape applies to the remaining unimplemented-feature
threads too.

#### The zero-comment filter was never the whole band — the rest, measured 2026-08-11

The 40→7 count above only ever covered discussions with **no comments at all**. The band is much
bigger, and the rest had never been classified. Full re-measurement, paginating
`discussions(first:100, orderBy:{field:CREATED_AT, direction:ASC})` and then fetching every comment
author **including `comments.nodes.replies`** in aliased batches of 20:

`#3500`–`#5259`: **750 total, 567 open, 458 actionable** (open + unlocked + no chosen answer).

| bucket | n | meaning |
|---|---|---|
| MINE | 94 | already carries my comment |
| MARUKOME | 95 | @Marukome0743 answered |
| JDX | 122 | maintainer engaged |
| COMMUNITY | 116 | some other contributor commented |
| **SELF_ONLY** | **22** | **only the reporter ever spoke** |
| NO_COMMENTS | 9 | the 7 owed above plus #4268/#4793, both deliberately skipped |

**The lead list is 43**: the 22 SELF_ONLY plus **21 where the last top-level comment is the reporter**
and neither of us has touched the thread. Both are the same "stalled" signal — the reporter spoke
last and nobody came back — and SELF_ONLY is the sharper half, because nobody ever answered at all.
A raw "no comment from us" filter returns 269 and is mostly noise.

The 22 SELF_ONLY, newest-upvoted first: #4777, #4958, #4581, #4792, #4690, #4488, #4597, #4622,
#4782, #4798, #4892, #5129, #3940, #4217, #4234, #4301, #4366, #4425, #4440, #4496, #4575, #4812.

**The first run of this classifier was wrong, and the controls did not catch it.** It reported
SELF_ONLY = 2 and COMMUNITY = 135. The jq was

```jq
map(.replies.nodes[]?.author.login // "(ghost)")
```

and `.replies.nodes[]?` over an **empty** reply list produces *nothing*, so `//` fired and injected a
phantom `"(ghost)"` author into every comment that had no replies. A phantom author is never the
discussion owner, so SELF_ONLY collapsed into COMMUNITY. Found only because #4581's classification
(`others=["(ghost)"]`) contradicted the thread, which has one comment and no replies. Correct form:

```jq
[$d.comments.nodes[] | .replies.nodes[]? | .author.login // "(ghost)"]
```

**Two lessons.** The controls (#4281 = my reply, #3539 = a Marukome0743 reply) both passed, because
MINE and MARUKOME are tested *before* SELF_ONLY — **a control only covers the branch it exercises, so
pick one per branch, including the branch you most want to be true.** And `//` in jq is an
emptiness test, not a null test: any `[]?` or `.foo[]` on its left silently turns "no elements" into
the default. The membership of the 43 was unaffected; only the split between the two halves was.

**Replied 2026-08-11:** #5173 (zig), #4898 (ansible/uvx), #4581 (own aqua registry), #4597 (go
package paths), #4892 (nested venv). #4777 was left alone on the user's call — its reporter opened
the PR that implemented it. #4958 (aws-cli/poetry on macOS) is the user's to check on their own
hardware.

**Two are implemented but deliberately unanswered — reply when the PR merges** (user's call
2026-08-11, matching how #4789/#4813 were handled):

| discussion | PR | what the reply has to say |
|---|---|---|
| **#4792** | **#11883** | only one of the three asks is covered (broken-include detection). The `mise tasks include` command is *not* built, and the reason is worth telling them: `includes` **replaces** the defaults |
| **#4690** | **#11885** | "yes it is a bug, and your reading of the source was right" — they have been waiting on exactly that since 2025-03 to decide whether to write the patch |

#### Four SELF_ONLY threads worked 2026-08-11 — one is a live defect

- **#4690** (👍3, python venv vs `disable_tools`) — **REPRODUCES on 2026.8.2. Fixed in PR #11885,
  merged 2026-08-12. The reply is OVERDUE — see "Replies owed".**
  `disable_tools = ["python"]` in `mise.local.toml` turns the tool off — `mise which python` says
  *"python is not a mise bin"* — but the `_.python.venv` directive still activates an **existing**
  venv: `VIRTUAL_ENV` is exported and the venv's `Scripts`/`bin` is prepended to PATH. `venv.rs`
  contains no reference to `disable_tools` at all, which is exactly what the reporter worked out
  from the source in 2025-03. They offered to write the patch and asked whether it would be
  accepted; that question is still open.

  **The first measurement said "fixed" and was wrong.** With no `.venv` on disk, `disable_tools`
  suppressed everything — but only because *creation* needs the tool. The control run (same config,
  no `disable_tools`) created the venv, and re-running with `disable_tools` then exposed the real
  behaviour. **A suppression test on a fixture that was never built proves nothing**; build the
  artifact first, then suppress.

- **#4597** (👍2, go package paths) — fixed. Resolution goes over `$GOPROXY` now, so `go` is never
  spawned: with **no go installed** and a cold cache, `go:connectrpc.com/connect/cmd/protoc-gen-connect-go`
  lists 45 versions and `go:github.com/brianhuster/nvcat` (the one that "got stuck" on
  `go list -m -versions -json`) lists 11. The reporter's 404s were the upward module-path walk
  leaking `go list` stderr; the walk is now HTTP and its misses are DEBUG-only. **#11054** (jdx) gave
  the `GOPROXY=direct` fallback the same walk, **#11816** (mine, from #5189) stopped its diagnostics
  reaching stdout. Note *installing* a `go:` package still needs go on PATH — only resolution is free
  of it.

- **#4892** (👍2, nested venv) — fixed by **#6124** (@elvismacak, first release **v2025.9.1**): the
  directive prepended a reversed path list onto an already-reversed `env_paths`, so a child venv
  landed behind its parent. Verified with the reporter's own config shape under a real
  `mise activate` + `cd`, not just `mise env`. #6124 credits #4510 and issue #4515, so this thread
  never heard about it.

- **#4792** (👍4, `mise tasks include`) — the command is still unimplemented; `mise tasks` has only
  `add/deps/edit/graph/info/ls/run/validate`. **The detection half became PR #11883.** Everything
  below was measured on 2026.8.2.

  **The request is three things, and they are in three different states:**

  | ask | state |
  |---|---|
  | idempotent `mise tasks include <path>` | unimplemented. `mise config set task_config.includes '/a,/b' --type list` is the nearest primitive and **replaces** rather than appends — precisely what they asked not to happen. (`--type list` splits on commas, so a JSON-looking `["/a","/b"]` writes the brackets and quotes into the list.) |
  | detect broken includes | **was completely silent** — no output, nothing at `--verbose`, and `mise tasks validate` answered *"✓ All 1 task(s) validated successfully"*. PR #11883 |
  | delete broken includes | unimplemented |
  | *(their stated motivation)* pull global tasks from a git repo | **solved another way**: `includes` takes `git::` URLs — `git::https://…/repo.git//tasks?ref=main`, ssh too, per-file or per-directory, `?ref=` pinned. #7582 (@vmaleze), first release **v2026.1.1**. No clone, no setup.sh |

  **The trap that stops `mise tasks include` from being a thin `settings add` clone:** setting
  `includes` **replaces** the five default task directories instead of adding to them. Measured — a
  project whose only task lives in `mise-tasks/` loses it the moment one entry is written:

  ```console
  $ mise tasks ls          # no includes set
  fromdefault
  $ mise config set task_config.includes 'extra' --type list
  $ mise tasks ls
  fromextra                # fromdefault is gone
  ```

  So any such command has to seed the defaults on first write, or refuse.

  **The CLI-config-editing surface is not thin — `[task_config]` is the one hole.** Asked whether
  this area is built out enough to justify the feature; it is:

  | section | editors |
  |---|---|
  | `[tools]` | `use` / `unuse` |
  | `[env]` | `set` / `unset` |
  | `[settings]` | `get` / `ls` / `set` / **`add`** / `unset` |
  | `[alias]` | `get` / `ls` / `set` / `unset` |
  | `[tasks]` | `tasks add` |
  | **`[task_config]`** | **none** — only the generic `config set`, which is set-only |

  And the exact semantics asked for already exist: **`mise settings add` dedup-appends** ("Used with
  an array setting, this will append the value to the array"), measured — `foo`, `foo`, `bar` gives
  `["foo", "bar"]`. It just cannot reach `task_config.includes`: that is not a registered setting,
  so it answers `Unknown setting: task_config.includes`.

Findings kept from the three not replied to:

- **#4777** (👍5) — `enable_tools` was asked for and the reporter's own PR #4784 delivered it; first
  release **v2025.5.5**. Gotcha if it ever needs stating: when set explicitly it is a *complete
  allowlist* and `disable_tools` stops being applied (`settings.toml:600`).
- **#4581** (👍4) — **REPLIED 2026-08-11**, as a threaded reply to the reporter's question. The note
  here first said the "show only my own registry" half was unanswerable by settings. **That was
  wrong** — `enable_tools` does exactly it, and the reason nobody could say so in 2025-03 is that it
  shipped in **v2025.5.5**, two months later (#4784 — which is #4777, the neighbouring thread in this
  same lead list). Isolated one setting at a time on 2026.8.2:

  | config | `mise registry` |
  |---|---|
  | none | 999 |
  | `enable_tools = ["k9s", "jq"]` | **2** — `jq  aqua:jqlang/jq`, `k9s  aqua:derailed/k9s` |
  | `disable_backends` = all but aqua | 877 (a tool only drops when *every* backend is disabled, and 686 of 999 have an aqua one) |
  | `aqua.baked_registry = false` | 999 — **no effect on the listing at all** |

  It is not just a display filter: with `enable_tools = ["k9s"]` and a mise.toml naming both,
  `mise install --dry-run` offers only k9s and `mise ls --current` lists only k9s. Two caveats that
  went into the reply — `mise use <tool>` still *writes* a non-enabled tool into the config (it is
  an allowlist over what is used, not over what can be added), and the list is hand-maintained, so
  the reporter's "generate `registry.toml` from the aqua registry" idea is still not a thing.
  `aqua.registry_url` is deprecated for `aqua.registries` (warns 2026.12.0, removed 2027.12.0).
- **#4975** (👍4) — still open, but **not the lead it first looked like, and the first write-up here
  was wrong.** Three corrections, all measured on main 2026-08-11:
  1. **`ubi:` is deprecated** — `ubi.rs:126` carries `deprecated_at!("2026.4.0", "2027.1.0", …)` and
     `docs/dev-tools/backends/ubi.md` opens with a deprecated badge. Warns from **2026.4.0**, removed
     in **2027.1.0**. Anything proposed for `ubi:` alone is work with an expiry date. (The same trap
     already recorded for #2878 — check it *before* planning, not after.)
  2. `github:` — the replacement — **already has `resolve_exact_version`** (`github.rs:607`). The
     earlier note here said ubi *and* github were left out of #11070; only ubi was.
  3. That fast path **does not remove the GitHub call**, it narrows it: it swaps listing every
     release for one `get_release_for_url_with_versions_host` lookup, and returns `Ok(None)` when
     offline. So it does not answer the reporter's actual question, which is why an *already
     installed*, exactly pinned tool needs GitHub at all to **run**.

  **The slash-sanitisation hypothesis was tested and is wrong — do not re-propose it.** The idea was
  that their config asks for `toolName/20.7.0` while the shim error offers `toolName-20.7.0`, so a
  `/` sanitised into the install-dir name might leave shim resolution unable to map the request back
  without re-resolving remotely. Measured on **2026.8.2 windows-x64** with
  `kubernetes-sigs/kustomize`, whose real tags carry a slash (`kustomize/v5.8.1`, and it publishes
  release binaries):

  - The sanitisation is real — config keeps `"github:kubernetes-sigs/kustomize" = "kustomize/v5.8.1"`,
    the install lands in `installs/github-kubernetes-sigs-kustomize/kustomize-v5.8.1`.
  - **It is mapped back correctly, with no network.** `mise which`, `mise exec` and the shim all
    return `v5.8.1` with `MISE_OFFLINE=1` **and the cache directory deleted** — the cold cache is the
    control that separates "resolves locally" from "cache hit".
  - Online with a cold cache, `mise which kustomize --verbose` emits **no GitHub request at all**.
  - Same result on **both backends** (`github:` and `ubi:`), and with the reporter's exact config
    shape reproduced — `[tools] toolName = { version = "…", exe = "…" }` plus
    `[alias] toolName = "ubi:…"` — for `mise exec` and the shim alike.

  So an installed, exactly-pinned tool does not reach GitHub today, on either backend, with or
  without a slash in the version. **The one condition that could not be reproduced is that their
  repository is private**, where a call that is not made here would 404 without a token. Either it
  was fixed somewhere after 2025.4.5 (no candidate PR identified) or it depends on that. Do not open
  an implementation PR off this thread without a fresh repro.

**Add `closed` to the pre-post check.** The first sweep of this band filtered on comments, lock and
`answerChosenAt` but *not* `closed`, so #3882 and #3891 were investigated and drafted before the
user pointed out both were already closed as RESOLVED. Re-running the listing with `closed` dropped
**26 of 66** in one go. The query that is actually right:

```graphql
discussions(first:100, orderBy:{field:CREATED_AT, direction:DESC}) {
  nodes { number closed locked answerChosenAt comments { totalCount } }
}
```

**Replied this pass:** #4281, #5199, #5028, #4291, #4091, #4677, #5189, #4170, #4397, #4537, #4352,
#4802, #4374, #4205, #5082, #4322, #4678, #4403, #3843, #4229, #4304, #4491, #4098, #4520, #4917,
#4587, #4646, #4709, #4790, #4805, #5015, #4467, #4708, #4492, #4555, #3878, #4243, #4536, #4789,
#4813, #4801, #4633, #5173, #4898, #4581, #4597, #4892.

**Two earlier "nothing useful to add" calls were wrong and got reversed** — worth remembering,
because both looked settled:

- **#4243** and **#3878** were listed here as not worth answering. Both turned out to have a
  measurable answer. #4243: mise's bash completion registers `-o nospace`, which is *why* there is
  no trailing space, and re-registering without it is the opt-out. #3878: jdx asked for use cases,
  and `[settings] enable_tools = []` already delivers the whole feature — `[env]` and enter/leave
  hooks still fire, no tool reaches PATH. "The reporter resolved it themselves" and "it's the
  maintainer's own RFC" are not reasons to skip measuring.
- **#4789** was moved to *resolved* and then back to *broken*. Measuring `hook-env --silent`
  directly showed the warning suppressed, so it read as fixed; running it the way the reporter
  did — `mise activate bash --silent` — reproduced the bug. See the process note below.

**Deliberately not replied:**

- **#4194** — @Marukome0743 answered it 2026-08-10 with a macOS-arm64 reproduction and the PR that
  fixed it (#6003, v2025.8.9). Nothing to add. *Third time that person has landed on a thread in
  this queue; the "re-check immediately before investing" rule keeps earning its place.*
- **#4033** (aqua case-insensitivity) — user's call: treated as by-design, out of scope
- **#4268**, **#4793** — Show and tell, nothing to correct

**The old region really is untouched — verified, not assumed.** Across `#413`–`#3499` (108 open +
42 closed) there is **exactly one** comment from this account: #2379, 2026-07-08. A prior note
claiming a 2026-06-14 sweep of the oldest 26 with "~15 answered by reply" was **wrong and has been
retracted from the memory**; its "zero code bugs found" conclusion is unverified and must not be
leaned on. Checked with batched aliased GraphQL over
`discussion(number:N){comments{nodes{author{login}}}}` in chunks of 20, **with a control** on #4881
and #5876 (both known to carry my reply) so a silently-broken classifier could not read as
"nothing found".

### Someone else is already sweeping this exact region — check before touching anything

**@Marukome0743 has been answering old threads since 2026-07-18.** Measured 2026-08-09 over all 677
open discussions below `#5260`: they have commented on **108** of them, spanning **#340 to #5235**,
dated 2026-07-18..2026-08-02. My own account has 25 in the same region (all above `#3500`).

```
340, 605, 617, 869, 995, 1258, 1517, 1551, 1656, 1723, 1823, 1835, 1946, 2164, 2213, 2262, 2303,
2366, 2498, 2519, 2540, 2659, 2907, 2916, 2951, 2964, 3223, 3431, 3539, 3540, 3547, 3550, 3553,
3554, 3780, 3796, 3811, 3820, 3831, 3848, 3861, 3874, 3879, 3886, 3897, 3912, 3921, 3973, 4005,
4021, 4035, 4080, 4093, 4097, 4117, 4126, 4146, 4163, 4179, 4210, 4212, 4222, 4245, 4314, 4315,
4327, 4336, 4384, 4428, 4431, 4439, 4447, 4469, 4470, 4473, 4478, 4480, 4485, 4489, 4510, 4551,
4572, 4580, 4590, 4596, 4603, 4614, 4641, 4655, 4687, 4688, 4698, 4722, 4758, 4803, 4831, 4837,
4840, 4843, 4853, 4985, 4987, 5040, 5053, 5127, 5137, 5211, 5235
```

**Skip every one of these unless a defect is found that their reply does not cover.** This is the
third time that person has cleared threads out from under this queue (#5357, #5655, now at scale) —
the "check for a resolution comment first" note is the single highest-value process rule here.

**The 108 is a floor, not the true count — the query had two blind spots, one of them real.**
It read `comments(last:5)`, so a thread with more than five comments where they replied *early*
would be missed (their comments are all recent, so this one is theoretical). **The one that actually
bit: it only looked at top-level `comments` and never at `comments.nodes.replies`.** Found while
reading — **#3068** and **#3423** both carry a Marukome0743 answer as a *nested reply* and neither
appears in the 108. Threaded replies are invisible to a top-level-only scan. Re-check per thread
before investing; never treat that list as exhaustive.

That leaves roughly **544 open discussions below `#5260` with no reply from either of us.**

### `#413`–`#3499` — **READ IN FULL, 2026-08-09**

108 open. 23 skipped as already answered by @Marukome0743; **85 read body-and-comments**. Every
thread below is either a candidate or explicitly cleared — nothing in this band is unexamined.

**20 reply candidates. Six verified, four of those posted (2026-08-09).**

| # | state |
|---|---|
| ~~**#3428**~~ | **REPLIED 2026-08-09** (top-level) — `task.output = "keep-order"` |
| ~~**#1554**~~ | **REPLIED 2026-08-09** — starship `mise` module shipped |
| ~~**#644**~~ | **REPLIED 2026-08-09** — `node.npm_shim = false` + `corepack = true` |
| ~~**#815**~~ | **REPLIED 2026-08-09** — GOROOT/GOPATH/GOBIN, measured with the reporter's own repro |
| **#1424** | **deleted, not answered** (user's call) — see "Deliberately not posted". #11791 merged 2026-08-09, so the `env_only` hole it was held for is closed |
| **#1638** | **OUT OF SCOPE — do not post.** User's call: it is jdx's own design thread, not a user report. The findings live in the #815 reply instead |

#### Investigated 2026-08-09 — the two "bug-adjacent" candidates

- **#292** (`hook-env` unsets `LESS_TERMCAP_*`) — **does not reproduce on v2026.8.3.** Measured under
  bash with the three vars exported before activation: `mise hook-env -s bash` output never mentions
  `LESS_TERMCAP` at all, and the value survives two hook-env round trips **byte for byte**
  (`od -c` → `033 [ 0 1 ; 3 1 m` before and after). **Why it cannot happen now:**
  `EnvDiff::new(original, additions)` (`src/env_diff.rs`) iterates **`additions` only**, so it never
  emits a `Remove` for a key that exists in the environment but not in mise's own env; and
  `clear_old_env` (`src/hook_env.rs`) unsets strictly what `__MISE_DIFF.reverse()` contains, i.e.
  only what mise recorded as its own. The 2023 trace shows rtx emitting `unset LESS_TERMCAP_me`,
  which means the mechanism was whole-environment based back then. **The fixing release cannot be
  named**: the rtx-era tags and releases are gone — `releases/tags/v1.25.5` is a 404 and
  `contents/...?ref=v1.25.5` does not resolve, so neither binary nor source bisection is possible.
  jdx's "probably a dup of #288" also cannot be followed: issues are disabled (410).
- **#1407** (conda venv python loses to mise's) — **does not reproduce with default settings**, and
  **my first two probes were both invalid** (see the landmine below). Measured properly, with
  `eval "$(mise activate bash)"` and `python = "3.13"` in the config:

  | `activate_aggressive` | prepend a dir, then hook (no dir change) | then `cd` / `--force` |
  |---|---|---|
  | false (default) | prepended dir wins | **prepended dir still wins** |
  | true | prepended dir wins (hook exits early) | mise wins |

  So by default a directory put in front of PATH after activation keeps precedence, across `cd`.
  mise does not push its python ahead of a conda env. **zsh was untested** (not installed in this
  WSL image) and zsh is what they used.

  **CLOSED OUT, and not by me — @Marukome0743 answered it 2026-08-09 06:59, hours after I finished
  the investigation above. Do not reply.** Their answer is strictly better than mine: they name the
  fix (`71ee6716c451`, *"activate: use less aggressive PATH modifications by default"*, first release
  **v2024.1.17**) and they verified on **macOS arm64 with zsh 5.9 and a real Miniconda env** —
  covering the exact gap I had flagged as untested — checking `which`, `whence`, zsh's command cache
  and `sys.prefix`. They also reproduced the old behaviour on current mise by enabling
  `activate_aggressive`, which matches my own table.

  **Their release claim verified independently before recording it**: `compare/71ee6716...v2024.1.16`
  is `behind`, `...v2024.1.17` is `ahead`. The reporter was on **2024.1.14** — also `behind` — so the
  fix landed three releases after their last message, which is why nothing here reproduces today.
  That also retires my "the report's output is internally inconsistent" theory: it was simply the
  pre-fix aggressive behaviour.

  **Fourth time this person has cleared a thread out from under this queue** (#5357, #5655, the
  108-thread sweep, now this) — and the first time it happened *while I was working the same thread
  the same day*. See the process note.

#### Verified 2026-08-09 (second pass) — and a finding that changes another answer

**Re-checked all 12 remaining candidates for new comments first** (the #1407 lesson): none had
activity since 2026-08-01, so all are still mine to work.

- ~~**#1764**~~ — **REPLIED 2026-08-09** (git hooks, 👍2). **The first draft was too strong and was
  corrected before posting**: it claimed `--hook commit-msg` delivers the `[hooks.commit-msg]` the
  reporter wanted, which measuring disproved. The posted reply states the caveat.
  `mise generate git-pre-commit --write --hook commit-msg --task X` writes
  `.git/hooks/commit-msg` and **the hook does fire** — measured end to end with mise on `PATH` and an
  existing HEAD: `[lint-commit-msg] $ echo …` ran during `git commit`, and the commit landed.
  mise's own `[hooks]` section is a different thing (`enter`, `leave`, `cd`, `preinstall`,
  `postinstall`) and will never give you `[hooks.commit-msg]`.

  **But `--hook` only changes the destination filename.** `generate()`
  (`src/cli/generate/git_pre_commit.rs`) is a fixed `format!` with no hook-specific branch:

  ```sh
  STAGED="$(git diff-index --cached --name-only -z HEAD | xargs -0)"
  export MISE_PRE_COMMIT=1
  exec mise run {task}
  ```

  Measured consequence for `commit-msg`: `TASK RAN. arg1=[] MISE_PRE_COMMIT=1 STAGED=[f.txt]` —
  **git's hook arguments are dropped** (`exec mise run {task}` has no `"$@"`), so the task cannot see
  the commit-message file, which is the entire point of that hook. `MISE_PRE_COMMIT=1` is set anyway,
  and `STAGED` is a pre-commit-only concept.

~~**D4**~~ — **`mise generate git-pre-commit --hook <other>` emits a pre-commit-shaped script.
FIXED in #11801 (draft).** Found
2026-08-09 while verifying #1764. The flag advertises *"Which hook to generate"*, but the body is
hardcoded for `pre-commit`. Minimal honest fix: append `"$@"` so hook arguments reach the task —
that alone makes `commit-msg` usable. Whether to emit hook-specific bodies (and whether
`MISE_PRE_COMMIT`/`STAGED` should be conditional) is a maintainer call — left out of #11801 and
stated in its body, along with two other things deliberately not touched: the `STAGED` line uses
`HEAD`, so the generated hook errors with `fatal: ambiguous argument 'HEAD'` on a repository's
**first** commit, and `--write`'s own help still reads *"write to .git/hooks/pre-commit"* (a doc
comment, so editing it needs `mise run render`, which does not run on this box).

**Two design points settled by measurement while planning #11801, worth not re-deriving:**
`mise run` takes task args with **`allow_hyphen_values = true`** (`src/cli/run.rs`), so a `-`-leading
hook argument is not misparsed and **no `--` separator is needed**. And **args are appended to the
task's command line, not bound to `$1`** — `mise run show /tmp/COMMIT_EDITMSG` renders as
`[show] $ echo "…" /tmp/COMMIT_EDITMSG`. I nearly wrote "`$1` works" into both the reply and the PR
body before checking.

- ~~**#3351**~~ — **REPLIED 2026-08-09** (Nim installer broken). The plugin route works, the bare
  name no longer resolves. Measured on v2026.8.3:
  - `mise install nim@latest` → `nim not found in mise tool registry`. There are 955 registry
    entries and **no `nim*.toml`**, so the shorthand the reporter used now fails loudly instead of
    half-installing.
  - **`asdf:mise-plugins/mise-nim` installs and runs**: `✓ installed`, then
    `mise exec … -- nim --version` → `Nim Compiler Version 2.2.10 [Linux: amd64]`, and
    `mise which nim` / `mise which nimble` both resolve under `…/bin/` — which is exactly the
    `which {nim,nimble}` that came back empty in the report.
  - Dead ends worth not re-testing: `aqua:nim-lang/Nim` → *no aqua-registry found*;
    `ubi:nim-lang/Nim` **lists** 2.2.6/2.2.8/2.2.10 but **install 404s** on
    `releases/tags/2.2.10`, because **nim-lang/Nim publishes no GitHub releases at all**
    (`releases` empty, `releases/latest` 404) — the versions come from tags and there is nothing to
    download. That `ls-remote`-succeeds / install-fails split is inherent to tag-listing backends on
    a repo with no releases.

**#3379 dropped from the candidate list (user's call, 2026-08-09): already adequately answered in
thread.** For the record, since it was investigated: `auto_install` (default `true`),
`not_found_auto_install` (default `true`, shell handler only) and **`auto_install_disable_tools`**
(a per-tool list) all exist.

**The `ubi:` backend is deprecated — this changes what #2878 can be told.** `src/backend/ubi.rs`
carries `deprecated_at!("2026.4.0", "2027.1.0", "ubi", "The ubi backend is deprecated. Use the
github backend instead (e.g., github:owner/repo).")`, so it warns from **2026.4.0** and is
**removed in 2027.1.0**. #2878 is entirely about redirecting `asdf:` shorthands to `ubi:`
alternatives, and @powerman listed ten of them in-thread — **any reply there has to say `github:`,
not `ubi:`**. Check every queued thread for the same trap before recommending a backend.

#### Verified 2026-08-09

- **#3428** — `task_output = "keep-order"` is the answer. **Source-bisected**: `src/cli/run.rs` has
  no `keep-order` at **v2024.12.16**, has it at **v2024.12.17** (published 2024-12-21) via
  **#3763**, alongside `replacing` (#3764) and `timed` (#3766). The discussion opened **2024-12-09**,
  so the fix landed **12 days later** and nobody said so — and @shousper re-reported it on
  2025-10-02, ten months after it shipped. **Measured on v2026.8.3**: default `prefix` interleaves
  the two tasks line-by-line; `keep-order` prints each task contiguously; total wall time
  850.3ms vs 888.3ms, i.e. still parallel, only the display is buffered. Full value set:
  `prefix` (default), `keep-order`, `interleave`, `replacing`, `timed`, `quiet`, `silent`.
- **#1554** — starship **#5747 merged 2025-04-26**; `src/modules/mise.rs` exists on starship main.
  **Disabled by default** (`[mise] disabled = false` to enable). The `health` variable comes from
  running `mise doctor` — exactly the "healthy/not healthy flag" jdx asked for in-thread. The
  "count of missing tools" idea did **not** land. Two caveats to state: it shells out to
  `mise doctor` **on every prompt** in a matching directory, and starship's own docs example is
  wrong (`[mise] health = 'ready'` — `health` is a variable, the option is `healthy_symbol`).
- **#1424** — the thread's conclusion ("project-specific settings are impossible") is **false now**.
  **Measured on v2026.8.3**: global `[settings] experimental = false, jobs = 2`, project
  `[settings] experimental = true, verbose = true` → inside the project `experimental` is `true`,
  `jobs` is still `2` (inherited), `verbose` takes effect; outside it, `experimental` is `false`.
  Settings merge additively with the project overriding. **Exception measured too**: `paranoid` in a
  project file →`WARN paranoid in non-global config … is ignored for security reasons` and
  `settings get paranoid` → `false`. `global_only` today: `ci`, `paranoid`, `safe`, `yes`,
  `trusted_config_paths`, the three `*.credential_command`, the four `*_default_*_shell_args`, and
  the `task.cache*` token settings. The remaining hole — five config-loading settings that are
  accepted and silently ignored — is #11791.
- **#644** — **solved, and the thread was never told.** `node.npm_shim` (default `true`,
  `MISE_NODE_NPM_SHIM`) turns off the `bin/npm` bash wrapper, and when it is off **mise runs
  `corepack enable npm` itself** (`node.rs:699-703`: `if settings.node.corepack && corepack_path
  exists { enable_default_corepack_shims; if !npm_shim { enable_npm_corepack_shim } }`). That is
  exactly the either/or @jasisk proposed in-thread. **#10082** added it, first release
  **v2026.5.16** (source-bisected: `npm_shim` absent in `settings.toml` at v2026.5.15). Its PR body
  restates @jasisk's 2023 diagnosis word for word — *"corepack's safety logic refuses to clobber the
  existing non-symlink `bin/npm` file"*. The `node.corepack` setting is older (absent at v2026.2.14,
  present at v2026.2.20). **No PR references discussion #644**, which is why nothing here says so.
- **#1638** + **#815** — **all four cases measured on v2026.8.3** with `go = "1.24"` installed, using
  `mise env`:

  | parent env | mise emits |
  |---|---|
  | nothing set | `GOBIN` + `GOROOT` (mise install path). **No `GOPATH`** |
  | `GOROOT=/opt/go-1.21.6` | `GOROOT` **overridden** with mise's |
  | `GOBIN=/home/me/gobin` | **no `GOBIN`** — an inherited one is respected |
  | `go.set_goroot = false` + `GOROOT` set | **no `GOROOT`** — inherited one left alone |

  So the thread's outcome is: **GOPATH is no longer touched** (`go.set_gopath` is deprecated and
  defaults off; `go.rs:181` warns if set), **GOROOT is set by default and now overrides an inherited
  value** — the opposite of the 2024 behaviour jdx described, and it fixes @brigitops' exact
  `compile: version "go1.21.6" does not match go tool version "go1.22.0"` failure because GOROOT now
  matches the `go` mise puts on PATH — and **GOBIN is asymmetric**, deferring to an inherited value
  (`go.rs:193-197`, `gobin.is_none() && !gobin_env_is_set`). Opt out of GOROOT with
  `go.set_goroot = false`.
- **#413** — verified from `docs/cli/*` on main: `mise upgrade` has `--bump` (upgrades **and**
  rewrites the config), `--dry-run`, `--dry-run-code`, `-x/--exclude`, `--inactive`,
  `--minimum-release-age`, and `--no-prune` (mine, #11639). `mise prune` deletes versions no longer
  latest in any tracked config, keeps versions a tracked tool stub still references, and has
  `--dry-run`/`--dry-run-code`; `mise ls --prunable` lists them. **`sub-N:` measured**: in config,
  `node = ["lts", "sub-2:lts"]` resolves to `24.19.0` and `22.23.2`. **But the CLI form is broken —
  see D1/D2 above.** The reply must recommend the config form and must not show
  `mise latest node@sub-2:lts`.

**All 9 verified 2026-08-09 (third pass), then filtered — only 3 were posted.** The user asked for a
worth-posting check *before* drafting: read every existing comment in full and skip anything that
merely restates what the thread already says. That filter removed a third of them. **Do this on
every thread from now on** — the point of the queue is threads that lack an answer, not threads I
can add prose to.

| # | 👍 | outcome |
|---|---|---|
| ~~**#2878**~~ | 1 | **POSTED.** Answers @powerman's *reworded* question (unanswered since 2024-11): **`[tool_alias]` in the *global* config** redirects a tool while the third-party project's `mise.toml` stays untouched — measured, `Backend: github:magefile/mage` with the project still saying `mage = "latest"`. Two traps carried into the reply: **`[plugins]` is not this** (read as an asdf *plugin source* → `asdf:github:magefile/mage` → `plugin not installed`), and `[alias]` warns as deprecated. Also **`ubi:` is deprecated → `github:`**, which stales every entry on @powerman's list, and `mage` already defaults to **`aqua:`** |
| ~~**#2338**~~ | 2 | **POSTED. My pre-measurement read was wrong and would have been a wrong answer.** I had written "wrapper still needed"; installing watchexec and running it showed `mise watch mkdb ::: client` runs **both** tasks under one watch, so `watch_mkdb` *can* be deleted. Caveat in the reply: both tasks re-run on change, tunable with `--on-busy-update` |
| ~~**#2107**~~ | 1 | **POSTED.** The accepted answer is now silently inert: precompiled python is the default, so `PYTHON_CONFIGURE_OPTS` never reaches a compiler. `python.compile` is tri-state (`true` / `false` / unset = precompiled-if-available). Verified the passthrough with a **deliberately invalid flag** — `configure: error: unrecognized option: '--bogus-flag-xyz'` — which proves the variable reaches `./configure` instead of assuming it. `-f` still means "force reinstall" |
| **#1750** | 1 | **Not posted — user's call: already resolved.** Kept for the record: reproduced on v2026.8.3, and it is **not a mise bug** — `pkill -f` matches full command lines *including its own shell*, so the shell is signalled and `\|\| true` is never reached (`sh -c "pkill -f '.*XxYyZz.*' \|\| true; echo survived=$?"` prints **nothing**). If it ever needs answering: do **not** claim the wording is mise's — `bail!("exited with non-zero status: {status}")` is `src/cmd.rs:1261`, but the literal `no exit status` is not in `src/`, so it comes from `ExitStatus`'s Display |
| **#68** | 1 | **Not posted — redundant.** @amoosbr's own 2023-03-07 edit already records *"Since the introduction of experimental shim support, I use them"*, and the reporter had solved it with a hand-rolled shim. Saying "`mise activate --shims` exists" adds nothing |
| **#607** | 1 | **Not posted — confirms rather than adds.** jdx already answered "can't". Still can't: prefix matching cannot express "newest 1.14.x **with** `-otp-25`" because the suffix trails the varying part. Only new facts are that elixir is now **`core:elixir`** and `mise latest elixir@1.14` → `1.14.5-otp-26` |
| **#862** | 2 | **Not posted — too thin.** Latest release carries `linux-armv7` (+musl) and **no armv6**, so the Pi Zero W still needs the cross-compile recipe already in the thread |
| ~~**#2435**~~ | 1 | **POSTED 2026-08-09** (top-level: the two unanswered people sit in different places — @iilyak top-level, @NiklasRosenstein as a reply under jdx — so only a top-level comment reaches both). **Investigated first —** The setting is **`aqua.registries`**: repository URL, direct `registry.yaml`/`.yml` URL, or absolute `file://` to a local dir/file; checked **before** the baked-in registry (`aqua.registry_url` is the deprecated single-source form, remove 2027.12.0). Measured: `aqua:myorg/mytool` is *"no aqua-registry found"* by default, lists **2.94.0–2.97.0** once `aqua.registries = ["file:///…/myreg"]` points at a hand-written `registry.yaml`, and with **`aqua.baked_registry = false`** even a baked tool (`aqua:magefile/mage`) becomes *"no aqua-registry found"* — which is exactly @Sytten's *"they should be the only ones that can be installed"*. Settings are per-project (see #1424), so @iilyak's project-scoped shape works. `shorthands_file` → `[plugins]` is a separate, smaller correction |
| ~~**#2441**~~ | 3 | **POSTED 2026-08-09** (top-level; @ParadaCarleton's question is itself the newest top-level comment). **The measurement contradicts the thread's premise —** Installing the **same tool** both ways on v2026.8.3: `github:magefile/mage` printed `checksum …` + **`verify GitHub artifact attestations`** + **`verify SLSA provenance`**; `aqua:magefile/mage` printed **only** `checksum …`. So "aqua is more secure" is not a property of the backend — aqua verifies whatever its registry entry declares (`aqua.cosign`, `aqua.slsa`, `aqua.minisign`, `aqua.github_attestations`, all default `true`), and mage's entry declares only a checksum. The **lockfile is backend-independent**: identical per-platform `checksum`/`url`/`url_api` rows were written for both |

**Cleared — read and needing nothing** (63): #235, #333, #340\*, #440, #518, #603, #605\*, #608,
#617\*, #677, #678, #703, #734, #841, #869\*, #983, #995\*, #1090, #1092, #1114, #1201, #1204,
#1289, #1301, #1357, #1363, #1491, #1514, #1523, #1525, #1550, #1581, #1582, #1616, #1768, #1935,
#1940, #1966, #1988, #1998, #2023, #2026, #2041, #2106, #2122, #2160, #2215, #2251, #2316, #2329,
#2368, #2444, #2492\*, #2888, #2991, #3006, #3068\*, #3168, #3340, #3416, #3417, #3423\*, #3436,
#3487. (\* = answered by @Marukome0743, several as nested replies.)

Two of these are worth remembering rather than re-reading: **#1935** — jdx *declined* falling back to
the global version when the requested one is missing, so do not propose it. **#1988** (👍5, direnv
`.envrc` support) — jdx declined on performance grounds in 2025-01: mise runs on every prompt,
direnv only on `cd`.

### Residuals in the bands already worked

1. **`#5260`–`#5700` is closed out.** Two decisions under "Deliberately not posted" must not be
   re-litigated.
2. **`#5701`–`#5790`** — the four threads with substance are answered. Unread and all low
   substance: #5710 erlang, #5712 php PEAR (👍3), #5716 maven, #5728 sha256-vs-blake3, #5733,
   #5742 ubi executable bit, #5762 ruby, #5789 Docker generator (👍4, **0 comments**).
3. **`#5791`–`#5880`** — answered: #5842, #5840, #5831, #5830, #5833, #5876, #5813. Unread:
   #5797 Mason backend (👍5), #5821, #5869, #5855, #5860, #5871, #5850, #5820, #5825, #5798, #5801,
   #5839. **Re-checked 2026-08-08: no new activity on any of them.**
4. **Replies owed are tracked in the section below, not here.** Do not post one early — a reply that
   announces a fix before the merge says something false the moment anyone checks.

### Replies owed — none, as of 2026-08-16 (late)

**The table is empty for the first time.** #4792 was the last row and it is posted.

**Posted 2026-08-16: #4792.** Top-level, and it answers all three asks. #11883 was not merged — jdx
closed it, deciding that a missing `task_config.includes` entry should not warn at all — so ask 2 is
answered "no, by design" from **his reasoning rather than the PR's premise**, which is what the
previous version of this row said to do. Every claim was re-measured on 2026.8.6 first, because the
notes behind it were taken on 2026.8.2: the subcommand still does not exist, `mise config set …
--type list` still **replaces** (`/a,/b` then `/c` leaves `["/c"]`), and a missing include is still
silent through `tasks ls`, `tasks validate` and `--verbose`.

**The reply is held together by one fact worth remembering:** `task_config.includes` *replaces* the
five default file-task directories rather than adding to them. That single behaviour is both the
trap in ask 1's automation and the reason ask 2 is declined — the docs tell you to list all five,
most are normally absent, so warning about absent entries would indict the documented setup.

**Edited 2026-08-16:** **#7507**, the second reply (the `file_windows` one). It said the docs still
described the old sibling rule; #12051 merged, so that sentence was replaced with what the page now
says. **Editing, not a new comment** — the count on that discussion is still two.

**A merge does not announce itself.** #4690 sat unanswered for two days because the PR merging was
the only signal and nothing was watching for it. When a reply is parked on a merge, re-check the
whole owed table on the next pass rather than trusting that the merge will be noticed. Proven again
2026-08-15: three of the four owed rows unblocked when their PRs merged that morning, and nothing
surfaced it — the merges were only noticed on an explicit "what is still open" pass.

**Posted 2026-08-15:** **#11423** (#11982, shipped v2026.8.6, + #11986, next release), **#11431**
(#11978), **#7507** (#11992, **threaded under hoshsadiq's 2026-02-04 comment**, not top-level).

**#7507's two claims were re-measured before posting, not taken from this file.** It said "claim 1
no longer reproduces" with nothing recorded behind it. Measured on 2026.8.2 windows-x64 in an
isolated env, using @budak7273's `robtest.sh` unchanged: the PowerShell path mangling does **not**
reproduce, and — the control — adding the `.ps1` sibling back does still produce two tasks named
`robtest` that both run. A claim in this file is a lead, not evidence; re-measure before it goes
into a public reply.

**Posted 2026-08-14:** **#11046** (#11934 + #11935), **#11192** (#11937 + #11947), and **#4690**
(#11885, the overdue one above). **#5842**'s existing comment was *edited* to add the local
write-target half that #11917 closed, and to replace "ships in the next release" with the release it
actually shipped in.

**Nothing else is owed.** Re-verified 2026-08-14: #3866 and #4894 carry their replies, and the two
posted comments this file flagged as *wrong* are both corrected in place — #4881 (the `--file`
reversal) and #5876 (`mise_env` returns `RuntimeError`, not `FromLuaConversionError`). #5791 and
#1424 were **deleted**, not answered — see "Deliberately not posted". #413/#340/#10758 went out when
#11796 merged.

The five in the band table above stay owed indefinitely; their action is outside this repository.

### Reply policy — set by the user 2026-08-09

**One comment per discussion.** When a PR lands or a fact changes, **edit the existing comment**
rather than adding a follow-up, and **write it as if it had been correct from the start** — no
"Update:" blocks, no "correction to what I wrote above".

This **replaces** the earlier instruction for #4881, which was to keep the reversal visible. I raised
that distinction (a withdrawn feature is not the same as a wrong detail) and the user reaffirmed, so
#4881 was flattened too. GitHub still shows an edit marker and keeps the edit history, so the record
is not erased — only the presentation changes.

**Do not post first and consolidate after.** On 2026-08-09 the #5840 reply went out as a *new*
comment before this policy was stated, and had to be merged into the original and then removed with
`deleteDiscussionComment`. Decide new-vs-edit **before** calling `addDiscussionComment`; for any
thread that already carries one of my comments, the answer is now always edit.

**Top-level is not the default — "answering a question" wins over "announcing a fix".** The note
above about resolution announcements going top-level was applied mechanically to #7507, whose last
comment is someone asking *"@jdx can you confirm?"*. The user pushed back and was right: a reply that
only makes sense as a response to a specific comment belongs under it. Visibility was the only
argument for top-level and it is weak — a thread with no existing replies does not collapse anything.

**Read the replies, not just the top-level comments.** The same #7507 mistake had a worse half: the
GraphQL query fetched `comments.nodes` without `replies.nodes`, so three replies were invisible and
the draft contradicted them. `isAnswered=false` was already known not to mean "nobody replied"; this
is the same trap one level down. Always request `comments { nodes { replies { nodes { … } } } }`.

## Open PRs — two, as of 2026-08-22

| PR | what | opened as |
|---|---|---|
| **#12274** | `fix(task): run pwsh shebang file tasks on Windows` — a file task pwsh cannot open unless its name ends in `.ps1`; runs it from a temp `.ps1` copy. Covers **both** `-File` (loud, exit 64) and `-Command` (**silent, exit 0**). The tenth pass's finding, below | ready |
| **#12277** | `fix(task): forward a file task's arguments through a -c shell` — a `-c` shell reads the script path as a command string, so the task's arguments land on `$0` and vanish (and on Windows the path itself is mangled, exit 127) | ready |

**These two touch the same function** (`get_file_program_and_args`) and **will conflict**. The user
chose to open #12277 from main rather than stack it; whichever lands first, rebase the other. Said
so in #12277's body as well.

**#12274 was amended on 2026-08-22 and is now smaller than when it was opened** (+194/-6 across
three files, from +245/-16 across four) — see "the next candidate corrected the PR" below. Any
reading of it from before that amend is stale.

Twenty-six landed across 2026-08-16..22, so this section turns over inside a
single session — **read it back from `gh` rather than trusting it.** Draft-vs-ready is the user's
call each time — **do not change it unilaterally**; #12080 was opened draft and went ready without
me, as #12055 and #12050 did before it, while #12078, #12089, #12117, #12131, #12161, #12176, #12205,
#12207 and #12267 were asked for as ready up front, and #12218 was asked for as a draft and merged
from it.

**Merged 2026-08-22 (2):** #12207 00:53 (`mise set --file` wrote files mise cannot read back),
#12267 02:27 (`mise doctor -J` never ran the new-version check — the ninth pass's finding).
**Both byte-identical to what I pushed**, and no late review on either — worth checking each time,
since #12117 and #12218 both changed during review.

**Nothing is queued.** The old candidate list is spent (only the weak B1/B2/B3b/C3 rows remain, all
re-measured and thin), the ninth pass's held-back item (`%VAR%` in task arguments) was **closed as
intended behaviour**, and the tenth pass's two findings both became PRs — #12274, and #12277 from the
control that pass turned up. An **eleventh pass** is the next move, not another look at the table.

**A crate-wide lint landed under #12207 while it sat.** main added
`#![deny(dead_code_pub_in_binary, unreachable_pub)]` and swept the crate to `pub(crate)`; the PR's
new `pub async fn ensure_writable_as_toml` sat inside `pub(crate) mod config_file`, which
`unreachable_pub` denies. Caught by reading the branch after someone else had rebased it, not by CI,
which was still pending. **After a rebase, re-read what the branch now sits on top of** — it carries
the new lints as well as the new code.

**Merged 2026-08-21 (1):** #12218 01:54 (bash applied the environment at activation under
`--no-hook-env`; a regression from #8920, not the design decision I first called it — see its
section below).

**Merged 2026-08-20 (3):** #12161 02:14 (azure-cli from the official Windows ZIP, extended to ARM64
after jdx's review — see its section below), #12176 02:17 (the assert helpers, usable from zsh at
last), #12205 12:33 (the self-update sweep, made reachable from the machines that need it, plus a
`doctor` warning). **#12161 and #12176 merged byte-identical to what I pushed** — worth checking
rather than assuming, since #12117 did not, and #12218 did not either: its test grew hardening
during review.

**Nothing is left un-PR'd.** The sixth and seventh passes' parked findings — the `\\?\UNC\` display
and the self-update leak — merged as #12078 and #12080, and the eighth pass's merged as #12089.

**Merged 2026-08-19 (2):** #12164 10:46 (`ls-remote` answered from a cache that was not keyed by the
tool options which reshape the listing, so a second call with `[version_prefix=…]` got the first
call's answer), #12117 10:55 (the `--no-hook-env` refresh — **read its review round below, the shape
changed completely between opening and merging**).

**Merged 2026-08-18 (1):** #12131 13:51 (pwsh was the only shell not skipping `mise` / `mise-*` in
its command-not-found handler). **Merged with no review findings at all — the first in this stream.**
Worth noting what was different: the whole change was one early `return`, and the PR body carried the
measurements (500–557 ms wasted per unresolved `mise-*`, the deactivate handler-persistence table,
and a match table ruling out the two broader spellings) rather than leaving them to be asked for.

**Merged 2026-08-17 (1):** #12089 12:08 (the pwsh command-not-found hook read stdout instead of the
exit code, so auto-install had never worked there).

**Merged 2026-08-16 (16), in the order they landed:** #12041 17:55 (poisoned test lock), #12023 17:56
(`windows_executable_extensions`), #12062 and #12066 20:19 (long `TEMP` in `self-update`; UNC working
directory), #12051 20:20 (`.sh` sibling docs), #12048 20:22 (`activate`/`hook-env` panic), #11919
20:30 (`bootstrap --windows`), #11837 20:39 (dead `aqua.cosign_extra_args`), #12045 20:59 (brew
`ENV_LOCK`), #12050 and #12055 21:08 (`SHELL` on Windows; `mise env` default), #11888 21:16 (Windows
launchers beside generated stubs), #12058 21:40 (Windows IO errors explain themselves), #12078 22:29
(`\\?\UNC\` reaching the user), #12064 22:37 (`mise lock` and a long `TEMP`), #12080 23:16
(self-update's 145 MB orphans).

### Windows, eighth pass — 2026-08-16 → #12089, and the first one I did not find

**The user found it, and it killed a theory of mine.** I had blamed the pwsh command-not-found
handler's *registration* for the feature not working. That was wrong. The registration is fine; the
condition guarding it could never be true.

In PowerShell, `if (& native)` tests the command's **standard output**, not its exit code. Measured:

| native command | exit | stdout | `if (& …)` takes |
| --- | --- | --- | --- |
| `cmd /c "exit 0"` | 0 | — | **FALSE** |
| `cmd /c "exit 1"` | 1 | — | FALSE |
| `cmd /c "echo hi"` | 0 | `hi` | TRUE |
| `cmd /c "echo hi & exit 1"` | **1** | `hi` | **TRUE** |

`mise hook-not-found` answers with an exit code and nothing else — measured: exit 127 and empty
stdout for a bin no tool provides, and its install progress goes through `safe_eprintln!` to stderr,
so the success path prints nothing to stdout either. The condition was therefore false whatever
happened, and **auto-install on command-not-found has never worked on pwsh**. The last row is the
other half: a *failed* command that printed something would have looked true.

**bash, zsh and fish are the control and all three are right** — each puts the command straight into
the condition and gets its status. Only pwsh wrapped it. That asymmetry is the tell, and it is worth
looking for whenever one shell behaves differently from the rest: **the same intent spelled once per
shell is four chances to spell it wrong, and only the odd one out is suspicious.**

Fixed with `| Out-Null` plus `$LASTEXITCODE -eq 0`, measured to preserve the code (0 stays 0, 127
stays 127) and to be right in both directions where the old form was wrong in both.

**Left alone deliberately:** pwsh is also missing the `mise` / `mise-*` guard its siblings have.
Different bug, and #11853 was closed for carrying unrelated changes under a narrow description.

**Also of note:** `cargo insta` cannot run on this machine, so the activate snapshot was hand-edited
— indentation verified line by line against the source (`formatdoc!` strips exactly 12 spaces here)
rather than eyeballed, because a snapshot that is right except for whitespace fails in CI and tells
you nothing about the change.

**#12078 corrected a comment #12014 left behind, and #12014 was mine.** It said verbatim UNC paths
keep the prefix "because those genuinely do not resolve without it" — they do resolve, which is why
this sat unfixed. `dunce::simplified` strips `Prefix::VerbatimDisk` and nothing else, so #12014 could
not have caught the UNC half no matter how carefully it was written. **A wrong sentence in a doc
comment justifies the gap it describes until somebody measures it.**

### Windows, ninth pass — 2026-08-21/22 → #12267, and a candidate I had to withdraw

**The pass started because the old queue was spent**, and it was designed around a mistake made
immediately before it. Both are the point of this entry.

#### The withdrawal that set the method

I proposed fixing `mise doctor path`, which prints `C:\…\mise\target/debug` — separators mixed,
because `_.path = ["./target/debug"]` keeps its slashes — and framed it as "bypasses `display_path`,
so every fix that layer has received, including #12078's `\\?\UNC\` work, misses this command".
**Withdrawn before writing any code**, for three reasons found while planning it:

1. **No harm.** PATH dedup compares by path components, not bytes
   ([`path_env.rs`](src/path_env.rs:265) — the test is literally named
   `to_vec_dedups_by_path_components_not_bytes`), and `shims_on_path` uses `paths_eq`.
2. **`display_path` would change Unix output.** `display_user`'s `~` substitution is `cfg!(unix)`,
   and this command's own help example shows absolute paths.
3. **Decisive: raw `.display()` is the convention, not a deviation.** `doctor path`, `bin-paths` and
   `which` all print raw. `display_path` is for prose; commands that emit paths meant to be consumed
   deliberately do not use it.

> **When something looks like an exception, count the other places doing the same thing.** I called
> it a deviation without looking at its two siblings. Paired with the #12218 lesson — where I called
> a regression a design decision without looking at the history — the shape is the same: **a claim
> about intent, made without the cheap check that would settle it.**

That became the gate for the pass: reproduce on the current release, have a control, **count the
siblings**, be user-visible, stay narrow.

#### Found

**`mise doctor -J` never runs the new-version check** → #12267. Same machine, same moment: the text
output carried two warnings, the JSON one. Not guessed at — I counted the `analyze_*` calls on both
paths and confirmed the other differences are covered (`analyze_toolset`'s error has a JSON-side
equivalent, `analyze_settings` propagates with `?`, `analyze_paths` pushes nothing), so this is the
only check one path runs and the other silently drops.

**The reproduction does not need a new release.** `get_latest_version` returns the cached file
whenever its mtime is inside the TTL, so `echo "2099.1.0" > "$(mise cache path)/latest-version"`
creates the condition offline. **`2099.1.0`, not the reflexive `99.0.0`** — mise's versions are
calendar-shaped and `99` sorts *below* `2026`. Worth remembering for any test that needs "a newer
mise".

#### Held back — now **closed as intended behaviour, 2026-08-22. Do not re-propose.**

**Task arguments containing `%VAR%` are expanded and word-split** under the default Windows shell:
`mise run t -- '%USERPROFILE%'` arrives as `C:\Users\Jam`, and `%PATH%` arrives as thirty-odd
arguments. Three controls pass it through untouched — running the binary directly, `mise exec --`,
and `shell = "pwsh -c"` — so only the `cmd /c` path mangles it. Only `%NAME%` naming a *real*
variable is affected; `%20`, `100%`, `%NOPE%` survive.

**The blocking question was answered and it killed the candidate.** mise *does* build the command
line itself — `task_executor.rs`'s `InlineArgsStyle::CmdCommandText` arm calls
`crate::path::cmd_verbatim_args` — so the first reading was right. But the quoting function it uses
says this in its own doc comment:

> (`%` is intentionally omitted — cmd expands `%VAR%` even inside quotes, so quoting cannot protect it.)

`&`, `|`, `<`, `>`, `(`, `)`, `^` are quoted; `%` is deliberately excluded because **no quoting on a
cmd command line protects it** (`%%` is batch-file-only). The exclusion is deliberate, documented,
correct, and has a supported workaround. **This is the "count the siblings / check whether it is
intended" gate working** — the answer was sitting in a doc comment three lines from the code.

#### Looked at, nothing there

- `generate git-pre-commit --write` — the hook is written **LF-only** with a correct shebang
- `generate task-stubs` — `bin/hello` (LF) and `bin/hello.cmd` (CRLF) written correctly; #11888's
  fix is in place
- Task arguments containing `"`, `^`, `&` — all verbatim
- A quick sweep of `where` / `which` / `bin-paths` / `env -s pwsh` from a cwd containing a space and
  non-ASCII — no mangling

### Windows, tenth pass — 2026-08-22 → #12274

Swept the surfaces the ninth pass had left: the rest of the `generate` family, `generate bootstrap`
(including its `--windows` `.cmd` launcher), lockfile contents, every `--json` output, paths with
spaces and non-ASCII, and file tasks.

**The finding — #12274.** A file task whose shebang names pwsh cannot run on Windows. The
documentation's own example (`docs/tasks/file-tasks.md`, Shebang section: `#!/usr/bin/env pwsh`,
no extension) fails verbatim with pwsh's own message about `-File` needing a `.ps1` extension — and
mise finds the task and reads its `#MISE` header before failing to start it.

**It is the Windows build of pwsh alone.** Measured on the *same* pwsh 7.6.5, installed in WSL via
`mise use -g powershell@latest` for the control:

| | `pwsh -File <no extension>` | kernel shebang |
|---|---|---|
| Linux | ✅ rc=0 | ✅ rc=0 |
| Windows | ❌ rc=64 | — |

So the shape works on Linux/macOS and fails only here; **the fix removes a divergence rather than
creating one.** Four escape routes were measured and only one survives: a temp `.ps1` copy.

**The user caught me getting this backwards.** I first reported it as Windows-specific (right), then
"corrected" myself to "Linux fails too, so fixing it creates divergence" (wrong) on the strength of
*code reading only* — no pwsh was installed to measure with. The user pushed back: pwsh ships a Linux
build, so `.ps1` runs there; why not fix it everywhere? Installing pwsh and measuring settled it in
one command. **A correction issued from reading, against a measurement, is still a guess.**

#### The next candidate corrected the PR — 2026-08-22

The pass left `shell = "pwsh -c"` on an extensionless file task as the next candidate, on the
strength of a **direct pwsh probe**: `pwsh -Command "& '<path>'"` exits 0 having done nothing.
Measuring it **through mise** before writing any code produced the reproduction *and* something
else: the reason I had written into #12274 for exempting `-Command` from the shim was **factually
wrong**. The comment said

> `-Command` takes a script *string*, so the path is never opened as a file and a different name
> would change nothing.

PowerShell's **command** resolution asks for `.ps1` exactly as `-File` does, so the name does
change things. Measured through mise on Windows: extensionless + `shell = "pwsh -c"` → rc=0, no
output; the same file as `.ps1` → runs, args forwarded. And directly: `pwsh -c <temp .ps1 copy>
ARG1` → runs. **The shim was always the right answer for both modes.**

Removing the exemption made the PR *smaller*: the `-Command`/`-File` classification extracted into
`src/path.rs` had no remaining caller, so that whole refactor came back out. #12274 went from
+245/-16 across four files to +194/-6 across three. **An extraction whose only consumer disappears
is scope, not tidying — take it back out.**

The user chose to fold this into #12274 rather than open a second PR against the same function.

**The lesson, and it is not the one I expected.** The rule "measure a candidate before implementing
it" is already written down here. What it caught this time was not the candidate — that reproduced
fine — but **a false premise in code I had opened a PR with two hours earlier**. Reading pwsh's
docs-shaped behaviour and reasoning about "modes" gave me a distinction that does not exist. Had I
skipped the measurement and just implemented the candidate, the wrong comment would have gone to
review as fact.

#### Command-mode file shells drop or mangle their input — **implemented, #12277**

Found in the same session as a *control* for the pwsh work. Separate cause, separate fix, **not**
part of #12274 — though it lands in the same function, so the two will conflict.

| setting | measured |
|---|---|
| Linux `shell = "sh -c"` (with `use_file_shell_for_executable_tasks=1`) | task runs, **argument silently lost** — `RAN sh-c: []` where the control prints `[ARG1]` |
| Windows `shell = "bash -c"` | every backslash eaten out of the path — `C:UsersJamAppData…: command not found`, rc=127 |
| Linux default `sh` / Windows default `cmd /c` | ✅ args forwarded |

One cause: mise pushes the script path onto a shell that takes a **command string**, as if it were
a file argument. `sh -c <path> ARG1` makes ARG1 into `$0`, so `$1` is empty.

**The file-shell contract is "a program that takes a script path plus args"**, and the defaults say
so: `unix_default_file_shell_args` is **`sh`**, no `-c`, described as *"For example, `sh` for sh."*
`cmd /c` is not a counter-example — `/c` is cmd's only way to start anything, and it forwards args
correctly (measured).

The fix is the POSIX idiom `sh -c '"$0" "$@"' <path> <args>`, which also stops the mangling because
the path stops being part of the command string.

**The blocking question is answered: yes.** Git-Bash `bash` execs a `C:\...` path as `$0` without
complaint — `bash -c '"$0" "$@"' 'C:\…\task' ARG1` → `ran: [ARG1]`, rc=0, where the current shape
gives rc=127. Paths and arguments containing spaces survive too.

**Dropping the `-c` instead was measured and rejected.** `sh <path>` makes sh *interpret* the
script rather than run it, so the shebang stops choosing the interpreter:

```
sh -c <path>                  → bash-array ok: y []      shebang honoured, argument lost
sh -c '"$0" "$@"' <path> ARG1 → bash-array ok: y [ARG1]  shebang honoured, argument kept
sh <path> ARG1                → Syntax error: "(" unexpected
```

**The trap in this one: `is_posix_shell_program` counts fish, and fish is not POSIX here.**
`fish -c '"$0" "$@"'` → *"$@ is not supported. In fish, please use $argv."* Reaching for that helper
unmodified would have broken fish while fixing everything else. fish has the *same* defect
(`ran: []`) and its own cure (`$argv`, measured on 3.7.0 including the no-extra-args case). **That
helper answers "does this shell want a Unix-style PATH", not "is this shell POSIX" — check what a
predicate was written for before borrowing it.**

`ksh` is **not measured** — not installed in WSL. The idiom is POSIX so it should behave like the
others; that is reasoning, not a measurement, and #12277's body says so.

Note the Linux case is reachable **only** with `use_file_shell_for_executable_tasks=1` — without it
an executable file task is spawned directly and `shell` is ignored entirely (measured both ways).
On Windows the shell path is the normal one, since an extensionless shebang task is never directly
executable there. Both are covered: `e2e/tasks/test_task_file_shell_command_mode` (which runs
through the real harness — `./e2e/run_test tasks/… ` works from WSL against `/mnt/c`) and
`e2e-win/task_file_shell_command_mode.Tests.ps1`.

#### Looked at, nothing there

- **`.cmd` line endings** — `generate bootstrap --windows` writes its launcher **LF**, while
  `task-stubs` and `tool-stub` write theirs **CRLF**. A real inconsistency, but **not a defect**:
  a CRLF copy of the same launcher was run as a control and behaved identically on both the
  `goto :run` path and the `goto :fail_download` label-jump path. Not proposed.
- **Task discovery needing a shebang or extension on Windows** — documented, `file-tasks.md`.
- **`mise.lock`** — LF, idempotent across repeated `install`/`lock`, all platforms recorded, no
  backslash leakage.
- **Eight `--json` outputs** (`doctor -J`, `ls`, `env`, `settings`, `config ls`, `task ls`,
  `outdated`, `ls --offline`) — all parse, Windows backslashes included.
- **A project directory named with a space and Japanese characters** — `install`, `which`, `run`,
  `exec`, `env` all correct, quoting included.
- **`generate` write paths** (`github-action`, `devcontainer`, `task-docs`, `bootstrap`) — LF, correct.

#### My own measurement was broken for part of this pass

`grep -c $'\r$'` reported **every** file as CRLF, including files `od -c` showed ending in a bare
`\n`. I nearly filed "all generated files are CRLF on Windows" off it. What caught it was putting
two files of *known* line endings through the same command; the contradiction showed up immediately.

**Measure line endings by counting bytes** — `tr -cd '\r' < f | wc -c` against
`tr -cd '\n' < f | wc -c` — and **keep a known-good and known-bad control in the same run.**

### #12277's review round — a bot finding that was simply correct, and a container to check it

Greptile, one comment, **P1**, empty review body (all of it was inline — check both, the body was
`length=0` here but that is not the norm): *"Ash command-mode payload is skipped."* `ash` is not in
`is_posix_shell_program`'s list, so `shell = "ash -c"` would keep the defect the PR fixes.

**Correct, and no caveat to attach to it.** Not every finding needs an argument — this one was a
gap in coverage, and the work was verifying it rather than debating it.

**Verifying it needed a shell this box does not have.** No `ash`, no `busybox`, no `mksh` in WSL;
`/bin/sh` is dash. **An alpine container is the way to measure a shell you do not have** — and
`wslc` handled it, which is the machine's stated preference for the simple case:

```
wslc run --rm -i alpine:latest sh -s < probe.sh
  ash -c /tmp/task ARG1 ARG2              → ran: [] []
  ash -c '"$0" "$@"' /tmp/task ARG1 ARG2  → ran: [ARG1] [ARG2]
```

Same defect, same cure. `ash` went into `is_posix_shell_program`'s list rather than a second list
beside it, so the Windows PATH-conversion caller picks it up too — equally correct there.

**Named the edge it does not reach, rather than leaving it to be found:** `shell = "busybox sh -c"`
still misses, because the program stem is `busybox`. Every shell predicate in `src/path.rs` matches
on the program name alone, so teaching one of them to read the first argument would make it the odd
one out. Said so in the reply.

### #12274's review round — the bot's scenario was unreachable and its point was still right

CodeRabbit, one comment, 🟠 Major, against the amended HEAD (it named the commit range, so it had
seen the `-Command` change): *"Line 1451 passes the `.ps1` shim into `get_file_program_and_args`,
which resolves the shell again. For an extensionless task with no task shell or shebang, this
replaces a configured default such as `pwsh -Command` with the `.ps1` extension mapping
`pwsh -File`."* It asked for an E2E case with `windows_default_file_shell_args = "pwsh -Command"`.

**The scenario it named cannot happen.** An extensionless file with no shebang is not a task on
Windows — discovery needs a shebang *or* an executable extension. Measured with both fixtures in
`mise-tasks/` and that setting exported: `mise task ls` lists only the `.cmd` one. So the requested
E2E case would have asserted against a task that never runs, and I said so rather than adding it.

**But checking it found a regression I had already pushed.** The re-resolution hazard *is* real —
just by another route. With `use_file_shell_for_executable_tasks=1` and a PowerShell default file
shell, a `.cmd` task goes through the file shell, and my `needs_ps1_shim` said yes to it:

- before the branch, measured on 2026.8.10: `mise run cmd_task ARG1` → `cmd task ran: ARG1`, rc=0
- what my code would have done: copy the `.cmd` to a `.ps1`, then `pwsh -c` it →
  `ParserError ... @echo off`, **and still rc=0**

A working task turned into a silent parser error. Fixed two ways: the shell is now resolved **once**
from the original path and threaded into `get_file_program_and_args` (the bot's structural point),
and staging is skipped for any name the OS can start (`os_can_launch_extension`), because PowerShell
resolves `.cmd`/`.exe` as commands and runs them correctly. A test pins it — and it is honestly
labelled a **guard, not a reproduction**: it passes before and after.

**The lesson, and it is the same one twice in two days.** Verifying a claim instead of accepting or
dismissing it is what pays — and both times the payment came from an unexpected direction. Measuring
the *next candidate* exposed a false premise in this PR; verifying a *bot's wrong scenario* exposed a
regression in it. **A finding can be wrong in every particular and still be pointing at something.
Reproduce what it describes, then go looking for what it might have meant.**

### #12267's review round — a false statement about the harness, and a stale re-run

**Greptile was right and I was wrong.** My test comment said `run_test` does not export
`MISE_CACHE_DIR`. It does, at [`run_test:96`](e2e/run_test:96). I had grepped **a line range rather
than the file** and concluded from its absence in the part I sampled. A comment that states
something false about the harness is worse than no comment: the next person maintaining the cache
setup reads it as fact. **`grep` the file, not a window into it.**

**CodeRabbit's "the update is reported twice in text mode" was true but pre-existing** — the deleted
lines of my own diff show `show_latest()` and the `warnings.push` were both already there. Declined
the suggested fix (push the warning only under `--json`): it would make the warnings summary
conditionally incomplete, which is the same shape as the bug being fixed, and it would break the
PR's own text assertion, since only the warning carries `currently on …`. Offered the other
direction — dropping `show_latest()` — as a separate question about presentation.

**A nitpick then arrived that was already fixed.** Its own "Commits" line named the range ending at
the commit *before* the fix. **Read which commits a bot reviewed before answering it**; the reply is
"already addressed in `<sha>`", not another round of work.

**A last round found a real hole in my own assertion, and a fix aimed at the wrong file.**
`assert_succeed` runs its argument through a fresh `bash -c`, where `pipefail` is off, so in
`mise doctor -J | jq …` the pipeline's status is jq's alone: a doctor that printed the right JSON
and then exited non-zero would pass unnoticed. Measured, producer printing matching JSON then
exiting 1 — **rc 0 as the helper runs it today, rc 1 with `set -o pipefail`**, and the healthy and
warning-absent cases still 0 and 1.

**The first attempt at that measurement was wrong and looked wrong.** I put the producer and
`exit 1` in one string separated by `;`, so only `exit 1` reached the pipe and every case came back
`4`. The odd value is what prompted a second look — **an exit code that fits no hypothesis is the
measurement failing, not the subject behaving strangely.**

**Fixed on the assertion, not in `assert_succeed`.** That helper backs every `assert_succeed`,
`assert` and `assert_contains` in the suite; enabling `pipefail` there changes the exit status of
every pipeline any test has ever handed it, and a test tolerating a benign failure left of a pipe
would start failing. **A harness-wide behaviour change is not a side effect of fixing one
assertion** — offered separately instead.

### #12218 — I called a regression a "design decision" because I had not looked at the history

**The user asked why, and the question was the whole finding.** I had reported that `--no-hook-env`
applies the environment at activation in bash and in no other shell, and classified it as a design
call to put to jdx rather than a bug to fix. My reasoning: the flag admits two readings — "do not
install the periodic hook" (bash right, three shells unhelpful) versus "do not touch the
environment" (three shells right, bash leaking) — and each reading changes a different set of shells
with user-visible consequences, so #11883's lesson said ask first.

**The history answers it in one command, and I had not run it.** `sl annotate -c` on
`src/assets/bash/activate.sh`, then the parent of the commit it names:

```rust
// bash.rs, before src/assets/bash/activate.sh existed
if !opts.no_hook_env {
    …
    _mise_hook            // inside the guard
}
```

bash matched the other three until `48e5dd59ca7d` — **"fix(bash): avoid duplicate trust warning
after cd" (#8920)** — extracted that script into the asset file and left the call outside the guard.
The subject of that change was trust warnings; the flag is not mentioned in it. Nothing pinned the
new behaviour either: the test that same commit added activates with `--status`, and no bash test
covered the flag at all.

> **"Design decision" can be a name for "I have not checked."** The tell was that I could describe
> both readings but could not say which one anyone had ever chosen. When a question has a
> *historical* answer, asking the maintainer is not caution — it is handing them work I could have
> done. Run `annotate` on the line before deciding a behaviour was intended.

**The measurement I had deferred, taken before implementing:** pwsh was the one shell I had only
read, not run. Measured — not applied under the flag, applied without it — which completed the table
and made bash the only outlier of four.

**The review round then found the probe could pass for the wrong reason, twice.** Greptile: the
inner `bash -c` had no `errexit`, so a failed `mise activate` fell through to the final `echo` and
printed the expected `unset`. CodeRabbit: an inherited `NO_HOOK_ENV_PROBE` would be read as the
environment having been applied, and `eval "$(mise activate …)"` swallows the activation's own exit
status. All three are the same shape as the bug the test guards — **a check that reports success for
a reason other than the one it names** — and this is now the fourth PR in a row where that shape
showed up in my own test rather than in the code.

### #12205 — merged with no review findings, the second one

Like #12131. What both have in common is worth copying: a single-statement change, and a body that
carried the measurements up front — here the two orphans with sizes, the sixty-second persistence,
the unlocked check, and the argv[0] table — rather than leaving a reviewer to ask for them.

### #12161's review round — a maintainer asked for a measurement this box cannot take

**jdx confirmed the premise and rejected the scoping.** The PyPI launcher defect was real, but my
`platforms = ["windows-x64"]` left Windows ARM64 falling through to `pipx:` — a backend already known
not to launch there. **That is worse than either working or reporting unsupported**: it picks a
backend we know is broken. The defect was never architecture-specific; I had scoped by architecture
anyway because that is what the asset name said.

**The ask was concrete: test the x64 ZIP on GitHub's `windows-11-arm` runner.** Doable, and the
method generalises:

- **A registry entry can be tested without building mise.** The registry is compiled in, so a
  registry change normally needs a build — but the same thing spelled as an explicit backend with
  options in a `mise.toml` exercises the identical code path with a *released* binary:
  `"github:Azure/azure-cli" = { version = "…", version_prefix = "azure-cli-", asset_pattern = "…" }`.
- **The driver has to be the right architecture too.** An x64 mise under emulation would detect
  `windows-x64` and the run would prove nothing. Read mise.exe's PE header (`0xAA64`) before trusting
  a single later line.
- **`platform.machine()` answers a different question than the one asked.** It reports the host CPU —
  `ARM64` even inside an emulated x64 process. The PE header (`0x8664`) and the
  `[MSC v.1944 64 bit (AMD64)]` build tag are what say *this is the x64 build*. **When asked whether a
  binary is x64, measure the image, not the machine.**

**Precedent hunting is what made it uncontroversial.** `codeql` already points `macos-arm64` at the
`osx64` asset for the same emulation reason, and `flyway` already uses a platform-scoped
`asset_pattern` containing `{{ version }}`. Two existing entries turned a proposal into a convention.

**Two findings that were only about the probe, kept because both cost a round trip:** `run: & $env:MISE …`
is a **YAML parse error** — `&` opens an anchor, so any `run:` starting with it must be a block scalar,
and GitHub reports it as "workflow file issue" with no job and no annotation. And mise's shim
re-invokes `mise` **by name**, so installing to an absolute path is not enough; `mise` has to be on
`PATH` or the shim fails with `mise-shim: failed to execute mise: program not found`.

The probe lived on a scratch branch in the fork and was **deleted before the reply claiming it was
deleted** was posted. Say it after doing it, not before.

### #12176's review round — two bots, and both holes were the PR's own subject

Three findings, and every one of them was **an assertion that passes for a reason other than the one
it names** — which is exactly what the PR was fixing. That is not a coincidence worth shrugging at:
the guard you write against a class of bug is written in the same hand that produced it.

**Greptile:** the new test called `assert_fail` only with `false`, never the branch that rejects a
command which *succeeded* — the false-green direction, and the one the PR body made the most noise
about. **Writing it was the interesting part.** The two natural forms both report "accepted" against
the *fixed* helpers:

| form | fixed helpers | `main`'s helpers |
| --- | --- | --- |
| `if ( assert_fail "true" ); then …` | accepted | accepted |
| `( assert_fail "true" ) \|\| rc=$?` | accepted | accepted |
| child shell, plain top-level call | **rejected** | accepted |

`assert_fail` rejects by calling `fail`, which `exit`s, and `set -e` is suspended inside an `if`
condition and to the left of `||`. **bash behaves identically**, so the child shell is not a zsh
workaround. A test written either of the first two ways would have passed against anything.

**CodeRabbit (major), on that same child shell:** `if <child>; then` treats *any* non-zero exit as a
pass, so an unset `TEST_ROOT` or a failed `source` satisfies it without ever running `assert_fail`.
Measured: the old form passed that sabotage, the marker form (`READY` must appear, `RETURNED` must
not) catches it. **A child process's exit status is not evidence about what the child did.**

**CodeRabbit (minor):** `run_with_timeout` and `as_group` were only called with `true`, which returns
0 whether or not the renamed variable holds anything. Measuring the failure paths turned up something
better than coverage: under `set -euo pipefail` — how `run_test` invokes tests — the unfixed helpers
do not misreport there, they **terminate the test at the `local status` line**, silently once the
helper's stderr is redirected. Those branches were unreachable on `main`, not merely untested.

**Left as a trap, not fixed here:** `assert_fail` silently accepts a succeeding command whenever it is
called in a `set -e`-suspended position, in bash as much as zsh. Every current caller is a plain
statement so the suite is fine today; the next person to write `assert_fail … || something` will not
be.

### #12117's review round — jdx's deep review, and every finding traced to one wrong choice

**The richest review received so far, and it was AI-assisted** (jdx's comment signs off "Tool: Claude
Code; model: anthropic/claude-fable-5"). It opens by confirming the happy path end-to-end — flag
parsing, quoting, the data-dir mtime watch, the snapshots, the new assertions — and then takes the
shape apart. **A maintainer review that starts by listing what it verified is worth reading twice:
the confirmations are as load-bearing as the objections.**

**The root defect: "the definition is absent" is also the post-deactivate condition.** `deactivate`
unsets `_mise_hook` (zsh) / `MISE_SHELL` (pwsh) but leaves the command-not-found handler registered.
So the fallback fires in shells the user explicitly deactivated — and in pwsh the handler runs
in-process, so `Invoke-Expression` re-applies PATH / `__MISE_SESSION` **permanently**. Before the PR
that state failed loudly; after it, it silently reactivates.

**I copied `_mise_hook`'s body and dropped the one line that mattered.** The pwsh fallback duplicated
its seven lines verbatim *minus* the `$env:MISE_SHELL -eq "pwsh"` guard — the line that keeps
post-deactivate hooks inert. jdx's phrase: **drift on day one.** When you inline an existing body,
the guard around it is part of the body.

**`(( $+functions[_mise_hook] ))` dlopens `zsh/parameter` — the exact hazard the same file works
around fifty lines up.** `_mise_hook_env_state` was deliberately rewritten to use `typeset +m`
because referencing a `zsh/parameter` special can deadlock under Rosetta in login shells (#11187).
I took the idiom from `deactivate` in that same file **without asking why the neighbouring code
avoided it**. `typeset -f x >/dev/null 2>&1` is the module-free form, and the very next `elif`
already used `declare -f`. CodeRabbit flagged this before jdx did.

**Greptile's early-exit P1 was right, and my refutation was right too — at default settings.** I
measured that installing a tool bumps `dirs::DATA`'s mtime and so busts `should_exit_early`, and jdx
confirms that. But with `hook_env.cache_ttl` set **and** an inherited `__MISE_SESSION`, the TTL fast
path returns *before* that check, and the refresh prints nothing. `cache_ttl` defaults to `0s` and
`_mise_hook`/fish share the hole, so it is parity with a pre-existing flaw rather than a regression —
but the fallback is uniquely positioned to pass `--force`, which is what shipped.

> **A measurement taken only at default settings does not refute a claim about a code path.** The
> control I built was sound and the conclusion still didn't generalise, because I never varied the
> setting that gates the path. Next time a bot names a code path, vary the settings that reach it.

**Structural: the guarded fallback was strictly more code than either precedent.** In zsh both arms
were byte-identical (`_mise_hook` with no arguments *is* that `eval`); in pwsh the else-branch was a
verbatim copy. Collapsing to fish's shape — unconditional inline `hook-env`, gated on `MISE_SHELL` —
is less code and dissolves the deactivate bug and the `zsh/parameter` bug as side effects. **When one
change fixes three findings, the findings were symptoms of the shape, not separate bugs.**

**Dead code I added for symmetry.** The `$status` save/restore in the pwsh fallback restores a
constant `0` — the branch is only entered when `$LASTEXITCODE -eq 0` and nothing reads it before the
handoff. I added it so the two arms would "behave identically"; symmetry with a branch that should
not have existed is not a reason.

**Tests, and one repeat offence.** The zsh e2e's `mise uninstall` plus its not-installed precondition
guarded a state that cannot exist — the harness gives every test a fresh `HOME`/`MISE_DATA_DIR` — and
`mise use -g tiny@3.1.0` was unnecessary because `registry/tiny.toml` declares `bins = ["rtx-tiny"]`,
which is all `install_missing_bin` needs. Worse: the e2e-win line I added promised uniqueness in its
comment ("the only `hook-env` left in the script") while `Should -Match` only asserted existence —
**the same hole CodeRabbit had taught me about in that very file two rounds earlier, reintroduced one
line away from the count pattern that closes it.** A lesson learned in a file does not stick to the
file; it has to be applied at each new assertion.

**Copy this habit:** jdx closed by recording two theories he chased and *ruled out* — that the zsh
test's regression mode is not unbounded recursion, and that staleness for already-installed tools
under `--no-hook-env` is the flag working as documented. Ruled-out theories are worth writing down;
they are what stops the next reader re-chasing them.

Taken in full in one commit, rebased onto main at #12152, merged 2026-08-19 10:55. Earlier bot rounds
on the same PR: CodeRabbit also asked for a UTF-8 BOM on the Pester file (`PSUseBOMForUnicodeEncodedFile`).

### #12089's review round — three rounds, and the finding was right while the patch was wrong twice

**Round 1 — Greptile (P1), valid: the fix made a latent bug reachable.** `--no-hook-env` omits the
`_mise_hook` definition while still emitting the command-not-found block, so the branch I had just
un-deadened called a function that does not exist. Measured, with the control:

| | `_mise_hook` defined | command-not-found block emitted |
| --- | --- | --- |
| `mise activate pwsh` | yes | yes |
| `mise activate pwsh --no-hook-env` | **no** | **yes** |

The consequence, measured inside a real `CommandNotFoundAction` ending in the same handoff: unguarded
the handler dies with `CommandNotFoundException` and never reaches `$EventArgs.Command`; guarded, the
handoff runs. **Un-deadening a branch means auditing what the branch does, not just whether it
fires** — nobody had ever executed those four lines.

**A plain script block is not a model of the handler.** `& { __absent; 'handoff' }` yields `handoff`:
execution continues past a name it cannot resolve. Inside the handler the same call aborts the block.
Measuring both is the only reason the e2e test asserts the real behaviour instead of the plausible
one.

**Round 2 — Greptile (P1), refuted: it argued against the guard it had asked for one round earlier.**
The claim was that skipping `_mise_hook` leaves the environment unrefreshed, so `Get-Command` fails
and the handoff never happens. True as far as it goes — but the unguarded alternative never reaches
`Get-Command` at all. The guard is weakly better in every case and worse in none, and round 1's
measurement was already the whole answer. **A bot contradicting its own previous round is not a
reason to concede; it is a reason to re-read the measurement.**

**What that objection did point at is real, and separate.** pwsh is the only shell that drops the
definition. Measured on the shipped build:

| shell | `--no-hook-env` defines `_mise_hook` | its command-not-found path calls it |
| --- | --- | --- |
| bash | **yes** | yes |
| zsh | no | yes |
| fish | no | no — runs `hook-env` inline |
| pwsh | no | yes |

`bash.rs:44-52` always renders the whole `activate.sh` and passes the flag through as
`__MISE_HOOK_ENABLED_VALUE__`, so `--no-hook-env` controls whether the hook is *installed*, not
whether the function *exists*. pwsh puts the definition inside `if !opts.no_hook_env`, which is
exactly why its generated `mise` wrapper and prompt function both have to `Test-Path` before calling.
**Follow-up shipped as #12117 — and the shape argued for here was wrong.** The reasoning against
bash's always-define approach held: defining `_mise_hook` unconditionally would switch on pwsh's
wrapper call, so `mise use` would modify the environment under a flag documented for the opposite.
But what actually shipped first was not fish's shape, it was a hybrid — `_mise_hook` when defined, a
copy of its body when not — and jdx took it apart. **Read the #12117 section below before reusing
any of the reasoning in this one.**

**The zsh half stopped being shape-only, and the measurement changed what the PR could claim.**
`zsh` went into WSL (`wsl -u root -- apt-get install -y zsh`; `sudo` there wants a password, `-u root`
does not) and the released build reproduced it end-to-end, with the control that makes it a finding
rather than an anecdote — **the tool installs in every case; only one cannot then run it**:

| activation | installed | runnable after |
| --- | --- | --- |
| `activate zsh` | ✅ | RAN |
| `activate zsh --no-hook-env` | ✅ | **NOTRUN** |
| `activate bash` | ✅ | RAN |
| `activate bash --no-hook-env` | ✅ | RAN |

And the fix's mechanism, without a build: after the failing case, `eval "$(mise hook-env -s zsh)"` by
hand turns NOTRUN into RAN. **A released binary can demonstrate the line you are about to add, even
though it cannot demonstrate your patch** — worth reaching for whenever the change is one statement.

**The two shells fail differently, which I would have got wrong from the pwsh result alone.** In pwsh
the undefined call throws out of the handler. In zsh it **re-enters `command_not_found_handler`** with
`_mise_hook` as the missing command, falls through, and carries on — so zsh does not abort, it just
runs `"$@"` before PATH is updated, after a wasted `hook-not-found`. Measured, not inferred.

**Round 2 — CodeRabbit, valid, and the one to remember: my new assertion asserted nothing.** I had
added `LASTEXITCODE -eq 0\)\{[^}]+Test-Path …` as the "positive" check answering an earlier round.
It matched the **unfixed shipped script** too. **A regression test that has never been run against
the unfixed input is not yet a test** — and here the unfixed input is one command away
(`mise activate pwsh --no-hook-env` from the installed binary). Replaced with the full shape plus a
count of bare `_mise_hook` calls inside the branch, so a second unguarded call added later cannot
slip through either.

**Round 3 — CodeRabbit, valid finding, wrong patch.** The empty `catch { }` meant a handler that
never ran would leave `Reached` false and pass — a false green. Their fix asserted the caught message
matches the missing hook's name. Measured: it names **the command the user typed**
(`mise-probe-missing-tool`), because PowerShell does not re-enter the handler for the unresolved name
inside it. Committing that suggestion would have been red on every run. Closed at the entry instead —
a flag set before anything can throw — keeping the exception *type*, the part of the suggestion that
survives measurement.

**Two of three patches would have broken something.** Treat a bot's diff as a hypothesis with the
same standing as its complaint: measure the suggestion, not just the objection.

### #12080's review round — both bots found the same thing, and it was the dangerous one

Greptile (P1) and CodeRabbit (minor) independently said the orphan matcher was too loose: it
accepted `.mise.<anything>.__selfdelete__.exe`, and the caller acting on it **deletes the file**. A
predicate that only has to be right about *display* can be sloppy; one that feeds `remove_file`
cannot. Tightened to the shape `self-replace` actually generates — 32 characters of `a-z`, read out
of `get_temp_executable_name`'s `for _ in 0..32 { file_name.push(rng.lowercase()) }` — with
`SELF_REPLACE_RANDOM_LEN` shared rather than a fourth private `32`.

Two things worth copying from how that was answered:

- **The tests assert the previously measured orphan still matches.** Tightening a destructive
  matcher can overshoot into not finding the thing the PR exists to clean up, and nothing else would
  have said so.
- **Two controls neither bot asked for** — right length with a digit, right length with an uppercase
  letter — because "32 characters" and "32 lowercase characters" are different predicates.

**#12058 merging settled the `MAX_PATH` debt.** #12062's body promised that whichever of the two
landed second would drop the duplicate constant; #12058 landed second and did. Then #12064, still in
review, had introduced a third copy because `file::MAX_PATH` was not yet in `main` — that one is now
gone too, and points at the shared constant. **A promise written into a PR body outlives the PR: it
came due twice, days apart, and nothing but this file was tracking it.**

**Closed without merging, both by jdx, both worth reading before proposing anything similar:**

- **#11853 — too broad for what it claimed to fix.** "Most of the patch changes production sandbox
  and spawn-error behavior… A narrower PR limited to improving `quiet_assert_succeed` output would
  be welcome." The e2e-diagnostics goal was accepted; the production changes carried along with it
  were not. **A PR is judged against the problem its own description states.**
- **#11883 — rejected on design, not on the code.** A missing `task_config.includes` entry should
  *not* warn: entries are search candidates, missing ones can be deliberate, and the docs recommend
  listing all five default directories, most of which are normally absent — warning would make the
  documented configuration noisy. Consistent with other config and env-file search paths, which
  quietly skip. **This is the answer to #4792's second ask, and it is the opposite of what the PR
  assumed** — see "Replies owed".

### #12064's review round — the same objection twice, and only the second one landed

Worth keeping because the two rounds look identical and are not.

**Round 1, about `MISE_DOWNLOADS_DIR`.** Greptile said a deep enough downloads root reproduces the
failure. Pushed back with a measurement: install writes a longer path **under the same root** — the
`.{filename}.mise-part.json` sidecar — so it fails at 214 while the scratch would only fail at 226.
No reachable window, and Greptile accepted it. **That reply's first version had the mechanism wrong**
(it claimed install's `<short>/<version>/<filename>` was the longer path; it is *shorter*, +30
against +32) and the correction is what turned up the sidecar and the general form `S + V + 7`.

**Round 2, about `MISE_CACHE_DIR`, after jdx asked for the move.** The same objection, and this time
**the defence does not transfer**: the cache and downloads roots are configured independently, so
nothing makes install fail first. Measured on 2026.8.6 with only `MISE_CACHE_DIR` varying — at 150
and at 200, `mise install` and `mise lock` both exit 0 and provenance is recorded. Nothing else in
mise fails at that depth, so there is no second signal.

Fixed by checking the sidecar length before downloading and bailing with a message that names
`MISE_CACHE_DIR`. **It does not make `mise lock` fail** — the caller already catches this error,
warns, and degrades to install-time verification, so what changed is that the reason is legible.

**Round 3 — the fix from round 2 was the wrong shape.** The guard checked one path, the artifact's
sidecar, before downloading. Greptile pointed out that the same scratch directory later receives a
checksum file and a provenance or signature file, each named from a URL, so the first check passes
while a later name is longer. **Trying to enumerate what will be created is the mistake**; the guard
was replaced by a note appended to the failure, which covers every file written there including any
added afterwards. Same non-effect on control flow: the caller still catches, warns and degrades.

The note is split into a pure function taking the directory, so the test does not depend on where
the machine running it keeps its cache — the earlier version asserted against the live `dirs::CACHE`
and would have failed on any host with a deep one. It also errs toward firing (a flat 64-character
allowance), which is the right side to be wrong on for something printed only after a failure.

**The residual is stated in the PR rather than hidden:** this class cannot be closed by choosing a
directory, because every root mise uses is configurable. Whether `mise lock`'s output should depend
on whether verification could run is a larger design question and jdx's call.

**Four review rounds, four separate commits.** Once a maintainer has reviewed a branch, follow-ups
go on top rather than into an amend, so the review still applies to what it reviewed.

**Two of the four rounds were me being wrong in a way a measurement caught**: the mechanism in the
round-1 reply, and the shape of the round-2 fix. Both were found by checking rather than by arguing,
which is the only reason the replies were worth reading.

**Merged 2026-08-15:** #11986 (`MISE.EXE` case), #11992 (`.sh` sibling), #11978 (dotfiles
symlink), #12012 (settings path separator), #12013 (BOM shebang), #12014 (`\\?\` in trust),
#12016 (pwsh quoting), #12024 (display separators), #12032 (`task_source_files` case re-enabled).

### Rebasing after the 2026-08-16 merges

Three of the eight then-open PRs conflicted; the other five were left alone.

- **#12058** — `src/file.rs`. main (via #12023) and this branch both appended tests to the end of
  the same `mod tests`, and both of the last tests end with the same `for` + `}` + `}` shape, so the
  merge aligned the wrong braces. Resolution keeps both sets.
- **#12050** — **no conflict at all.** GitHub called it CONFLICTING because the branch was cut from
  #12048; once that merged, rebasing the single commit onto `main` applied cleanly and the diff
  shrank to its own three files. **A "conflict" on a stacked PR may just be the parent landing.**
- **#11888** — two files. `tool_stub.rs` was the same both-added-a-test-module shape as #12058.
  `docs/tips-and-tricks.md` was **not mechanical**: the branch's paragraph said `mise generate
  bootstrap` had no Windows form yet, and #11919 had just merged one. Rewrote it to describe both
  halves and dropped the caveat. **A rebase can turn a true sentence into a false one — read prose
  conflicts for meaning, not just for markers.**

**#12045 needed no rebase even though it was stacked.** Once #12041 merged the merge-base moved and
GitHub's diff dropped the parent's files by itself. Check the diff before assuming a stacked PR needs
work.

**The `MAX_PATH` promise came due.** #12062's body said whichever of it and #12058 landed second
should drop the duplicate constant. #12062 landed first, so #12058 now keeps the definition in
`file` (`pub(crate)`) and `self_update` imports it. That is why #12058 touches a file unrelated to
what it fixes, and its body says so. **A commitment written into a PR body is a debt, and nothing
tracks it but this file.**

**`Should -Match [regex]::Escape($x)` does not do what it reads like.** In argument mode PowerShell
splits it into two arguments: `[regex]::Escape` becomes the pattern and `$x` silently becomes
`-Because`. CI said so plainly — `Expected regular expression '[regex]::Escape' to match …, because
\\example\share` — and it cost a CI round on #12066. Bind it first:

```powershell
$escaped = [regex]::Escape($script:UncDir)
$output | Should -Match $escaped
```

**Same family as `Args` being an automatic variable:** PowerShell parsing, invisible in review, and
only a CI failure tells you. Worth a grep for `Should -\w+ \[` before pushing a Pester suite.

**#12028 was closed, not merged.** It made plugin discovery repair an unresolvable `core:` backend
recorded in `.mise.backend.toml`. jdx's #12029 fixed the same red CI by correcting the e2e fixture
that recorded `core:dummy` for a tool the harness installs through an asdf plugin — the fixture was
simply wrong, and #12010 only exposed it. Competing with a maintainer's minimal fix on the same
symptom is not useful; the residual question (mise installs fine, then reports "not found in mise
tool registry" forever) is real but wants a clear error, not a silent repair.

**Merged 2026-08-14:** #11982 (argv[0]), #11981 (dotfiles conflict), #11985 (Pester teardown),
#11924, #11923 (chmod hint), #11917 (conf.d write target), #11989 (below).

**#11989 — `main` did not compile, and half of it was mine.** Two changes landed 24 minutes apart:
#11981 added `link_req`, a `cfg(test)` helper building a `FileRequest`, and #11983 then added
`content` as a required field. Each was green against the `main` it was cut from. `cfg(test)` is why
it was invisible to the build jobs and only `unit*`/`nightly` went red — on *every* open PR at once,
which is what made it look like infrastructure rather than a semantic conflict.

**When every PR fails the same way at the same moment, suspect `main`, not the PRs.** Check
`main`'s own content directly (`gh api contents?ref=main`) before diagnosing anything else. Reading
the error's file:line against `main` settled it in one step.

**#11883 changed an existing test, and that is the part to watch in review.**
`e2e/tasks/test_task_edit_nested_names` captured a path with `2>&1`, so the new warning landed in
the captured value and broke an equality assertion. Changed to stdout-only — but the reason it fired
is a genuine design question, raised in the PR body rather than buried: that block tests *"select the
first existing directory in include order"*, under which a missing entry is a candidate that lost,
not a mistake. The other three missing-include blocks in that file are unaffected because they use
`assert_fail_contains`, which tolerates extra stderr.

**A red e2e is unexplained until the failing test names are read.** On 2026-08-11 GitHub's API rate
limit was flapping (core 0/5000 at 03:23) and every e2e failure examined was a **network-tool**
test; #11861 went fully green on a re-run with no code change.

**Merged 2026-08-11..14 (Windows pass):** #11928, #11934, #11935, #11937, #11947, #11948, #11949,
#11950 — see the Windows section below. Also merged in that window: #11846 (#3866 pypy), #11850
(#4894 node patching), #11861 (e2e defect **A**), #11885 (#4690 venv `disable_tools`).

**Merged in the 2026-08-11 pass:** #11799 (`go.set_gopath` deprecation text), #11801 (#1764 git-hook
arguments), #11803 (#4407 inactive-tool hint), #11804 (relative `aqua.registries`), #11807
(RubyInstaller2 build revision), #11808 (flutter `-stable` doubling), #11811 (tera v1 `trim` ignoring
`pat`), #11813 (libc docs), #11816 (#5189 `go list` stderr), #11818 (#5199 `ignored_config_paths` on
Windows), #11820 (#4304 git-hook mise flags), #11822 (#4491 `mise ls` across backends), #11825 (#4098
conda DLLs on Windows), #11828 (#4917 aqua metadata lookup key), #11830 (`not_found_auto_install`
docs), #11831 (#4789 `activate --silent`), #11832 (#4813 aqua `semver()`), #11833 (Windows `.exe` in
the aqua envs override test), #11835 (list settings from env vars), #11839 (workspace member tests in
CI). Earlier still: #11788, #11789, #11791, #11793, #11796.

**#11826 was closed by jdx** — *"I think this goes without saying"*. That was a docs PR explaining
what `tools = true` costs. Second docs PR of the pass to be judged obvious; #11830 was written to
avoid the same fate by leading with a measurement and a wrong sentence rather than an addition.

**#11814 was closed by jdx** — *"doesn't look like an improvement to me"*. #4397 carries that
outcome plus what came out of the attempt, so nobody has to rediscover it. Draft/ready and
open/closed are the maintainer's call; do not reopen.

**Do not panic when the `triage` bookmark moves.** On 2026-08-09 it went `894bae7e` → `bc71cd5d`
without me touching it, and `sl diff` between the two showed **19 source files** changed. That is not
contamination: the triage commit gets rebased onto `upstream/main`, so a diff between two of its
revisions shows *main's* movement. TRIAGE.md itself was identical. Check
`sl log -r "parents(<rev>)"` against `upstream/main` before assuming anything is wrong.

**`windows-e2e` flakes on a teardown file lock — diagnosed on #11796, 2026-08-09, kept because it
will recur.** Only `windows-e2e` failed;
`test-ci` is a gate job that exits 1 when it does. The failure is
`e2e-win/shim_recursion.Tests.ps1` → **Container failed** with `Tests Passed: 84, Failed: 0` —
Pester's `Remove-TestDrive` hitting *"The process cannot access the file 'mytool.exe' because it is
being used by another process"*, i.e. a teardown file lock. That file last changed 2026-07-15
(#10982); this PR touches `sub-N:` resolution and `e2e/cli/*`, which is Unix-only. **The same
branch's previous push (`5221b06`) passed `windows-e2e`**, and every other recent branch passes it.
Both retries failed because the retry reuses the same workspace, so a leaked process keeps the lock.
**Re-running is not possible from this account** — `gh run rerun` returns
`Must have admin rights to Repository`; the only lever a contributor has is a push that changes the
SHA, and `upstream/main` had not moved at the time.

### The flag-alias rule — from #11789 (merged), keep

**A live trap came out of #11648, and it was from my own #11631.** Measured on **v2026.8.3**, intent
"write the dotfiles entry into `~/dots/config.toml`":

```console
$ mise dotfiles add -n --file ~/dots/config.toml "~/.bashrc"
~/dots/config.toml: "~/.bashrc" = {}

$ mise dotfiles add -n -f ~/dots/config.toml
~/.config/mise/config.toml: "~/dots/config.toml" = {}      # wrong config targeted
cp ~/dots/config.toml ~/.dotfiles/dots/config.toml         # and the file is adopted as a dotfile
```

`targets` takes any string, so the path is swallowed. No error, and `-f` means no prompt either.
**`mise use` has the same alias over the same collision**, from #11577 — there the value must resolve
as a tool, so it fails loudly (`other.toml not found in mise tool registry`), but the error names
neither the flag nor the mistake.

**jdx closed #11648 with *"not sure about this, it could make users think `--force`"* and the
objection was right** — in mise **`-f` means `--force` on ten commands** (root `Cli`, `deps install`,
`dotfiles add`, `dotfiles apply`, `dotfiles unapply`, `hook-env`, `install`, `link`,
`plugins install`, `plugins link`) against `--file` on **three** (`unset`, `config get`,
`config set`). Applied consistently that forbids offering `--file` wherever `-f` is already force, so
the user's call was to remove it from **both**, not just the dangerous one.

**The rule, which needs no exception list:**

> A long alias may be offered only when its natural short form is not already taken by a
> **different** argument on the same command.

That selects **exactly `use` and `dotfiles add`**; the other nine keep both spellings, and **`--path`
still reaches all eleven**, so #4881's "one spelling that works on both" is satisfied — by `--path`,
not `--file`. **Guard:** `config_target_aliases_do_not_shadow_another_short_flag` walks the whole
command tree (not the `cases` table), restricted to the `file`/`path` vocabulary, so re-adding the
alias anywhere fails the build even if the table is left alone.

### The e2e defects — A and B, found 2026-08-10 while investigating someone else's PR

Started from #11838's red CI, which turned out to have **nothing to do with that PR**. Two separate
pre-existing defects came out of it. **A is fixed (#11861, merged); B is still open as #11853.**

**B — the e2e workflow discards half its failures.** `.github/workflows/test.yml`'s retry step put
**two `run_all_tests` invocations in one `command:`** with no aggregation and no `set -e`, so the
job's exit code was the second line's and the first line's failures vanished. Tranche is
`index % TEST_TRANCHE_COUNT` over `find . -name "test_*" | sort` (`e2e/run_all_tests:67`), and
**tranches 0–3 are always the first line** — half the suite could fail silently. Three CI logs
show the same test failing with the job green (`31375451198`, `31436203952`) and then red once the
index shifted (`31439676909`). Reproduced the shift by arithmetic: main has 830 test files and the
fixture sits at index 563 → tranche 3; #11838 adds one file above it, 831/564 → tranche 4. PR
**#11853** aggregates both tranches. It is deliberately *not* `set -e`, because a failure in the
first line would then skip the second and halve coverage.

**A — `e2e/tasks/test_task_action_cache_session` had been failing since #11812 (2026-08-09).** Its
`[tasks.compile]` used `deny_write = true` + `allow_write = ["target"]`, and **the CI containers
have no Landlock**. With a diagnostic print added on #11853's branch the runner said so itself:

```
mise sandbox: failed to apply landlock restrictions: RestrictionStatus { ruleset: NotEnforced,
no_new_privs: true, landlock: NotEnabled, … }
```

(run `31449920970`, job `93652822330`.) `restrict_self()` returns `NotEnforced`, `apply_landlock`
bails **inside the `pre_exec` hook, before `execve`**, and `cargo build` never starts. PR **#11861**
drops the sandbox from that fixture; all 18 checks pass, with
`PASS: tasks/test_task_action_cache_session` in the log (job `93673507583`).

**jdx opened #11865 with a different diagnosis; it did not hold, and #11865 is now closed.** That PR
kept `deny_write` and redirected `CARGO_HOME`/`CARGO_TARGET_DIR` under `target/`, on the theory that
Cargo's global lock files were being rejected. **Its own CI still failed the fixture on its own head
commit** (`3fc941c1`, job `93663096515`, both retry attempts) — far better evidence than the local
Docker reproduction I ran first, and what the comment posted there led with. **Keep the shape of
that argument**: a PR whose own CI reproduces the failure it claims to fix settles the question
without needing a local repro at all. The theory was not wrong in general, just conditional on
Landlock working: `e2e/run_test:43` resolves `CARGO_HOME` from the **outer** `$HOME` before `HOME` is
swapped, so it does land outside `/tmp`, and the `deny_write`-only branch of `apply_landlock` grants
only `/`(read), `/tmp`, `/dev` and `allow_write`. Where Landlock is `NotEnabled` there is nothing at
that layer to fix.

Worth keeping: **`deny_write` was barely constraining this fixture anyway.** The e2e isolated dir is
under `/tmp` and that branch grants `/tmp` full access, so `target/`, the config and the cache were
always writable. The only write it actually denied was Cargo's own `CARGO_HOME` — not what a
task-action-caching test is asserting.

### Two traps from #11846 — pypy on the precompiled path (#3866, merged and replied)

python-build-standalone is **CPython only**, and the precompiled path is taken unconditionally on
Windows, so `pypy*` could not be installed there at all. The fix added a pypy branch reading
`downloads.python.org/pypy/versions.json`. Both traps below are general, not pypy-specific.

**The ordering is concatenation, not a sort** — pypy first, CPython after, in `merge_pypy_and_cpython`
— because AGENTS.md forbids new `Versioning` call sites and PyPy's `7.3.4rc2` shapes are exactly what
a semver comparator gets wrong. An earlier revision *did* sort and produced
`… 7.3.4, 7.3.4rc2, 7.3.4rc1 …`, resolving a bare `pypy3.6` to `7.3.3rc1`. **The PR body still
described that deleted sort for a while** — a body that outlives its diff is the same class of error
as an unrun command; re-read it after every design change.

**CodeRabbit's `Settings::os()` finding was real and worse than stated.** Three pypy call sites took
arch from `Settings` but OS from `std::env::consts::OS`. `PlatformTarget::is_current()` compares
against `Platform::current()`, which is **built from `settings.os()`** — so in `resolve_pypy_lock_info`
the branch was *selected* by one OS and resolved with another, and `MISE_OS=linux` on a Windows host
would record a `win64` archive URL under the linux platform key. **The control that proved the fix:**
`mise ls-remote python` listing 208 entries / 87 pypy on win64 against 215 / 94 under
`MISE_OS=linux MISE_ARCH=x64` — an override that changes the output is what shows `settings.os()` is
the one being read.

## The Windows implementation-gap pass — 2026-08-12..14

**Scope note: this is not old-band triage.** The user directed a sweep for Windows implementation
gaps, so `#11xxx`-era discussions are in scope *here* by that direction, against the standing scope
policy at the top of this file. Do not generalise it into re-opening the 10xxx/11xxx band.

**Merged (8):** #11928 (`activate`/`completion` accept both `pwsh` and `powershell`), #11934 +
#11935 (discussion #11046, one half each), #11937 + #11947 (discussion #11192, one half each),
#11948 (restore `MISE_TRUSTED_CONFIG_PATHS` after the trust suite), #11949 (stop calling a mangled
value a semver range), #11950 (resolve a shell named by a Windows path).

**Merged later the same day:** #11982, #11981, #11985, #11924, #11923, #11917.

**Open from this pass:** #11919, #11888 — see the Open PRs table above. #11986, #11992 and #11978
merged 2026-08-15.

**Discussions:** #11046 and #11192 replied 2026-08-14. #11423, #11431 and #7507 replied 2026-08-15,
once their PRs merged. Nothing from this pass is owed.

### A second Windows pass — 2026-08-15

Six more findings, all shipped: #12007 (unknown file-task header key warns instead of failing the
whole config load), #12008 (docs), #12012 (`mise settings set` split a path list on `:`), #12013 (a
BOM in front of a shebang hid the task entirely), #12014 (`\\?\` leaked into `mise trust` output)
and #12016 (pwsh env output did not escape `'`), plus #12023 and #12024. **None of them came from
a discussion** — they were found by probing, and their PR bodies cross-reference only sibling PRs.

**All three findings from that pass are now PRs** — #12048, #12050, #12055 — but the notes below
stay, because each carries a trap that is not visible from the diff:

1. **`mise activate` (no shell argument) and `mise hook-env` (no `--shell`) panic on Windows,
   always.** `env::SHELL` reads `COMSPEC` there, which is `cmd.exe`, which is not a `ShellType`, so
   `get_shell(None)` is `None` and `.expect()` fires — `src/cli/activate.rs:71`,
   `src/cli/hook_env.rs:55`. Measured from PowerShell **and** Git Bash. Linux control, same binary
   in a container: fine with `SHELL` set and fine with it unset (falls back to `sh`); only
   `SHELL=""` panics, which is pathological. `mise shell` and `mise deactivate` hold the same
   `.expect()` but are guarded by `env::is_activated()` first, so they give a clean error — the
   inconsistency is inside mise.
2. **Windows shell detection ignores `SHELL`.** Git Bash/MSYS2/Cygwin set it, and `ShellType`
   already parses a Windows shell path (there is a test for `C:\msys64\usr\bin\bash.exe`), but
   `COMSPEC` wins so it is never read. `mise doctor` says `shell: (unknown)`. **Do not "fix" this by
   changing `env::SHELL`** — `src/cli/exec.rs:191` and `src/cli/en.rs:28` pair it with
   `SHELL_COMMAND_FLAG`, which is `/c` on Windows, so honouring `SHELL` there would run
   `bash.exe /c …`. Only the `MISE_SHELL` detection should consult it.
3. **`mise env` defaults to bash syntax on Windows** (`src/cli/env.rs:183` hardcodes the fallback),
   so plain `mise env` in PowerShell prints `export FOO='…'`. #12050 covers Git Bash users; plain
   PowerShell is a design call, so **#12055 is written as a question** — it picks pwsh and lays out
   the alternatives (error like #12048, or leave it) for jdx to choose. `mise env` is not like the
   other four: it has `--json` / `--dotenv` / `--values`, so a fallback there is legitimate and
   erroring would be a contract change.

### Windows, fourth pass — 2026-08-15 → #12058

The two leads the third pass had parked as "needs setup" both turned out to be real. One PR,
because they are the same defect: **a Windows IO error reaching the user as a bare OS code.**

1. **`mise uninstall` cannot delete a running tool and does not say so.** Install `jq`, start its
   exe, uninstall: `failed rm -rf: …` then `アクセスが拒否されました。 (os error 5)`. On Windows an
   access-denied under an install directory is nearly always the tool still running; unix unlinks a
   running binary silently, so there is nothing to say there. **The failure is correct** — the
   install survives and `mise ls` still lists it — so the fix is the message, not a retry.
   Deliberately **no retry added**: a process holding a file keeps holding it, unlike the transient
   antivirus lock `do_rename` already retries through.
2. **A long install path fails with "path not found".** `failed to persist temporary file: (os
   error 3)` for a path that exists.

**The second one is where the guessing would have gone wrong, twice.** First guess — "MAX_PATH" —
looked confirmed by a length-only control. Then a rustc probe said the opposite: plain `std::fs`
(`create_dir_all`, `write`, `read`, `rename`, `canonicalize`, `read_dir`) all succeed at **490**
characters with `LongPathsEnabled=0`, so there is no blanket wall. Bisecting the install path
found the real edge — **233 chars installs, 253 fails** — which is `MAX_PATH` after all, but only
in `write_atomic`: it goes through `tempfile`, which does not get std's extended-length handling,
and prefixes the temporary with `.{filename}.`, so the temporary crosses 260 before the final path
would. The error message naming *persisting a temporary file* was the clue that resolved it.

**Reusable:** `rg 'raw_os_error'` first — this file's `do_rename`, `should_retry_atomic_persist`
and `shims.rs` all already key on `ERROR_ACCESS_DENIED (5)` / `ERROR_SHARING_VIOLATION (32)`, so
new Windows error handling has vocabulary to match rather than invent.

**Two process notes from writing the test**, both caught by running Pester locally before pushing:

- `mise ls --installed | Should -Not -Match 'jq'` passes for the wrong reason on any machine with
  another `jq` version. Assert on the install directory with `Test-Path`.
- An `e2e-win` suite that installs a tool will use the **real** `MISE_DATA_DIR` when run locally —
  CI sets it job-wide, a laptop does not. Set the `MISE_*` dirs for the local invocation, not in
  the suite.

**Checked and clean, do not re-investigate:** writing a Windows path into TOML (literal string,
correct); CRLF in a shebang (`split_whitespace` eats the `\r`, and `task_script_parser` uses
`lines()`); `env::split_colon_list` (filenames, not paths); every `ListPath` setting has
`parse_env = "list_by_os_path_separator"`; `mise settings add` delegates to `set`.

**#11986 is the deferred case-sensitivity half.** `is_mise_binary` compared exactly, so `MISE.EXE`
was misread even after #11982 fixed the separator half. Measured: it does **not** error — it goes
through `handle_shim`, `which_shim` resolves the name, and `args[0] = bin` re-executes a *different*
binary, so the command appears to work:

```console
> mise.exe --trace --version    ARGS: ...\argv0\mise.exe --trace --version
> MISE.EXE --trace --version    ARGS: C:\...\WinGet\Links\mise.exe --trace --version
```

The fix ignores case on Windows only, matching `BackendArg::matches_bin_name`, which already had
that shape. On unix `MISE` is a different file and a shim by that name must stay a shim.

### Findings worth keeping

1. **A "Windows bug" is often not Windows-specific.** #11046's first half reproduced identically on
   Linux — `os error 2` there against `os error 3` on Windows, the same missing parent directory.
   Running the same steps in a container before putting "Windows:" in a PR title is cheap and was
   twice decisive.
2. **`path:` validation was POSIX-shaped throughout.** The denylist (`$`, backtick, quotes, `\`) is a
   POSIX shell's metacharacters; cmd's own (`& | < > ^ %`) were **all accepted**. Fixing the
   backslash complaint alone would have left that hole open. **`%` is the sharp one** — cmd expands
   `%NAME%` *even inside double quotes*, so correct quoting at the call site is not a defence.
   `(` and `)` are deliberately **not** rejected: `C:\Program Files (x86)` is far too common, and
   measured against `&` as a control they do not inject.
3. **`\` was fixed by rewriting it to `/`, not by dropping it from the list.** The list exists to keep
   `\` out of `ctx.rootPath`, which vfox hooks interpolate into shell commands; permitting it would
   have weakened the guard rather than fixed the platform mismatch. `\\?\` and `\\.\` stay rejected
   because they are the one place Win32 does *not* accept `/`.
4. **`Path::file_name` follows the host's path grammar, and that is correct.** `\` separates only on
   Windows; on unix it is an ordinary filename character. #11982's first push asserted the Windows
   behaviour unconditionally and `unit-macos` caught it. CodeRabbit's suggested fix — split on both
   separators always — would make a unix shim named `weird\name` resolve to `name`. The tests are now
   a **platform-split pair** so the choice is pinned in both directions rather than left implicit.
5. **Reproducing an `argv[0]` bug needs a launcher that passes it verbatim.** PowerShell's `&`
   rewrites the path to backslashes before spawning, so #11423 looks *fixed* from a PowerShell
   prompt. `cmd /c` passes it through, as does libuv. A "does not reproduce" from the wrong launcher
   is not a measurement.
6. **Pester does not carry `Describe`-scope functions into `It` blocks**, and it runs every suite in
   one process, so env vars must be saved and restored. On #11947 a helper defined in `Describe`
   looked cleaner than repeating the assertion and was *more* certain to break than the `-ForEach`
   it replaced.
7. **`e2e-win` convention: no `Remove-Item $TestRoot` in `AfterAll`.** `$TestRoot` lives under
   `$TestDrive` and Pester owns that; jdx's own `task_artifact_cache.Tests.ps1` is the reference
   shape. `Set-Location $script:OriginalDir` must stay — Pester cannot remove `TestDrive` while the
   process sits inside it. The same line was on `main` in three files from #11937, #11947 and
   #11948; **#11985 removed all three (merged 2026-08-14).**
8. **`clap`'s `conflicts_with` is not rendered into `mise.usage.kdl` or the generated docs**, unlike
   aliases, which are. A conflict therefore needs prose in the docs if users are to learn about it.
9. **#11981 is a deliberate behaviour change, not a regression fix.** Measured that 2026.8.2 already
   destroyed an unmanaged file on Windows, so the protection is *new*; anyone who relied on a
   `symlink` entry quietly replacing a file now needs `--force`. Saying so plainly in the PR body is
   what makes it the maintainer's decision rather than a footnote.
10. **`mise tasks --json` reports `display_name`, not `Task::name`** (`src/cli/tasks/ls.rs`:
    `"name": task.display_name`). `name_from_path` **keeps** the extension — a file task is called
    `build.sh` — and only `display_name` strips it. Reading the JSON and calling it the internal name
    is what broke #11992; see the entry below. **A field labelled `name` in output is not the field
    called `name` in the struct.**
11. **File tasks cannot branch on platform.** `run_windows` is a TOML-task key and a file-task header
    rejects it outright (`unknown field(s) ["run_windows"]`) — and that error fails the whole config
    load, taking unrelated TOML tasks with it. So two files, one per platform, is the only option
    available, which is why the sibling-preference mechanism exists at all.
12. **Windows has no shebang concept; mise implements it.** `CreateProcess` refuses a shebang script
    *and* a `.ps1` — measured, both give "not a valid application for this OS platform". On Windows
    `is_executable` is "known extension **or** shebang", where the extension half means "the OS can
    run it" and the shebang half means "mise can work out an interpreter". #7941 added the second.

### The #11992 flip-flop — read this before trusting a bot on task naming

Worth keeping as a process failure, not just a code note. Sequence:

1. I fixed the POSIX-sibling gap and keyed on `strip_task_extension(&task.name)` with a rename —
   correct, as it turns out.
2. CodeRabbit said discovery already produces stems, so the strip and rename were wrong.
3. **I "confirmed" that with `mise tasks --json`**, which reports `display_name`, and told CodeRabbit
   so. Applied its suggestion. That regressed two cases upstream had handled.
4. Greptile caught it, correctly, quoting `name_from_path`.
5. Reverted; probed three variants over eight fixtures built the way `name_from_path` builds names.

**The measurement was the failure, not the judgement.** A bot's premise was checked against the
wrong field and the wrong answer came back confirming it. When a review disputes what a value *is*,
read the code that produces it — not a command that formats it.

---

## Deliberately not posted — do not revisit

- **#5458** — investigated, draft written, **NOT posted** (user's call). Does not reproduce:
  **measured** on v2026.7.15 that `mise use pipx:kraken-wrapper` installs `krakenw`,
  `<install>/bin/` holds only `krakenw.exe`, `mise which krakenw` resolves, and the shim is created
  without a manual reshim. mise never derives the executable name — `pipx.rs` sets
  `UV_TOOL_BIN_DIR`/`PIPX_BIN_DIR` to `<install_path>/bin` and has no `list_bin_paths` override, so
  the default `runtime_path()/bin` exposes the dir wholesale, **and the same was true at v2025.6.5**,
  the release current when they posted. Their `uvx_args = "--from …"` attempt cannot work for a
  different reason: `pipx:krakenw` 404s at `pypi.org/pypi/krakenw/json` during version resolution,
  before uv runs, and `uv tool install` has no `--from` (only `uv tool run`). Real docs gap:
  `docs/dev-tools/backends/pipx.md` never says the executable name comes from entry points.
- **#5646** — investigated, answer drafted, **DO NOT POST** (user's call — already reported by
  someone else). If it ever needs posting: fixed by **#5822** (@syhol, body says `Fixes:` this
  discussion), first release **v2025.7.30**. Cause: `backend_arg.rs` consulted
  `install_state::get_plugin_type("pipx")` **before** checking for a built-in backend, so
  `pipx:commitizen` routed to a plugin backend. Also measured: @risu729's "uninstall the plugin"
  workaround is obsolete. @mnowotnik's leftover TLS complaint is separate — uv does not read
  `REQUESTS_CA_BUNDLE`; it has `--system-certs` (`UV_SYSTEM_CERTS`), forwardable via `uvx_args`.

## Open design questions — no clean answer, low value to reply

- **5454** (👍5) pyenv-virtualenv-style named central venvs. mise has no equivalent; syhol pointed at
  automatic virtualenv activation, which the reporter had already discounted.
- **5498** (👍3) `mise install --lazy`. jdx engaged at length: shim names are only known *after*
  install, unlike aqua — but softened to "might be feasible if mise-versions stored possible names",
  and risu729 supports it. A design thread, not a question.
- **5475** (👍3) OCaml OPAM backend, 0 comments. **5516** `mise install --tasks a,b`, 0 comments.
- `#5521`–`#5610` feature requests: 5528, 5541, 5544, 5554, **5575** (👍6, scoop backend).
- `#5611`–`#5700`: 5648 (task-docs header level).
- **#5588** left a possible follow-up: W1M0R notes the upstream duct.rs 1.1.0 fix may help beyond
  `mise x`.

## Checked and found sound — do not re-open

### Windows, third pass — 2026-08-15 (nothing found)

Five leads, all measured on 2026.8.2 windows-x64 in an isolated `MISE_*` env unless noted.

This round concluded "the cheap empirical surface is close to exhausted". **That was wrong**: the
two leads it parked as needing setup were done next and both were real defects (#12058). A round
that finds nothing says the probes missed, not that there is nothing there — the ones that need
setup are exactly the ones nobody has run before.

- **Environment variable casing.** Windows env names are case-insensitive, mise keys them
  case-sensitively. Put `Path_Probe` and `PATH_PROBE` in one `[env]`: `mise env` emits both
  assignments, and `mise exec`'s child sees the same value the emitted script would leave. Consistent,
  and writing one name twice in two casings is not a thing people do. Not worth a change.
- **`mise x -c` and cmd metacharacters.** `mise x -c "echo pre%CLOBBER%post"` prints `preGOTCHApost`;
  `&` and `^` behave as cmd's too. **Correct** — `-c` means "hand this line to the shell", exactly as
  `$VAR` and `&` behave under `sh -c`. Not a defect, do not "fix" the quoting.
- **`MISE_WATCH_FILES_MODIFIED` joins paths with `:`** (`src/watch_files.rs:83`), and every Windows
  path carries a drive colon. But `docs/hooks.md:156` states the format — colon-separated, colons
  escaped with a backslash — so `C:\a.txt` becomes `C\:\a.txt` and it is lossless. Unlike #12012,
  docs and implementation agree. Awkward to consume in cmd, not wrong.
- **Trusted-path matching and casing.** Set `MISE_TRUSTED_CONFIG_PATHS` to the fully upper-cased form
  of the same directory: still trusted. Case-insensitive, as it must be. (Note `Set-Location` cannot
  be used to test this — PowerShell normalises the cwd back to the real casing, so that probe proves
  nothing.)
- **`file::remove_all` on a read-only file.** It delegates straight to `fs::remove_dir_all`
  (`src/file.rs:72`), and archive members often carry the read-only attribute. Probed with rustc
  1.95: a tree containing a read-only file is removed cleanly. Modern std clears the attribute
  itself; mise needs no guard.

**Two of the leads this round parked as "needs setup" were then done, and both were real** — see
"Windows, fourth pass" below.

### Windows, fifth pass — 2026-08-15 (nothing found)

Mapped drives and filename casing, all measured on 2026.8.2 windows-x64. **`subst` is the cheap way
to test drive-letter behaviour** — no admin, no share, `subst Q: <dir>` and `subst Q: /D`. (Quoting
the drive as `"Q:"` trips this environment's path-safety guard; write it bare, and do not put a
`Remove-Item` in the same command.)

- **Config discovery stops at a mapped drive's root.** From `Q:\proj` where `Q:\` is `subst`ed to a
  real directory, a config placed *above* the mapped root — reachable through `C:\` but not through
  `Q:\` — is **not** loaded. The control is the same config being loaded when the same directory is
  entered by its real path. `mise config` also reports `Q:\proj\mise.toml`, keeping the mapped
  spelling rather than the resolved one.
- **Trust survives the mapping.** `mise trust` from `Q:\proj` records the resolved real path, and
  the config then loads from *both* spellings. Canonicalising is the right call here.
- **A task `dir` on another drive works.** cmd's `cd` cannot change drive without `/d`, so this
  looked like a trap; it is not one. mise sets the child's working directory through the process
  API, which changes drive and directory together — verified through both the default `cmd /c`
  shell and pwsh, both landing in `Q:\other`.
- **Config filenames are found whatever the casing.** `mise.toml`, `Mise.toml`, `MISE.TOML` and
  `.Mise.toml` all load. Windows treats them as one name and so does mise.

**Still not examined:** a true UNC path (`subst` covers the drive-letter half but not
`\\server\share`, and standing up a share needs administrator); reserved device names (`con`, `nul`,
`aux`) — Windows refuses to create a file so named, so there is likely nothing for mise to get
wrong; dotfiles symlinks as a non-administrator with Developer Mode off, which is #11978's territory
and already has a tested fallback. **`mise self-update` replacing a running mise.exe has since been
measured and is fine** — it was on this list as "not testable here", which was wrong; see the sixth
pass.

**C1: `local_toml_config_path()`'s cached `dirs::CWD` vs the live cwd under `-C/--cd`.** The lead was
`trust.rs:225-229`, which deliberately uses `env::current_dir()` and warns that "a `cd` setting
applied during settings load can move the process directory, and both passes must agree." Real
concern, but **it does not happen** — measured on v2026.7.18, `mise -C B` from `A`:

- `mise -C B set FOO=bar` → `B/mise.toml`, and `mise -C B settings set --local jobs 2` → `B/mise.toml`
  too. `settings set --local` is the one that goes through `local_toml_config_path()` → `dirs::CWD`.
- `{{cwd}}` in an `[env]` directive (`env_directive/mod.rs:475`, which inserts `dirs::CWD` verbatim)
  renders as `B`, i.e. `dirs::CWD` *is* the post-`cd` directory.
- Still `B` with `MISE_ENV_FILE=.env` set, which is the one path that reads `dirs::CWD` from inside
  `Settings` (`settings.rs:893`); the `.env` picked up was `B`'s.

Why it cannot diverge today: `Settings::try_get`'s **first** pass builds from CLI settings + env only
(`settings.rs:481-488`) and does not touch `all_settings_files()` or `env_files()`, so nothing forces
the `Lazy` before `env::set_current_dir` at `:495`. Every first touch of `dirs::CWD` therefore
happens after the `cd`. `MISE_ORIGINAL_CWD` is consistent for the same reason. Re-opening this needs
a caller that reads `dirs::CWD` during the first settings pass; none exists.

### Windows, sixth pass — 2026-08-16 → #12062

Opened up by moving this machine off its winget-managed mise onto a self-managed install: once mise
owns its own binary, `self-update` is testable. Every check below runs against a **copy** of
`mise.exe` in an isolated `MISE_*` environment, so the real install is never at risk. Five checks,
one finding.

| check | result |
|---|---|
| a second process running the same `mise.exe` throughout the update | fine — exit 0, the holding process survives, no `.old`/`.bak` left behind |
| `TEMP` longer than 201 characters | **destroys the install — #12062** |
| install directory with write denied (`icacls /deny`) | `mise.exe` survives, because the relocation fails before it can move anything. Exit 1 with a bare `os error 5` and no explanation |
| path with spaces, Japanese, `&` and parentheses (136 chars) | fine — exit 0 |
| `self-update <version>` downgrade and back | fine — 2026.8.6 → 8.5 → 8.6, each step confirmed by hash. This is also what proves the swap really rewrites the file |

**The finding.** `self-replace` renames the running exe out of its install directory *first*, then
launches a helper it drops in `TEMP` to finish the swap. Past a `TEMP` of 201 characters that
helper's path exceeds MAX_PATH, `CreateProcess` cannot start it, and nothing undoes the rename: the
install directory is left empty and the binary is stranded in `TEMP` under a generated name.
Measured 31 / 190 / 201 fine and 202 / 205 / 243 destructive — 202 is exactly where
`len(TEMP) + 1 + 57 >= 260`, the 57 being the fixed length of `.mise.<32 random>.__selfdelete__.exe`.

**Two traps this pass.**

- **A `>MAX_PATH` mise.exe cannot be launched at all** — plain path gives `ERROR_FILE_NOT_FOUND`,
  `\\?\`-prefixed gives `ERROR_FILENAME_EXCED_RANGE` — even though `.NET File::Copy` puts it there
  happily. So "self-update from a very long install path" is unreachable, not a bug; the reachable
  variant is the long `TEMP`. **Control:** the identical copy at 137 characters runs.
- **A near-miss that was dropped.** At `TEMP`=201 the run also printed `… is not a valid shim` and
  left the helper behind, which looked like a second finding. The **default** `TEMP` holds the same
  leftovers, so there is no control for "201 is special" and it was left out of the PR rather than
  asserted.

**Reusable:** an e2e test that runs `self-update` must ask for a **version that does not exist**.
Without the guard the run then dies at the release lookup (404) long before anything replaces the
binary, so a regression cannot destroy the runner's mise. Confirmed by running the new suite against
a release build with no guard: the failure is the 404 and `mise.exe` is untouched.

### Windows, seventh pass — 2026-08-16 → #12064

**The lead:** the sixth pass only proved that a long `TEMP` destroys `self-update`. It said nothing
about the rest of mise, and #12062's guard covers exactly one command. So: does a long `TEMP` break
anything else?

**Mostly no.** With `TEMP` at 250 characters, `install`, `reshim`, `doctor --json`, `cache clear`,
`ls` and `upgrade --dry-run` all exit 0. **`mise lock` is the only other path that touches `TEMP`**,
and code-reading over-promised here: `aqua.rs` was the one production caller of
`tempfile::tempdir()`, `file.rs`'s `write_atomic` uses `tempfile_in(parent)` (next to the
destination, not `TEMP`), `cache/rustc.rs` uses a root from an env var, and `file.rs`'s other
`TempDir::new` is macOS-only `un_dmg`.

**The finding.** `mise lock` verifies provenance for the current platform by downloading the release
artifact into `tempfile::tempdir()`. Once `<TEMP>\.tmpXXXXXX\<artifact filename>` reaches MAX_PATH
the download fails, and lock **exits 0** while silently omitting the `provenance` line for the
current platform. The generated lockfile — a committed artifact — therefore depended on how deep the
machine's `TEMP` was. Predicted from the arithmetic and then measured with jq 1.8.2
(`jq-windows-amd64.exe`, so the path is `TEMP + 32`): 210 records provenance, 230 does not.

**Severity was measured, not assumed, and it is low.** With no `provenance` in the lockfile
`has_lockfile_integrity` is false, so install takes the *real* verification branch rather than
trusting the lockfile: installing from the degraded lockfile logs `verify GitHub artifact
attestations` → `GitHub attestations verified`, and the missing line is restored. No verification
gap — the defect was non-determinism in a committed file.

**The design question, and why the first proposal was wrong.** The initial suggestion was "stop using
`TEMP`", which the user pushed back on: downloading to `TEMP` is the conventional thing, and a tool
that never uses `TEMP` makes `TEMP` pointless. That is a fair objection and the first framing did not
earn its conclusion. What actually settles it is narrower:

- Every tool manager on this box uses a **tool-owned** directory, not `TEMP` — cargo, npm, uv, pip,
  bun, winget each have their own cache, and **rustup keeps `~/.rustup/downloads`, which is empty
  between runs**. That last one is the answer to "then what is `TEMP` for": rustup wants the
  transient-scratch role *and* owns the directory.
- **mise was already inconsistent with itself.** Install downloads the same artifact to
  `MISE_DOWNLOADS_DIR` via `tv.download_path()`; only the lock-time copy went to `TEMP`.
- The lock-time download is **thrown away** — measured: after `mise lock` alone, the data dir holds
  one 0-byte file and the cache only API metadata, so install re-downloads it.

So #12064 is "match what install already does", not "`TEMP` is wrong". Reuse of the downloaded
artifact would be a real improvement and was deliberately left out.

**The review round is the part worth re-reading.** Greptile raised a P1: `MISE_DOWNLOADS_DIR` is
configurable, so a deep enough one reproduces the same failure. The answer is that install fails
first — but **the first reply gave the wrong reason, and it was posted before being checked**. It
claimed install wins because `DOWNLOADS/<short>/<version>/<filename>` is longer than the scratch. It
is *shorter*: `DOWNLOADS + 30` against `DOWNLOADS + 32`. The filename was also miscounted as 22
characters; it is 20, which had already gone into the PR body.

The real mechanism is a sidecar. [`PartialDownload::new`](src/http.rs:236) writes
`.{filename}.mise-part` and `.{filename}.mise-part.json` beside the artifact, and the `.json` one is
the longest path in the download step. Predicted `DOWNLOADS + 46`, then measured: 213 installs, 214
fails. Generalised, with `S` the short name, `V` the version and `F` the artifact filename:

- install's longest path is `DOWNLOADS + S + V + F + 19`
- the lock scratch is `DOWNLOADS + F + 12`

`F` cancels, so install always exceeds MAX_PATH first by `S + V + 7` — **structural for every tool**,
not a coincidence of jq. That is a better answer than the one first given, and it only appeared
because the wrong one was checked.

**Two process lessons from this pass.**

1. **A plausible path model is not a measurement.** The "install's path is longer" claim was arrived
   at by reading `downloads_path` and reasoning, and it was published in a review reply. One `ls` of
   the downloads directory would have contradicted it before posting. The standing rule — never
   present unrun commands as observed output — extends to *derived* claims: if a number can be
   measured, measure it before asserting it to anyone.
2. **Do not clean up with a glob.** `t4*` matched `t4801`, `t4801b`–`t4801f` from earlier sessions
   and deleted six directories that were never inspected. Delete by the exact names that were
   created.

**Also produced this pass:** a full issue draft for `mitsuhiko/self-replace` (not posted; the user is
continuing it elsewhere) covering the missing rollback in `self_replace`, with a 20-line standalone
reproduction that does not involve mise. The reproduction crate was deleted afterwards on request —
**do not leave build artifacts in the scratchpad; the draft carries the program's full text.**

## Landmines — do not re-propose these

Candidates that look attractive on a fresh read and are **not** work. Each cost real time to
disprove.

1. **Do NOT "fix" `--path` by swapping `all_dirs()` for `all_dirs_from(p)`.** `Path::ancestors()` on
   a relative path ends at the **empty path**, and `config::glob` resolves `"".join("mise.toml")`
   against the process cwd — so `--path ../other` would still land on the cwd's config, `sub/../other`
   would scan `sub/`, and `..` never reaches the real grandparent. Any upward-walk design needs `p`
   absolutized first, and even then `unuse --path ./sub` can still delete from the repo root. What
   shipped in #11575 instead: `config_file_in_dir(dir)` looks **only inside `dir`**, which is also
   what the docs already promised (`use.rs:79-82` "look for a config file **in that directory**").
2. **A PATH-precedence probe that skips `mise activate` measures nothing.** Cost two wrong
   conclusions on 2026-08-09, one of which I nearly reported as a defect in `activate_aggressive`.
   `hook_env.rs:291` reads
   `match &*env::__MISE_ORIG_PATH { Some(orig) if !Settings::get().activate_aggressive => … , _ => (vec![], current_paths, vec![]) }`
   — **`__MISE_ORIG_PATH` is set by the activation script**, so calling `mise hook-env` directly
   leaves it `None` and the non-aggressive branch is unreachable *whatever the setting says*. Both my
   probes did that and produced "mise always wins", identical for `true` and `false`, which looked
   exactly like a broken setting. Second trap in the same area: `mise activate` **already applies one
   hook-env**, and a following hook with no directory change hits `should_exit_early` and does
   nothing — so "prepend then hook" measures the activation, not the setting. Always
   `eval "$(mise activate bash)"`, and force a real re-evaluation with a `cd` or `--force`.
   **`activate_aggressive` itself is sound** — measured to behave exactly as its docs describe once
   the probe is valid.
3. **Do NOT extend `file::decode_text` to other backends' checksum reads.** reqwest's `text()` →
   `text_with_charset("utf-8")` → `encoding_rs::Encoding::decode`, whose first act is
   `Encoding::for_bom(bytes)`: a BOM overrides the declared encoding and is stripped
   (`encoding_rs-0.8.35/src/lib.rs:3009`). Every `get_text`/`get_text_cached` path already decodes
   UTF-16. Only reads from **disk** need help, because `std::fs::read_to_string` is UTF-8-only.
   #11552 got this wrong for its HTTP third; #11558 corrected it, and
   `file::read_to_string_bom`'s doc comment now records the asymmetry in-tree.
4. **Do NOT change zsh's completion guard to `type -P`.** `-p`/`-P` do not mean the same thing
   across shells. Measured in zsh 5.9: `type -P` is `bad option: -P` and **always** exits 1, so
   `if ! type -P usage &> /dev/null` (error swallowed) would print "usage CLI not found" for every
   user who *has* the CLI. zsh's `-p` already forces a `$PATH` search ignoring functions/aliases —
   the inverse of bash's. jdx/usage#760 excluded zsh **deliberately**, and the change was tried and
   reverted upstream in two days: `f65a7b465` (2025-07-16) → `dfdc67b94` (2025-07-18). mise's
   `completions/_mise` is correct as-is.
5. **The "Windows-only" framing was wrong twice over — read this before re-investigating.**
   On 2026-08-01 I reported a Windows-only bug, then retracted it, and *both* were wrong. What is
   actually true: an **empty** `MISE_CONFIG_DIR` (`export MISE_CONFIG_DIR=`) makes `dirs::CONFIG`
   the empty path, so `global_config_files()` is empty, `~/.config/mise/config.toml` stops being
   recognised as global, and `mise use` writes into it. **Measured on Linux and Windows alike** on
   v2026.7.18. It is **already fixed on main** — not by #11571 but by **#11508**, which added
   `.filter(|p| !p.as_os_str().is_empty())` to `env::var_path` and landed just after the v2026.7.18
   tag was cut. A released-versions-only defect with a fix already queued; nothing to report.
   **Two measurement lessons, both of which cost hours:**
   - `[Environment]::SetEnvironmentVariable('X', $null)` in PowerShell **creates `X=` (defined,
     empty) in the child environment block** when `X` was never set. `cmd /c echo %X%` still
     reports it undefined — only `cmd /c set` shows it. That is what silently switched the variable
     under test. Diff the child env (`Compare-Object (cmd /c set) …`) before trusting an A/B.
   - Env vars do **not** persist across PowerShell tool calls (verified), but they do persist
     across every `&` invocation *within* one call. One scenario per call.
6. **Do NOT try to make the asdf backend work on Windows.** Deliberately unsupported, not
   unfinished: `src/main.rs` swaps in `fake_asdf_windows.rs` whose `setup()` is a no-op stub;
   `ScriptManager::run_by_line` spawns the plugin script directly and Windows `CreateProcess`
   rejects a shebang-only file (os error 193, measured); `docs/.../asdf.md` marks asdf
   `Windows Support ❌` and steers users to vfox. asdf is legacy — new asdf/vfox plugins are no
   longer accepted into the registry.

---

## Process notes

- **Build and lint on CI, not on this box — set by the user 2026-08-11.** *"出来る限りCIでビルドとか
  clippyのチェックをお願い致します… forkして一旦、pushして確認することは可能なはずです"*. A local
  `cargo clippy --all-targets` ran 12 minutes and `cargo build --bin mise` 16; pushing the fork branch
  and reading CI costs nothing of the user's machine. Keep `cargo fmt --all` local — it never builds
  dependencies and finishes in seconds. Reach for a local build only when the question genuinely
  needs a binary in hand (an end-to-end behaviour measurement), and say so.
- **PowerShell eats `?` into a variable name, so `"…/$f?ref=main"` silently becomes `"…/=main"`.**
  `?` is a legal character in a PowerShell identifier, so the interpolation reads `$f?ref` — an
  undefined variable — and expands it to nothing. On 2026-08-14 that turned three `gh api contents`
  probes into 404s, and the 404s became the claim "none of these files is on `main`", which went
  into this file **and into a posted PR comment**. All three were on main. **Escape it (`$f` + a
  backtick before `?`) or build the URL separately — and run a control**: the same query against a
  file known to be on main returned a 404 too, which would have exposed it in one step. Same class
  as the `head -5` truncation on #5876: a broken measurement is not a negative result.
- **Prove the binary is fresh before you believe a behaviour measurement.** On 2026-08-11 I reported
  that #11883's warning "does not fire" — from a binary built on a different branch hours earlier. I
  had checked that `target/debug/mise.exe` *existed*, which is not the same as it being current. The
  fix is a control that fails when the binary is stale: run something only the new code can produce
  — here `mise tasks validate --help | grep 'Task Includes'` — and only then measure. Same class as
  every other "a check that cannot fail is not a check" entry in this file.
- **A `#[cfg(unix)]` test module is not compiled on Windows, so tests placed there are unverified —
  not merely unrun.** Both #11883 and #11885 first put new tests inside the file's existing
  unix-gated module; a type error would have surfaced only in CI. Both fixes are the same: if the
  code under test is platform-independent, give it **its own non-gated module**, and put it at the
  **end of the file** — clippy's `items_after_test_module` fires on a test module with items after
  it, which is what happens if you drop one next to the function it tests.
- **A new diagnostic can break tests that fold stderr into a value.** #11883's warning broke
  `test_task_edit_nested_names`, which did `TASK_PATH5=$(mise tasks edit … --path 2>&1)` and compared
  the result to a path. Before adding any warning, grep the e2e suite for `2>&1` captures in the area
  you are about to make noisier — and check whether the case that triggers it is a pattern someone
  relies on, rather than quietly editing the test.
- **Search your own past comments before answering a thread in a familiar area.** #5173 (zig) was
  drafted without noticing that I had diagnosed and fixed the neighbouring #10251 — the very code
  the reply describes carries `(#10251)` in its comments. The user remembered; the sweep did not.
  `search(query:"repo:jdx/mise <topic>", type:DISCUSSION)` filtered on my login across
  `comments.nodes.replies` finds them in one call, and citing the earlier thread makes the new reply
  land better. Do this whenever the subject is one this queue has touched before.
- **Measure with a released binary when one is on the box, not the local debug build.** The #5173
  numbers were first taken on `2026.8.4-DEBUG` built from a feature branch. The system had mise
  **2026.8.2** installed; re-running everything there removed the caveat entirely and let the reply
  name a release the reporter can install. Only fall back to a local build for behaviour that has
  not shipped, and say so in the body when you do.
- **An A/B in one environment beats a code citation.** #4898's whole answer is that `uvx = false` in
  a *registry entry* vetoes the `pipx.uvx` setting. Reading `pipx.rs:312` proves the `&&`; running
  `ansible` and `ansible-core` back to back with neither uv nor pipx installed proves the veto is
  per package, because the two produce different branches of the same error. The second costs one
  extra command and is what makes the reply unarguable.
- **When you disagree with a maintainer's diagnosis, lead with *their* CI, not yours.** #11865 was
  first contradicted with a local Docker reproduction (their patch applied on main, `landlock_*`
  syscalls blocked by a seccomp profile → still exit 1). That is a *model* of the runner and carries
  a caveat. Then their own PR's e2e log turned out to show the fixture still failing on their own
  head commit, both retry attempts. **Check whether the claim is already disproved by evidence the
  other person owns before building an apparatus to disprove it.**
- **A PR body outlives its diff.** #11846's body kept describing a sort key that had been deleted
  three revisions earlier, complete with a table of resolutions measured under it. Same class of
  error as presenting an unrun command as output: the reader cannot tell. **Re-read the body after
  every design change**, and when a table was measured under code that no longer exists, either
  re-measure or delete it. Re-measuring is usually cheap — here it needed one `cargo build` and two
  `ls-remote` runs, and it also produced the control that proved a separate fix worked.
- **A red `e2e` is not evidence until the failing test names are read.** Through 2026-08-10..11
  GitHub's API rate limit was flapping (core 0/5000 at 03:23) and every e2e failure examined was a
  network-tool test. #11861 went from 19 failures to fully green on a re-run with **no code change**.
  Conversely #11853's e2e is red **by design** — it is the PR that stops failures being swallowed.
- **Fork PRs get no pool token, so every job shares one installation token — measured 2026-08-14.**
  `.github/actions/fetch-token` needs a repository secret, and a `pull_request` from a fork gets
  none: the e2e log says `No API secret provided, skipping token fetch` **16 times**, once per
  tranche. All eight tranches then compete for `secrets.GITHUB_TOKEN`, whose 5000/hr is shared across
  the whole repository. The error names it: `API rate limit exceeded **for installation**`.
  - **Do not judge by the failing step name.** On 2026-08-14 `windows-e2e` failed at
    `Run ./.github/actions/mise-tools` and `e2e` failed at `Test tranches 0-7`, and I called them
    different problems. The e2e log carried **572** `API rate limit exceeded` lines. Same cause,
    different moment of exhaustion. Grep the log for the message before concluding anything.
  - The guard in `mise-tools` checks once, at step start, with a threshold of `remaining <= 1`. It
    read `4808/5000` and proceeded; the tranches drained it minutes later. A check-then-use against a
    bucket other jobs are draining cannot work — expect it to pass and the job to fail anyway.
  - **Pushing all the failing PRs at once re-creates the exhaustion.** Six force-pushes on 2026-08-14
    put ~48 tranches onto one token and they died together. Space them out, or wait for the
    maintainer to re-run (an in-repo run *does* get the pool).
  - `gh run rerun` is not available to this account (`Must have admin rights to Repository`). The only
    lever is a push that changes the SHA: `sl amend --date now` does that with no content change —
    **verify with `sl diff -r old -r new --stat` that it really is empty before pushing.**
- **`cargo clippy --all-features` cannot run on this box** (`openssl-sys` build fails), but
  `cargo clippy --all-targets` can. Beware the difference from CI, which runs both: a local clippy
  newer than CI's reports lints CI does not (2026-08-11: `collapsible_match` in `backend/cargo.rs`
  and `large_enum_variant` in `cli/bootstrap.rs`, neither in the touched file). **Check the reported
  file before assuming a finding is yours.** And `cargo fmt --all` is still the cheap gate — the one
  lint failure that *was* mine on #11846 was a long `warn!` line rustfmt wanted wrapped.
- **A negative conclusion needs a control that has nothing to do with mise.** Three times on
  2026-08-09..10 an "X does not work" claim was wrong, and every one would have been caught by one
  extra command:
  - **`mise settings get libc` reported "not set" while the setting was in effect** — reported to
    the user as a bug, and it was not. The measurement ran mise inside `$( )` under WSL, where the
    exported `MISE_*` variables and the `cd` never arrived. `$(printenv MISE_LIBC)` returning empty
    while the direct call returned `gnu` is the control that settles it, and it involves no mise.
  - **"`update_submodules` is never called for the aqua registry, so add the call"** — the premise
    was that mise git-clones the registry. It does not: `src/aqua/` contains no git at all and
    fetches a single `registry.yaml` over HTTP. Reading the *consumer* before calling something
    unimplemented would have shown it.
  - **"#4678 cannot be verified on Windows"** — WSL was right there and had been used for other
    checks the same day.

  Rule: before writing "does not / is not / never", produce a control that would fail if the
  *measurement apparatus* were broken.
- **Reproduce the reporter's exact invocation, not a convenient equivalent.** #4789 was declared
  fixed on the strength of `mise hook-env --silent` suppressing the warning. The reporter had run
  `mise activate --silent`, and that still fails: `activate` embeds only `--quiet` and `--status`
  into the generated hook, so the flag applied to one process and was gone. The two commands look
  interchangeable and are not. A near-miss like this is worse than no measurement, because it
  produces a confident wrong answer — and this one nearly went out as a reply.
- **"The reporter resolved it themselves" and "it's the maintainer's own RFC" are not reasons to
  skip measuring.** #4243 and #3878 sat in the do-not-reply list on exactly those grounds. Both had
  a concrete, measurable answer (`-o nospace` in the generated completion; `enable_tools = []`
  already being `--no-tools`). Cheap to check, and the check is what turned them into replies.
- **`gh` expands `{...}` in `-f`/`-F` values.** A comment body containing a TOML inline table —
  `{ version = "4.4-stable", exe = "Godot" }` — made `gh api graphql -F body=…` fail with
  *"failed to run git: fatal: not a git repository"*, because gh tried to resolve it as a
  placeholder. Nothing about the body is invalid. **Post through a JSON payload instead**: build
  `{query, variables}` with `ConvertTo-Json` and pass `--input`. All discussion comments now go out
  that way.
- **An empty `-f` value posts nothing and `gh` still exits 0-ish — check the returned URL.** On
  2026-08-17 two review replies were sent as `-f b=(Get-Content …)`; PowerShell did not expand the
  subexpression inside the bare `b=…` argument, so the mutation went out with an empty body. GitHub
  answered `{"data":{"addPullRequestReviewThreadReply":{"comment":null}}}` — **no comment was
  created**, which is the only reason this was harmless. **Bind the body to a variable first**, print
  its length, and read back the thread afterwards: `comment.url` in the response, or a follow-up
  query listing each thread's comments with `len=\(.body|length)`. Same class as the `?`-in-`$f`
  bug — the command looked like it ran.
- **A `gh pr create` permission error can be about draft-vs-ready, not permissions.** Three attempts
  at a ready-for-review PR returned *"does not have the correct permissions to execute
  CreatePullRequest"* (and 404 over REST) with auth healthy, `repo` scope present, rate limits
  untouched, and two PRs created minutes earlier. The same command with `--draft` succeeded
  immediately. Cause unproven — secondary rate limiting is the likely explanation — but the
  practical move is to try draft before concluding anything is broken.
- **WSL through this harness mangles `$VAR` and `$( )`.** `for t in a b; do echo "$t"; done` prints
  blanks, and a command substitution does not see variables exported earlier on the same line. It is
  not bash behaving oddly — it is the layer in between. **Write the script to a file and run
  `wsl.exe -d <distro> -- bash /mnt/c/...`**, which passes nothing through the command line. Note
  Git Bash rewrites `/mnt/c/...` into a Windows path, so invoke that from PowerShell, not Bash.
- **The caveat has to be in the comment, not just in the chat.** The #4304 reply went out with a
  `$ mise generate …` block showing output from a merged-but-unreleased build that had never been
  run. The user was told that in chat before approving; the reporter could not know. Fixed by
  rewriting the comment. Either put "this is what the change produces, pinned by tests, not a
  release I ran" **in the body**, or do not use a `$`-prefixed console block for it.
- **CI is the render engine when `mise run render` cannot run locally.** Adding a CLI argument
  changes `mise.usage.kdl`, `docs/cli/**` and `man/man1/mise.1`, and this box cannot build mise
  (`libz-ng-sys` wants `cmake`). Guessing the generated text fails on a byte. What works: push the
  `src/` change alone, let `lint` fail its *"assert render produces no diff"* step, pull `git diff
  HEAD` out of the job log, reconstruct the patch (strip the timestamp prefix), `patch -p1`, amend.
  One extra round trip and it lands exactly. Verify with `patch --dry-run` first.
- **`isAnswered=false` is not "nobody replied."** It is only the *marked-answer* flag, and mise's
  threads are rarely marked. Batch metadata queries are good for spotting *movement*, not for
  deciding a thread is unanswered.
- **Placement rule, set by the user 2026-08-11: when a specific comment asks a question, reply to
  that comment.** *"可視性は気にしなくて良いです。それよりも投稿者へどれだけ有益な情報を届けられるかです"* —
  usefulness to the person waiting outranks visibility to future readers. This **narrows** the note
  below: visibility is the tie-breaker only when no single comment owns the question (#2435's two
  unanswered people in different places is still a top-level case). #4581 went as a reply under
  @gbloquel's *"I just need to know if this is a bug and what solution you propose!"*, opened by
  quoting that line.
- **A threaded reply CAN be marked as the answer.** I claimed the opposite on 2026-08-09 while
  choosing where to post the #3428 reply; the user said they had had a threaded comment accepted, and
  the measurement backed them: of 50 answered jdx/mise discussions
  (`search(query:"repo:jdx/mise is:answered", type:DISCUSSION)` reading `answer { replyTo { id } }`),
  **two have a threaded reply as the accepted answer** — #11259 and #11168. So markability is not a
  reason to prefer top-level; **visibility is** (replies collapse behind "N replies"). #3428 went
  top-level on that ground alone, because its whole problem was an answer nobody saw for ten months.
- **NEVER write a node ID you did not fetch, and verify where a post landed.** The worst mistake of
  2026-08-09: I had queried #2435/#2441 for their *structure* but not their `id`, then supplied
  invented IDs (`D_kwDOIvux3s4AbUXR`, `D_kwDOIvux3s4Ab3rF`) to `addDiscussionComment`. One failed;
  **the other posted a full technical reply onto an unrelated spam discussion in another
  repository** (a piracy-spam thread, `TITTENOLDEST/STEPHENSZ` #2 — a discussion that had evidently
  been transferred out of jdx/mise, which is why a jdx/mise-shaped ID resolved at all). Deleted via
  `deleteDiscussionComment` after resolving it with
  `node(id:"…"){ ... on Discussion { comments { nodes { id author{login} } } } }`, and confirmed
  `totalCount: 0`; it was the only comment on that thread.

  Two rules from it. **(1)** An ID is data to be fetched, never composed — the "never present unrun
  commands as observed output" rule applies to identifiers, not just console blocks. **(2)** Make
  every posting mutation return its destination and check it:

  ```graphql
  comment { url discussion { number repository { nameWithOwner } } }
  ```

  That is what caught it immediately on the retry (`landed on jdx/mise #2435`). Requesting only
  `url` is how it went unnoticed the first time.
- **Confirm a post did not land before retrying it.** The first `addDiscussionComment` for #815
  returned an empty URL: `-f discussionId=$d.id` does not expand a property in PowerShell, so the
  variable went out as a literal. Before re-running, query the thread's last comments and check the
  author/timestamp. A retry that assumes failure is how a thread gets two identical replies. Use
  `"$($d.id)"` — or bind the id to its own variable first.
- **Read every existing comment in full before drafting, and be willing to conclude "not worth
  posting".** Set by the user 2026-08-09: *"posting something similar to what others already wrote
  is pointless — I only want to post things that mean something."* Applied to the nine remaining
  `#413`–`#3499` candidates, **6 of 9 were dropped**: two were redundant with what the thread
  already said (#68, #607), one was too thin (#862), and two would have been half-answers to people
  still waiting (#2435, #2441). A verified fact is not automatically a comment worth making. The
  test is: **does this thread lack this answer today?**
- **A pre-measurement read is not an answer.** #2338 was written up as "wrapper still needed" from
  reading `--help`; installing watchexec and running it showed the opposite, and the posted reply
  says the wrapper *can* go. Two other near-misses the same day: the #1764 draft claimed
  `--hook commit-msg` delivers what the reporter wanted (it drops git's arguments), and the #2107
  draft asserted `PYTHON_CONFIGURE_OPTS` still works (it is inert unless `python.compile = true`).
  **Prove passthrough with a deliberately invalid value** — `PYTHON_CONFIGURE_OPTS="--bogus-flag-xyz"`
  produced `configure: error: unrecognized option`, which is proof rather than inference.
- **Check for a resolution comment before investigating — and re-check right before you invest, not
  just before you reply.** #5357, #5655 and a 108-thread sweep were all @Marukome0743 answering
  independently while threads sat in this queue. On 2026-08-09 it went further: **#1407 was answered
  hours after I finished a full investigation of it the same day**, with a better answer (real
  Miniconda on macOS + zsh 5.9, which was the gap I could not test). That person is sweeping this
  exact region *now*, so for anything below `#5260` the check has to be immediately before starting
  work, not at draft time.
- **A fix that closes a discussion usually does not say so.** In `#5701`–`#5790`, three of four live
  threads were already fixed and **not one fixing PR referenced its discussion**: #6852 was a
  *refactor*, #6168 was *PowerShell v5 support*, #10165 was *miserc discovery*. Searching PR titles
  or `<number> in:body` finds none of them. What works: reproduce on an old release binary, then
  **bisect the published binaries** — `https://github.com/jdx/mise/releases/download/v<ver>/mise-v<ver>-linux-x64`
  runs standalone from `/tmp`, so a five-version sweep costs a minute — or **bisect the source**
  (`gh api repos/jdx/mise/contents/<path>?ref=<tag> -H "Accept: application/vnd.github.raw"`) on the
  presence of a symbol. Then read `compare/vA...vB` and match against the symptom. For "has this
  merge shipped", `compare/<sha>...<tag>`: `ahead` = included, `behind` = not.
- **Verify the "obvious" candidate before naming it.** #5723's fix looked like #7286 from its title
  alone. It was not — the repro already passed on a release predating it.
- **Re-check every citation at draft time.** `main` moves fast; two line refs in this file went
  stale within days (`which_no_shims` `:1094`→`:1144`, venv `--python` arms `:57-66`→`:67-74`).
- **Never let a truncated search become a claim — `head` is not a summary.** The first #5876 reply
  said `pre_install.rs`'s panic was already gone. It was not. The grep behind that sentence had
  `head -5` on it, and the five lines it kept happened to be the converted hooks; the four panics
  sorted below the cut. **The sentence was posted before the truncation was noticed**, and only came
  out when tag-by-tag source fetches contradicted it. Re-run without the limit gave 4 panic / 5
  error, and the comment was corrected in place. **A `head`/`-m`/`Select-Object -First` on a search
  whose result you are about to assert is a bug in the measurement.** Count first, then narrow —
  and if the output was cut, the only honest report is "at least N".
- **Re-run the *analysis*, not just the citations, when a held reply comes off hold.** Both replies
  released on 2026-08-08 corrected notes in this very file. #5664 named the wrong environment
  variable (`XDG_DATA_HOME`; the reporter's own `mise doctor` says `cache: mise`), because I wrote
  the row from my reproduction instead of from their paste. #5570 blamed ordering, and the A/B
  showed the dependency installs first and the dependent **still** fails — ordering was never the
  missing piece. A row written weeks earlier is a lead, not a finding: **re-measure before it
  becomes a public claim.**
- **Attribute a fix to the PR that actually contains it, not the one you found first.** The #5362
  and #5365 replies credited #8402 with both halves of the uv-shim recursion fix. Reading the #8402
  diff shows it only adds `which_no_shims` and the `Ok(false)` arm; the `--python <abs path>` half
  is #7905, one release train earlier. **Read the PR's own diff before naming what it changed** —
  the PR body describing a mechanism is not proof it introduced the code that handles it.
- **Search for an existing PR before planning any implementation.** #5686 was reproduced, diagnosed,
  and fully planned before I noticed #11572 had covered it hours earlier. The reliable query is by
  **discussion number in the PR body** — `repo:jdx/mise 5686 in:body` — because the PR title shares
  no words with the discussion title. Do this *first*, not after the repro succeeds; a successful
  repro is exactly the moment the check feels unnecessary.
- **Never write an assertion for output you have not seen.** #11575's e2e failed on
  `assert "cat ../to/mise.toml" "[tools]"` — `mise unuse` removing the *only* tool empties the file
  (measured: 1 byte), and `e2e/cli/test_use:52` already encoded that. The verification run before
  that PR only checked `-match 'uv'`, never the exact contents, so the guess went unnoticed. Same
  failure mode as the `MISE_CONFIG_DIR` and `find -type f` mistakes: **a check that cannot fail is
  not a check.** Run the whole scenario and print the actual bytes. Two probe bugs of that class,
  both from the #5501/trust investigation: `find … -type f` does not match **symlinks** (the trust
  store is symlinks — use `\( -type f -o -type l \)`), and in `find … | sed … || echo "(none)"` the
  `||` binds to the *pipeline*, whose status is `sed`'s `0`, so the fallback never ran. **A probe
  that cannot distinguish "no effect" from "not measured" is not evidence.**
- **Verify what a flag *is* at command scope, not argument scope.** #11631 added `--file` to
  `dotfiles add` and the test asserted the alias existed on that one `Arg`. Neither ever asked what
  else the command owned, and `-f` was `--force`. The colliding letter is invisible to grep because
  `#[clap(long, short)]` derives it from the field name. **When adding or aliasing a flag name,
  enumerate every argument on that command.**
- **Verify an API exists before formatting with it.** The guard test in #11789 first wrote
  `panic!("… --{}", arg.get_id())`. `clap::Id` has `as_str()` and `AsRef<str>` but **no `Display`
  impl** in clap_builder 4.6.0 — checked in
  `~/.cargo/registry/src/*/clap_builder-4.6.0/src/util/id.rs`. Without that check it would have
  been a compile error found only by CI, one round trip per guess.

### Build and generated artifacts on this box

- **`cargo fmt` runs fine here even though a workspace `cargo check` does not.** fmt never builds
  dependencies, so the `libz-ng-sys` failure does not apply. #11631's first CI run failed on
  `hk`/rustfmt because adding `visible_alias` pushed four `#[clap(...)]` attributes over the width
  limit; `cargo fmt --all` reproduced CI's expected output exactly. **Run it before pushing any
  attribute edit.**
- **"`cargo check` does not run here" is true of the *workspace*, not of every member crate.**
  `cargo test -p vfox --lib` builds and runs: that crate never pulls `libz-ng-sys`. Cold build
  **15m44s**, incremental rebuild of just that crate **49s**. That was enough to verify #11793
  properly instead of shipping it on reasoning: with the fix, 4 passed; with one panic put back,
  `env_keys.rs:62:18: Expected table`, 1 failed. **A test that has only ever been seen passing has
  not been shown to test anything** — break the fix, watch it fail, restore. Try `-p <crate>` on any
  change confined to `crates/`.
- **Flag aliases render into the man page only.** `usage generate markdown` does not emit visible
  aliases, so `docs/cli/*.md` never changes for one — proof on main: `mise unset` has carried
  `flag "-f --file --path"` since #11616 and `docs/cli/unset.md` still reads `### \`-f --file <FILE>\``.
  Hand-adding it makes lint's "assert `mise run render` produces no diff" fail. (Short flags *do*
  appear in markdown headings; aliases do not.) Corollary: **a bot patch that edits
  `man/man1/mise.1` directly is wrong** — the next render reverts it. Fix the doc comment in
  `src/cli/*.rs` instead.
- **`mise run render` cannot be run on Windows.** `mise usage` emits the live CLI surface, and
  Windows does not register the Homebrew subcommands, so regenerating `mise.usage.kdl` here drops
  them and produces a huge spurious diff. `usage generate markdown|manpage` only read the kdl and
  are safe anywhere. The route that works: push a **probe branch to the fork** with a throwaway
  workflow that runs `mise run render` on ubuntu and uploads `git diff` as an artifact, then apply
  that patch to the real branch. **The probe branch and its workflow must never touch a PR branch**,
  and both get deleted afterwards. Apply with `git -c core.autocrlf=false apply` — plain `git apply`
  rewrites the repo's LF files as CRLF and turns the diff into a whole-file replacement.
- **Watch `mise.lock` before every commit.** `mise exec <tool>@latest` rewrites it (it bumped
  `usage` 4.0.0→4.1.0 and `markdownlint-cli` 0.48.0→0.49.1 during this work) and it has silently
  ridden along into a commit more than once. Check `sl status`, and prefer the pinned versions the
  lockfile already names.
- **PowerShell's `>` writes CRLF, so never use it to restore a repo file.** On 2026-08-14 a conflict
  in `e2e-win/bootstrap.Tests.ps1` was resolved by writing main's version back with
  `sl cat … > file`; the bytes matched in length but the file stayed in the commit with **every line
  changed**. `main` was 1688 bytes, the working copy 1739 — the difference was exactly the 51 lines.
  Restore through Bash (`sl.exe cat … > file` there preserves bytes), and check new files too:
  `[IO.File]::WriteAllLines` uses `Environment.NewLine`, so a hand-built file arrives CRLF while the
  repo's `e2e-win/*.ps1` are all LF. `head -1 file | od -c` settles it in one line.
- **A conflict can be a filename collision rather than a content one.** #11919's only conflict was
  `e2e-win/bootstrap.Tests.ps1`, a file *this* branch added — and jdx's #12003 had added one with the
  same name for an unrelated feature (`mise bootstrap` the system command, not `mise generate
  bootstrap`). Two disjoint `Describe` blocks. Resolved by keeping theirs untouched and renaming mine
  to `generate_bootstrap.Tests.ps1`. **Read what the other side actually is before merging the two
  together**; the resolution here is a rename, not a merge.
- **The *schema* half of render does run here — the blanket "render is impossible on Windows" above
  is too strong.** `xtasks/render/schema.ts` is a bun script that reads `settings.toml` and
  `schema/mise.json` and spawns only `prettier`; it never asks mise for the CLI surface. `bun
  xtasks/render/schema.ts` regenerated `schema/mise.json` for #11837 with a diff that was exactly
  the removal — no reformatting churn. bun, prettier and `node_modules/toml` are already present.
  So: kdl/markdown/manpage need the probe branch, JSON schema does not.
- **Most `settings.toml` edits need no render at all.** `parse_env` and the long `docs = """…"""`
  block reach no checked-in artifact: `build.rs`'s `codegen_settings` writes to `OUT_DIR`,
  `xtasks/render/schema.ts` reads only `description`/`type`/`default`/`deprecated`/`enum`, and
  `docs/settings.data.ts` reads `settings.toml` directly at VitePress build time. Adding or removing
  a *setting* does change `schema/mise.json`; changing how one is parsed or documented does not.
- **CI never ran the workspace member crates, and 337 tests rotted there.** Every `cargo test` in
  `.github/workflows/test.yml` is invoked from the workspace root, and with a root package and no
  `default-members` that selects `mise` alone — members are built as dependencies but their tests
  never execute. Six were failing on main when this was found, two of them Windows-only. **A member
  crate's green test on this box was the only signal there was**, until **#11839 merged 2026-08-11**
  and put the members on both gating unit jobs. Before that date, any test added under `crates/` was
  unverified by CI.
- **`cargo test --workspace --exclude mise` runs locally.** Excluding the root package sidesteps the
  `libz-ng-sys`/cmake wall entirely, so all six member crates build and test here in one command —
  and it is the exact command #11839 puts into CI, so local verification and CI check the same thing.
  Full run on this box: aqua-registry 117, vfox 110 (+2 ignored), mise-interactive-config 37,
  mise-sigstore 26, mise-cache-rustc 23, mise-cache-core 22.
- **A throwaway crate in the scratchpad is the cheapest way to pin an external crate's semantics
  before writing a fix.** For #11832 the whole design rested on how `versions` 7.x compares a
  4-component bound against a 3-component version. A 30-line crate depending only on `versions`
  answered it in 16 seconds of compile time, and turned "this should work" into eight passing
  assertions *before* touching mise. Same trick for #11835's settings.toml walker, with a planted
  offender so a walker that silently found nothing could not pass.
- **A GitHub Actions probe repo is the right tool for CI-only bugs.** For #5665 a throwaway
  **private** repo with a matrix over `jdx/mise-action`'s `version:` input measured four mise
  releases against one config in a single push. Two traps: (a) mise-action runs `mise install`,
  which **creates the venv before your test step** — `rm -rf .venv` immediately before measuring, or
  the path under test never executes; (b) `gh run view --log` fails while a run is in progress — use
  `gh api repos/{o}/{r}/actions/jobs/{id}/logs`, and match the step *output* (`^exit=\d`), not the
  echoed command.
- **`tasks/test_task_broken_symlinks` blocked every PR for a while and it was nobody's fault here.**
  #11574 added the test, then main moved and the expectation went stale. **The `test` workflow does
  not run on main pushes** — only `docs`, `perf` and `release-plz` — so a broken test lands
  invisibly and only surfaces on the next PR. jdx fixed it in #11618. Before concluding a red e2e is
  yours: check whether the failing test is one you touched, and compare run *creation times*
  against when the suspect PR merged.
