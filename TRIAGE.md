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

| id         | what                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | evidence                                                                                                                                                                                                                                                                                    | blocked on                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| ~~**A1**~~ | **Dead — re-measured 2026-08-21 on 2026.8.9: fixed.** In a HOME holding `mise.toml`, `mise set` now appends to it; no `.config/mise/config.toml` is created. Original entry: `$HOME/mise.toml` is read but is never a write target; `use` and `set` create a new file instead. At the `$HOME` level `first_config_file` returns `.config/mise/config.toml` (it precedes `mise.toml` in `LOCAL_CONFIG_FILENAMES`), that is the global config, and the `!is_global_config` guard then skips **the whole directory**                                                                                                                                                               | measured on v2026.7.18 (Linux + Windows): with both files present `mise config ls` lists both, yet from `~/work/proj` both commands create `~/work/proj/mise.toml`; remove the global config and `~/mise.toml` is chosen immediately; an intermediate `~/work/mise.toml` is chosen normally | ready — same line, now inside `nearest_local_config_file` (#11571)                               |
| ~~**A2**~~ | **Superseded — #12207.** Re-measured 2026-08-21: the panic below is long fixed on both Windows and Linux (2026.8.3 still aborts, 2026.8.9 errors cleanly). What survived was the asymmetry with `mise set`, which is what #12207 fixes. Original entry: `--path`/`--file` pointing at a **non-existent directory**: `mise use` panics in `config_file::init` ("Unknown config file type"); `mise set --file` instead writes an **extension-less file** named after the directory. Two commands, one input shape, two different wrong answers                                                                                                                                    | measured on v2026.7.18 and unchanged on the #11575 branch; noted in that PR body as pre-existing                                                                                                                                                                                            | ready                                                                                            |
| **B1**     | **Refactor only — measured 2026-08-21, no observable divergence.** `use`/`unuse` agree on the target for the plain case, `--env staging`, and the case where `.mise.staging.toml` and `mise.staging.toml` both exist. Structurally still two resolvers; without a user-visible difference this is a hard sell after #11853. Original entry: `unuse`'s target ladder is a second implementation of `use`'s. Not a drop-in: its default arm searches the _loaded_ configs for the tool and returns early via `config_file::parse` (`unuse.rs:170-180`), which `resolve_target_config_path` cannot express. Same "duplicated resolvers drift" class as #11571                      | code reading only                                                                                                                                                                                                                                                                           | ready                                                                                            |
| **B2**     | `config_file_from_dir`'s name is a lie — after #11575 it is only ever asked about the cwd. Fold the rename into B1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | code reading only                                                                                                                                                                                                                                                                           | B1                                                                                               |
| **B3b**    | `use`/`unuse` declare `value_hint = FilePath` although both accept directories (`set` uses `AnyPath`). Dropped from #11577 after measuring that `value_hint` never reaches `mise.usage.kdl`, so it changes no generated output — possibly inert entirely, since completions come from the kdl                                                                                                                                                                                                                                                                                                                                                                                   | measured                                                                                                                                                                                                                                                                                    | verify it does anything first                                                                    |
| **C3**     | `mise fmt` reformats configs that config loading excludes — verified for both a relocated `MISE_CONFIG_DIR` and `MISE_IGNORED_CONFIG_PATHS` (`go="1.26"` → `go = "1.26"`). Defensible for a formatter; probably a docs sentence, not code                                                                                                                                                                                                                                                                                                                                                                                                                                       | measured                                                                                                                                                                                                                                                                                    | —                                                                                                |
| ~~**E1**~~ | **Done — #12176, merged 2026-08-20.** `status` became `exit_status` at the four sites zsh reaches (three in `assert.sh`, `as_group` in `style.sh`); `e2e/shell/test_zsh_assert_helpers` guards it. The three sites left alone are bash-only. See its review round below. Original entry: `e2e/assert.sh` is sourced for zsh tests (`run_test:147`) but is not zsh-safe: `quiet_assert_succeed`, `quiet_assert_fail` and `run_with_timeout` all declare `local status`, and `status` is read-only in zsh — the helpers print `read-only variable: status` and capture nothing, so an assertion reports `expected '3.0.0' to be in ''` while the thing under test actually passed | measured — cost #12117 a CI round; all four pre-existing zsh e2e tests use **zero** assert helpers, which reads like the same discovery made silently before                                                                                                                                | ready — rename the variable; test-only, no product code                                          |
| ~~**E2**~~ | **Done — #12218, merged 2026-08-21.** Not the design decision recorded here: the history shows a regression from #8920. See its section below. Original entry: Under `--no-hook-env`, **bash alone applies mise's env at activation**: `activate.sh:82` calls `_mise_hook` outside the `__MISE_HOOK_ENABLED` block, while zsh/fish/pwsh keep theirs inside. Either bash leaks under a flag documented as "without actually modifying the environment", or the other three leave the shell unconfigured. Same "one shell differs" tell that found #12089                                                                                                                         | measured in WSL on the released build: bash `--no-hook-env` → the tool is ON-PATH immediately after activation; zsh and fish → not on PATH; all three ON-PATH without the flag. pwsh from source reading only, unmeasured                                                                   | **design call — ask in a Discussion/issue first**, do not PR blind (#11883 was closed on design) |

**D1/D2 — found 2026-08-09 while verifying #413's `sub-N:` claim. Measured on v2026.8.3 linux-x64.**

| id         | what                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | evidence                                                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| ~~**D1**~~ | **Dead — re-measured 2026-08-20: fixed.** `mise ls-remote node@sub-2:lts` lists 22.x. Original entry: **`mise ls-remote <tool>@sub-N:<alias>` panics.** `mise ls-remote node@sub-2:lts` → `called Option::unwrap() on a None value`, `src/toolset/tool_request.rs:592`. `version_sub()` does `orig.chunks.0[i].single_digit().unwrap()`, and an **alias** base (`lts`) parses into a non-numeric chunk, so `single_digit()` is `None`. `ls-remote` does not resolve the alias before calling it; `use`/`install` do | measured: `sub-2:lts` panics, **numeric base `sub-1:24` works** (lists 23.x). Same file also unwraps at `:585`, `:586`, `:597` |
| ~~**D2**~~ | **Dead — re-measured 2026-08-20: fixed.** `mise latest node@sub-2:lts` returns 22.23.2. Original entry: **`mise latest <tool>@sub-N:…` rejects a spec every other command accepts.** `mise latest node@sub-2:lts` **and** `node@sub-1:24` → `invalid version`, while `mise use --dry-run node@sub-2:lts` and `mise install --dry-run node@sub-2:lts` both resolve it to `22.23.2`, and `[tools] node = ["lts", "sub-2:lts"]` resolves correctly in config                                                           | measured, all on the same binary                                                                                               |

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
for (_"not all the time—but when installing a new go version"_) — and it carries no guidance.
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
before returning to newer ones.** The band walk had been climbing _upward_ from `#5260`; that was
working the wrong direction.

### The map, measured 2026-08-09

`#413`–`#5989`: **912 open**. Fetched with `discussions(first:100, orderBy:{field:CREATED_AT,
direction:ASC})`, paginated.

| range               | open    | what it is                                                                                                                                                                    |
| ------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`#413`–`#3499`**  | **108** | 2023-01..2024-12, rtx era. Q&A 60 / General 27 / Ideas 14 — the "Troubleshooting and bug reports" category **did not exist yet**. Expect stale support questions, not defects |
| **`#3500`–`#5259`** | **566** | where the bug category begins: **295 Troubleshooting/bug reports**, 113 Ideas, 105 Q&A. **This is where the defect yield is**                                                 |
| `#5260`–`#5880`     | 197     | already worked — closed out bar the residuals below                                                                                                                           |
| `#5880`+            | 38      | newer than anything worked                                                                                                                                                    |

**677 open below `#5260` have never been triaged.** Only **5** of the oldest 108 have zero comments
(#608, #1204, #1616, #1638, #2338); in `#3500`–`#5259` **38 bug reports have zero comments**, the
strongest single lead list in the whole backlog.

#### Band `#3500`–`#5259` progress — 2026-08-14

**5 remain** that are open, zero-comment, unanswered and unlocked — down from 40. The count moves
faster than the replies do because a lot of it turns out to be already-fixed.

The 5 left are not "not yet looked at": every one has been investigated and the finding recorded
below. They are held back because **each needs something this account cannot do alone** — none is
waiting on work here.

| still owed                                                                                                   | why it is held                                                                                                                                                                |
| ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
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

| bucket        | n      | meaning                                                      |
| ------------- | ------ | ------------------------------------------------------------ |
| MINE          | 94     | already carries my comment                                   |
| MARUKOME      | 95     | @Marukome0743 answered                                       |
| JDX           | 122    | maintainer engaged                                           |
| COMMUNITY     | 116    | some other contributor commented                             |
| **SELF_ONLY** | **22** | **only the reporter ever spoke**                             |
| NO_COMMENTS   | 9      | the 7 owed above plus #4268/#4793, both deliberately skipped |

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

and `.replies.nodes[]?` over an **empty** reply list produces _nothing_, so `//` fired and injected a
phantom `"(ghost)"` author into every comment that had no replies. A phantom author is never the
discussion owner, so SELF_ONLY collapsed into COMMUNITY. Found only because #4581's classification
(`others=["(ghost)"]`) contradicted the thread, which has one comment and no replies. Correct form:

```jq
[$d.comments.nodes[] | .replies.nodes[]? | .author.login // "(ghost)"]
```

**Two lessons.** The controls (#4281 = my reply, #3539 = a Marukome0743 reply) both passed, because
MINE and MARUKOME are tested _before_ SELF_ONLY — **a control only covers the branch it exercises, so
pick one per branch, including the branch you most want to be true.** And `//` in jq is an
emptiness test, not a null test: any `[]?` or `.foo[]` on its left silently turns "no elements" into
the default. The membership of the 43 was unaffected; only the split between the two halves was.

**Replied 2026-08-11:** #5173 (zig), #4898 (ansible/uvx), #4581 (own aqua registry), #4597 (go
package paths), #4892 (nested venv). #4777 was left alone on the user's call — its reporter opened
the PR that implemented it. #4958 (aws-cli/poetry on macOS) is the user's to check on their own
hardware.

**Two are implemented but deliberately unanswered — reply when the PR merges** (user's call
2026-08-11, matching how #4789/#4813 were handled):

| discussion | PR         | what the reply has to say                                                                                                                                                                     |
| ---------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **#4792**  | **#11883** | only one of the three asks is covered (broken-include detection). The `mise tasks include` command is _not_ built, and the reason is worth telling them: `includes` **replaces** the defaults |
| **#4690**  | **#11885** | "yes it is a bug, and your reading of the source was right" — they have been waiting on exactly that since 2025-03 to decide whether to write the patch                                       |

#### Four SELF_ONLY threads worked 2026-08-11 — one is a live defect

- **#4690** (👍3, python venv vs `disable_tools`) — **REPRODUCES on 2026.8.2. Fixed in PR #11885,
  merged 2026-08-12. The reply is OVERDUE — see "Replies owed".**
  `disable_tools = ["python"]` in `mise.local.toml` turns the tool off — `mise which python` says
  _"python is not a mise bin"_ — but the `_.python.venv` directive still activates an **existing**
  venv: `VIRTUAL_ENV` is exported and the venv's `Scripts`/`bin` is prepended to PATH. `venv.rs`
  contains no reference to `disable_tools` at all, which is exactly what the reporter worked out
  from the source in 2025-03. They offered to write the patch and asked whether it would be
  accepted; that question is still open.

  **The first measurement said "fixed" and was wrong.** With no `.venv` on disk, `disable_tools`
  suppressed everything — but only because _creation_ needs the tool. The control run (same config,
  no `disable_tools`) created the venv, and re-running with `disable_tools` then exposed the real
  behaviour. **A suppression test on a fixture that was never built proves nothing**; build the
  artifact first, then suppress.

- **#4597** (👍2, go package paths) — fixed. Resolution goes over `$GOPROXY` now, so `go` is never
  spawned: with **no go installed** and a cold cache, `go:connectrpc.com/connect/cmd/protoc-gen-connect-go`
  lists 45 versions and `go:github.com/brianhuster/nvcat` (the one that "got stuck" on
  `go list -m -versions -json`) lists 11. The reporter's 404s were the upward module-path walk
  leaking `go list` stderr; the walk is now HTTP and its misses are DEBUG-only. **#11054** (jdx) gave
  the `GOPROXY=direct` fallback the same walk, **#11816** (mine, from #5189) stopped its diagnostics
  reaching stdout. Note _installing_ a `go:` package still needs go on PATH — only resolution is free
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

  | ask                                                           | state                                                                                                                                                                                                                                                                                              |
  | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | idempotent `mise tasks include <path>`                        | unimplemented. `mise config set task_config.includes '/a,/b' --type list` is the nearest primitive and **replaces** rather than appends — precisely what they asked not to happen. (`--type list` splits on commas, so a JSON-looking `["/a","/b"]` writes the brackets and quotes into the list.) |
  | detect broken includes                                        | **was completely silent** — no output, nothing at `--verbose`, and `mise tasks validate` answered _"✓ All 1 task(s) validated successfully"_. PR #11883                                                                                                                                            |
  | delete broken includes                                        | unimplemented                                                                                                                                                                                                                                                                                      |
  | _(their stated motivation)_ pull global tasks from a git repo | **solved another way**: `includes` takes `git::` URLs — `git::https://…/repo.git//tasks?ref=main`, ssh too, per-file or per-directory, `?ref=` pinned. #7582 (@vmaleze), first release **v2026.1.1**. No clone, no setup.sh                                                                        |

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

  | section             | editors                                                     |
  | ------------------- | ----------------------------------------------------------- |
  | `[tools]`           | `use` / `unuse`                                             |
  | `[env]`             | `set` / `unset`                                             |
  | `[settings]`        | `get` / `ls` / `set` / **`add`** / `unset`                  |
  | `[alias]`           | `get` / `ls` / `set` / `unset`                              |
  | `[tasks]`           | `tasks add`                                                 |
  | **`[task_config]`** | **none** — only the generic `config set`, which is set-only |

  And the exact semantics asked for already exist: **`mise settings add` dedup-appends** ("Used with
  an array setting, this will append the value to the array"), measured — `foo`, `foo`, `bar` gives
  `["foo", "bar"]`. It just cannot reach `task_config.includes`: that is not a registered setting,
  so it answers `Unknown setting: task_config.includes`.

Findings kept from the three not replied to:

- **#4777** (👍5) — `enable_tools` was asked for and the reporter's own PR #4784 delivered it; first
  release **v2025.5.5**. Gotcha if it ever needs stating: when set explicitly it is a _complete
  allowlist_ and `disable_tools` stops being applied (`settings.toml:600`).
- **#4581** (👍4) — **REPLIED 2026-08-11**, as a threaded reply to the reporter's question. The note
  here first said the "show only my own registry" half was unanswerable by settings. **That was
  wrong** — `enable_tools` does exactly it, and the reason nobody could say so in 2025-03 is that it
  shipped in **v2025.5.5**, two months later (#4784 — which is #4777, the neighbouring thread in this
  same lead list). Isolated one setting at a time on 2026.8.2:

  | config                            | `mise registry`                                                                           |
  | --------------------------------- | ----------------------------------------------------------------------------------------- |
  | none                              | 999                                                                                       |
  | `enable_tools = ["k9s", "jq"]`    | **2** — `jq  aqua:jqlang/jq`, `k9s  aqua:derailed/k9s`                                    |
  | `disable_backends` = all but aqua | 877 (a tool only drops when _every_ backend is disabled, and 686 of 999 have an aqua one) |
  | `aqua.baked_registry = false`     | 999 — **no effect on the listing at all**                                                 |

  It is not just a display filter: with `enable_tools = ["k9s"]` and a mise.toml naming both,
  `mise install --dry-run` offers only k9s and `mise ls --current` lists only k9s. Two caveats that
  went into the reply — `mise use <tool>` still _writes_ a non-enabled tool into the config (it is
  an allowlist over what is used, not over what can be added), and the list is hand-maintained, so
  the reporter's "generate `registry.toml` from the aqua registry" idea is still not a thing.
  `aqua.registry_url` is deprecated for `aqua.registries` (warns 2026.12.0, removed 2027.12.0).

- **#4975** (👍4) — still open, but **not the lead it first looked like, and the first write-up here
  was wrong.** Three corrections, all measured on main 2026-08-11:
  1. **`ubi:` is deprecated** — `ubi.rs:126` carries `deprecated_at!("2026.4.0", "2027.1.0", …)` and
     `docs/dev-tools/backends/ubi.md` opens with a deprecated badge. Warns from **2026.4.0**, removed
     in **2027.1.0**. Anything proposed for `ubi:` alone is work with an expiry date. (The same trap
     already recorded for #2878 — check it _before_ planning, not after.)
  2. `github:` — the replacement — **already has `resolve_exact_version`** (`github.rs:607`). The
     earlier note here said ubi _and_ github were left out of #11070; only ubi was.
  3. That fast path **does not remove the GitHub call**, it narrows it: it swaps listing every
     release for one `get_release_for_url_with_versions_host` lookup, and returns `Ok(None)` when
     offline. So it does not answer the reporter's actual question, which is why an _already
     installed_, exactly pinned tool needs GitHub at all to **run**.

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
`answerChosenAt` but _not_ `closed`, so #3882 and #3891 were investigated and drafted before the
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
  measurable answer. #4243: mise's bash completion registers `-o nospace`, which is _why_ there is
  no trailing space, and re-registering without it is the opt-out. #3878: jdx asked for use cases,
  and `[settings] enable_tools = []` already delivers the whole feature — `[env]` and enter/leave
  hooks still fire, no tool reaches PATH. "The reporter resolved it themselves" and "it's the
  maintainer's own RFC" are not reasons to skip measuring.
- **#4789** was moved to _resolved_ and then back to _broken_. Measuring `hook-env --silent`
  directly showed the warning suppressed, so it read as fixed; running it the way the reporter
  did — `mise activate bash --silent` — reproduced the bug. See the process note below.

**Deliberately not replied:**

- **#4194** — @Marukome0743 answered it 2026-08-10 with a macOS-arm64 reproduction and the PR that
  fixed it (#6003, v2025.8.9). Nothing to add. _Third time that person has landed on a thread in
  this queue; the "re-check immediately before investing" rule keeps earning its place._
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
It read `comments(last:5)`, so a thread with more than five comments where they replied _early_
would be missed (their comments are all recent, so this one is theoretical). **The one that actually
bit: it only looked at top-level `comments` and never at `comments.nodes.replies`.** Found while
reading — **#3068** and **#3423** both carry a Marukome0743 answer as a _nested reply_ and neither
appears in the 108. Threaded replies are invisible to a top-level-only scan. Re-check per thread
before investing; never treat that list as exhaustive.

That leaves roughly **544 open discussions below `#5260` with no reply from either of us.**

### `#413`–`#3499` — **READ IN FULL, 2026-08-09**

108 open. 23 skipped as already answered by @Marukome0743; **85 read body-and-comments**. Every
thread below is either a candidate or explicitly cleared — nothing in this band is unexamined.

**20 reply candidates. Six verified, four of those posted (2026-08-09).**

| #             | state                                                                                                                                               |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| ~~**#3428**~~ | **REPLIED 2026-08-09** (top-level) — `task.output = "keep-order"`                                                                                   |
| ~~**#1554**~~ | **REPLIED 2026-08-09** — starship `mise` module shipped                                                                                             |
| ~~**#644**~~  | **REPLIED 2026-08-09** — `node.npm_shim = false` + `corepack = true`                                                                                |
| ~~**#815**~~  | **REPLIED 2026-08-09** — GOROOT/GOPATH/GOBIN, measured with the reporter's own repro                                                                |
| **#1424**     | **deleted, not answered** (user's call) — see "Deliberately not posted". #11791 merged 2026-08-09, so the `env_only` hole it was held for is closed |
| **#1638**     | **OUT OF SCOPE — do not post.** User's call: it is jdx's own design thread, not a user report. The findings live in the #815 reply instead          |

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

  | `activate_aggressive` | prepend a dir, then hook (no dir change) | then `cd` / `--force`        |
  | --------------------- | ---------------------------------------- | ---------------------------- |
  | false (default)       | prepended dir wins                       | **prepended dir still wins** |
  | true                  | prepended dir wins (hook exits early)    | mise wins                    |

  So by default a directory put in front of PATH after activation keeps precedence, across `cd`.
  mise does not push its python ahead of a conda env. **zsh was untested** (not installed in this
  WSL image) and zsh is what they used.

  **CLOSED OUT, and not by me — @Marukome0743 answered it 2026-08-09 06:59, hours after I finished
  the investigation above. Do not reply.** Their answer is strictly better than mine: they name the
  fix (`71ee6716c451`, _"activate: use less aggressive PATH modifications by default"_, first release
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
  108-thread sweep, now this) — and the first time it happened _while I was working the same thread
  the same day_. See the process note.

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
2026-08-09 while verifying #1764. The flag advertises _"Which hook to generate"_, but the body is
hardcoded for `pre-commit`. Minimal honest fix: append `"$@"` so hook arguments reach the task —
that alone makes `commit-msg` usable. Whether to emit hook-specific bodies (and whether
`MISE_PRE_COMMIT`/`STAGED` should be conditional) is a maintainer call — left out of #11801 and
stated in its body, along with two other things deliberately not touched: the `STAGED` line uses
`HEAD`, so the generated hook errors with `fatal: ambiguous argument 'HEAD'` on a repository's
**first** commit, and `--write`'s own help still reads _"write to .git/hooks/pre-commit"_ (a doc
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
  - Dead ends worth not re-testing: `aqua:nim-lang/Nim` → _no aqua-registry found_;
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
  restates @jasisk's 2023 diagnosis word for word — _"corepack's safety logic refuses to clobber the
  existing non-symlink `bin/npm` file"_. The `node.corepack` setting is older (absent at v2026.2.14,
  present at v2026.2.20). **No PR references discussion #644**, which is why nothing here says so.
- **#1638** + **#815** — **all four cases measured on v2026.8.3** with `go = "1.24"` installed, using
  `mise env`:

  | parent env                             | mise emits                                              |
  | -------------------------------------- | ------------------------------------------------------- |
  | nothing set                            | `GOBIN` + `GOROOT` (mise install path). **No `GOPATH`** |
  | `GOROOT=/opt/go-1.21.6`                | `GOROOT` **overridden** with mise's                     |
  | `GOBIN=/home/me/gobin`                 | **no `GOBIN`** — an inherited one is respected          |
  | `go.set_goroot = false` + `GOROOT` set | **no `GOROOT`** — inherited one left alone              |

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
worth-posting check _before_ drafting: read every existing comment in full and skip anything that
merely restates what the thread already says. That filter removed a third of them. **Do this on
every thread from now on** — the point of the queue is threads that lack an answer, not threads I
can add prose to.

| #             | 👍  | outcome                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ~~**#2878**~~ | 1   | **POSTED.** Answers @powerman's _reworded_ question (unanswered since 2024-11): **`[tool_alias]` in the _global_ config** redirects a tool while the third-party project's `mise.toml` stays untouched — measured, `Backend: github:magefile/mage` with the project still saying `mage = "latest"`. Two traps carried into the reply: **`[plugins]` is not this** (read as an asdf _plugin source_ → `asdf:github:magefile/mage` → `plugin not installed`), and `[alias]` warns as deprecated. Also **`ubi:` is deprecated → `github:`**, which stales every entry on @powerman's list, and `mage` already defaults to **`aqua:`**                                                                                                                                                                                                                                                                                                                                                                                                   |
| ~~**#2338**~~ | 2   | **POSTED. My pre-measurement read was wrong and would have been a wrong answer.** I had written "wrapper still needed"; installing watchexec and running it showed `mise watch mkdb ::: client` runs **both** tasks under one watch, so `watch_mkdb` _can_ be deleted. Caveat in the reply: both tasks re-run on change, tunable with `--on-busy-update`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ~~**#2107**~~ | 1   | **POSTED.** The accepted answer is now silently inert: precompiled python is the default, so `PYTHON_CONFIGURE_OPTS` never reaches a compiler. `python.compile` is tri-state (`true` / `false` / unset = precompiled-if-available). Verified the passthrough with a **deliberately invalid flag** — `configure: error: unrecognized option: '--bogus-flag-xyz'` — which proves the variable reaches `./configure` instead of assuming it. `-f` still means "force reinstall"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **#1750**     | 1   | **Not posted — user's call: already resolved.** Kept for the record: reproduced on v2026.8.3, and it is **not a mise bug** — `pkill -f` matches full command lines _including its own shell_, so the shell is signalled and `\|\| true` is never reached (`sh -c "pkill -f '.*XxYyZz.*' \|\| true; echo survived=$?"` prints **nothing**). If it ever needs answering: do **not** claim the wording is mise's — `bail!("exited with non-zero status: {status}")` is `src/cmd.rs:1261`, but the literal `no exit status` is not in `src/`, so it comes from `ExitStatus`'s Display                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **#68**       | 1   | **Not posted — redundant.** @amoosbr's own 2023-03-07 edit already records _"Since the introduction of experimental shim support, I use them"_, and the reporter had solved it with a hand-rolled shim. Saying "`mise activate --shims` exists" adds nothing                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **#607**      | 1   | **Not posted — confirms rather than adds.** jdx already answered "can't". Still can't: prefix matching cannot express "newest 1.14.x **with** `-otp-25`" because the suffix trails the varying part. Only new facts are that elixir is now **`core:elixir`** and `mise latest elixir@1.14` → `1.14.5-otp-26`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **#862**      | 2   | **Not posted — too thin.** Latest release carries `linux-armv7` (+musl) and **no armv6**, so the Pi Zero W still needs the cross-compile recipe already in the thread                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ~~**#2435**~~ | 1   | **POSTED 2026-08-09** (top-level: the two unanswered people sit in different places — @iilyak top-level, @NiklasRosenstein as a reply under jdx — so only a top-level comment reaches both). **Investigated first —** The setting is **`aqua.registries`**: repository URL, direct `registry.yaml`/`.yml` URL, or absolute `file://` to a local dir/file; checked **before** the baked-in registry (`aqua.registry_url` is the deprecated single-source form, remove 2027.12.0). Measured: `aqua:myorg/mytool` is _"no aqua-registry found"_ by default, lists **2.94.0–2.97.0** once `aqua.registries = ["file:///…/myreg"]` points at a hand-written `registry.yaml`, and with **`aqua.baked_registry = false`** even a baked tool (`aqua:magefile/mage`) becomes _"no aqua-registry found"_ — which is exactly @Sytten's _"they should be the only ones that can be installed"_. Settings are per-project (see #1424), so @iilyak's project-scoped shape works. `shorthands_file` → `[plugins]` is a separate, smaller correction |
| ~~**#2441**~~ | 3   | **POSTED 2026-08-09** (top-level; @ParadaCarleton's question is itself the newest top-level comment). **The measurement contradicts the thread's premise —** Installing the **same tool** both ways on v2026.8.3: `github:magefile/mage` printed `checksum …` + **`verify GitHub artifact attestations`** + **`verify SLSA provenance`**; `aqua:magefile/mage` printed **only** `checksum …`. So "aqua is more secure" is not a property of the backend — aqua verifies whatever its registry entry declares (`aqua.cosign`, `aqua.slsa`, `aqua.minisign`, `aqua.github_attestations`, all default `true`), and mage's entry declares only a checksum. The **lockfile is backend-independent**: identical per-platform `checksum`/`url`/`url_api` rows were written for both                                                                                                                                                                                                                                                         |

**Cleared — read and needing nothing** (63): #235, #333, #340\*, #440, #518, #603, #605\*, #608,
#617\*, #677, #678, #703, #734, #841, #869\*, #983, #995\*, #1090, #1092, #1114, #1201, #1204,
#1289, #1301, #1357, #1363, #1491, #1514, #1523, #1525, #1550, #1581, #1582, #1616, #1768, #1935,
#1940, #1966, #1988, #1998, #2023, #2026, #2041, #2106, #2122, #2160, #2215, #2251, #2316, #2329,
#2368, #2444, #2492\*, #2888, #2991, #3006, #3068\*, #3168, #3340, #3416, #3417, #3423\*, #3436,
#3487. (\* = answered by @Marukome0743, several as nested replies.)

Two of these are worth remembering rather than re-reading: **#1935** — jdx _declined_ falling back to
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

**The reply is held together by one fact worth remembering:** `task_config.includes` _replaces_ the
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
(#11885, the overdue one above). **#5842**'s existing comment was _edited_ to add the local
write-target half that #11917 closed, and to replace "ships in the next release" with the release it
actually shipped in.

**Nothing else is owed.** Re-verified 2026-08-14: #3866 and #4894 carry their replies, and the two
posted comments this file flagged as _wrong_ are both corrected in place — #4881 (the `--file`
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

**Do not post first and consolidate after.** On 2026-08-09 the #5840 reply went out as a _new_
comment before this policy was stated, and had to be merged into the original and then removed with
`deleteDiscussionComment`. Decide new-vs-edit **before** calling `addDiscussionComment`; for any
thread that already carries one of my comments, the answer is now always edit.

**Top-level is not the default — "answering a question" wins over "announcing a fix".** The note
above about resolution announcements going top-level was applied mechanically to #7507, whose last
comment is someone asking _"@jdx can you confirm?"_. The user pushed back and was right: a reply that
only makes sense as a response to a specific comment belongs under it. Visibility was the only
argument for top-level and it is weak — a thread with no existing replies does not collapse anything.

**Read the replies, not just the top-level comments.** The same #7507 mistake had a worse half: the
GraphQL query fetched `comments.nodes` without `replies.nodes`, so three replies were invisible and
the draft contradicted them. `isAnswered=false` was already known not to mean "nobody replied"; this
is the same trap one level down. Always request `comments { nodes { replies { nodes { … } } } }`.

## Open PRs — none, as of 2026-09-01

**Sixty-eight merged across 2026-08-16..09-01**, one closed unmerged (#12318), and **five closed by
the maintainer** — #12569, #12573, #12578, #12625 and #12632. Read the scope section below before
opening the next one; four of those five were the same target.

**Merged since the last entry (3):**

- **#12627** `registry: drop three more os limits aqua no longer restricts` — 08-31 12:09 UTC,
  `27583a919f40`
- **#12624** `fix(install): name the file when the install marker cannot be created` — 09-01
  11:19 UTC. The narrow half of #12573, the half jdx named when closing it. **The broad version was
  refused and the narrow one merged with no changes requested** — the clearest evidence in this file
  that scope, not correctness, was what failed.

**Closed since the last entry (2):** #12625 (`this should not be part of the backend`) and #12632
(`don't think it's worth it, especially with all the tests`).

**Merged in the previous entry (6):**

- **#12560** `fix(registry): let windows/arm64 use x64 backends, as aqua already does` — 08-29
  00:13:55 UTC, `514ba2fca1cb`
- **#12568** `fix(install): stop --dry-run claiming it would install what it cannot` — 08-30
  16:36 UTC, `9b4f28f71948`
- **#12549** `registry(pre-commit): use the pipx backend on Windows, as aws-sam does` — 08-30
  18:45 UTC, `d53a37b9f75c`
- **#12584** `fix(elvish): write elvish's quoting rules, not bash's` — 08-30 22:37 UTC,
  `9fc912dae676`
- **#12582** `fix(fish): split PATH on the host's separator, not always ':'` — 08-30 22:38 UTC,
  `4a2d2e58f12e`
- **#12580** `fix(http): list the platform keys a tool actually declares` — 08-30 23:02 UTC,
  `8849d40a04ff`

**Every one of the five closures came as the closing comment and nothing else** — no inline
findings, no requested changes. A one-line refusal is not a small signal; it means the objection is
to the premise, and there was nothing in the diff worth annotating.

### Scope — read this before opening a PR

**Is this a defect in mise's machinery, or a fact about one tool?** mise is a tool manager, so its
bugs live in backends, resolution, the install pipeline, shell output, registry routing. A single
tool's packaging gap is not mise's to patch, even when the symptom appears in mise.

Four of the five closures were **one tool**, `libsql-server`, which ships no Windows build at all:

| PR     | mechanism tried            | jdx                                                                                                  |
| ------ | -------------------------- | ---------------------------------------------------------------------------------------------------- |
| #12569 | detect via `bins`          | `bins` is a hint; platform/archive correctness belongs to the backend or the specific registry entry |
| #12578 | asset matcher, name family | seems like it could have false positives                                                             |
| #12625 | asset matcher, exact name  | this should not be part of the backend                                                               |
| #12632 | `platforms` on the entry   | don't think it's worth it, especially with all the tests                                             |

Those read as four objections to four locations. **They are one answer: mise does not encode
individual tools' packaging facts.** #12569's "the backend or the specific registry entry" was an
explanation of where such things belong, not an invitation to go and do it — and it was read as a
map to the next attempt three times running.

The rule, and it was already in this repository's own history: **#12549's "Deliberately not
included" table applied it correctly to eleven tools** — `mark`, `sheldon`, `turso`, `xcodegen`,
`zprint` were excluded because "the github alternative has no Windows asset either", which is
exactly `libsql-server`'s shape. Written down, then not generalised.

- **A fact about one tool** → upstream, or aqua-registry. mise's job stops at reporting it
  accurately. The user fixed **17 tools** that way in the same week; that is what the fix looks like.
- **A machinery defect** → mise, but with **several independent examples**. The asset matcher
  picking a non-binary asset by elimination may well be a real machinery defect; argued from one
  tool it reads as a special case, and was refused twice as one.
- **A registry entry may be edited when mise's own claim has gone false** (#12552, #12627, both
  merged — `os` lines that no longer matched what installs). Not to cover a tool's gap (#12632).

**Two refusals on one target means the target is wrong, not the location.** Stop and ask in the
thread — one line — instead of building the next version.

Related and secondary: the evidence has to be sized to the change. #12632 was **one TOML line** with
two unit tests and a new network-dependent Windows e2e attached, which is what "especially with all
the tests" names. Measurements and history belong in the PR body, not in the tree.

**Nothing is unreleased any more.** `v2026.8.15` shipped 08-30 **23:44**, forty-two minutes after
the last of those merges (#12580 at 23:02), so all twenty merges that had piled up behind
`v2026.8.14` are out. The previous entry here read "fifteen merges are still unreleased"; that
sentence has a short shelf life and should be recomputed, never edited by arithmetic.

**The two PRs open on 2026-08-28 conflicted with #12552 the moment it merged, in the same way.**
All three append
tests to the end of the same region of `src/registry.rs`'s `mod tests`, so each rebase produced a
conflict whose two sides were _both_ wanted and neither of which had a semantic disagreement. The
resolutions were mechanical — keep both blocks — but the shape is worth naming: **a conflict where
both sides are additive still has to be read, because the merge cuts the block mid-body and the
closing braces after the marker belong to whichever side came last.** Verified afterwards with
`sl diff --stat -r '.^' -r .`: 0 deletions on both, which is what proves nothing from the merged PR
was clobbered.

Doing this **left the two branches inconsistent with what had just been reviewed**: #12552 landed
with its test reading `BAKED_REGISTRY` after a CodeRabbit finding, while #12549's tests still read
`REGISTRY` for the same kind of claim. Fixed in the same commit rather than waiting for the same
finding to be filed a second time.

**Every PR went red on `cli/test_tool_stub_basic` on 2026-08-29, and `main` could not show it.**
The e2e installed `npm:stylelint`, whose transitive dependency `fastq` published `1.20.2` without
provenance while `1.20.0` had it. Verified against the registry rather than inferred:

```
fastq 1.20.0  attestations=true   fastq 1.20.1  attestations=true   fastq 1.20.2  attestations=false
```

aube's `no-downgrade` trust policy refused it — correctly. **Pushes to `main` do not run the e2e
suite** (only docs, perf, cache-benchmark and friends), so this class of breakage is visible on PRs
and nowhere else, which makes "is it me?" genuinely hard to answer from one PR.

The answer was in the upstream history: **`17822bccc442` (#12576) had already replaced the tool with
`npm:typescript`**, with the comment "TypeScript has no transitive dependencies, keeping this
tool-stub test isolated from unrelated npm dependency metadata changes." Rebasing past it is the
whole fix. Worth noting what the maintainer did _not_ do: add a `trust_policy_excludes` entry to get
CI green. **They removed the dependency instead of excusing it** — the same instinct that kept me
from adding the exclusion myself.

**`config/test_required_env_vars_tools_filter` is flaky and the mechanism is still unknown.** It
failed once and passed on retry inside the same run, and passed on a sibling PR in the same window.
Recorded because the elimination is worth more than another guess:

| hypothesis                                                  | verdict                                                                                                                                                           |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| the product dropped the variable name from the message      | **no** — the raw log has `0: Required environment variable 'NON_TOOL_VAR' ...`. My first report said otherwise because an output filter of mine hid the `0:` line |
| ANSI escapes split the token                                | **no** — raw bytes put `\x1b[91m` before `Required`, outside it                                                                                                   |
| `pipefail` + `grep -q` exiting early → `echo` takes SIGPIPE | **no** — `yes \| head -1` gives `PIPESTATUS=[141 0]` in the same shell, so SIGPIPE does arrive, yet `echo "$out" \| grep -q` gives `[0 0]` at 4KB, 100KB and 5MB  |
| the captured output itself                                  | **no** — replaying the exact 14031 bytes CI echoed through the same helper matches                                                                                |
| a shadowed `grep`/`echo`, or `IFS`/`shopt` from the harness | **no** — none defined                                                                                                                                             |
| a recent change to the test                                 | **no** — unchanged since 2026-04-30                                                                                                                               |
| known upstream                                              | **no** — zero search hits                                                                                                                                         |

What remains unexplained is the helper taking its failure branch on input that contains the pattern.
**Timestamps cannot order it**: the harness buffers a test's output and dumps it only on failure, so
"Test 1/2/3 passed" all carry timestamps within 4 ms and say nothing about execution order — a trap
worth remembering when reading these logs.

The one defensible change is independent of the cause: the test **shadows the harness's
`assert_contains` with its own pipe-based version**, while `assert_contains_text` already does the
same job with `[[ $actual == *"$2"* ]]` and no subprocess. Dropping the local copies is right on its
own terms and removes the only untested surface left. **It would be a mitigation, not a proven
fix**, and saying so is the point.

**`sl push --to <name>` pushes the working copy, not the bookmark of that name.** Running it in a
loop over three branches while the working copy sat on `triage` force-pushed the triage commit over
all three open PRs. Local bookmarks were untouched, so recovery was `sl goto <branch>` then push,
one at a time, verified with `gh pr view --json files`. **Every earlier push in this session did
`sl goto` first**; batching them into a loop is what dropped the step. Push singly, and check
`sl log -r .` immediately before.

**#12496 is what merging #12463 cost.** Both touch `task_stubs.rs` and the same e2e file, and #12463
rewrote enough of both that the rebase produced a ~200-line conflict. **Aborting the rebase and
re-applying the change by hand onto the new `main` was faster and safer than resolving it** — the
change is four small edits and a test block, and every one had to be re-read against the new code
anyway. Worth doing the same next time two of these overlap.

**The `render` diff does not apply from a stale CI log.** #12496's lint failure printed the
`git diff HEAD` for the three generated files, but #12463 had since added `--windows-launcher`
directly after `--mise-bin`, so every hunk's trailing context had moved. Anchoring each insertion on
the _line above_ it — unique in all three files, and unchanged — placed them correctly; the result
was then compared line for line against the CI output, roff escaping included.

**A GitHub API rate limit hit two PRs on 2026-08-26 around 13:0x–13:19 UTC** and failed
`windows-e2e`, `unit-macos` and the attestation step with `403 API rate limit exceeded for
installation`. Nothing to fix: the same commits passed the same jobs on the fork, and other PRs in
the same window passed too. `gh run rerun` needs admin rights on jdx/mise, so re-triggering from
this account means a new SHA — **rebase onto current `main` rather than an empty amend**, which
re-runs CI and keeps the branch current in one step.

**It happened again on 2026-08-27 around 23:03 UTC, on #12510**, and the shape is worth knowing
because it is easy to misread. Both `windows-e2e` and `unit-macos` came back red, which looks like
a platform-specific problem with the change. It was neither: both died in the **`mise-tools` setup
step**, before Pester or `cargo test` ran at all —
`Failed to install tools: … GitHub artifact attestations verification error … 403 API rate limit
exceeded for installation`. **Read where in the job it failed before concluding anything from
which jobs failed.** The PR merged unchanged on the next run.

**Watchman breaks every time its server exits on this machine, and `sl` then takes 15 s+ instead of
0.5 s.** Diagnosed 2026-08-28. The server creates `%LOCALAPPDATA%\watchman\sock` (an AF_UNIX socket
= a reparse point) and **leaves it behind on exit**; here the leftover cannot be opened or deleted
by any Win32 caller — `Remove-Item`, `del`, `fsutil` and a `FILE_FLAG_OPEN_REPARSE_POINT` handle all
give **ERROR 1920**. Watchman is a Win32 program, so it cannot clear its own leftover either, and
the next server dies in ~60 ms:

```
[listener] bind(C:/Users/Jam/AppData/Local/watchman/sock): Invalid argument
[listener] Failed to initialize unix domain listener
[listener] Exiting from service with res=false
```

Sapling spawns another, hence `warning: watchman has recently restarted … operation will be slower
than usual` and full crawls of a working copy holding ~226k files in `target/`.

**The fix is to delete it from WSL**, which reaches the file through drvfs rather than Win32:
`wsl.exe -e sh -c "rm -f /mnt/c/Users/Jam/AppData/Local/watchman/sock"`. Measured after: 0.48–0.58 s
per `sl status`, stable pid, no warning.

Three things that look like fixes and are not, all measured: **a reboot does not clear it** (last
boot 2026-08-20, the `sock` dated 2026-08-14 survived); **`WATCHMAN_SOCK` and `--sockname` do not
reach the auto-spawned server**, which still binds the default path; and **renaming the state
directory aside works but only resets it** — the next server exit poisons the new directory the same
way.

**A reboot is the trigger to expect, and it recurred the same day.** Second occurrence 2026-08-28:
the machine had booted at 19:18:29 and watchman was already dead by 19:34, this time with
`sl status` **timing out at 120 s** rather than merely being slow. Same `bind(...): Invalid
argument`, same one-line cure. Expect this after every restart until a logon task runs it; that
task has still not been installed, so it stays a manual step.

### The `docs` workflow fails on every fork — #12498, **merged 2026-08-27**

Not a Windows finding; it came out of the account owner asking why syncing `main` into the fork
always turned the `docs` check red.

`docs-impl.yml`'s job carries `if: github.repository == 'jdx/mise'`, so on a fork it is skipped —
and both the `trusted` and `untrusted` callers in `docs.yml` come back `skipped`. The gate job then
requires _exactly one_ of them to have succeeded and the other to be skipped, sees neither, and
exits 1:

```
trusted=skipped untrusted=skipped
##[error]Process completed with exit code 1.
```

**The guard is there; the gate was never told about it.** Five consecutive `push`/`main` runs on the
fork failed this way. `docs` is the only one of the gated workflows with the mismatch — `test`,
`registry` and `test-vfox` have no repository guard in their impl workflows at all, so their jobs
run on forks and their gates see a success. **The fork's other workflows are not skipped, they
pass**; that is the opposite of what it looks like from the outside.

**Verified rather than reasoned about, and the technique is reusable:** `docs.yml` has a
`workflow_dispatch` trigger, so the same workflow can be dispatched on a fork branch with and
without the change.

|              | run         | `trusted` | `untrusted / docs` | `docs` (gate) |
| ------------ | ----------- | --------- | ------------------ | ------------- |
| fork `main`  | **failure** | skipped   | skipped            | **failure**   |
| with the fix | **skipped** | skipped   | skipped            | skipped       |

Pull requests are unaffected: `github.repository` is the **base** repo for that event, confirmed on
this account's own PRs where `docs` and `untrusted / docs` both pass on jdx/mise.

**Review feedback: the comment was longer than the change.** The first version carried a five-line
explanation above a one-line `if:`. The account owner asked for it removed — the same reasoning was
already in the PR body, so in the diff it was pure duplication. **A one-line fix should read as a
one-line diff.**

**zizmor failed on it once, and not because of the change.** `known-vulnerable-actions` could not
reach `https://api.github.com/advisories` while auditing `registry-impl.yml`; the log shows
`completed ./.github/workflows/docs.yml` before that, so the edited file passed. A token _is_
supplied (`GHA_ZIZMOR_TOKEN`, `online-audits: true`), so it is not a configuration gap — it is the
same API flakiness as the 403s above, and it clears on a re-run.

### The first PR of mine to be closed rather than merged — #12318, 2026-08-24

`fix(config): keep a config file's line endings when writing it back`. **Closed by jdx at 13:24:52
UTC, sixty-one seconds after he merged #12320**, with **no comment and no review**. Both bots had
cleared it — greptile "Confidence Score: 5/5 … The PR appears safe to merge", CodeRabbit "No
actionable comments were generated".

**The change did not land another way.** No CRLF or line-ending handling exists on `main`, and no
commit has touched `src/config/config_file/mod.rs` since #12366 on 08-24 12:23. So it was declined,
not superseded.

**Record — bot approval measures the diff, not whether the project wants the change.** Two bots
saying "safe to merge" said nothing about whether mise should preserve CRLF, and that is the
question the close answered.

**A hypothesis, labelled as one.** The same sweep merged #12320 (accept a BOM when _reading_ an env
file) and closed #12318 (preserve CRLF when _writing_ a config). "Read whatever the user's editor
produced, write one canonical form" is a coherent position, and #12318 is the only one of the two
that changes bytes mise emits. **Nothing observable confirms this** — no comment was left — so it
stays a hypothesis and does not become a rule in this file.

**Closed out by the user, 2026-08-25**: _"closeされたものはもう気にしないで下さい。あの変更も
CRLF という正直、そこまで重要なものじゃないし良いと思っています"_. So the forward-looking
constraint this record used to carry — treat anything that changes what mise _writes_ as a product
question first — **is dropped**, and no one is asking jdx why. What stays is the part that is about
method rather than about CRLF: bot approval measures the diff, not whether the project wants the
change.

### CI, 2026-08-24 — two PRs were red, and not because of their changes. **Resolved.**

#12318 and #12320 each showed `unit-macos` and `test-ci` failing. The failing step was
`mise run test:e2e e2e/cli/test_system_install_brew_macos_slow`, and the log said Homebrew now
refuses untrusted taps: `The following taps are not trusted: aws/tap`. Neither PR touched brew.

**Control**: `fix-nushell-deactivate-session` — someone else's branch — failed on the same
step with the same two jobs. So the wall was in the runner image, not in either branch.

The other PRs were green, and the reason was timing rather than merit: their runs were from 01:36
UTC and earlier, before this started biting at ~05:05. **A green check from before an
infrastructure break is not evidence the break does not apply.**

**Gone by 08-25**: every open PR is green, including the two that had been red. Nothing was done to
them — the fix was on the runner side, which is what the record said to wait for.

**Merged 2026-08-24 13:23 through 2026-08-25 12:07 (6) — the whole open set:**

- **#12320** `fix(env): strip a byte-order mark before parsing an env file` — 08-24 13:23:51 UTC,
  `c393373fa59f`. Eleventh pass, surface 4. `strip_utf8_bom` appears twice in
  `src/config/env_directive/file.rs` on `main`.
- **#12375** `fix(cli): default to an editor Windows has, and name the one that failed` — 08-25
  10:31:29 UTC, `d4008a4c5943`. Fourteenth pass, surface 2. `DEFAULT_EDITOR` is on `main` and
  `src/cli/editor.rs` exists there, so both halves landed — the Windows default and the collapse
  of the duplicated launcher.
- **#12372** `fix(trust): refuse a path that does not exist instead of trusting its parent` —
  08-25 10:37:40 UTC, `7a2c3df05965`. Fourteenth pass, surface 1. The `Path does not exist` bail
  and `e2e/cli/test_trust_missing_path` are both on `main`.
- **#12363** `fix(self-update): do not fail the command when updating plugins fails` — 08-25
  11:08:37 UTC, `e6863dfd44f0`. `fn update_plugins` is on `main`. **The one that came from the
  user's own machine rather than a sweep**, and the one whose defect turned out to be reported
  already as discussion #8827.
- **#12341** `fix(generate): name a task stub after the task, not its file` — 08-25 11:09:47 UTC,
  `e309981921b6`. Thirteenth pass, surface 2. `display_name_to_path` is on `main`.
- **#12330** `fix(config): say what a backslash does when a config fails to parse` — 08-25
  12:07:58 UTC, `987b7cc2b628`, and it is `main`'s head as of this entry. Thirteenth pass,
  surface 1. `backslash` appears eight times in `src/config/config_file/diagnostic.rs`.

**Every pass from the eleventh to the fourteenth is now fully landed**, and the last three went in
within an hour of each other. **Forty-one merged across 2026-08-16..25.**

**None of the six is in a release yet**: `v2026.8.12` was cut 08-24 08:33 UTC, before all of them.
Whatever ships next carries a lot of Windows-shaped changes at once — worth remembering if
something regresses right after that release rather than assuming a single culprit.

**Merged 2026-08-24, 12:27–12:36 UTC (4) — four in nine minutes**, all marked ready by the
account owner and merged by jdx in the same pass:

- **#12334** `fix(ui): stop padding the last table column past its content` — 12:27,
  `01a892d9c11d`. Family B of the `generate` gaps, eight commands.
- **#12333** `fix(generate): name every file a generator writes` — 12:27, `1a78355769ee`.
  Family A.
- **#12329** `fix(config): name the config file once in a TOML parse error` — 12:35,
  `2dcf74e57b5f`.
- **#12327** `fix(config): report an unparseable settings file once, through the logger` — 12:35,
  `1e0eb270fea5`. The `cli_log_level` extension went in with it.

**Two of those were the parents of still-open stacks.** #12330 sat on #12329 and #12341 on #12333.
Nothing broke — both had been rebased onto `main` separately on 08-24 and carry their own replay —
but the "stacked on" wording in their bodies now points at merged PRs. **A merged parent is a
reason to re-read the child's diff, not to assume it shrank.**

**Merged 2026-08-23/24 (5) — all five shipped in `v2026.8.12`**, cut at 07:08 UTC on 08-24:

- **#12313** `docs(tasks): point extensionless pwsh tasks at MISE_TASK_DIR` — 08-23 17:34 UTC,
  `2a02059445d2`. Docs only, and **never a draft**: what #12277's declined review comment
  legitimately earned.
- **#12343** `refactor(cli): keep one copy of the task-flag escape rule` — 08-23 22:57 UTC,
  `e14c046de89a`. **The review-derived one**, declined twice as outside-diff and sent standalone.
  `fn escape_flag_arg` appears exactly once on `main`; the predicate is down to one copy as
  intended.
- **#12314** `fix(cli): report a cd target it cannot enter instead of panicking` — 08-24 01:00 UTC,
  `25a37270af21`. Eleventh pass, surface 2.
- **#12324** `fix(tasks): tell Windows users why a task file was skipped` — 08-24 01:20 UTC,
  `b6bf059e63bd`. Twelfth pass, surface 1.
- **#12325** `fix(config): strip a byte-order mark before reading a version file` — 08-24 01:57
  UTC, `77148ad10b44`. Twelfth pass, surface 2. **The late CodeRabbit finding landed with it**:
  `cached_idiomatic_version` and its unit test are both on `main`, so the asdf cache no longer
  serves a marked version past the fix.

**The merged head is not the commit I pushed, on any of the four drafts.** Each was rebased onto a
newer `main` before merge — #12343 went out at `c6411edf52c0` and merged from `107b3bfd3e63`, and
the same holds for #12314, #12324 and #12325. **So "byte-identical to what I pushed" is not the
check any more.** What I actually verified is content-level, on `main`, for the two things
reviewers had asked for. Say which of the two checks was run rather than implying the stronger one.

**Merged 2026-08-23 (3, earlier the same day):**

- **#12312** `fix(env): fold any spelling of PATH onto one key on Windows` — 11:42 UTC, merged by
  jdx as `9c2858338631`. **The eleventh pass's first surface, and the first of that pass to land.**
  It went in as `ready`, not a draft, which is the pattern for the ones that only add a rule the
  codebase already stated elsewhere.
- **#12274** `fix(task): run pwsh shebang file tasks on Windows` — 01:42 UTC, from the tenth pass.
  It changed `get_file_program_and_args`' signature, which is exactly what #12277 conflicted on;
  #12277 was rebased onto it the same day (`cc03c2562b96`), resolved by keeping #12274's shape and
  inserting the payload into it.
- **#12277** `fix(task): forward a file task's arguments through a -c shell` — 02:33 UTC, under an
  hour later. **The rebase held**: the two changes never touched each other, because
  `command_mode_script_payload` returns `None` for PowerShell and the `.ps1` staging never reaches
  a POSIX shell.

**#12277 merged byte-identical to what I pushed** — checked file by file against `cc03c2562b96`.
`task_executor.rs` hashes differently and that is **not** a review edit: #12273 (the confirmation
prompt refactor) landed on the same file. **Compare the hunk, not the file** — a whole-file hash
says "someone else also touched this", not "your change was rewritten".

**The conflict was predicted and it still cost a round.** Opening from main rather than stacking
was the user's call and the repo's norm; the cost is one rebase, which is small. **What made it
cheap was writing the overlap into the PR body up front** — nobody had to rediscover why.

Forty-four landed across 2026-08-16..26 — nineteen of them in the last three days — and one was
closed unmerged, so this section turns over inside a single session. **Read it back from `gh`
rather than trusting it.**
Draft-vs-ready is the user's call each time — **do not change it unilaterally**; #12080 was opened
draft and went ready without me, as #12055 and #12050 did before it, while #12078, #12089, #12117,
#12131, #12161, #12176, #12205, #12207 and #12267 were asked for as ready up front, and #12218 was
asked for as a draft and merged from it.

**Merged 2026-08-22 (2):** #12207 00:53 (`mise set --file` wrote files mise cannot read back),
#12267 02:27 (`mise doctor -J` never ran the new-version check — the ninth pass's finding).
**Both byte-identical to what I pushed**, and no late review on either — worth checking each time,
since #12117 and #12218 both changed during review.

**Queued, in the order they are worth doing:**

1. **Write up the PowerShell task-stub argument loss as a Discussion** — it is measured and
   corrected in this file already, and none of its three fixes is free, so it needs jdx's call
   before any of them can be built. The only queued item that does not need a fresh sweep.
2. **Continue the Windows sweep** — the fifteenth pass closed out the "decide about an entry
   without resolving it" family and the sixteenth found nothing. Unswept: `mise bootstrap`,
   `mise sync`, `mise watch`, and shims / `mise exec` `.cmd` resolution.

The docs sentence naming `MISE_TASK_DIR` became #12313. The `usage_*` / `USAGE_*` question is
**closed, not queued** — see its section: the wipe is correct under Windows' case-insensitive names,
and narrowing it is a design call for jdx.

**Declining a review's prescription does not discharge what it noticed.** #12277's second round
proposed staging the `.ps1` copy in the task directory; that was measured and rejected (the copy
becomes a discoverable task). But the _observation_ underneath — a task that reads a file beside
itself has no documented answer other than "rename it" — was real, and #12313 pays it. The comment
was against #12274's already-merged code, so it went into **its own PR rather than widening #12277**.

The old candidate list is spent (only the weak B1/B2/B3b/C3 rows remain, all re-measured and thin),
the ninth pass's held-back item (`%VAR%` in task arguments) was **closed as intended behaviour**, and
**the tenth pass's two findings are both merged** — #12274, and #12277 from the control that pass
turned up. A pass that yields a finding _and_ a usable control is worth more than one that yields a
finding: half the tenth pass's output came from a measurement taken only to prove the other one.

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
handler's _registration_ for the feature not working. That was wrong. The registration is fine; the
condition guarding it could never be true.

In PowerShell, `if (& native)` tests the command's **standard output**, not its exit code. Measured:

| native command              | exit  | stdout | `if (& …)` takes |
| --------------------------- | ----- | ------ | ---------------- |
| `cmd /c "exit 0"`           | 0     | —      | **FALSE**        |
| `cmd /c "exit 1"`           | 1     | —      | FALSE            |
| `cmd /c "echo hi"`          | 0     | `hi`   | TRUE             |
| `cmd /c "echo hi & exit 1"` | **1** | `hi`   | **TRUE**         |

`mise hook-not-found` answers with an exit code and nothing else — measured: exit 127 and empty
stdout for a bin no tool provides, and its install progress goes through `safe_eprintln!` to stderr,
so the success path prints nothing to stdout either. The condition was therefore false whatever
happened, and **auto-install on command-not-found has never worked on pwsh**. The last row is the
other half: a _failed_ command that printed something would have looked true.

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
calendar-shaped and `99` sorts _below_ `2026`. Worth remembering for any test that needs "a newer
mise".

#### Held back — now **closed as intended behaviour, 2026-08-22. Do not re-propose.**

**Task arguments containing `%VAR%` are expanded and word-split** under the default Windows shell:
`mise run t -- '%USERPROFILE%'` arrives as `C:\Users\Jam`, and `%PATH%` arrives as thirty-odd
arguments. Three controls pass it through untouched — running the binary directly, `mise exec --`,
and `shell = "pwsh -c"` — so only the `cmd /c` path mangles it. Only `%NAME%` naming a _real_
variable is affected; `%20`, `100%`, `%NOPE%` survive.

**The blocking question was answered and it killed the candidate.** mise _does_ build the command
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

### The `.cmd` launcher and arguments — **the first record here was wrong**, corrected 2026-08-23

Recorded earlier as "the generated `.cmd` launcher mangles `& ^ | %VAR%` in arguments", with the
batch workaround measured not to help and a native `.exe` named as the only real fix. **The control
was unfair and the conclusion did not survive re-measuring.**

The original comparison ran `mise run` **from bash** against `bin\task.cmd` **from bash**. Bash
quotes for the child differently than cmd re-parses `%*`, so the two sides had different first
parsers. Re-run with both invoked from the _same_ shell:

| argument   | via launcher    | `mise run` direct |      |
| ---------- | --------------- | ----------------- | ---- |
| `c&d`      | `[c]`           | `[c]`             | same |
| `i^j`      | `[ij]`          | `[ij]`            | same |
| `k\|l`     | (nothing)       | (nothing)         | same |
| `e%PATH%f` | `[eC:\Program]` | `[eC:\Program]`   | same |

**From cmd the launcher is identical to `mise run` over 12 argument shapes, 0 differing.** Those
losses are cmd's own line parsing, and they hit `mise run task c&d` typed at a prompt just as hard.
Quoting at the call site fixes `& ^ |` there — `"c&d"` arrives intact — because `%*` preserves the
caller's quotes.

**What is real, and it is narrower.** Invoked from PowerShell, where argv is passed directly:

| argument   | via launcher | direct       |
| ---------- | ------------ | ------------ |
| `c&d`      | `[c]`        | `[c&d]`      |
| `i^j`      | `[ij]`       | `[i^j]`      |
| `k\|l`     | (nothing)    | `[k\|l]`     |
| `e%PATH%f` | expanded     | `[e%PATH%f]` |
| `g"h`      | `[gh]`       | `[g"h]`      |

Five of seven differ. PowerShell hands argv straight to the child, so `mise run` keeps everything;
the `.cmd` is reached through `cmd /c`, whose parse of the line PowerShell built is where it is lost.
**Git Bash is unaffected** — it runs the shebang stub itself, and all four hostile arguments survive.

**Record — a control has to share every stage of the pipeline you are not testing.** Both sides must
be typed into the same shell. Comparing across shells measured the shells, not the launcher, and it
produced a finding that pointed at a redesign of something that was not broken.

#### The design space, all measured

| approach               | cmd                                  | pwsh `RemoteSigned` | pwsh `Restricted`                             | Git Bash | committed                |
| ---------------------- | ------------------------------------ | ------------------- | --------------------------------------------- | -------- | ------------------------ |
| today, `.cmd` only     | fine                                 | mangles             | mangles, but runs                             | fine     | 2 files                  |
| add a `.ps1` sibling   | unaffected — `PATHEXT` has no `.PS1` | **fixed**           | **fails outright**, no fallback to the `.cmd` | fine     | 3 files                  |
| native `.exe`          | fine                                 | fixed               | fixed                                         | fine     | **a binary in the repo** |
| `!CMDCMDLINE!` surgery | ?                                    | plausible           | plausible                                     | fine     | 2 files                  |

- The `.ps1` is preferred by PowerShell over the `.cmd` for a bare name, on PATH and by relative
  path, and all four hostile arguments survive. **But under `Restricted` it does not fall back** —
  measured: with both files present the command fails, where today the `.cmd` runs. That trades
  "arguments mangled" for "does not run", on machines that work now.
- `!CMDCMDLINE!` does carry the raw line: invoked from PowerShell, a probe batch saw
  `cmd.exe /c ""…\probe.cmd" c&d i^j k|l e%PATH%f"` — **arguments verbatim**. Delayed expansion is
  not re-parsed for metacharacters, so recovering them is possible in principle. It needs string
  surgery to strip the `cmd.exe /c "` prefix and the script path, and a way to tell that case from
  an interactive cmd (where `%CMDCMDLINE%` is the parent shell's own line, not the invocation).

### The registry's `os` lists go stale, and #12547 turns that into a false statement — #12552, **merged 2026-08-28**

A tool's `os = [...]` drops it from the request set before any backend is consulted. **59 of 980
entries carry one; 921 do not.** For an aqua-backed tool the list duplicates something aqua holds
**per version** while mise can only hold it **per tool** — and the duplicate is what rots.

**Five are rotten.** The first three came from reading aqua's files — a method `acli` then
disproved, below — so the list was redone as a **sweep of all 52 entries whose `os` line omitted
`windows`**: `mise install <tool>@latest` on Windows, then execute whatever landed on disk.

| tool                | run straight out of the install directory                              |
| ------------------- | ---------------------------------------------------------------------- |
| `entireio-cli`      | `entire.exe version` → `Entire CLI 0.10.2 / OS/Arch: windows/amd64`    |
| `go-swagger`        | `swagger.exe version` → `version: v0.36.5`                             |
| `httpie-go`         | `ht.exe --version` → `httpie-go 0.7.0`                                 |
| `gitsign`           | `gitsign.exe --version` → `gitsign version v0.17.1`                    |
| `grpc-health-probe` | `grpc_health_probe.exe --version` → `0.4.56; commit b5fef775b4ec749e…` |

Run from the install directory because the `os` list is precisely what stops `mise x` reaching them.
Each matches the `expected` string its own registry entry already declares.

#### The second step is the whole method — `mise install` exiting 0 proves nothing

**Ten entries installed with exit 0. Only two of them produced a Windows executable.** The other
eight unpacked none at all; `libsql-server`'s archive is a **source tarball** (`Dockerfile`,
`Makefile`, `LICENSE`). Had the sweep stopped at the exit code, the PR would have freed eight tools
that cannot run — a worse defect than the one being fixed, and one no reviewer could catch by
reading the diff.

Eight more hit the unauthenticated GitHub rate limit mid-sweep (`tmux`, `tridentctl`, `tuist`,
`umoci`, `xchtmlreport`, `xcodegen`, `xcodes`, `xcresultparser`) and were settled afterwards against
the releases API with `gh api`: **none publishes a Windows asset of any kind.** Correct as they
stand. A few could not be settled for reasons unrelated to Windows — `cocoapods` wants a ruby that
is not installed, `swift` overflowed the capture — and were left untouched. **Unsettled is not the
same as wrong.**

**Not wrong decisions — stale ones.** `entireio-cli`'s line dates to the commit that added the tool
(2026-02-27, #8378), when aqua did restrict it. The other **four** all trace to the same commit,
`178cafd57d27` (2026-01-25, #7820) — the mechanical split of `registry.toml` into 934 files. Nobody
judged those lines there; they were carried across, and they predate the split. Four of five stale
entries sharing one mechanical ancestor is the shape of the problem: **the data was never reviewed
per tool, so it cannot have been kept current per tool.**

**Why removed rather than set to all three:** absence is how 921 entries spell "runs everywhere",
and deleting hands the question back to the backend, which answers accurately per version.

#### Reading aqua's files does not predict what mise does

**The method that produced the candidate list was wrong, and only running the install caught it.**
`acli` looked like a sixth: fetching `pkgs/atlassian.com/acli/registry.yaml` from
`raw.githubusercontent.com` showed **no `supported_envs` anywhere** plus a `goos: windows`
override. Then:

```console
$ mise install acli@latest
mise ERROR Failed to install aqua:atlassian.com/acli@latest: unsupported env: windows/amd64
           (supported: ["linux/amd64", "linux/arm64", "darwin/amd64", "darwin/arm64"])
```

**mise carries its own snapshot of the aqua registry**, so the upstream file is not the authority
for mise's behaviour — and the survey the account owner supplied had `acli` right where this
reading had it wrong. **Check these by running the install, not by reading aqua.**

`kpt` was dropped too, for a different reason worth keeping: the word `windows` appears **six times**
in its aqua entry, all in superseded version blocks, while the current one is `[linux, darwin]` and
the CLI ships no Windows asset. Counting string matches decides nothing here.

Both are now **controls in the unit test** — they must stay restricted — so a later blanket
deletion of `os` lines fails instead of passing.

#### It matters more once #12547 is in

That PR makes mise say the restriction out loud instead of dropping the tool silently:
`… is not available on windows: mise's registry lists it for linux, macos only`. For these five
that sentence is false. A silent wrong answer became a stated one, which is the right trade only if
the data behind it is kept honest.

#### A merged e2e was coupled to the data, and freeing the tool would have hollowed it out silently

`grpc-health-probe` is the **fixture** in `e2e-win/exec_os_unsupported_tool.Tests.ps1`, added by
#12547 hours earlier. Removing its `os` line does not fail that test — it leaves it **green with
nothing to observe**, which is the failure mode a test cannot report about itself. Caught only by
grepping the tree for the tool name before touching the data; the sweep would not have surfaced it.

The fixture moves to `docker-slim` in the same commit: measured as genuinely restricted, and it
keeps the property the old one had of providing a bin under **another name** (`mint`), which is the
branch of the message that has to name both. `docker-slim` is now pinned in **two** places — a
control in `src/registry.rs` that asserts it stays restricted, and a `#[cfg(windows)]` test in
`src/shims.rs` pinning the exact strings the e2e matches — so a future registry edit fails in
`windows-unit` **by name** rather than quietly emptying a Windows e2e run.

**Generalisable:** before changing registry data, grep `e2e/` and `e2e-win/` for the tool name. Test
fixtures chosen for a data property are invisible dependencies on that data.

### windows/arm64 is refused backends that aqua itself accepts — #12560, **merged 2026-08-29**

mise **already states** that Windows arm64 runs amd64 binaries. It is in the aqua backend,
`is_platform_supported` (`src/backend/aqua.rs`):

```rust
// Windows ARM64 can typically run AMD64 binaries via emulation
if os == "windows" && arch == "arm64" {
    myself.insert("windows/amd64");
    myself.insert("amd64");
}
```

`backend_matches_platform` in `src/registry.rs` does not, **and it runs first** — a backend declared
`platforms = ["windows-x64"]` is filtered out before aqua is ever asked, and aqua would have said
yes. The vendored registry proves it: ImageMagick's current block is
`supported_envs: [windows/amd64, linux/amd64]`.

#### `MISE_OS`/`MISE_ARCH` make this measurable without arm64 hardware

Neither this machine nor mise CI has a Windows arm64 runner, and that looked like a blocker until
the settings overrides turned out to move **exactly** the decision under test:

| platform          | `mise registry imagemagick`                      | `mise registry android-cli`     |
| ----------------- | ------------------------------------------------ | ------------------------------- |
| windows/x64       | `aqua:ImageMagick/ImageMagick conda:imagemagick` | `http:android-cli`              |
| **windows/arm64** | **`conda:imagemagick`** — aqua dropped           | **(empty — no backend at all)** |
| macos/arm64       | `conda:imagemagick`                              | `http:android-cli`              |
| linux/arm64       | `conda:imagemagick`                              | (empty)                         |

imagemagick reaches aqua on **windows/x64 only**, which makes every other row a control. The same
trick drives the new e2e, so the whole rule is verified on an ordinary Linux runner. **Worth reusing:
when a bug is a routing decision, look for the setting that moves only that decision before
concluding the platform is untestable.**

#### The pitch was wrong before the research, and the research changed the scope

Presented as "mise contradicts itself in one place, small and testable". Reading all three layers
showed it is **one outlier among three** — `platform_aliases()` has no emulation rule either, so
fixing only the filter lets `android-cli` through and then fails at `No URL for platform
windows-arm64`. One failure traded for another.

`platform_aliases()` is used by every backend and by `mise lock`, so it was left alone;
`registry/android-cli.toml` declares its windows-arm64 URLs explicitly instead. **The scope question
went to the account owner rather than being settled silently**, because the three answers were
materially different pieces of work.

#### Two premises that broke during implementation

- **`Settings` is not imported at `mod tests` level** in `src/registry.rs` — each test brings its own
  `use super::*`. A module-level helper returning `Settings` does not compile; it needs the full path.
- **An e2e written from Windows measurements fails on Linux.** asdf is removed by `cfg!(windows)`, a
  **compile-time** check that `MISE_OS` cannot move, so `mise registry imagemagick` lists asdf on a
  Linux runner and not on a Windows one. Exact-equality assertions had to become containment ones.
  Also `assert "cmd" ""` only checks that the command succeeded — `assert_empty` is the one that
  checks for empty output.

#### What is deliberately not done, and not verified

No Rosetta rule: aqua declares none for macOS, and inventing one would be a new assumption rather
than a consistent application of an existing one. No alias tolerance either — the function's doc
comment already promises it is _"deliberately not alias-tolerant"_, and `windows-amd64` / `amd64`
still do not match. Both are pinned as controls.

**Not verified: whether an amd64 binary really runs on Windows arm64.** Everything asserted is the
routing decision. Said as much in the PR rather than letting the tests imply more than they check.

### `--dry-run` said "would install" for what cannot install — #12568, **merged 2026-08-30**

`mise install --dry-run acli@latest` answered `would install` and exited 0; the same command in the
same isolated environment, minus the flag, exited 1 with
`unsupported env: windows/amd64 (supported: ["linux/amd64", ...])`. The control is a tool that does
install — `mise install --dry-run jq@latest` — and its output is the same shape, so nothing about
the answer distinguished the two.

Placement rather than a missing check: `Backend::install_version` returns from its dry-run branch
before calling `install_version_`, and the judgement lives past that return in aqua's `validate()`.
A new `verify_install_feasible` trait method, default `Ok(())`, is called from the dry-run branch —
**only when an install would actually be attempted**, so an already-installed tool is not
re-examined. aqua reuses the install path by extraction rather than restating it: skipping the tag
lookup would select a different `version_overrides` block, and a check reading the wrong block would
call a working tool impossible, which is worse than the optimism it replaces.

**This changes what `--dry-run` exits with**, which is the point and also the risk; it is stated in
the PR rather than buried.

#### Three fixtures, and two of them were wrong first

The e2e went through three shapes, each corrected by a measurement:

1. **`android-cli` via `MISE_OS`/`MISE_ARCH`** — abandoned once a local `http:` fixture turned out
   to reproduce it with no network and no platform staging at all.
2. **`plan9-mips` as the declared platform** — failed in CI with `Http backend requires 'url' option`
   instead of `No URL for platform`. `list_available_platforms_with_key` enumerates nested keys by
   **probing known OS tokens**, so an invented platform is invisible and the list comes back empty.
   Replaced with `windows-x64`, which is never the host on the Linux-only `e2e` job.
3. **`mise install --dry-run` with no tool named** — for an already-installed toolset that prints
   `all tools are installed` and never reaches `install_version`. Naming the tool is what reaches
   the branch, which `test_cargo_install_options_slow` already did.

**Generalisable:** a fixture invented to be "obviously absent" can be absent in a way the code does
not model. `plan9-mips` was absent from the _enumeration_, not just from the machine.

### `create_dir_all` reported success for a directory it never made — #12573, **closed by the maintainer**

`mise install jq@nul` failed with a bare `The system cannot find the path specified. (os error 3)`,
naming neither the path nor the operation. Every control — `aux`, `prn`, `nulx`, `auxx`, `zzz` —
gave the ordinary `no asset released`, so the shape of the error pointed nowhere.

A rustc probe on the exact path shape mise builds:

```
installs/jq/zzz   create_dir_all=Ok   after: is_dir()=true
installs/jq/aux   create_dir_all=Ok   after: is_dir()=true
installs/jq/nul   create_dir_all=Ok   after: is_dir()=false
```

**`std::fs::create_dir_all` answers Ok and creates nothing.** `create_install_dirs` makes three such
calls and then writes `<CACHE>/<short>/<version>/incomplete` underneath, so the failure surfaced from
a `File::create` three calls away from the cause, unwrapped.

`create_dir_all` now verifies, after an attempt, that a directory is there — distinguishing "something
is in the way" (`symlink_metadata` succeeds) from "nothing was created", because saying the wrong one
sends the reader somewhere useless. Measured: for `nul` both `metadata` and `symlink_metadata` fail
with error 1, so it takes the second branch.

**`aux` created a directory perfectly well**, so the device-name note is added only to a failure that
already happened and is never used to refuse a name in advance. The tests state the fix as an
invariant — the function's answer must match what is on disk — rather than as a verdict per name,
because "reserved names fail" is a claim the `aux` measurement contradicts.

#### The blast radius landed exactly where the plan said it would

The plan named `create_dir_all` as a helper the whole codebase leans on and CI as the regression
surface. CI duly found one: `Path::new("plainstub").parent()` is `Some("")`, so every caller
ensuring a parent directory for a bare filename arrives with nothing, std answers Ok, and the new
check read that as its failure — six Windows and eight Linux e2e cases, each reporting
`failed create_dir_all: ` **with no path at all**.

**The input shape was predictable from the call sites and was not enumerated.** The investigation
fixated on one concrete trigger (`nul`) and never asked what else arrives at the same function. An
empty path was made exempt, restoring the previous behaviour for that input exactly.

#### Closed on 2026-08-30, and the closing comment names the replacement

> I don't think we should add Windows device-name handling and additional filesystem checks to this
> widely used helper for this case. The extra metadata calls also add overhead while holding the
> global directory-creation lock. **A narrowly scoped improvement to the marker-file error context
> would be preferable**, but this change is too broad and complex as written.

Three objections, and **all three are about `src/file.rs`** — none about the diagnosis. The third is
not a rejection at all: it names what to send instead, and **that half was already in the PR**, one
line in `src/backend/mod.rs`:

```rust
-        File::create(self.incomplete_file_path(tv))?;
+        file::create(&self.incomplete_file_path(tv))?;
```

`file::create` already ensures the parent and wraps with `failed create: {path}`. `create_dir_all`
keeps answering Ok for `nul` — that stays unfixed — but the failure now names the file instead of
being a bare `(os error 3)` three calls from its cause.

**The lesson is about the shape of the submission, not the finding.** The PR bundled a general
invariant on a hot shared helper with a Windows-specific note and a one-line diagnostic improvement.
Two of those were arguable; the third was not. **Sending the arguable part first buried the part
that was going to be taken.** A one-line change with an e2e would have landed on its own, and the
invariant could then have been argued separately with the diagnostic already in.

**Also worth keeping: the objection about overhead was half right, and worth stating precisely
rather than defending.** The added `is_dir()` ran inside `if !path.exists()`, so per _creation_
rather than per _call_ — but it was still inside the global lock, and that is the reviewer's point.

Resubmitted as **#12624** and **merged 2026-09-01 with no changes requested** — the one line, plus
one Windows e2e. The broad version was refused and the narrow one taken as written, which is the
cleanest split in this file between "wrong" and "too much". Re-measured on `v2026.8.15` first
rather than reusing the `2026.8.14` numbers, and the reproduction is unchanged. Two details the
new PR turns on:

- **No call is added on any path.** `file::create` does `create_dir_all(parent)` for the same
  directory the line two above already created, so nothing new runs inside the lock. Saying that
  explicitly is what answers the second objection.
- **The e2e asserts mise's own words, not the OS error text.** `os error 3` renders as
  指定されたパスが見つかりません。 on this machine — a localised string is not a test fixture.
  `failed create`, `incomplete` and `nul` are all mise's.

### `bins` is a discovery hint, not an install-time invariant — #12569, **closed by the maintainer**

`mise install` reports success for an install that produced nothing usable: of ten tools that exited
0 during the Windows sweep, only two produced a Windows executable, and `libsql-server` unpacked a
source tarball. Nothing verifies afterwards — `bins` is read only by `provides_bin` for shims, and
`test = { cmd, expected }` belongs to `mise test-tool`.

The PR warned when none of a tool's declared `bins` was present. **The maintainer closed it on the
premise**, and the reasoning is worth keeping:

> `bins` is intentionally only a hint for command discovery and needs to remain that way. Registry
> entries cannot vary `bins` by OS, and the binaries shipped by a tool can also change between
> versions, so treating this field as an install-time invariant will inevitably produce incorrect
> warnings. Platform/archive correctness should be handled by the backend or the specific registry
> entry rather than inferred from `bins`.

Both reasons are visible in the type: `pub bins: &'static [&'static str]` is one flat list per tool,
with no platform and no version dimension.

**This is the shape of a measurement that cannot generalise.** 31 of 31 installed tools resolved a
declared bin — zero false positives — and the PR said plainly that 31 does not represent the 937
entries declaring `bins`. What it could not say was _why_ the sample was unrepresentative. The
maintainer named the two structural reasons, neither of which the sample could ever have exposed,
because every tool in it has a stable cross-platform bin list.

**The observation is not disputed, only the detector.** The suggested direction — let the backend or
the individual registry entry judge platform/archive correctness — is where a future attempt belongs.

### A release's source archive won by elimination — #12578, **closed by the maintainer**

`mise install libsql-server@latest` exited 0 on Windows and unpacked a **source checkout** —
`Cargo.toml`, `CODE_OF_CONDUCT.md`, nothing runnable. The release builds only for linux and darwin;
`AssetPicker::pick_best_asset` keeps assets scoring `> 0`, and on a platform the release skipped:

| asset                        | os                  | format               | total  |                      |
| ---------------------------- | ------------------- | -------------------- | ------ | -------------------- |
| `…-unknown-linux-gnu.tar.xz` | **−100** (other OS) | +11                  | neg    | dropped              |
| `sqld.rb`, `…-installer.sh`  | 0                   | 0 (not an archive)   | **0**  | dropped, needs `> 0` |
| `source.tar.gz`              | **0** (names no OS) | **+10** (an archive) | **10** | **picked**           |

**Nothing subtracts for a source tarball.** Where real assets exist it loses to them by 100; where
they do not, it is the last thing above zero.

Closed with one sentence:

> seems like it could have false positives

The rule was `stem == "source" || ends_with("-source") || ends_with("_source")`, with a boundary
test pinning `sourcery-2.2.7-macos-arm64.zip`. **That was not enough**, and arguing the boundary
tests would have missed the point: the objection is about the _class_ of rule, so the answer is to
shrink the class, not to defend it. Narrowed to `stem == "source"` — one exact name, which is what
cargo-dist emits and what `libsql-server` ships — the surface becomes a filename that cannot
plausibly be a binary distribution.

**Generalisable: "could have false positives" is answered by making the rule smaller, not by
adding tests that show it does not.** A test says "not these"; a narrower rule says "not possible".

Resubmitted as **#12625**, matching `stem == "source"` only — and **closed too**: `this should not
be part of the backend`. Then **#12632** put it in the registry entry instead (`platforms` on the
github backend, verified on a real Windows build in fork CI) and was closed as well: `don't think
it's worth it, especially with all the tests`.

**Four attempts, one tool, one answer.** See the scope section under "Open PRs". Narrowing the rule
answered the words of the #12578 refusal and missed what it was about: the objection was never to
the rule's width, it was to mise carrying a fact about `libsql-server` at all.

### `mise env -s fish` shredded PATH on Windows — #12582, **merged 2026-08-30**

`mise env -s fish` printed `set -gx PATH C '/aaa/bin;C' '/bbb/bin;C' …` — every drive letter severed
from its path — and `mise hook-env -s fish`, the real activation path, did the same. All six other
shells were correct on the same config, which is what made it a one-shell defect rather than a
platform one.

`set_env` matched the literal `"PATH"` and split on `':'`, while `prepend_env` and `move_prepend_env`
**eight lines below in the same file** already used `env::PATH_KEY` and `env::split_paths`. Only one
of the three was left behind, and its PATH branch had no test at all: `test_set_env` covered
`set_env("FOO", "1")` and nothing else, and fish's `mod tests` is `#[cfg(all(test, not(windows)))]`,
so a Windows test could not go in it — hence a sibling `mod windows_tests`.

**On unix the change is provably neutral**: `split_paths` splits on `:` there and `is_path_key`
reduces to `key == "PATH"`, so both helpers are the identity on what the code did. That claim is
what made the diff easy to review, and it is worth reaching for deliberately.

One behaviour did move, and it was measured rather than assumed: `std::env::split_paths` yields an
empty entry for a trailing `;`, which a Windows PATH usually has, and an empty element of a fish list
is the current directory. Empty entries are now dropped, as `prepend_env` and `env::split_colon_list`
already did.

### `list_available_platforms_with_key` probed a grid instead of reading the keys — #12580, **merged 2026-08-30**

A typo'd or wrongly-separated platform key (`lnux-x64`, `linux_x64`) produced
`Http backend requires 'url' option` — telling an author **who wrote a `url`** to provide one, with
`Available:` empty so nothing said which part was not understood. The enumeration walked
`BINARY_OS_TOKENS × BINARY_ARCH_TOKENS`, so a key outside the grid was invisible.

Diagnostic only — one production caller, `HttpOptions::url_platforms`, feeding one message.

**The review added the part that was missing:** reading the keys is not enough, the _value_ has to
be one the lookup would accept. Walking the table directly would have started offering
`platforms.linux-x64.url = { href = … }` as available while the lookup still rejected it. Gated on
`scalar_value_to_string`, the same function the lookup uses.

### elvish had four defects in one file — #12584, **merged 2026-08-30**

Started as "the PATH separator is `:` on every host" and ended as four, all from one module reaching
for `shell_escape::unix::escape` and bash's idea of how quoted words compose:

1. **`'v'':'` is one string, not two.** Elvish reads `''` as one literal quote — _"they represent one
   single quote, instead of terminating a single-quoted string and starting another"_ — so the
   separator written as its own quoted word merged into the value as `':`.
2. **The separator was `:` on Windows too.** A Windows path is always quoted (drive colon,
   backslashes), so 1 and 2 fired together on every Windows activation.
3. **`'` and `!` arrived with a backslash.** `escape` writes bash's `'\''` and `'\!'`; a backslash is
   an ordinary _bareword character_ in elvish, so `a'b` became `a\'b` — **not a parse error**, just a
   wrong value. pwsh and xonsh already had their own escapers; elvish did not.
4. **`set_env` rewrote `\n` into a newline.** Found by CodeRabbit. `C:\nodejs` reached elvish as
   `C:` + newline + `odejs`. No other shell in the directory does this.

**What made 1 and 3 findable without running elvish: the language reference, quoted.** elvish is not
in mise's registry and `e2e/shell/` has never had an elvish test, so every claim about mise's own
output was measured and every claim about how elvish reads it was cited. Saying which was which, in
the PR body, is what let it be reviewed at all.

**The lesson from 4: a pre-existing line inside a function you are already fixing is in scope.** The
first pass listed it as an out-of-scope limit; the bot was right that it belonged in the same PR,
because it is the same defect class the PR is named for.

### aqua-registry caught up, and three registry `os` lists are now stale — **next up**

The user landed **17 Windows-support PRs in aquaproj/aqua-registry** on 08-28..30 (one still open,
`#59572` yamlscript). `v2026.8.15` refreshed the vendored snapshot: `6d546dfab…` → `9031eee36f…`.

Read out of `vendor/aqua-registry/registry.yml` on current `main`, not assumed:

- `atlassian.com/acli` — **`supported_envs` is gone**, and it carries a `goos: windows` override
- `grafana/mimir/mimirtool` — no `supported_envs` on the base entry; the `- linux` still in the file
  is inside a `version_overrides` block for two specific rc versions

So `registry/acli.toml`, `registry/mimirtool.toml` and `registry/specstory.toml` still carry
`os = ["linux", "macos"]` that no longer matches what installs — the exact shape #12552 fixed for
five other entries.

**`acli` is also a control in #12552's own test** (`src/registry.rs`, the
`for short in ["acli", "docker-slim", "kpt"]` loop asserting `!is_supported_os()`), with a comment
citing the `unsupported env: windows/amd64` measurement. Removing its `os` line **fails that test**,
so the control and its comment move in the same commit. `docker-slim` stays — it is also the fixture
in `e2e-win/exec_os_unsupported_tool.Tests.ps1`.

Method is #12552's: install on Windows, then run the installed binary. Do not infer from the
snapshot alone.

### Windows, twentieth pass — 2026-08-28 → #12550, and a diagnosis that took three attempts

One finding out of seven surfaces, and getting to its cause was the work.

#### The finding — a long `MISE_DATA_DIR` fails installs with a bare `os error 3` — #12550

Bisected, one variable:

| data dir | download destination | result     |
| -------- | -------------------- | ---------- |
| 182      | 222                  | ok         |
| 232      | 272                  | os error 3 |
| 342      | 382                  | os error 3 |

Threshold between 222 and 272 — `MAX_PATH`. **Creating the directory with the `\\?\` prefix is not
the variable**: a 161-character directory made the same way installs fine. `LongPathsEnabled` is
`0` here, the Windows default, so CI reproduces it.

**The explanation already existed and the downloader did not reach it.** `windows_io_hint` handles
exactly this, and `PreparedAtomicWrite::commit` documents the cause _and_ the measurement —
"`tempfile`'s persist does not get the extended-length path handling `std::fs` applies … breaks at
a 253-character target while `fs::rename` on the same tree succeeded at 415". `with_io_hint` had
**two** call sites, neither on the download path, so all three of `PartialDownload`'s temp-file
operations dropped the error to a bare `io::Error`. Same shape as #12547.

#### How the diagnosis went wrong twice, and what fixed it

1. **Guessed `create_dir_all`.** The failing tree always showed `downloads\jq` present and
   `downloads\jq\1.8.2` absent, which points straight at it — but `file::create_dir_all` wraps its
   errors and no such frame appeared. Dead end.
2. **Disproved my own premise.** A standalone `rustc` probe created a 372-character tree and a
   404-character file without complaint, so `std::fs` was not the limit. **Reported that the
   premise had collapsed and stopped**, rather than building on it.
3. **The old debug binary settled it without a rebuild.** `target/debug/mise.exe` from 2026-08-12
   was still there, reproduced the failure, and printed the context the release build had dropped:
   `failed to persist temporary file`. That named `tempfile`, and the rest followed from reading.

**A stale debug build is worth trying before paying for a fresh one** — it costs one command, and
here it replaced a build the user had already approved. What it cannot do is prove where _current_
code fails, so the site was confirmed by reading current `src/http.rs` afterwards.

**Which of the three temp-file operations fires first was never pinned down.** They are consecutive
steps on the same directory and the failure looks identical from any of them, so all three were
covered rather than guessed between — and the PR says so instead of implying a precision the
diagnosis did not reach.

#### What review changed

- **greptile P1, correct**: the create site measured the _directory_ while the name `tempfile`
  generates is 27 units longer, and the hint's threshold has only a 16-unit margin — a real window
  where the temp path is over the limit and the hint stays silent. **I had spotted this while
  writing it and talked myself out of it with arithmetic that did not work.** Now measured against
  a `.mise-download-state.XXXXXX` stand-in, with the prefix a named constant.
- **greptile P1, declined**: the same argument for the two persist sites. Their gaps are 11 and at
  most 10 units, inside the margin `windows_io_hint`'s own comment says is there for exactly this.
  **The number I gave first ("at most 6") was wrong**; the bound is 10, which happens not to change
  the conclusion. Engaging with it found a worse problem: the test asserting
  `placeholder.len() == PREFIX.len() + 6` was **true by construction** and pinned nothing. It now
  compares against a name `tempfile` actually generates.
- **CodeRabbit, correct**: an empty `catch` around the fixture cleanup. Not a style nit here — a
  long-path tree left in `TestDrive` makes Pester's own teardown fail the run with every test
  green, the #12510 failure mode, and the swallowed exception was the only thing that would have
  explained it.

#### Measured dead — do not re-investigate

| candidate                                                    | result                                                                                  |
| ------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| `mise run BUILD` when the task is `build`                    | exit 1 with `Did you mean one of these? - build`. Correct                               |
| a toml task `Build` beside a file task `build`               | both resolve and run separately. Correct                                                |
| replacing a running binary (handle held, `--force`)          | already excellent: "A file under it is in use. A program started from this directory …" |
| `mise trust` on a directory whose name ends in a dot         | already excellent, and explains that trust-root resolution is lexical                   |
| `mise unuse`, `mise completion pwsh` (parsed), `en`, `watch` | fine                                                                                    |
| reserved device names as a version (`con`, `aux`)            | both work; only `nul` fails, with `os error 1`. Too unreachable to file                 |

#### windows/arm64 is closed, by construction rather than by testing

The standing "amd64 only" caveat is answerable from source. `is_platform_supported` carries an
explicit arm64 case — _"Windows ARM64 can typically run AMD64 binaries via emulation"_ — that adds
`windows/amd64` and `amd64` to the match set. **arm64's set is a strict superset of amd64's, so the
blocked list cannot grow there**, and nothing in the survey's 85 declares a bare `arm64`.

mise's own `backend_matches_platform` has **no** such rule, so `windows-x64` in a `platforms` list
excludes arm64 where aqua would have allowed it. Three entries are arch-qualified for Windows:
`android-cli` (documented — Google ships no arm64 build), `azure` (an explicit `windows-arm64`
override, its comment noting it was _"Verified on a `windows-11-arm` runner"_), and **`imagemagick`,
whose `platforms = ["windows-x64"]` carries no explanation** and sends arm64 to conda. Measured with
`MISE_ARCH=arm64`, which does reach that filter. Left as a question, not filed: whether aqua's
ImageMagick asset runs under emulation is not something this machine can answer.

**mise CI has no Windows ARM runner** — no `windows-11-arm` in any workflow — so this area is only
ever verified by hand.

#### Three process mistakes from this pass

- **A probe wrote into the real data directory.** `mise link` was run with `MISE_CONFIG_DIR` and
  `MISE_TRUSTED_CONFIG_PATHS` isolated but **not `MISE_DATA_DIR`**, leaving `con` and `aux`
  junctions in `installs\node\`. Removed with `mise uninstall` once noticed. **Isolate all four
  variables, mechanically, in every probe** — later probes in this pass do.
- **`-f` binds to the last string of a concatenation.** `("a {0}" + "b" -f $x)` leaves `{0}` in the
  first fragment. Caught by rendering the message before committing; it was going into a warning
  that only prints when a run has already failed elsewhere.
- **Reading `conclusion` as a failure when it is an empty string.** A `jq` filter of
  `!= "success" and != null` labelled _running_ jobs FAILED, and I investigated two "failures" that
  did not exist. Compare against the empty string too, or read `status` first.

**The survey is not mine and is not recorded here as measured.** The account owner supplied a report
covering all 2,288 `aqua-registry` packages: `supported_envs` parsed from every block, 283 candidate
tools reachable through `mise registry`, **all 283 run through a real `mise install`**, and the 85
that failed split into **20 where upstream does ship a Windows binary** (registry gaps — PR material
for `aquaproj/aqua-registry`, e.g. `atlas-community`, `amazon-ecs-cli`, `dyff`, `lima`, `mimirtool`,
`mold`, `rustic`, `terraformer`) and **65 where upstream ships none** (macOS-only Xcode tooling,
Linux-kernel tooling, shell scripts). Six more pass `supported_envs` and then fail on an asset-name
mismatch.

Two things from it are worth keeping even if nothing else is acted on:

- **A bare GOARCH in `supported_envs` matches every OS**, so `[darwin, linux, amd64]` **includes
  Windows**. 161 packages use exactly that triple. Grepping for the string `windows` to decide
  support gives a huge false-negative rate — `helm`, `yq`, `trivy`, `kustomize`, `k9s`, `minikube`,
  `chezmoi`, `pulumi` and `packer` are all in that shape and install fine. aqua's own documentation
  does not spell this out.
- **`aws-cli` is not a gap to file.** AWS ships only `AWSCLIV2.msi` for Windows, and the documented
  PowerShell one-liner is an MSI wrapper (`msiexec /i ... /qn`). aqua unpacks archives; an installer
  that manages PATH itself has no place in a shim/symlink version-switching model. Point Windows
  users at `winget install --id Amazon.AWSCLI`.

#### What is mise's, measured here

The report's one mise-side claim checked out, but the control changed what it means, and a second
defect turned up next to it. All on 2026.8.14 windows-x64, `MISE_DATA_DIR` isolated:

| command                                      | result                                                                     |
| -------------------------------------------- | -------------------------------------------------------------------------- |
| `mise install --dry-run aws-cli@latest`      | exit 0 — `⇢ would install`                                                 |
| `mise install aws-cli@latest`                | exit 1 — `unsupported env: windows/amd64 (supported: ["linux", "darwin"])` |
| `mise use --dry-run aws-cli@latest`          | exit 0 — `would install` **and** `would update mise.toml`                  |
| **`mise x aws-cli@latest -- aws --version`** | exit 1 — **`cannot find binary path`**                                     |
| `mise install --dry-run aws-cli@99.99.99`    | exit 0 — `⇢ would install`, for a version that does not exist              |

**The last row is why the dry-run finding is weaker than the report frames it.** `--dry-run` does
not check that the version exists either, so "it does not evaluate `supported_envs`" is one instance
of "it does not check feasibility at all" — arguably a plan preview working as designed. A PR would
have to argue that from the start rather than presenting an omission.

**The fourth row is the real one, and it is our usual shape.** `mise install` and `mise use` both
produce a good message from the aqua backend; `mise x` produces the opaque `cannot find binary path`
that discussion #11183 was about on the shim side. Root cause traced:

- `registry/aws-cli.toml` carries `os = ["linux", "macos"]`, so
  [`BackendArg::is_os_supported`](src/cli/args/backend_arg.rs:723) is false here.
- [`ToolRequestSetBuilder::is_disabled`](src/toolset/tool_request_set.rs:208) folds four unrelated
  reasons together — unknown backend, asdf-on-Windows, **OS unsupported**, user-disabled — and the
  tool is removed from the set.
- `should_report_unknown_tool` then deliberately excludes it (`requests.iter().any(is_os_supported)`),
  correctly, because it is not unknown — **and nothing else reports it**. The tool the user named on
  the command line is dropped in silence, no install is attempted, and the bin is simply missing.

So **mise knows the answer, in its own registry, and only some commands use it.** The fix went
next to [`exec_resolution_hint`](src/shims.rs:981), which already appends "installed but not
configured" to that same failure — **#12547, merged 2026-08-28**.

**The same registry knows it well one branch over.** When _every_ backend is filtered out rather
than the tool being dropped by its `os` list, the message was already right — measured with
`MISE_ARCH=arm64`, which makes `android-cli`'s only backend unavailable:

```console
$ mise tool android-cli
mise ERROR android-cli is in the mise tool registry but none of its backends
           (http:android-cli) are supported in the current configuration
```

Named tool, named backend, and it says the exclusion is configuration rather than a missing file.
Only the `os`-list path lacked an equivalent.

**That control was itself a bug, and it took another pass to see it.** `android-cli` having no
backend on arm64 was used here purely as a way to reach a message — the condition was read as the
setup, never as the finding. On windows/arm64 it is wrong: the machine runs amd64 binaries, mise says
so in `is_platform_supported`, and the registry filter refuses anyway. That is #12560. **A condition
manufactured to demonstrate something else is still a real state of the program; worth asking
whether it should exist at all before moving on.**

#### The e2e fixture assumed a machine, not the runner

**#12547's first Windows e2e failed, and the product code was fine.** It used `aws-cli` and asserted
`mise x aws-cli -- aws` fails — but the GitHub `windows-latest` image **ships the AWS CLI**, so `aws`
resolved, `mise x` succeeded, and three assertions fell over. This machine has no `aws`, which is
exactly why local reasoning missed it.

**A fixture that depends on a binary being absent must be checked against the CI image, not the
developer's box.** Replaced with `grpc-health-probe` (also `os = ["linux","macos"]`, and its bin
`grpc_health_probe` differs from the tool name, so it exercises the "names both" branch too), plus
an `It` that asserts the absence itself — a runner that starts shipping these now fails saying so
instead of looking like a regression in the message.

#### What the survey led to

- **#12547** — merged. The opaque `mise x` failure.
- **#12549** — `pre-commit` routed to `pipx` on Windows. aqua serves a `.pyz` zipapp it cannot run
  there, and `aws-sam` had already solved the identical case.
- **#12552** — merged 08-28. Five registry `os` lists that no longer match what installs, from a
  sweep of all 52 candidates. See the section above, including why reading aqua's files is not how to
  find these and why `mise install` exiting 0 is not enough on its own.
- **#12560** — windows/arm64 refused backends aqua accepts. Came out of the same survey work, one
  layer below: this one is not about a tool's data but about the filter that runs before the backend.

**The survey's category A is already partly obsolete**: `acli` was listed as an aqua gap, and the
aqua registry upstream has since dropped the restriction — but the snapshot mise carries has not,
so it is neither an aqua PR nor a mise data fix yet. Worth re-checking before acting on that list.

### Windows, nineteenth pass — 2026-08-28 → #12510, and five candidates measured dead

One finding out of six surfaces, and the finding is a **decision of mine that had to be narrowed**.

#### The finding — a link loop under a task directory takes down every task command — #12510

Task discovery walks with `follow_links(true)`, deliberately: a shared task directory linked into a
project works, measured (`mise-tasks/lib` → elsewhere, `mise run lib:shared` → `FROM_SHARED`). When
the link forms a loop, walkdir's loop error was collected as fatal.

Same tree, one junction apart, nothing else changed:

| command                                           | before        | after `tasks\current -> tasks` |
| ------------------------------------------------- | ------------- | ------------------------------ |
| `mise tasks ls`                                   | exit 0 — `ok` | **exit 1**                     |
| `mise run ok` (a task file)                       | exit 0        | **exit 1**                     |
| `mise run toml_task` (**defined in `mise.toml`**) | exit 0        | **exit 1**                     |

```
mise ERROR File system loop found: ...\tasks\current points to an ancestor ...\tasks
```

**The third row is the finding.** A task with no file behind it, sharing nothing with the walk, goes
down with it. Mutual links (`a -> b`, `b -> a`) do the same. `mise env` and `mise ls --current` stay
exit 0, so the blast radius is task loading.

The same walk already answered three ways: a plain link is followed and works, a **dangling** link
is skipped, a **looping** link failed everything.

#### It was my own decision, and checking that first is the point

`test_collect_task_files_preserves_symlink_loop_errors` pinned the fatal behaviour, and `sl annotate`
put it in `38522b5be161` — **#11574, mine**, whose body says _"Other traversal errors remain fatal"_
and names _"permission, **loop**, and other filesystem errors"_. Had I not looked, the PR would have
read as fixing an oversight rather than narrowing a stated position.

What justified narrowing it: **#11574's own problem statement applies unchanged** — it "aborted all
task commands ... even when other tasks were healthy" — and loops separate from the rest on a
principle the others fail. From walkdir's source, `check_loop` compares against the directories
**already on the walk stack** and errors only on a match, so everything under the link has been
visited through the real path: **skipping is lossless**. A permission or I/O error hides a whole
subtree and stays fatal. `vfox.rs::lua_sources_fingerprint` had already reached the same conclusion
in a comment — _"Symlink cycles surface as errors here and are skipped below"_.

**The boundary is narrow on purpose.** `ln -s loop loop` fails in `fs::metadata` with ELOOP before
walkdir reaches its ancestor check, so it arrives as an io error and stays fatal — nothing was
reached through it either. Verified from walkdir's source (`follow()` calls `DirEntry::from_path`
before `check_loop`) rather than guessed, because if the premise were wrong the existing test would
have turned a narrowing into a full reversal. The test is renamed to
`..._preserves_unresolvable_symlink_errors`, since its old name now describes the case that is
skipped.

#### What review changed

One CodeRabbit finding, **valid**: the control compared the two listings without capturing
`$LASTEXITCODE`, so two identical _failures_ would have satisfied it — the equality would read as
"the loop changes nothing" while nothing had been listed at all. Both exit codes are now captured
immediately and asserted before the comparison.

**A junction in `TestDrive` fails the Pester run with every test in it green.** The fix's own
comment records the mechanism: Pester hands the drive back by enumerating it with
`Directory.GetFileSystemEntries(AllDirectories)`, which follows the junction and does not come back
out. `AfterAll` now deletes **the link, not what it points at**
(`[System.IO.Directory]::Delete($junction, $false)`). Worth remembering for any future Pester
fixture that makes a junction — the failure surfaces in the framework, not in a test, so it does not
look like the test's fault.

#### Measured dead — do not re-investigate

| candidate                               | result                                                                                                                                |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `mise activate` from **cmd.exe**        | the message is already good — names `MISE_SHELL` then `SHELL`, says PowerShell and cmd set neither, lists the supported shells        |
| `mise env` from **cmd.exe**             | emits pwsh syntax, and that is **deliberate and documented**: `fallback_shell()` in `src/cli/env.rs` carries the reasoning and a test |
| drive-relative `_.file = "C:rel.env"`   | identical to the plain relative form                                                                                                  |
| a **dangling** junction in `mise-tasks` | skipped; `tasks ls` and `run` both exit 0 — already correct, and the contrast that made the loop case a defect                        |
| a **plain** junction in `mise-tasks`    | walked into, its tasks run — already correct                                                                                          |
| CRLF shebang (`core.autocrlf=true`)     | measured in the previous pass and clear; `mise run` handles LF and CRLF identically                                                   |

**One candidate could not be measured and nothing is claimed about it:** a mise data directory whose
name contains `;`, the Windows PATH separator. The probes never got the `;` onto an emitted PATH —
`mise link` puts the _link_ path there, not the target — so the question is untested. Exotic enough
to be low priority; if it is picked up, start by getting a tool actually installed under such a
directory.

### The `file`-mode shim destroys arguments too — #12502, **merged 2026-08-27**

Not a sweep. This was the top candidate left over from the seventeenth pass, **blocked until #12463
merged** and unblocked the moment it did: `recover_launcher_args`, `split_command_line` and
`LAUNCHER_ARGS_SENTINEL` are all on main now, so the shim body could reuse them by name.

`windows_shim_mode = "file"` writes a `<tool>.cmd`, and cmd parses the whole line before `%*`
expands — the same mechanism #12463 fixed for task-stub launchers, on a surface nobody had checked.
Measured, same six shapes through each mode:

| mode                                     | writes                    | wrong |
| ---------------------------------------- | ------------------------- | ----- |
| `exe` (default) / `hardlink` / `symlink` | `<tool>.exe`              | 0/6   |
| `file`                                   | `<tool>` and `<tool>.cmd` | 6/6   |

`c&d` → `c` then cmd ran `d` (exit 255); `i^j` → `ij`; `e%OS%f` → `eWindows_NTf`; `a>b` → gone, and
a file called `b` appeared; `a<b` → `a`; `^caret` → `caret`.

**Reachable without asking for it.** [`effective_shim_mode`](src/shims.rs) falls back to `"file"`
when `mise-shim.exe` is not beside the binary or on PATH — measured with a lone `mise.exe`. So a
default-settings install that lost its `mise-shim.exe` lands here silently. Unreported upstream:
#8045's motivation lists spawnSync ENOENT, batch control flow, `where.exe` and package-manager
compatibility — **not** argument loss — and `e2e-win/shim.Tests.ps1` checked file shape only.

**The two bodies are kept separate, with a test that says so.** The shim needs its recursion guard
first, and `is_generated_launcher` pins the launcher body's line layout by index; coupling them
would make stub recognition depend on shim code. Instead
`the_shim_body_carries_the_same_recovery` compares the part they share line for line, with only the
label and the command normalised away. The protocol _names_ were already shared — they come from
`src/env.rs` constants — so only the shape could drift.

**Folded in:** the `mise-shim.exe not found …` warning ran once **per shim** (three tools → eight
copies). `warn_once!` dedups on the formatted message, and this one embeds `mise_bin`, so it is now
one line.

**The e2e puts the load-bearing premise under test rather than under assumption.** The recovery
matches the shim's own full path against the raw command line, so it only works if PowerShell puts
the resolved path on the `cmd /c` line. #12463's e2e only ever invoked launchers by relative path;
shims are invoked **by bare name off PATH**, which is a different resolution. So the test invokes it
that way — if PowerShell had used the bare name, the guard would decline and the fix would silently
do nothing. It does not.

#### Three bot findings, and the third was a defect in committed code

1. **greptile P2 — `AfterAll` ran `mise settings unset windows_shim_mode`**, clearing a preference
   the developer may have set. Valid, and **reading the old value back is not the fix**:
   `mise settings get` cannot distinguish "never set" from "set to `exe`", so restoring it would
   turn an unset setting into an explicit one. `settings.toml` gives the setting
   `env = "MISE_WINDOWS_SHIM_MODE"` and every `mise reshim` is a fresh process, so the mode is now
   switched through the environment and **nothing persistent is written at all**. The
   `windows-e2e` job sets `MISE_DATA_DIR` and `MISE_CACHE_DIR` but **not** the config dir, so this
   was not isolated on CI either. `e2e-win/shim.Tests.ps1` still has the same `unset` and predates
   this PR — left alone, unrelated to shim arguments.
2. **greptile P1 — the cleanup uninstalls `node@e2e-shimargs` unconditionally.** The stated case (a
   developer using that exact version name) is not real — the file next door owns `e2e-broken` and
   `e2e-kept` the same way. **The reachable case is a run of this suite that died before
   `AfterAll`**: `$TestDrive` is a new directory each run, so the stale link points elsewhere,
   `link.rs` takes the `!file::is_symlink_to` branch, and an unforced `mise link` then fails for
   **every later run**. `--force` makes a rerun recover.
3. **CodeRabbit — `[Environment]::SetEnvironmentVariable('NAME', $null, 'Process')` does not remove
   the variable.** Measured on PowerShell 7.6.5: `Test-Path Env:\NAME` stays `True` and the value
   becomes `''`. PowerShell binds `$null` to that `[string]` parameter as an empty string, so
   .NET's "a null value deletes the variable" rule never fires. `MISE_WINDOWS_SHIM_MODE=""` is not
   unset — `effective_shim_mode` would hand `add_shim` a mode matching none of its arms.
   **This contradicts the probe-hygiene note in the eighteenth pass below, which has been
   corrected.** In committed scripts use `Remove-Item Env:\NAME -ErrorAction SilentlyContinue`.

**Verified by name, not by conclusion.** Fork CI: `windows-unit` shows all four new tests as
`test … ok` among `2753 passed; 0 failed`, and `windows-e2e` shows
`[+] e2e-win\shim_args.Tests.ps1` inside `Tests Passed: 227, Failed: 0`. The control
(`the old body did not`) passed too, so the file is not one that would pass against the old shim.
The suite's single `Skipped: 1` is not from this file — it contains no `Set-ItResult` or `-Skip`,
which was checked rather than assumed.

### The encoding sweep's two findings, filed — #12507, **merged 2026-08-28**

The follow-through on the eighteenth pass's encoding table below. Both halves are the same cause —
**Windows PowerShell 5.1's `>` and `Out-File` write UTF-16LE**, measured again here
(`FF FE 23 00 21 00 2F 00` for `'#!/usr/bin/env bash' > file`) — and they end differently.

**The `.env` position recorded below was reversed, deliberately.** That note called it "weak and
probably not worth filing", on the grounds that a missing `.env` behaves identically so the contract
is consistent; the most it allowed was a `warn!`. That reasoning holds only if the file _cannot_ be
read. It can: `file::decode_text` already handles UTF-8 BOM, UTF-16LE and UTF-16BE, its own
documentation names this exact cause (#5399, the same `Out-File` default), and it was sitting unused
outside aqua checksums. **Reading the file is strictly better than warning about it**, so the dotenv
path now decodes instead of failing. The `warn!` survives for what is left: bytes that genuinely
cannot be decoded. "Could not be opened" is unchanged and still silent — a glob can match a file
that has gone.

The task-file half followed this file's own advice and did **not** teach `has_shebang` UTF-16. That
refusal is documented at the function and is right. Only the message changed, via a small
`file::utf16_bom` kept beside `decode_text` so the mark bytes are described once. It deliberately
does **not** report a UTF-8 mark: `has_shebang` reads past that one, so such a file is executable
and never reaches the hint.

**Found while measuring, not while reading:** the warning ran two sentences together —
`…\mise-tasks\build Add a shebang line to …` — because `task_list.rs` built its remedy as
`format!(" {}", hint)`. The other three callers of the hint already had a stop or a newline. It only
shows up in real output.

**The e2e fixture is written by `powershell.exe` itself**, not by placing BOM bytes. The claim is
that the shell shipped with the OS produces this file; a hand-built mark would test something else.
The `pwsh` running Pester is 7.x and defaults to UTF-8, so it cannot reproduce it. One test asserts
the fixture really is UTF-16LE with the shebang first, **before** anything is concluded from it, and
two controls follow: the same script as UTF-8 runs, and a UTF-8 file with genuinely no shebang still
gets the old advice — without that second control, an implementation that always blamed the encoding
would pass.

**One candidate died here, and it is worth not re-checking:** a CRLF shebang
(`#!/usr/bin/env bash\r\n`, what Git with `core.autocrlf=true` hands a Windows checkout) is the
classic Windows trap, so it was measured. `mise run` handles it — the LF and CRLF twins both print
their marker. No defect.

### Windows, eighteenth pass — 2026-08-27 → #12496 (**merged**), and an encoding sweep that mostly cleared

One finding, and a whole axis checked and closed. **Read the "already decided" note first**: the
first shape this finding suggested would have reversed a decision this account made and jdx merged.

#### The finding — a documented pairing that cannot work on Windows — #12496

`docs/cli/generate/task-stubs.md` presents this pairing in two places. Run exactly that:

```console
$ mise generate install-script --write bin/mise
$ mise generate task-stubs --mise-bin=./bin/mise
PS> .\bin\hello.cmd
'"./bin/mise"' is not recognized as an internal or external command
```

**The control is one flag.** Same steps with `--windows` on the first command: `hi-from-task`,
exit 0. So nothing about the stub, the launcher body or the quoting is wrong — only the file
`--mise-bin` points at.

The two commands apply **opposite defaults for the same stated reason**. `task-stubs` writes its
launcher unconditionally ("stubs are committed, and the contributor who runs one on Windows is not
the person who generated it"); `install-script`'s `--windows` says the same thing in its own doc
comment and is still opt-in, with the reason recorded at the branch: _"Opt-in: most projects never
need it, and it is a second committed file."_

#### Already decided — do not propose making `install-script --windows` the default

**That flag was introduced as opt-in by this account in #11919, and jdx merged it that way**
(2026-08-16, `d12fc07d6591`). The PR body's "What this adds" still reads as though the launcher is
unconditional on `--write`; the title and the merged code are the opt-in form, so **the body is the
stale half**. Anyone reading only the body will reach the wrong conclusion about what was decided —
as I did, for one message.

So #12496 changes nothing about that default. It closes the loop where the information already
exists: `task-stubs` knows it is writing a launcher and knows what `--mise-bin` points at, so it
warns once per run and names the command that fixes it. No second committed file.

#### What review changed, and it was all worth taking

Four bot comments, three distinct, **all four valid**:

1. **The predicate answered by the generating host's rules.** `Path::components` on unix reads
   `.\bin\mise` as one component, so it was classified as a bare PATH-resolved name — and the
   warning was suppressed **exactly where it was needed**, since cmd runs that value as a path. Now
   `\` counts as a separator too. This is the general lesson: a check _about_ Windows has to be
   written in Windows' terms even when it runs on Linux, because the file it is about is committed
   and read elsewhere.
2. **Case-sensitivity, inconsistently within one function.** The extension check on `--mise-bin`
   already used `eq_ignore_ascii_case`; the sibling probe built lowercase names and compared them
   exactly, so a `mise.CMD` on a case-sensitive host produced a warning about a gap that is not
   there. Now the directory is read and matched the way Windows matches.
3. **The warning fired whether or not a launcher was written** — an empty task set, or names that
   already end in an executable extension. Now gated on the same `launchers.path` call the write
   loop makes, so the two cannot disagree.

#### The encoding sweep — checked and clear, do not re-investigate

`read_to_string_bom`/`decode_text` (UTF-8 BOM, UTF-16LE, UTF-16BE) exist but are used **only** for
aqua checksums; every user-authored file goes through plain UTF-8 `read_to_string`. Windows
PowerShell 5.1 writes UTF-16LE from `>` and `Out-File`, so that pairing is worth knowing about.
Measured, with fixtures written through .NET encoders:

| file             | encoding              | behaviour                                                            |
| ---------------- | --------------------- | -------------------------------------------------------------------- |
| `mise.toml`      | UTF-8, UTF-8 BOM      | loads                                                                |
| `mise.toml`      | UTF-16LE / BE         | errors, naming the path **and** `stream did not contain valid UTF-8` |
| `.tool-versions` | UTF-16                | same                                                                 |
| task file        | CP932 (ASCII shebang) | same                                                                 |
| **task file**    | **UTF-16**            | **"Add a shebang line to …" — to a file that has one**               |
| `.env`           | UTF-16                | silent, exit 0, variables missing                                    |

**The two that error are fine** and need no work: the cause is on screen at the default log level.
(An earlier note here said `mise.toml` dropped the cause. That was a `head -4` cutting off the fifth
line — the same class of measurement error as reading `$?` after a pipe.)

**Both cases were fixed by #12507, merged 2026-08-28** — see the section above, and note that the
`.env` verdict below was reversed there.

**The task-file case was a real defect.** [`has_shebang`](src/file.rs) strips a UTF-8
BOM and then tests `#!`; UTF-16 starts `ff fe 23 00`, so the test fails and
[`make_executable_hint`](src/file.rs) tells the user to add something already present. **Do not fix
it by teaching `has_shebang` UTF-16** — mise would then treat the file as executable and the
interpreter would choke on UTF-16 content, trading a clear message for a worse failure. Fix the
message: detect the UTF-16 BOM and say to re-save as UTF-8. There is a sibling test to copy,
`has_shebang_looks_past_a_utf8_bom`.

**The `.env` case is weak and probably not worth filing.** The silence is deliberate — the code says
_"An unreadable file still yields nothing rather than an error, which is what the previous
`if let Ok(..)` did"_ — and measurement showed a **missing** `.env` behaves identically, so the
contract is consistent rather than accidental. The only defensible change is a `warn!` when the file
_exists_ but cannot be read, which keeps the contract (still yields nothing, still exit 0) while
separating "optional file absent" from "your file is unreadable".

#### Also checked and clear

- **A project reached through a junction.** `mise trust` from the junction path resolves to the real
  path and stores it (`\\?\C:\…\real`); the config then loads through both paths. **With a working
  control**: nothing trusted → the config loads through neither.
- **`mise doctor`** — output correct on Windows (`shell: bash` now detected, dirs shown as `~\…`),
  and it exits **1** when it reports a problem. It looked like exit 0 until the pipeline was
  removed: `$?` after `| tail` is tail's.

#### Probe hygiene learned here, all of it cost time

- **`MISE_CONFIG_DIR` alone isolates the global config. Setting `MISE_GLOBAL_CONFIG_FILE` to a
  non-existent path falls back to the real global config** and starts installing that config's
  tools — minutes of downloads inside what was supposed to be an empty fixture.
- `Remove-Item Env:NAME` trips this environment's path guard ("system path '/' is blocked"). Use
  `[Environment]::SetEnvironmentVariable('NAME', $null, 'Process')` — **for ad-hoc probes only.**
  **Corrected 2026-08-28 (see #12502 above): that call does not remove the variable**, it leaves it
  set to an empty string, which is not the same thing to the program reading it. Committed scripts
  must use `Remove-Item Env:\NAME -ErrorAction SilentlyContinue`; CodeRabbit caught this note's
  advice shipped into an e2e file.
- A PowerShell double-quoted here-string mangles TOML with embedded quotes. Write fixtures with
  `[System.IO.File]::WriteAllText`, which also lets the encoding be stated explicitly.
- `$?` after a pipe is the last command's, in bash as well as PowerShell. This produced one false
  finding here (`mise doctor` "exits 0") and one in the sixteenth pass.

### Windows, seventeenth pass — 2026-08-26..27: arguments through cmd, and links that lead nowhere

Two families, **all three PRs merged** (#12463, #12468, #12469). Read the "measured, so do not re-derive" table at the end before
touching anything Windows-and-links or Windows-and-arguments again.

#### 1. A generated `.cmd` launcher cannot carry arguments — #12463

`mise generate task-stubs` writes `bin/<task>.cmd` and forwards with `%*`. cmd.exe parses the whole
command line **before the batch file runs**, so PowerShell — which has no reason to know the target
is a batch file and hands the argument to `cmd /c` unquoted — loses `& ^ | < >` and expands
`%VAR%`. Measured against the same arguments through `mise run`: **10 of 18 shapes arrived
different**, and `a>b` silently created a file named `b`.

**The route table is what made this tractable**, and reaching it took a wrong turn first:

| route                  | `.cmd` | native `.exe`                   |
| ---------------------- | ------ | ------------------------------- |
| PowerShell `& x 'c&d'` | `c`    | `c&d` — **the only divergence** |
| `cmd /c "x c&d"`       | `c`    | `c` — the shell split it first  |
| batch `call x c&d`     | `c`    | `c` — same                      |

The bottom two rows are not mise's to fix, and they are exactly the routes where recovery is not
available, so the two line up. **My first conclusion — "unfixable, document it" — was wrong**, and
it was wrong because "`%CMDCMDLINE%` is unusable in routes 2 and 3" was treated as proof without
checking that a native exe is broken identically there. A negative claim needs its control.

Two traps, both measured:

- **`set "RAW=%CMDCMDLINE%"` truncates at the first `&`.** Percent expansion runs before special
  characters are parsed. `set "RAW=!CMDCMDLINE!"` (delayed expansion) gets the line whole.
- **Putting the recovered text back on a cmd line loses it again** (`g"h` becomes `gh`, `k|l` is
  re-piped). It has to go through the **environment**, where cmd never parses it a second time. And
  `CMDCMDLINE` is a cmd pseudo-variable that is **not inherited by a child**, so the launcher must
  copy it into a real one.

Result: **10 wrong to 4 wrong**, nothing worse than before. The four are a pipe (cmd builds it, so
the launcher's own line is not the caller's), a bare `"` (PowerShell writes it unescaped — Windows
PowerShell 5.1 loses it for a native exe too), `q\"r`, and the empty-string argument.

**One case is ambiguous by construction and cannot be resolved:** `cmd /c ""<launcher>" a & b"` is
both what a shell produces for the single argument `a & b` and what someone writes to run the
launcher and then `b`. Bare-name and relative-path chains are unaffected — the guard only fires on
an absolute quoted path.

The PR also adds an opt-in `--windows-launcher exe`, which copies the `mise-shim.exe` that already
ships and has none of this. `mise-shim` reads the extensionless stub beside it to learn the task
name and the `--mise-bin` path; the crate stays dependency-free.

#### 2. A link whose target is gone is invisible and unremovable — #12468 (merged) + #12469

`mise link node@dev <dir>`, then move or delete that directory. Six gates all resolved the entry
before deciding about it, so the name stayed occupied by something no command would admit to:

| gate                                             | test                                           |
| ------------------------------------------------ | ---------------------------------------------- |
| `file::remove_all`                               | `path.metadata()` — **#12468, merged**         |
| `dir_subdirs` via `install_state::scan_versions` | `ft.is_symlink() && entry.path().is_dir()`     |
| `cli/ls.rs` filter (**two sites**)               | `!source.is_unknown() or is_version_installed` |
| `cli/uninstall.rs`                               | `is_version_installed`                         |
| `remove_all_with_progress`, and the dry-run arm  | `!path.exists()`                               |

**`remove_all`'s first match arm was dead code**: it read `x.is_symlink() || x.is_file()` on
`metadata()`, which follows, so `is_symlink()` was never true. A dangling entry fell to `_ => {}`
and the function returned `Ok(())` having done nothing.

**The naive fix breaks Windows.** Switching to `symlink_metadata` routes junctions to `remove_file`,
which **refuses them with `PermissionDenied`, live or dangling**. The existing
`remove_symlink_or_junction` already handles both platforms (reparse-tag check plus delete-by-handle
on Windows; link check plus unlink on unix) and refuses anything that is not a link — measured on
all four cases on both platforms.

#12469 makes it visible: `ls` shows `<version> (broken symlink)`, `--json` gains `broken: true`
(omitted when false), and `uninstall` accepts it. **It is listed, not called installed** —
`e2e/cli/test_link` already decides a dangling link is not a complete install, and
`is_version_installed` is untouched.

#### 3. Not yet reported — the same defect in `windows_shim_mode = "file"`

**The largest unworked item.** `shims.rs` writes `mise x -- {tool} %*` for `file` mode, which is the
`.cmd` defect again:

| mode                                   | files                  | wrong of 6 |
| -------------------------------------- | ---------------------- | ---------- |
| `exe` (default), `hardlink`, `symlink` | `<tool>.exe`           | **0/6**    |
| `file`                                 | `<tool>`, `<tool>.cmd` | **6/6**    |

`c&d` exits 255, `e%OS%f` becomes `eWindows_NTf`, `a>b` writes a file. **It is reachable**:
`effective_shim_mode` **silently falls back to `file`** when `mise-shim.exe` is missing — measured
with a lone `mise.exe`. **Unreported upstream**: #8045's motivation lists spawnSync ENOENT, batch
control flow, `where.exe` and package-manager compatibility — not argument loss — and
`settings.toml` describes `file` neutrally. `e2e-win/shim.Tests.ps1` checks file shape only, never
argument delivery, in any mode.

Blocked on #12463: it reuses `env::recover_launcher_args` / `split_command_line` / the sentinel.
Fold in the second item while there — **`effective_shim_mode`'s fallback warning repeats per shim**
(three tools produced eight identical lines) and `warn_once!` already exists.

#### Measured, so do not re-derive

| fact                                                                                           | why it matters                                     |
| ---------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `%CMDCMDLINE%` truncates at `&`; `!CMDCMDLINE!` does not                                       | decides whether argument recovery works at all     |
| `CMDCMDLINE` is **not** inherited by a child process                                           | the launcher must copy it to a real variable       |
| `remove_file` on a junction gives `PermissionDenied`, live **or** dangling                     | rules out the naive `symlink_metadata` switch      |
| `remove_dir_all` on a **live** junction removes only the junction                              | no data-loss risk in `remove_all`, on either OS    |
| `Path::is_symlink()` **is** true for a junction — `symlink_metadata` and `DirEntry::file_type` | two bots claimed otherwise on #12469; both wrong   |
| `Test-Path` does **not** resolve a junction (True while dangling)                              | Rust's `exists()` is False — the two disagree      |
| pwsh 7.6.5 and Windows PowerShell 5.1 pass arguments identically                               | one measurement covers both                        |
| app-execution aliases report `is_file`, not `is_symlink`                                       | they do not fall into link-handling branches       |
| `mise x -- <tool> <args>` is byte-perfect over 8 shapes                                        | only the `.cmd` routes are broken; `mise x` is not |

#### Checked and clean — do not re-investigate

`.cmd` / `.bat` tool resolution through `mise x`; `mise watch`'s globs (`relativize_source` already
rewrites `MAIN_SEPARATOR` to `/`); `mise sync` and `mise bootstrap` smoke probes;
`runtime_symlinks::installed_versions_in_dir` (uses the plain `dir_subdirs`, so a broken version can
never become `latest`); `shims::list_tool_bins` (filters bin paths by `exists()`, so a broken
install contributes nothing and warns about nothing).

#### Process notes from this pass

1. **A negative claim needs a control that shares every stage you are not testing.** "Unfixable"
   above survived a round only because the failing routes were never compared against a native exe.
2. **Two bots asserted the same wrong thing about junctions on #12469** — once about
   `DirEntry::file_type`, once about `Path::is_symlink`. Both were answered with a measurement plus
   the argument that needs none: the predicate is pre-existing, and a **live** `mise link` already
   renders as `(symlink)` on Windows through exactly that branch.
3. **The bash heredoc in this environment eats backslashes** even with a quoted delimiter — `'\\'`
   arrived as `'\'` and broke a Rust char literal, and `\x93` arrived as a literal newline. Write
   any file containing backslashes with the editor tool, not a heredoc. (This section was drafted
   twice for that reason.)
4. **CI caught two vacuous assertions and one shadowing bug that local checks did not.** One
   assertion named a task that no longer existed at that point in `test_generate_task_stubs`, so it
   would have held whatever the command did; another copied `mise.exe` under a different name, which
   makes it dispatch as a **shim** for that name; and `let launchers = launchers(..)` shadowed the
   test helper, so a second call in the same test would not compile — on Windows only, because that
   was the first job to build the test target.
5. **`sl status` can hang for minutes here** despite watchman. Prefer `sed` / `grep` over Sapling for
   reading, and check `sl log -r .` before editing — the working copy was moved out from under this
   session several times.

### Windows, sixteenth pass — 2026-08-26 → nothing found, and one flaw in my own work

Run while CI was busy. **No new surface**, which after five passes in the same area is a reasonable
result to write down rather than keep digging for.

#### Checked and found sound

- **Executable-extension matching is not case-sensitive in practice.** `file::executable_names`
  appends each `windows_executable_extensions` entry to build candidate _names_, and the lookup is
  `dir.join(name)` — a case-insensitive filesystem finds `NPM.CMD` for `npm.cmd`. The expansion is
  also skipped when the caller already gave an extension, so `TOOL.CMD` goes straight through.
- **No extension comparison against a lowercase literal in a Windows-relevant path.** Grepped every
  `.extension()` compared with `==`/`is_some_and`: they are all `toml`, `lua`, `pub`,
  `artifactbundle`, and all sit behind either a constructed path (lowercase by definition) or a
  non-Windows concern.
- **`mise which` / `mise where` exit codes** — `which <not-a-bin>` and `where <unknown>` both
  exit 1, `where <installed>` exits 0.

#### Two measurement mistakes of mine, both caught before they became claims

**`Select-Object -First N` truncates the pipeline and leaves `$LASTEXITCODE` stale.** A probe
showed `mise which cmdtool` printing an error and "exiting 0", which would have been a real finding
— an error nobody's script could detect. Re-measured with the whole output captured
(`… | Out-String`) it exits 1. **In PowerShell, never read `$LASTEXITCODE` after a truncating
pipeline.**

**A shim probe produced no shims, and that was my setup.** `mise link node@99.0.0 <dir>` linked
fine, but `mise bin-paths` reports the **install root** rather than `<root>/bin` — the node plugin
puts the root itself on PATH on Windows — so a fake tool with its binaries under `bin/` has nothing
for `mise reshim` to find. Checked `mise ls`, `mise bin-paths` and the `installs` directory before
concluding anything.

**Record — an empty probe is a claim about mise until you have checked your own fixture.** Both of
these looked like findings for a minute. What separated them from real ones was the second
measurement, not the first.

#### And one flaw in work already in flight

Verifying the fifteenth pass's surface 2 on CI turned up that its two unit tests **never ran on
Windows**: they were added to `config_file/mod.rs`'s `mod tests`, which is `#[cfg(test)]` **and**
`#[cfg(unix)]`. Windows is the platform that fix is about, so the tests were gated out of the only
platform where they mean anything, and `windows-unit` went green without compiling them.

Moved to a new ungated `mod ignore_entry_tests`. The same file already had one ungated module for
exactly this reason, `ignored_config_path_tests`, carrying the comment _"Deliberately not
`#[cfg(unix)]` like the module below"_.

**Record — check that a new test is compiled on the platform it is about.** Grep the CI log for its
name; a green job proves nothing about a test that was never built. This is the third time this
week that reading a CI log rather than its conclusion changed the answer.

### Windows, fifteenth pass — 2026-08-25 → #12418, #12428 — two surfaces hit, eight sound, **both merged**

#### Surface 1 → #12418 (merged 2026-08-25) — `mise prune --configs` never prunes the trust store on Windows

`file::make_symlink_or_file` writes **a plain file holding the target path** on Windows
([file.rs:1015](src/file.rs)), because Windows symlinks need a privilege mise does not require.
[`Trust::clean`](src/cli/trust.rs) then asks whether the **entry** exists:

```rust
for path in file::ls(&dirs::TRUSTED_CONFIGS)? {
    if !path.exists() { remove_file(&path)?; }   // a plain file always exists
}
```

`IGNORED_CONFIGS` is the same loop. `mise prune --configs`' own help promises the opposite —
_"Prune only tracked and **trusted** configuration links that point to nonexistent
configurations"_.

**The same class has been fixed twice in this repo already, and one of them is the line above:**

```rust
Tracker::clean()?;   // #12380 (2026-08-24, Marukome0743) — resolves both forms
Trust::clean()?;     // still path.exists()
```

plus `runtime_symlinks.rs` in **#11095** (07-20), whose comment cites #5260. And
[`file::resolve_symlink`](src/file.rs) already resolves both forms and has eight callers, so the
fix reuses it instead of adding a fourth private resolver.

**Record — when a lesson is already written down twice, look for the third place.** Both prior
fixes carry a comment explaining the Windows pointer-file form. Neither author walked the other
call sites. The one that was missed is one line from the one that was fixed.

#### The measurement, and the control that isolated the form

Measured on 2026.8.12 with every `MISE_*_DIR` isolated: trust a project, load it, delete it,
`mise prune --configs` → **both** entries survive, both `Mode=-a---` plain files, both targets
gone.

Then the control that made it mean something: **in the same store with the same binary**, one
entry was converted to a real directory symlink. prune _attempted_ to remove that one (and failed
on `remove_file` — Windows needs `remove_dir` for a directory symlink) and **did not attempt** the
file one. So the detection genuinely differs by the form of the entry, not by anything else.

The `remove_file` failure is **not** a reportable defect: mise never writes a symlink into that
store on Windows, so it is only reachable through the artificial entry I made for the control.
**A control can surface something that is not a finding — say so rather than banking it.**

#### The caveat that sent this to CI

2026.8.12 **predates #12380**, so the tracked half failed in that run too and the two halves could
not be separated. The claim "on `main` the tracked half is fixed and the trusted half is not" is a
**reading of `main`**, not a run.

**So the branch went up with a failing Pester test and no fix**
(`fix/prune-trusted-configs-on-windows`, `69b6b9c413c8`), dispatched on the fork's own `test`
workflow. A red `windows-e2e` there _is_ the missing measurement, taken on a build of `main`.
Green would mean the defect is already gone and the whole finding is withdrawn.

**The unit tests could not go in that commit**: they call `Trust::clean_in`, which does not exist
without the fix, so the crate would fail to compile and the red would be the wrong red. **A
failing-test-first commit has to fail in the test, not in the build.**

#### Building here — a correction to this file

Earlier entries and several PR bodies say `cargo check` cannot run on this box because
`libz-ng-sys` needs `cmake` and cmake is not installed. **That is wrong.** Visual Studio 18
BuildTools is installed (`C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools`, MSVC
14.51.36231 + Windows SDK, confirmed with `vswhere`), and cmake ships inside it at
`…\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe` (4.3.1-msvc1). It is simply
not on PATH. `target/debug/mise.exe` from 2026-08-12 and the `running: "cmake" …` lines in
`target/debug/build/libz-ng-sys-*/stderr` are what a working build left behind.

A build with that directory prepended to PATH starts and compiles. **The user's standing preference
is still CI over local builds on this machine** — it is slow and memory-hungry here, and a local
build was stopped mid-run for exactly that reason. The correction is only that "cannot" was the
wrong word: the reason is cost, not capability.

**Record — a caveat that gets pasted into every PR stops being checked.** This one rode along in at
least six PR bodies. Re-derive a standing excuse occasionally, or it becomes folklore.

#### CI on the fork, without a PR

`test.yml` has `workflow_dispatch`, and `classify-changes` returns `full-ci=true` immediately for
any non-`pull_request` event. `windows-unit` (`cargo check` + `cargo test`) and `build-windows` →
`windows-e2e` (`pwsh e2e-win\run.ps1`) all run on `windows-latest`, so **the whole Windows chain
works on the fork**. The Linux and macOS jobs ask for Namespace self-hosted labels the fork does
not have and sit queued; cancel the run once the Windows jobs report.

**This is how to get a red measurement without showing jdx a deliberately failing PR.**

#### Surface 2 → #12428 (merged 2026-08-26) — `mise trust --ignore` does nothing on Windows, past the process that ran it

Found by taking surface 1's lesson literally and looking for the next place. [`is_persisted_ignored`](src/config/config_file/mod.rs)
loads the ignore store like this:

```rust
for entry in file::ls(&dirs::IGNORED_CONFIGS).unwrap_or_default() {
    if let Ok(canonicalized_path) = entry.canonicalize() {
        is_ignored.insert(canonicalized_path);
    }
}
```

**`Path::canonicalize` follows a symlink.** On unix the entry _is_ a symlink, so this happens to
land on the config it records. On Windows the entry is a plain file holding the path, so
`canonicalize` returns **the entry's own path inside `ignored-configs`** — never a config path. The
loaded set matches nothing.

Measured, isolated dirs, 2026.8.12:

```
1. after trust      : LOADED
2. after --ignore   : LOADED
3. new process again: LOADED
ignored-configs : 1 entry -> \\?\C:\...\proj   (Mode=-a---)
```

The entry **is written**; it is the reading that is wrong. `is_trusted`'s order is ① setting-ignore
→ ② in-memory `IS_TRUSTED` → ③ `trusted_config_paths` → **④ persisted ignore** → … ⑦ persisted
trust store, so ④ firing would keep it out of a fresh process. It never fires.

**The trust side is fine** — the persisted trust store is read by `trust_path(path).exists()`, a
hash-derived filename lookup with no directory scan. Only the ignore list walks entries.

**Record — the same wrong question can wear a different verb.** Surface 1 asked `path.exists()`
about an entry; this one asks `entry.canonicalize()`. Grepping for the first spelling would not
have found the second. What they share is _deciding something about an entry without resolving it_.

**Linux already has the control.** `e2e/cli/test_trusted_config_paths_override_ignore` asserts
`assert_not_contains "mise env" "PROJECT=…"` while ignored, and it is green — so the logic is right
and only the Windows record form is not being read. **When one platform's test is green and the
other has none, the missing test is the finding.**

Fixed by resolving with `file::resolve_symlink` — the shared helper surface 1 also uses. Branch
`fix/trust-ignore-persists-on-windows` (`c61cfd47d127`), unix behaviour unchanged.

#### How the CI measurement is actually taken

A conclusion is not a measurement. On 2026-08-25 a `windows-e2e` **failure** turned out to be the
Pester suite falling over in _setup_ — `mise trust` with no argument found nothing to trust, so the
store directory never existed and the control assertion blew up before prune was ever reached. Read
as "the defect reproduced", it would have been a false report.

What the log has to show, both ways:

- **Red**: the failing line must be the assertion _after_ the operation under test, not a control.
- **Green**: `[+] <file>` alone is not enough — Pester prints that for a file whose tests were
  collected. Look for the **side effects the tests produce** in the surrounding lines. For
  #12418's run that was two `mise trusted …` / `mise pruned configuration links` pairs immediately
  before the `[+]`, i.e. both `It` blocks really launched mise.
- **`cargo test`**: grep the log for each test **by name**; `test result: ok` says nothing about
  whether yours ran.

Mechanics: a dispatched fork run never "completes" (the Linux/macOS jobs queue forever on Namespace
labels), so `gh run view --log` refuses. Fetch the finished job directly —
`gh api --allow-escape-sequences repos/<fork>/actions/jobs/<id>/logs` — then cancel the run.

**Record — name the path when a test drives a CLI.** `mise trust` with no argument resolves through
config discovery from the cwd upward and finds different things in different environments. Every
assertion in a suite that drives a command should stand on its own, so a broken setup fails at the
setup line instead of masquerading as the defect.

#### Checked and found sound — 2026-08-25

- **`_.path` with backslashes** — `"C:\\tools\\bin"` and a relative entry both land on PATH.
- **`mise fmt` round-trip** — `"C:\\tools\\bin"`, `'C:\raw\path'` and `"a\tb"` come back
  unchanged, and the resolved values are identical afterwards.
- **`MISE_TRUSTED_CONFIG_PATHS`** — works on Windows even though the store records
  `\\?\`-prefixed paths. Two controls: untrusted → rc=1, store-trusted → rc=0.
- **Task-name case** — a TOML `Build` and a file task `build` coexist, each spelling runs its own,
  and `BUILD` errors. Windows' case-insensitive filesystem does not collapse them.
- **`file::is_symlink_to` and the Windows pointer-file form** — the obvious next suspect after the
  two surfaces above, since `is_symlink_or_junction` is false for a plain file. **Sound**: all three
  callers (`cli/link.rs`, `cli/sync/reconcile.rs`, `plugins/core/rust.rs`) only ask about links made
  by `make_symlink` — real symlinks or junctions — and `reconcile.rs` filters the pointer-file form
  out with `is_runtime_symlink` _before_ reaching it. **Reading the callers is what settled it; the
  helper looks wrong in isolation.**
- **No third instance of the bug shape.** Grepped for `canonicalize` applied to anything coming out
  of a `file::ls` / `read_dir` loop across `src/`: no other hits. The two surfaces above and the
  two already fixed (#12380, #11095) appear to be the whole set.
- **`mise config ls --json` and `mise ls --json`** — both parse as valid JSON with Windows paths in
  them, so nothing is hand-assembling the strings.
- **`mise unuse <tool>`** — removes `[tools]` and leaves `[env]` intact in a `mise.toml`.
- **`mise cache clear`** — rc=0 on an isolated cache dir.
- **`mise where` errors name the subject** — `go@1.27.0 not installed` for an uninstalled tool,
  `definitely-not-a-tool not found in mise tool registry` for an unknown one. Not the bare-error
  family that #12314, #12363 and #12372 came from.

- **`mise trust --all`'s descendant walk on Windows** — trusts the root, `sub` and `sub/deep`, and
  skips `node_modules`. The `ignore` crate's walk behaves the same way there.
- **`mise doctor -J` and `mise tasks --json`** — both parse as valid JSON with Windows paths in
  them.
- **`mise activate pwsh`** — emits `$env:MISE_SHELL = 'pwsh'` and guards `__MISE_ORIG_PATH` with
  `Test-Path -Path Env:/…`, which is the pwsh spelling rather than a POSIX one.
- **Writing a config while another process holds it locked** — a Windows-only failure mode with no
  unix analogue. `mise set` fails cleanly, **the file is left intact** (byte count and contents
  unchanged), and the error names both the file and the reason: `failed read_to_string: <path>` /
  `プロセスはファイルにアクセスできません。別のプロセスが使用中です。 (os error 32)`.

**Checked, and already fixed on `main` — not a finding.** That same locked-file probe printed
`Error loading settings file: …` **twice** before the error. That is the shape #12327 was about,
and #12327 merged at 08-24 12:35 — **after `v2026.8.12` was cut at 08:33**. On `main` the queue is
a `BTreeSet<String>` drained through `warn_once!`, so the repeat is already collapsed.

**Record — the released binary is a long way behind `main` right now.** Six PRs merged after
`v2026.8.12` was cut, several of them changing exactly the diagnostics these probes read. **Before
calling anything found with the installed binary a defect, check `main` for the same code and check
the release date against recent merges.** This one was caught; the fifteenth pass's surface 1
measurement needed the same check and got it.

**Verified rather than assumed: the Linux control for surface 2 really is green.** The claim that
`e2e/cli/test_trusted_config_paths_override_ignore` proves the ignore logic works off Windows was
read off the test file, which is not the same as knowing it runs. Pulled the `e2e` job log from a
green `main` run (job 96125520339): `PASS: cli/test_trusted_config_paths_override_ignore`. **A test
existing in the tree is not evidence that it passes.**

**Record — isolate every directory a probe can write to.** This pass set `MISE_DATA_DIR` as well as
state/cache/config, and a probe that tripped a `go` install wrote it into the scratchpad, where it
died with the probe tree. The previous pass isolated only the state dir and had to declare a real
install afterwards.

### Windows, fourteenth pass — 2026-08-24 → #12372, #12375 — two surfaces, both hit, **both merged 08-25**

Opened because the queue was empty: the thirteenth pass was spent (two hit, seven sound) and the
only other item needed a design decision from jdx.

#### Surface 1 → #12372 (merged 2026-08-25) — `mise trust` never checks the path it was given

`config_root` ([config_root.rs:18](src/config/config_file/config_root.rs)) resolves a path to a
trust root by **counting path components**. It never touches the filesystem, and nothing else
checks either — `resolve_config_file` only asks `is_dir()`, which is false for a path that is not
there and returns it unchanged. So the behaviour splits on whether the _computed_ root happens to
exist. Measured on 2026.8.12 with `MISE_STATE_DIR` pointed at a scratch directory:

| command                                   | rc    | output                                                         |
| ----------------------------------------- | ----- | -------------------------------------------------------------- |
| `mise trust <sp>\mise.toml` _(control)_   | 0     | `trusted ...\probe14`                                          |
| `mise trust <sp>\outer\inner\nope`        | **0** | **`trusted ...\outer\inner`**                                  |
| `mise trust <sp>\nope\mise.toml`          | 1     | `mise ERROR 指定されたファイルが見つかりません。 (os error 2)` |
| `mise trust --ignore <sp>\nope\mise.toml` | 1     | same                                                           |
| `mise untrust <sp>\nope\mise.toml`        | 1     | same                                                           |

Row 2 is the finding. The trust store afterwards held a real entry,
`trusted-configs\outer-inner-3c04af8520dd05dc`, for a directory never named on the command line.
**`mise trust ~/work/projet` trusts `~/work` and reports success.** `untrust` is the same defect
in reverse, measured separately: `mise untrust .../outer/inner/nope` printed
`untrusted .../outer/inner`, exited 0, and `--show` flipped from trusted to untrusted — the entry
really was removed.

**Record — check the store, not just the message.** "trusted \<parent>" could have been a
cosmetic mislabel. Listing `trusted-configs` afterwards is what turned it from a wording bug into
a security-boundary bug, and it took one command.

**Record — a bare `canonicalize()?` is a defect with two faces.** Rows 3–5 are the same missing
check, hitting the OS instead. The error names neither the path nor the operation, and on Windows
the string is localized — there is not even something to search for. Fixing the check fixes both
rows without touching the five `?` sites at all.

**The check is `exists()`, and deliberately not more.** Tightening it to "the config file must
exist" would break trusting a project _before_ writing its `mise.toml` — the trust root is the
directory either way. That path has its own unit test, because it is the thing an over-eager
version of this fix would quietly remove.

**One behaviour change, stated rather than filed under "better error".** Row 2 goes 0 → 1. The
old zero reported success for an action the user had not asked for.

**The e2e's second `--show` is the whole test.** Asserting only that a typo now errors pins rows
3–5 and misses row 2 entirely; asserting the parent is _still untrusted afterwards_ is what says
the failed command trusted nothing. `e2e/cli/test_trust_worktree` already asserts
`": untrusted"` through `--show`, so that observation surface was known to work before I leaned on
it.

Scoped out and written into the PR: `hashed_path_filename`'s `path.canonicalize().unwrap()` is a
latent panic, reachable now only if the path disappears between the check and the hash. Making it
fallible ripples through `trust_path`/`ignore_path` and their callers, so it wants its own PR.

#### Surface 2 → #12375 (merged 2026-08-25) — the editor default is `nano` on every platform

[`env.rs:83`](src/env.rs) is `VISUAL` → `EDITOR` → `"nano"`. Nothing ships `nano` on Windows —
measured on this box, `vi`, `vim`, `nano` and `code` are **none of them** on PATH — so
`mise task edit <task>` with neither variable set fails with `mise ERROR program not found`,
naming neither the program nor the variable to set. Two consumers,
`src/cli/tasks/edit.rs:55` and `src/cli/dotfiles/mod.rs:95`. No upstream report.

`program not found` is std's own wording for a failed Windows PATH lookup, and it carries no
program name — [`backend/mod.rs`](src/backend/mod.rs) already records that in a comment written
for a different reason. **A message that names nothing is sometimes not the caller's fault; find
out whose it is before deciding where to fix it.**

**The obvious Windows default turned out to need measuring.** `notepad` looked free, and it is not:
on Windows 11 26200 `System32\notepad.exe` **does not exist**, and `notepad` on PATH is a
**zero-byte reparse point** — an app-execution alias for the packaged Notepad. That matters because
[`dotfiles/edit.rs`](src/cli/dotfiles/edit.rs) calls `open_in_editor()` and then `apply_target()`
on the next line: **an editor that detached would apply a file the user had not saved.**

So it was spawned once, the way `Command::status()` does it (`UseShellExecute = false`, then wait
on the returned handle):

```
started pid=13552
WaitForExit(5s) returned: exited=False after 5291 ms
notepad processes now: 2
VERDICT: the spawned process is STILL RUNNING -> the parent waits on the real editor
```

The alias hands back the real process. **Had it detached, the PR would have shipped the message
alone** — the plan said so before the measurement, which is the only way that commitment means
anything.

**Record — a default is a promise about behaviour, not just a name.** "Windows has notepad" was
true and still not enough; the property the callers depend on is that it _waits_. Check the
property, not the availability.

**The Unix default stays `nano`.** Plenty of minimal Linux images lack it too, but that was not
measured, and the improved message now names the program wherever it happens.

**The duplication was inside the diff, so it collapsed rather than doubled.** `open_in_editor` and
`split_editor_command` existed verbatim in both consumers, identical apart from whitespace and
`env::` vs `crate::env::`. Writing the fix twice would have been the wrong answer to finding that;
they moved to `src/cli/editor.rs` with their three existing tests. Compare #12343, where the same
duplication finding was **out** of the diff and correctly went to its own PR — **where the
duplication sits relative to the change is what decides.**

#### Checked and found sound — 2026-08-24

- **`mise task edit --path <new task>`** writes `mise-tasks/<name>` with a
  `#!/usr/bin/env bash` shebang; `mise tasks` lists it and `mise run` exits 0 on Windows. Not the
  #12324 shape — that one is a file with neither extension nor shebang.
- **The trust store is case-safe on Windows.** `hashed_path_filename` hashes
  `path.canonicalize()`, and Windows' `canonicalize` returns the on-disk spelling, so `C:\Foo` and
  `c:\foo` land on one entry.
- **`mise doctor`'s `shell: (unknown)`** is correct: it reports `MISE_SHELL`, which only exists
  after `mise activate`. Identical on Linux without activation.
- **`mise env -s cmd`** is rejected — cmd.exe is not among the supported shells at all
  (`bash, elvish, fish, nu, xonsh, zsh, pwsh, powershell`). A missing feature and a design call for
  jdx, not a defect.

**Record — a probe that installs something is a side effect to declare.** `mise run newtask` in a
scratch directory whose `mise.toml` declared `node = "22"` installed node 22.23.2 into the real
data dir; `MISE_STATE_DIR` was isolated and `MISE_DATA_DIR` was not. Told the user rather than
quietly uninstalling it. **Isolate every dir a probe can write to, or expect to report what it
wrote.**

### Windows, thirteenth pass — 2026-08-23 → #12330, #12341 — two surfaces hit, seven sound, **both merged 08-25**

#### Surface 1 → #12330 — the TOML backslash trap has no hint

The most ordinary line a Windows user writes fails with a message that never mentions backslashes.
Measured on Windows 2026.8.10; the semantics are TOML's, so Linux is identical and **only the impact
is Windows-shaped**:

| config line                                      | result                                                                   |
| ------------------------------------------------ | ------------------------------------------------------------------------ |
| `P = "C:\Users\Jam"`                             | rc=1, `too few unicode value digits, expected unicode hexadecimal value` |
| `P = "C:\dev"` / `"C:\q"` / `"C:\Program Files"` | rc=1, ``missing escaped value, expected `b`, `e`, …``                    |
| `P = "C:\temp"`                                  | **rc=0 — the value silently becomes `C:<TAB>emp`**                       |
| `P = 'C:\temp'` (literal)                        | rc=0, correct                                                            |

**The project already documents this** — `docs/configuration.md` even names the silent case exactly
— but only under the `path:` tool scope, while the trap applies to every string in the config.
#12312 / #12320 / #12324 shape again: the rule is written down and one path never reached it.

**Record — do not hang a diagnostic on a dependency's wording alone.** The help fires on two
conditions: the message looks escape-related _and_ the failing line actually contains a backslash.
The wording belongs to the `toml` crate and can be reworded; the backslash is a fact about the
user's file. **AND them, and a reworded message costs the advice instead of misplacing it.**

**Record — a trap can have an exact half and a heuristic half.** `"C:\Users"` errors, so it can be
caught precisely. `"C:\temp"` is valid TOML, and telling a mangled path from a deliberate `"a\tb"`
is guessing. **Close the exact half, name the other, and do not pretend the guess is a fix.**

**The control that mattered was the negative one.** A parse error with no backslash must not collect
the advice; that assertion is green on the released binary already and has to stay green. Help that
turns up everywhere is worth nothing where it belongs.

**Rendering could not be verified locally.** `cargo check` does not run on this box, so the
`#[help]` derive form was settled by reading miette 7.6's source — `miette-derive/src/help.rs`
routes a field-level `#[help]` through `OptionalWrapper`, `handlers/graphical.rs:430` prints
` help:` and wraps it — rather than by running it. The e2e matches on **single words** because of
that wrap, and the PR says CI is the first place the output actually exists.

#### Surface 2 → #12341 — a task stub named after its file, not its task

Windows 2026.8.10, three tasks in `mise-tasks/`:

| task file     | stub written                            | result                                                                            |
| ------------- | --------------------------------------- | --------------------------------------------------------------------------------- |
| `shTask`      | `bin/shTask` + `bin/shTask.cmd`         | fine                                                                              |
| `psTask.ps1`  | `bin/psTask.ps1` + `bin/psTask.ps1.cmd` | typing `psTask` resolves neither — PATHEXT wants `psTask.CMD`                     |
| `batTask.bat` | `bin/batTask.bat`, **no launcher**      | cmd.exe runs the `#!/bin/sh` stub as a batch file, `'#!' is not recognized`, rc=1 |

**Record — one thing with two names gets picked differently by each path that reads it.** The stub's
_path_ came from `Task::name_to_path` (`name`, extension kept) while its _body_ came from
`display_name` (extension dropped), so `bin/batTask.bat` contained `mise run batTask`. **When an
entity has two spellings, count which path uses which** — the bug lives where they disagree.

`windows_launcher_path` then declined to write a `.cmd` beside a `.bat`, on the assumption that such
a file already runs on Windows. True of a real batch file, false of a generated stub, which is a
`#!/bin/sh` script whatever it is called.

**Record — a rename fix comes back as a regression somewhere else, and the place to look is where
the new name is not unique.** Two file tasks differing only by extension share a display name, and
on non-Windows platforms **both survive** — `prefer_windows_file_task_siblings` collapses the pair
only on Windows. Measured: `build.sh` + `build.bat` produce two working stubs today. Renaming both
onto `bin/build` would have made `resolve_stub_paths` fail the run. So a colliding group keeps its
file-named paths; Windows never reaches that branch, so the case being fixed is always unambiguous.
**Before renaming, measure what cannot be renamed.**

**The migration came for free, and that was the point of keeping `legacy_path`.**
`validate_stub_paths` already compares the old path with the new, verifies the file there is a
generated stub, and removes it with its launcher — while still refusing to delete anything mise did
not write. Deriving only the _new_ path from `display_name` let an existing mechanism do the rename.

**The Windows test went in a new file on purpose.** `e2e-win/task.Tests.ps1` has #12324 open against
it; two PRs appending to one file is an avoidable conflict.

#### Checked and found sound — Windows task argument passing

`a b`, `c"d`, `e&f`, `g^h`, `i%PATH%j` were passed through `mise run` to a `.ps1` task and compared
against pwsh invoking the same script directly with the same arguments. **All five identical.**
The control is the comparison; "no error" alone would have proved nothing.

#### Also checked and found sound — 2026-08-23

- **`mise env -s pwsh` value escaping** — `a'b`, `a"b`, `a$b`, ``a`b``, `a%b%`, `a b`, `a\b` emitted,
  evaluated in pwsh, compared against the intended values. All seven round-trip.
- **Project paths containing a space, a `%`, or an `&`** — `mise env` and `mise run` both work from
  `a b`, `pct%dir` and `amp&dir`.
- **A generated launcher started from a `%` path** — runs correctly; the launcher body embeds the
  bare `"mise"` rather than a path, so there is no `%` in it to expand.
- **A task named after a Windows reserved device** — `[tasks.con]` generates `bin\con` and
  `bin\con.cmd` without complaint. `std` opens files through the extended-length path prefix, which
  skips DOS device-name parsing, so the old trap does not fire.
- **A task name containing a character illegal in a Windows filename** — `a?b`, `a*b`, `a<b`, `a|b`
  all fail `generate task-stubs` with `failed write: bin\a?b` plus the OS error. The path _is_
  named, which is the part that matters; the rest is the OS's wording. Too niche to propose.
- **PATH deduplication is case-sensitive, and that is deliberate.** A directory already on PATH in
  a different case is added a second time on Windows (measured: seeded lowercase, mise's PATH
  carries it twice). I expected this to compound across activations — **it does not**: four
  successive runs feeding PATH back in stayed at two entries and a constant length. Then
  `path_env.rs`'s own `to_vec_dedups_by_path_components_not_bytes` turned out to state the rule and
  the reason: _"whether `/Dir` and `/dir` are the same place is a filesystem property mise does not
  assume"_ — true on Windows since per-directory case sensitivity became settable. **A measured
  oddity that a test already justifies is not a finding.**

### Windows, twelfth pass — 2026-08-23 → #12324, #12325 — three surfaces, **two hit, one sound**

Opened after the eleventh pass was exhausted.

#### Surface 1 → #12324 — Windows is told nothing when a task file is skipped

A task file with neither a known extension nor a shebang is skipped on Windows — **correctly**,
since [`file.rs` `is_executable`](src/file.rs) has no permission bit to consult there. What is
broken is only the telling. Measured on Windows 2026.8.10 against Linux 2026.8.3 as the control:

|                                        | Linux (control)                                               | Windows                                                  |
| -------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------- |
| `mise tasks ls`                        | names the problem and the remedy                              | **no output at all**                                     |
| `mise run <name>`, no other tasks      | names the file and the directory                              | `no tasks defined in …. Are you in a project directory?` |
| `mise run <name>`, other tasks present | `no task X found, but a non-executable file exists at <path>` | that line is absent                                      |

Three diagnostics, all excluded by `cfg!(windows)`.

**`sl annotate -c` settled whether the exclusion was a decision or a residue**, which is the #12218
lesson applied before writing anything:

- **2026-03-22 #8705** added all three. Their text was a hardcoded `chmod +x`, meaningless on
  Windows, so Windows was excluded **from the start** — a correct call at the time.
- **2026-08-14 #11923** "stop telling Windows users to run chmod +x" introduced
  `make_executable_hint` and applied it in `cli/run.rs` and `cli/tasks/validate.rs`.

**#11923 was mine and it did not touch `cli/tasks/ls.rs` or `task/task_list.rs`.** It removed the
_reason_ for the exclusion and left the exclusion standing. `find_non_executable_task_files`
already works on Windows, so the fix was dropping two gates and using wording that already existed.

**Record**: when you remove the _reason_ an exclusion was placed, **go count the exclusions that
were placed for that reason.** #12312 (a rule written down, one path missing it) and #12320
(a tool's doc stating its scope, one reader outside it) are the same shape — this is the third,
and the only one where **I made the gap myself**.

Two smaller things worth keeping:

- **`make_task_executable`'s early return mixed a diagnostic with an action.** Only the _prompt_ is
  inapplicable on Windows (`make_executable` cannot change whether Windows runs a file). Moving the
  return below the `warn!` is what gives Windows the one message that names the file when the
  project has other tasks. **An early return that guards an action should not also swallow the
  explanation.**
- **The first cut of the Windows test passed for the wrong reason and then failed for the wrong
  reason.** The fixture sat inside `$TestDrive`, whose root config includes a tasks directory, so
  the project was never empty and two of the three diagnostics could never fire. Moving the fixture
  outside `$TestDrive` and pointing `MISE_CONFIG_DIR` at an empty directory was needed before the
  red was the _reported_ red. **`e2e-win` does not isolate global config the way `e2e/run_test`
  does — a suite that needs an empty project has to arrange it itself.**

#### Surface 2 → #12325 — a BOM in a version-declaring file

`strip_utf8_bom`'s scope walked one step further than #12320 did. Windows 2026.8.10, control is the
same file with no mark:

| reader                                                      | with a BOM                                                                                                    |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `.tool-versions`                                            | **entry silently vanishes**; `mise install` → `﻿node not found in mise tool registry`                         |
| `.node-version` and the other plain-text idiomatic files    | version becomes `﻿20.0.0`; the download URL gets `%EF%BB%BF` → **404**, and the error never mentions the mark |
| `package.json` `packageManager`                             | **silently vanishes**                                                                                         |
| line-anchored registry regex (`Earthfile`, `.golangci.yml`) | **silently vanishes**                                                                                         |
| `.sdkmanrc`                                                 | **version comes back empty**                                                                                  |
| `mise.toml`, `rust-toolchain.toml`                          | fine — the toml crate accepts it, so untouched                                                                |

**The scope question was the whole difficulty, and it was settled by counting, not by taste.**
`file::read_to_string` has 180 call sites; fixing there would be the #12312 move. What was checked:

- **Config writers already drop the mark today** — measured: after `mise fmt` or `mise use` on a
  BOM'd `mise.toml`, byte 0 is `[`. The obvious objection did not apply.
- **All eight content-equality sites read files mise wrote** (generated stubs, launcher check,
  install fingerprint, cask shim, task-cache key). The two exceptions would be _helped_.
- **Hash sites** read `SHASUMS256.txt` and the trust hash; `aqua.rs` already uses `read_to_string_bom`.
- **`src/system/edits.rs` has six read-then-write-back sites** (plus one in `system/files.rs`) that
  edit _user_ files and put them back. Stripping in the primitive would silently delete a mark from
  a PowerShell `$PROFILE`.

**Record**: _"fix it upstream" is not decided by how many sinks there are._ #12312 was upstream and
right; here the same shape gave the opposite answer, because **one kind of caller — the one that
writes the user's file back — was hiding among the 180.** Count the callers _by kind_, not by
number, before calling something the upstream fix.

**A second record — do not add a name that sits next to a different name.** The plan called for a
read-and-strip helper. Dropped once written out: it would have read `read_to_string_no_bom` beside
the existing `read_to_string_bom`, which **also decodes UTF-16**. `strip_utf8_bom` was already the
named rule; #12312's lesson was about an _unnamed_ repeated expression, which is not this.

Where the strip went instead: `normalize_idiomatic_contents` (one line, and every plain-text
idiomatic reader passes through it), `parse_registry_idiomatic_file`, `package_json::parse`,
`ToolVersions::from_file`, and `java.rs`'s `.sdkmanrc` branch.

**`.sdkmanrc` was found by reading and then measured before being fixed** — it matches
`starts_with("java")` _before_ normalising, so it bypassed the shared fix. go.mod, `Gemfile` and
`.java-version` come along through the shared function; they were read, **not measured**, and the
PR does not claim them.

**The test nearly passed for the wrong reason.** `assert_contains "…" "20.0.0"` would have gone
green on the unfixed code, because the broken value is `﻿20.0.0` — which _contains_ the expected
string. Switched to an exact `requested_version` comparison via `mise ls --current --json | jq`.
**When the failure mode is "something extra is prepended", a substring assertion cannot see it.**

Two of the three regression suites **could not be baselined here**:
`test_registry_idiomatic_version_files` asserts a deprecation introduced in 2026.8.10 and this box's
Linux binary is 2026.8.3. Said so in the PR rather than implying a baseline that was not taken.

#### Checked and found sound — `mise env -s pwsh` value escaping

`a'b`, `a"b`, `a$b`, ``a`b``, `a%b%`, `a b`, `a\b` were emitted, evaluated in pwsh, and compared
against the intended values. **All seven round-trip.** The comparison against the expected value
is the control; without it "no error" would have proved nothing.

### Windows, eleventh pass — 2026-08-23 → #12312, #12314, #12320 merged, **#12318 closed** — four surfaces, all four hit, three landed

#### Surface 1 → #12312

**`[env]` declaring an env name in a different case destroys `PATH` on Windows.**

A config with `[env] Path = "C:/custom"` — and **`Path` is the spelling Windows itself uses** — makes
`mise env` emit _two_ assignments to what Windows treats as one variable:

```
${Env:PATH}='C:\Users\Jam\...\mise\installs\go\1.26.7\bin;...'    ← mise's PATH
${Env:Path}='C:/custom-from-mise'                                  ← later, so it wins
```

Measured on 2026.8.10, both ways a task can inherit the environment:

| route                               | the child's PATH                                                                                    |
| ----------------------------------- | --------------------------------------------------------------------------------------------------- |
| `mise exec`                         | `C:\Program Files\PowerShell\7;C:/custom-from-mise` — **system PATH and every mise tool path gone** |
| eval `mise env` (the activate path) | `C:/custom-from-mise` — **the whole thing replaced**                                                |

**The two spellings behave oppositely, and the harmful one is Windows' own.** `[env] PATH = "x"`
emits a single assignment and leaves PATH intact (the value is simply ignored, mise's PATH wins);
`[env] Path = "x"` emits two and wipes it.

**Unix is correct** — measured: `PATH` and `Path` are genuinely distinct there, so `export PATH=…`
and `export Path=/custom` coexist and PATH survives. Windows-specific.

**Four siblings say this is an omission, not a decision.** mise already handles Windows env-name
case-insensitivity in [`env.rs:729`](src/env.rs:729) (`path_key_from_env` resolves the real spelling
of PATH), [`env_diff.rs:284`](src/env_diff.rs:284) (`cfg!(windows) && k.eq_ignore_ascii_case("PATH")`
normalises the key), [`env_diff.rs:700`](src/env_diff.rs:700), and
[`env_diff.rs:729`](src/env_diff.rs:729) (`TMP`/`TEMP`). But `EnvDirective::Val(k, v, _)` in
[`env_directive/mod.rs:534`](src/config/env_directive/mod.rs:534) inserts the config's key verbatim
into `EnvMap` — a `BTreeMap<String, String>`, case-sensitive
([`env_diff.rs:38`](src/env_diff.rs:38)).

**Two process notes from this pass, both cheap to forget:**

- The Bash tool's heredoc **ate one backslash** again (`"C:\\x"` reached the file as `"C:\x"`,
  producing a TOML parse error). Write Windows paths from PowerShell, or sidestep with `/`.
- A probe **hung for the full 10-minute tool timeout**. `mise exec -- cmd /c "…"` through the Bash
  tool started cmd _interactively_. **Put `timeout N` on probes that spawn a shell**, or a single
  bad quote costs ten minutes.

#### Surface 2 → #12314 — `mise -C` aborts on the one failure its checks miss

`--cd` validates two things and reports both cleanly; a third crashes the process.

| `-C` given                             | today                                             |
| -------------------------------------- | ------------------------------------------------- |
| a path that is not there               | ✅ `Directory specified with --cd does not exist` |
| a path that is not a directory         | ✅ `Path specified with --cd is not a directory`  |
| **a directory that cannot be entered** | ❌ **abort**                                      |

`exists()` and `is_dir()` need only the _parent_ to be traversable; `chdir` needs the directory
itself. Measured on both, same failure by two different routes:

- **Linux 2026.8.3** — a directory at `chmod 000` → **SIGABRT (134)**
- **Windows 2026.8.10** — a 309-character directory, because `SetCurrentDirectory` is capped at
  `MAX_PATH` **whatever the long-path setting says** → **0xC0000409**

The error already existed and already named the path and the OS reason. It was dropped at
`let _ = measure!("settings", …)` and met `Settings::get()`'s `unwrap()` further on. **Dropping it
never avoided the failure, only deferred it** — `BASE_SETTINGS` stays empty, so the next
`Settings::get()` repeats the load and unwraps the same error. One line, plus a comment saying why.

**The lesson that generalises: `Settings::get()` is `try_get().unwrap()`.** Any code path that can
make a settings load fail therefore _ends in a panic_ unless something upstream propagates first.
`--cd` is one instance; the next one added will behave the same way.

**Deliberately not done: a pre-check in `validate_cd_path`.** A proxy for "can this be entered" is
wrong in both directions — on unix `chdir` wants `+x` while `read_dir` wants `+r`, so `chmod 111`
would be **rejected**; on Windows `read_dir` has no `MAX_PATH` cap, so the long path would be
**missed**. The only reliable probe is the `chdir`, which is process-global and would run before
`try_get` resolves a relative `cd`. Written into the PR body so it is not re-proposed.

**No Windows test, on purpose.** Reproducing it there needs a path past `MAX_PATH`, and whether that
is creatable depends on the runner's `LongPathsEnabled` (0 on this box). **A test whose result
depends on a machine setting is not worth having.**

**The Linux test says so when it cannot reproduce.** root ignores permission bits, so `chdir`
succeeds and the case is not exercised; the test prints that rather than passing quietly. The
harness has no skip idiom, so this is done with an `id -u` branch.

#### Surface 3 → #12318 — `mise set`/`use` rewrite a CRLF config entirely to LF — **closed unmerged, see the record above**

Measured on Windows 2026.8.10: `mise set B=2` against a CRLF `mise.toml` returns `LF (cr=0 lf=3)`.
**A one-line edit lands as a whole-file diff**, on the platform where CRLF is what an editor writes
by default.

**The control is what makes this a finding rather than "mise reformats".** Re-run with a comment and
uneven spacing and _only_ the endings move:

```
before:  # a comment the user wrote<CR><LF>   A    =    "1"   # trailing note<CR><LF>
after:   # a comment the user wrote<LF>       A    =    "1"   # trailing note<LF>
```

Comment kept, spacing kept, trailing note kept. Preserving shape is the _point_ of the round trip —
this same file already carries `insert_table_item_preserving_decor` and its inline twin. Line
endings were the one part nothing put back.

`mise use` and `mise set` share `MiseToml::save()`, so one change covers both. `save()` now reads
what is still on disk (at that moment still the user's file) and restores its ending; missing, empty
or terminator-less files keep the previous LF default. Only the **first** ending is consulted —
mixed files are pathological either way, and "match the first line" is a rule that can be stated,
where a majority vote would silently rewrite the minority.

**Left out on purpose, with reasons in the PR body:** `mise fmt` (writes via `file::write`, not
`save()` — and a _formatter_ normalising is defensible; the argument here is only that a command
editing one line should not rewrite the others).

**`.tool-versions` was excluded, and the exclusion was wrong.** The first version of #12318 said it
was out of scope because its `dump()` builds text from scratch rather than round-tripping, "and
whether it behaves the same way is not measured". Measuring it took **one command** and the
reasoning was wrong twice over: it has the same user-visible behaviour, and the fix is the same two
lines. The normalisation there is not even `toml_edit` — it is mise's own
`for line in s.lines() { pre.push_str(line); pre.push('\n') }` in `parse_str`, and `str::lines()`
drops the `\r`. Folded in; the helpers moved to `config_file/mod.rs` now that there are two
consumers, and `tool_versions.rs` gained a test module (it had none).

**The lesson: "out of scope" needs the same evidence as "in scope."** Writing an unmeasured
justification into a PR body puts a claim in front of a reviewer that nobody checked — and here it
would have shipped a knowingly half-done fix under a reason that does not hold.

**The trap this surfaced, and it is worth remembering:** `mise_toml.rs`'s test module is
`#[cfg(test)] #[cfg(unix)]`. **A unit test placed there does not run on Windows** — which is exactly
where this bug bites. Caught while planning, not after CI went green on a test that never ran. The
Windows behaviour is guarded by `e2e-win/config_line_endings.Tests.ps1` instead, and the unit test
covers the platform-neutral logic. **Check the module's cfg before deciding a unit test is enough.**

#### Dead ends from this pass, with reasons

- **Trusted-path case-sensitivity** — Windows paths are case-insensitive, so `MISE_TRUSTED_CONFIG_PATHS`
  spelled entirely in lower case was worth checking against a mixed-case directory. It works; the
  config is applied either way. No gap.
- **Long paths reached through the working directory** — cannot be measured on this box at all:
  `LongPathsEnabled = 0`, so **PowerShell itself refuses to start a process** with a 309-character
  cwd, before mise is involved. Switching the same path to the `-C` argument is what found surface 2.
  **When the OS refuses first, move the input to somewhere the program handles itself.**

#### What #12312 did, and the lesson in it

**Folded at storage, not filtered afterwards.** `env.insert(PATH_KEY, …)` appears at fifteen-odd
sites — six in `toolset_env.rs` alone, plus `task/`, `tool_stub.rs`, `tera.rs`. Fixing each would
have been a large diff that the _next_ new site could still miss. Normalising the key inside
`EnvDirective::Val`/`Default` fixes every one of them at once, because the key is right before it
ever reaches them. **When a bug appears at many sinks, look upstream for the single source.**

**The rule was already written down — and the codebase repeats it more than the PR body claims.**
`backend/mod.rs` and `vfox.rs` each guard tool env values with the same inline
`if cfg!(windows) { eq_ignore_ascii_case } else { == }`, each with a comment explaining why; vfox
_also_ has `remove_env_var` and `is_tool_option_env_key` doing case-insensitive Windows matching for
other keys. Four expressions of one fact, none of them named, and the config `[env]` path was the
one that missed it. **The second time you write `cfg!(windows) && eq_ignore_ascii_case`, name it** —
this PR does, and points the two PATH copies at the name.

**The `Temp` control is what keeps the fix honest.** Only names mise emits itself can collide, so
`[env] Temp` had to keep working untouched; the Windows suite asserts it. Without that, folding far
too much would still have looked like a fix.

#### Surface 4 → #12320

**A UTF-8 byte-order mark at the front of an env file makes mise reject the whole config**, taking
every command that reads it down with it. Notepad and PowerShell 5.1's `Out-File -Encoding utf8`
both write one by default; the file looks correct in an editor and the error points at a character
nobody can see, so a user has nothing to go on.

Measured with a no-BOM control through the same command:

| file                      | no BOM (control)           | with BOM                                      |
| ------------------------- | -------------------------- | --------------------------------------------- |
| `.env`, Windows 2026.8.10 | rc=0, `FOO=bar`            | **rc=1**                                      |
| `.env`, Linux 2026.8.3    | rc=0                       | **rc=1**                                      |
| `.json`, Linux            | rc=0, `export BOM_BAZ=qux` | **rc=1**, `expected value at line 1 column 1` |
| `.yaml`                   | rc=0                       | rc=0 — serde_yaml accepts it                  |
| `.toml`                   | rc=0                       | rc=0 — the toml crate accepts it              |

`dotenv()` read the file by two different routes — `dotenvy::from_path_iter(p)` by default, which
opened the file itself, and `file::read_to_string(p)` under `expand = true` — and **neither
stripped**. The read is now done once at the top and stripped before either branch sees it, so the
default branch becomes `from_read_iter`. Behaviour for an unreadable file is unchanged, and
`test_env_file` already asserted that (`_.file = 'not_present'` must not error).

**The scope was widened by a measurement, not by taste.** The first cut fixed `dotenv()` only. Five
readers sit in that one file and all five call `read_to_string` the same way, so all five went
through the same probe before the PR was called finished: **json fails too; yaml and toml do not.**
The PR fixes the two that fail and states in its body that the other two were _measured_ to work —
**an untouched sibling needs the same evidence as a touched one.** This is #12318's shape again, and
this time the count happened before shipping rather than after being told.

**Record**: `strip_utf8_bom`'s own doc states its scope — the writers that leave a mark are ordinary
on Windows — and it is deliberately **not** `#[cfg(windows)]`-gated. mise already applies it in task
bodies (`task/mod.rs`) and shebang parsing (`task_executor.rs`), uses `read_to_string_bom` twice in
`aqua.rs`, and `e2e-win` even has a dedicated `task_bom.Tests.ps1`. The rule and the tool both
existed; the env-file readers were the paths that had missed them. **When a tool's doc states its
scope, walking that scope is cheap** — second instance of the #12312 shape.

`read_to_string_bom` was deliberately _not_ used: it also decodes UTF-16, which is a wider behaviour
change than the failure that was reported and measured.

### The `usage_*` / `USAGE_*` question — 2026-08-23, and **nothing was on file**

The user asked whether an unfixed mise discussion had been blocked by the environment-variable
collision their own [jdx/usage#1213](https://github.com/jdx/usage/pull/1213) removed. **There was no
record of it** — `usage_` appeared nowhere in this file, and the one usage-related memory is a
different defect (`usage_*` empty under `shell = "bash -c"`, which was WSL-launcher routing,
PR #9750). Said so plainly instead of assembling a plausible-sounding answer, then went and found it.

**The chain runs the other way from what the question assumed:**

| when           | what                                                                                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-04-15     | discussion #9106 — `usage_*` leaks from a parent task into a nested child                                                                                     |
| **2026-07-13** | **mise #10963** `fix(task): isolate usage variables per invocation` — adds `clear_usage_env`, and in its own words "handle Windows environment-key semantics" |
| 2026-08-20     | mise 2026.8.10 released                                                                                                                                       |
| 2026-08-22     | jdx/usage#1213 moves usage's CLI settings from `USAGE_` to `USAGECLI_`                                                                                        |

**#9106 was fixed by mise's own #10963, not by anything in usage** — a change merged two days after
the release cannot explain that release's behaviour, and `sl annotate -c` puts `clear_usage_env`
and `is_usage_env_key` in `cca8fb759cbc` = #10963, whose Root cause paragraph is #9106's symptom
almost verbatim. Verified by reproducing #9106 on 2026.8.10: the child sees `usage_foo=[]`.

**And #10963 is what created the problem usage#1213 works around.** Its Windows arm compares the
first six characters case-insensitively, so clearing `usage_*` also clears `USAGE_*`. Measured on
Windows 2026.8.10:

|                   | `USAGE_MYSETTING` | `OTHER_MYSETTING` |
| ----------------- | ----------------- | ----------------- |
| `mise run <task>` | **`[]` — wiped**  | `[iset]`          |
| `mise exec -- …`  | `[iset]`          | `[iset]`          |

`USAGECLI_X` survives while `USAGE_X` does not (`USAGEC` ≠ `usage_`), which is exactly why the
rename works — measured too.

**Not a candidate as it stands.** On Windows `USAGE_FOO` and `usage_foo` _are_ one variable, so a
prefix match cannot separate a leaked parser value from a caller's own setting: the wipe is correct
under that constraint, and [`test_clear_usage_env_uses_platform_key_semantics`](src/task/mod.rs)
pins it deliberately. Narrowing it to "only the names mise injected" is a design call, and the party
it actually hurt has already left for `USAGECLI_`. **Do not open this without asking jdx first.**

**Both discussions were already answered — do not re-answer.** #9106 carries a correct reply
crediting #10963 (2026-08-08); #9460 has a detailed analysis with a reply under it (2026-05-18).
**Read the comments, not the metadata**: both report `isAnswered=false` because that flag only means
"no comment marked as _the_ answer", and in the Troubleshooting category nobody marks one. Two
discussions looked untouched and neither was.

### One typo, the same error three times → #12327

Measured on **Windows 2026.8.10 and Linux 2026.8.3**. One malformed line in `mise.toml`:

```toml
[env]
Bad = "C:\x"
```

Two raw `Error loading settings file:` blocks plus one miette diagnostic. The raw pair carries no
prefix and **`--quiet` cannot silence it**, because `Settings::all_settings_files()` used a bare
`eprintln!`.

**Why two, established by measurement rather than by reading:** `MISE_TIMINGS=2` shows
`all_settings_files` twice per run — **including with a config that parses**. The second build is
intentional (`add_cli_matches` resets settings so CLI flags take effect), and `raw=2` matches it
exactly. The first build happens _inside_ `logger::init()`, which calls `Settings::try_get()` before
`log::set_logger` — hence a block with no prefix, printed before everything else.

**Record — a measurement can look like a refutation when it is only too coarse.** The first count
said `all_settings_files` ran **once**, which appeared to kill the two-builds hypothesis. It was
taken at `MISE_TIMINGS=1`, which does not show that entry at all; at `=2`, side by side, both the
valid and the broken directory show two. **When a measurement contradicts a hypothesis, first ask
whether the measurement could see it.**

**Record — do not replace a pre-logger diagnostic with `warn_once!`.** It inserts the message into
`WARNED_ONCE` and _then_ calls `warn!`, so a call made before the logger exists prints nothing and
still poisons the dedup set; the call that comes after is suppressed and the result is **total
silence**. The fix routes it through the queue-and-flush that `settings.rs` already has for
deprecations found before the logger — `parse_settings_file` was queuing deprecations two lines
away from the `eprintln!`.

Renamed `DEPRECATED_WARNINGS_READY` → `WARNINGS_READY` and `flush_deprecated_warnings*` →
`flush_pending_warnings*`: the flag and the flush no longer serve deprecations alone, and **a name
that has stopped being true is a trap for the next reader** — 2 lines outside `settings.rs`.

**One intended behaviour change, pinned by the test rather than left implicit**: `quiet` sets
`log_level = "error"`, so the message is now suppressed under `--quiet`. Narrow on purpose — the
miette error is returned as an `Err` and printed by the top-level handler, not the logger, so any
command that loads config still reports the failure loudly.

### The diagnostic that named the file twice → #12329

Found while measuring #12327 and logged as "observed once, not root-caused". Root-causing it turned
a Windows cosmetic into a platform-independent duplication.

Linux 2026.8.3:

```
  × Invalid TOML in config file: /home/jam/diagprobe/cfg/miserc.toml    ← Path::display, raw
   ╭─[~/diagprobe/cfg/miserc.toml:2:8]                                  ← display_path, shortened
```

The same file, two lines apart, two spellings. On Windows the message copy is also the one that
wraps, because miette's line breaking takes the colon in `C:` as an opportunity — which is what made
it look like a Windows bug.

**Record — the loudest symptom is not always where the defect lives.** The wrap only appears on
Windows, so it was filed as a Windows cosmetic. The cause is a duplicate that prints on every
platform; remove the duplicate and the wrap goes with it. **Do not read the platform a symptom
shows up on as the location of the cause.**

**Record — the project's own tests can tell you which rendering it trusts.**
`e2e/config/test_miserc` already asserted `~/.config/mise/miserc.toml:2:8` — the _header_, in
`display_path` form — and asserted nothing about the path in the message. mise was already reading
the file name from the snippet. That is what made dropping the message copy an easy call rather than
a judgement.

**The `Display` question was answered by counting, not by assuming.** `MiseDiagnostic`'s plain
`Display` comes from the `#[error]` string, so dropping the path there matters wherever the snippet
is not rendered. All such paths name the file themselves — two `warn!` sites, two `wrap_err` sites,
and everything that `?`-propagates into `handle_err`, which renders the snippet. The last group is
the wide one, so its callers were enumerated rather than waved at, and two were run end to end.

**The e2e assertion had to count.** `assert_contains` cannot distinguish one naming from two, which
is the whole subject. `grep -c` compared exactly: `2` before, `1` after.

### The three `generate` gaps — root-caused 2026-08-23

Recorded earlier as three cosmetic notes. Root-causing them turns three items into **two families**,
and corrects one of the three records outright.

#### Family A → #12333 — a writer that does not name what it wrote

**`generate task-stubs` — measured.** Printed `Wrote to bin\echoargs.ps1` while creating
`echoargs.ps1` _and_ `echoargs.ps1.cmd`.

[`task_stubs.rs`](src/cli/generate/task_stubs.rs) — the launcher write sits inside an `if let` and
the one message after it names only the stub:

```rust
file::write(&stub.path, &stub.output)?;
if let Some(launcher_path) = super::windows_launcher_path(&stub.path) {
    file::write(&launcher_path, &stub.launcher)?;      // written
}
miseprintln!("Wrote to {}", display_path(&stub.path)); // names one file
```

**The sibling that gets it right is in the same directory.**
[`install_script.rs`](src/cli/generate/install_script.rs) prints `Wrote to` after _each_ write,
because its Windows variant and its message were written in the same change. task-stubs gained the
launcher later and the message did not move.

**`generate tool-stub` — read, not measured** (it needs a real HTTP URL, which this box cannot
exercise offline). `write_windows_launcher` has the same shape, plus a third case the note never
had: that function can also **`file::remove_file` the launcher** — a deletion that is equally
unreported. Its message is also worded differently (`Generated tool stub:` versus `Wrote to`).

**`windows_launcher_path` is not cfg-gated** — both generators write the launcher on every OS, by
documented intent. So the under-reporting is not a Windows detail; it happens on Linux and macOS too.

**`generate task-docs --output` — measured.** rc=0, **zero bytes** on stdout and stderr, file
written. [`task_docs.rs`](src/cli/generate/task_docs.rs) has exactly one `miseprintln!` and it is in
the **stdout** branch, where it prints the document itself; all three writing branches (`--multi`
directory, single file, `--inject`) end at `file::write` and return. Five sibling generators print
`Wrote to {}` — devcontainer, github-action, git-pre-commit, install-script (and its deprecated
`bootstrap` alias), task-stubs. task-docs is the only writer that says nothing at all.

**Implemented as #12333.** The stub message moved to sit against its own write and the launcher got
one; `write_windows_launcher` now returns the launcher so `tool_stub`'s `run` prints both lines from
one place — which is what keeps the launcher from being announced with a different verb than the
stub; all four `task-docs` writing branches say what they wrote.

**Two things kept out, and said so in the PR**: the existing wording (`Generated tool stub:` is not
renamed to `Wrote to` — aligning `generate`'s vocabulary is a separate change and would quietly
alter output someone may match on), and the two _removal_ paths. **The subject is naming what was
written; a deletion notice is a different message and a different decision.**

**Record — a count assertion needs a fixture that can only mean one thing.** The first red-state
measurement returned `Wrote to` = 2 on the _unfixed_ binary, which looked like the defect was
already fixed. The fixture had two tasks: two stubs, one line each. With a single task it is 1, and
the assertion `== 2` means what it says. **Before trusting a count, check the fixture cannot reach
that number another way.**

**Record — an emitted-output test still needs a negative control.** `tool-stub` asserts the launcher
line appears _and_ that the `unix-only-stub` case, which writes no launcher, prints no launcher
line. Without it the assertion would pass on code that printed the line unconditionally.

#### Family B → #12334 — the table fills its last column

**The earlier record was wrong about the scope.** It read "`mise settings` pads its last column".
It is not a `settings` behaviour: [`ui/table.rs::default_style`](src/ui/table.rs) is shared by
**eight commands** — `outdated`, `plugins ls` (×2), `set`, `settings ls`, `shell-alias ls`, `tool`,
`tool-alias ls`.

`default_style` already ends with `Modify::new(Columns::last()).with(Padding::zero())`, which is why
the line looks like it should have prevented this. **Padding and width fill are different things**:
zeroing the padding removes the spaces tabled puts _around_ a cell, not the spaces it adds to bring
the cell up to the column's width. Measured per line:

```
len=150  trimmed=56   fill=94
len=150  trimmed=150  fill=0
len=150  trimmed=150  fill=0
```

Every row is filled to exactly the widest.

**Record — a symptom needs two rows to appear, and one row is what I measured first.** The first
pass reported `0` trailing-whitespace lines for `mise settings` and `3` for `tool-alias ls`, which
looked like the record was simply wrong. With a single row there is nothing to fill _to_ — the only
row is the widest. **Before concluding a record is wrong, check that the reproduction has the shape
the symptom needs.** Two rows of differing length, and it reproduces exactly as first written.

Swept the surfaces the ninth pass had left: the rest of the `generate` family, `generate bootstrap`
(including its `--windows` `.cmd` launcher), lockfile contents, every `--json` output, paths with
spaces and non-ASCII, and file tasks.

**The finding — #12274.** A file task whose shebang names pwsh cannot run on Windows. The
documentation's own example (`docs/tasks/file-tasks.md`, Shebang section: `#!/usr/bin/env pwsh`,
no extension) fails verbatim with pwsh's own message about `-File` needing a `.ps1` extension — and
mise finds the task and reads its `#MISE` header before failing to start it.

**It is the Windows build of pwsh alone.** Measured on the _same_ pwsh 7.6.5, installed in WSL via
`mise use -g powershell@latest` for the control:

|         | `pwsh -File <no extension>` | kernel shebang |
| ------- | --------------------------- | -------------- |
| Linux   | ✅ rc=0                     | ✅ rc=0        |
| Windows | ❌ rc=64                    | —              |

So the shape works on Linux/macOS and fails only here; **the fix removes a divergence rather than
creating one.** Four escape routes were measured and only one survives: a temp `.ps1` copy.

**The user caught me getting this backwards.** I first reported it as Windows-specific (right), then
"corrected" myself to "Linux fails too, so fixing it creates divergence" (wrong) on the strength of
_code reading only_ — no pwsh was installed to measure with. The user pushed back: pwsh ships a Linux
build, so `.ps1` runs there; why not fix it everywhere? Installing pwsh and measuring settled it in
one command. **A correction issued from reading, against a measurement, is still a guess.**

**Implemented as #12334.** `table::print` does the styling and the trim, and `default_style` is now
private — with one entry point a table cannot be printed without the trim, which is how the spaces
got there. Eight call sites collapse to one line each. One `miseprintln!` rather than one per line,
so the newlines land exactly where they did and the only difference in the output is the trailing
space.

**Record — two concepts can share a word, and only one of them get handled.** `Padding::zero()` on
the last column reads as "no space after the last column" and is not wrong; it removes the space
_around_ a cell. The space that brings a cell up to its column's width is added separately and
survived. **Code that looks like it already addresses a symptom is worth checking against the
symptom, not against its name.**

**Record — closing the entry point outlives the fix.** Trimming eight call sites would have left the
ninth free to forget. Making `default_style` private means the next table cannot.

**The control had to come first, and this section is why.** Root-causing family B, the first
measurement of `mise settings` returned zero trailing-whitespace lines and looked like the record
was wrong — one row has nothing to fill _to_. The e2e therefore pins two alias targets of different
length and asserts both are present _before_ counting.

#### The next candidate corrected the PR — 2026-08-22

The pass left `shell = "pwsh -c"` on an extensionless file task as the next candidate, on the
strength of a **direct pwsh probe**: `pwsh -Command "& '<path>'"` exits 0 having done nothing.
Measuring it **through mise** before writing any code produced the reproduction _and_ something
else: the reason I had written into #12274 for exempting `-Command` from the shim was **factually
wrong**. The comment said

> `-Command` takes a script _string_, so the path is never opened as a file and a different name
> would change nothing.

PowerShell's **command** resolution asks for `.ps1` exactly as `-File` does, so the name does
change things. Measured through mise on Windows: extensionless + `shell = "pwsh -c"` → rc=0, no
output; the same file as `.ps1` → runs, args forwarded. And directly: `pwsh -c <temp .ps1 copy>
ARG1` → runs. **The shim was always the right answer for both modes.**

Removing the exemption made the PR _smaller_: the `-Command`/`-File` classification extracted into
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

#### Command-mode file shells drop or mangle their input — **merged, #12277 (2026-08-23)**

Found in the same session as a _control_ for the pwsh work. Separate cause, separate fix, **not**
part of #12274 — though it lands in the same function, so the two will conflict.

| setting                                                                | measured                                                                                 |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Linux `shell = "sh -c"` (with `use_file_shell_for_executable_tasks=1`) | task runs, **argument silently lost** — `RAN sh-c: []` where the control prints `[ARG1]` |
| Windows `shell = "bash -c"`                                            | every backslash eaten out of the path — `C:UsersJamAppData…: command not found`, rc=127  |
| Linux default `sh` / Windows default `cmd /c`                          | ✅ args forwarded                                                                        |

One cause: mise pushes the script path onto a shell that takes a **command string**, as if it were
a file argument. `sh -c <path> ARG1` makes ARG1 into `$0`, so `$1` is empty.

**The file-shell contract is "a program that takes a script path plus args"**, and the defaults say
so: `unix_default_file_shell_args` is **`sh`**, no `-c`, described as _"For example, `sh` for sh."_
`cmd /c` is not a counter-example — `/c` is cmd's only way to start anything, and it forwards args
correctly (measured).

The fix is the POSIX idiom `sh -c '"$0" "$@"' <path> <args>`, which also stops the mangling because
the path stops being part of the command string.

**The blocking question is answered: yes.** Git-Bash `bash` execs a `C:\...` path as `$0` without
complaint — `bash -c '"$0" "$@"' 'C:\…\task' ARG1` → `ran: [ARG1]`, rc=0, where the current shape
gives rc=127. Paths and arguments containing spaces survive too.

**Dropping the `-c` instead was measured and rejected.** `sh <path>` makes sh _interpret_ the
script rather than run it, so the shebang stops choosing the interpreter:

```
sh -c <path>                  → bash-array ok: y []      shebang honoured, argument lost
sh -c '"$0" "$@"' <path> ARG1 → bash-array ok: y [ARG1]  shebang honoured, argument kept
sh <path> ARG1                → Syntax error: "(" unexpected
```

**The trap in this one: `is_posix_shell_program` counts fish, and fish is not POSIX here.**
`fish -c '"$0" "$@"'` → _"$@ is not supported. In fish, please use $argv."_ Reaching for that helper
unmodified would have broken fish while fixing everything else. fish has the _same_ defect
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
two files of _known_ line endings through the same command; the contradiction showed up immediately.

**Measure line endings by counting bytes** — `tr -cd '\r' < f | wc -c` against
`tr -cd '\n' < f | wc -c` — and **keep a known-good and known-bad control in the same run.**

**Implemented as #12334.** `table::print` does the styling and the trim, and `default_style` is now
private — with one entry point a table cannot be printed without the trim, which is how the spaces
got there. Eight call sites collapse to one line each. One `miseprintln!` rather than one per line,
so the newlines land exactly where they did and the only difference in the output is the trailing
space.

**Record — two concepts can share a word, and only one of them get handled.** `Padding::zero()` on
the last column reads as "no space after the last column" and is not wrong; it removes the space
_around_ a cell. The space that brings a cell up to its column's width is added separately and
survived. **Code that looks like it already addresses a symptom is worth checking against the
symptom, not against its name.**

**Record — closing the entry point outlives the fix.** Trimming eight call sites would have left the
ninth free to forget. Making `default_style` private means the next table cannot.

**The control had to come first, and this section is why.** Root-causing family B, the first
measurement of `mise settings` returned zero trailing-whitespace lines and looked like the record
was wrong — one row has nothing to fill _to_. The e2e therefore pins two alias targets of different
length and asserts both are present _before_ counting.

### The post-update step that decided the update had failed → #12363 — 2026-08-24

**The first item here that came from the user's own machine rather than a sweep.** They hit it
updating 2026.8.10 → 2026.8.11 on a managed Windows 11 box: `Replacing binary file... Done`,
`Updated mise to 2026.8.11`, and then `mise ERROR アクセスが拒否されました。 (os error 5)` with a
non-zero exit. The install was fine afterwards — new `mise.exe` in place, `mise-shim.exe`
refreshed, no leftovers in `TEMP`.

The failure is `cmd!(&*env::MISE_BIN, "plugins", "update").run()?` at the end of `SelfUpdate::run`.
`MISE_BIN` is mise's own path, so the spawn is the **first launch of the 92MB binary that was just
written**, and Defender for Endpoint refuses it until the scan finishes. Measured on that box: 5/5
failures immediately after the write, success 5 seconds later with an identical hash, and a 222KB
executable written the same way launching immediately.

**The AV is not the finding.** The finding is that the two housekeeping steps directly above it —
`update_mise_shim` and `reshim_after_update` — are already `warn!`-guarded, and only this one used
`?`. One line out of three. That is what makes it a defect rather than a policy question.

#### It was already reported, and I nearly wrote a duplicate

Searching before writing turned up discussion
[#8827](https://github.com/jdx/mise/discussions/8827) (2026-03-31, **no replies in five months**):
a private plugin over SSH makes `mise plugins update` exit 1, and `self-update` reports
`mise is already up to date` and then exits non-zero. The reporter had already narrowed it to the
same line. **Two triggers, one defect** — the subprocess never starting, and the subprocess failing
— and the PR body sets them side by side rather than presenting the Windows one as the whole story.

Also learned while looking: **jdx/mise has GitHub Issues disabled** (`has_issues=false`;
`open_issues=70` is the PR count). The task asked for an issue draft, and there is nowhere to file
one — reports live in Discussions. **Check whether the tracker exists before writing for it.**

#### Three things checked rather than assumed

1. **Is the placement outside `if status.updated()` intentional?** Yes. `d714d4c` (#1069,
   2023-12-03) put it after the `if`/`else` in the same hunk that introduced it, and the doc
   comment has been unconditional since. `731bde2` only restored the `?` while reverting miette.
   **Left alone** — the task proposed questioning it, and the history answers it.
2. **Why is the error a bare OS message?** Read duct-1.1.1: `ChildHandle::start` (`src/lib.rs:1271`)
   returns the raw `io::Error` from `SharedChild::spawn`, and the `command [...] exited with code N`
   wording is built only for a non-zero exit (`src/lib.rs:1706`). **The failure mode that says
   least about itself is exactly the one duct attaches no command to** — which is why the fix names
   the step. That is a reading of the crate source, not a guess about it.
3. **Does `&Path` work as duct's program argument?** `IntoExecutablePath` is implemented for
   `&Path` (`src/lib.rs:1795`). Checked because `&PathBuf` would have tripped clippy's `ptr_arg`
   and the repo forbids `#[allow]`.

#### The e2e that needs no AV, no network, and replaces no binary

This looked untestable at first — reaching the line means completing a self-update. It is not:

- `do_update_blocking` compares the version argument against `cargo_crate_version!()` and returns
  `Status::UpToDate` **before looking up a release**, so `mise self-update <current version>`
  without `--force` never touches the network.
- `env::MISE_BIN` is overridable through `__MISE_BIN` (`src/env.rs:686`), and
  `e2e/cli/test_reshim_with_shims_on_path` already uses that override — precedent, not invention.
- With `status.updated()` false, the plugin spawn is the **only** thing on that path that reads
  `MISE_BIN`; the shim refresh and the macOS signature check are both inside the updated branch.
- `assert_contains` requires a zero exit, so the assertion _is_ the bug.

Safety was checked rather than hoped for: the version string is derived from the running binary, so
a mismatch can only produce a tag that does not exist — the run fails at the lookup and **no binary
is replaced**. The `--no-plugins` control doubles as the proof the up-to-date path was taken; had
the version not matched, that line would have gone to the network and failed there first.

**Record — "this needs the real thing to reproduce" is a claim to test, not a reason to skip the
test.** The reproduction needed an AV holding a 92MB file. The _defect_ needed a subprocess that
does not start, and there is an offline, deterministic way to produce one.

### #12418's review round — three findings, and all three were mine to have caught

The heaviest review round of the week, on a change of about twenty lines. Every finding was valid.

**greptile P1 — cleanup deletes trust metadata.** `TRUSTED_CONFIGS` holds more than entries:
`config_file::trust` writes `<entry>.hash` beside one in paranoid mode, `mark_as_monorepo_root`
writes `<entry>.monorepo`. Neither records a path — one is a SHA-256 string, the other is written
empty — so resolving them yielded `Some("0123…")` and `Some("")`, neither of which exists, and
every `mise prune --configs` deleted content-bound trust and monorepo inheritance **for projects
that were still there**. The old `!path.exists()` kept them by accident, so this was a regression I
introduced, **and it hit unix too** rather than only the platform the PR was about.

Fixed by skipping metadata and removing it with the entry it belongs to — the way
`config_file::untrust` already handles all three. The suffixes live in one constant and the sibling
path is built with `config_file::with_appended_extension`, the same helper that creates them (made
`pub(crate)`), so the naming convention keeps one definition.

**Record — widening what a loop looks at is a behaviour change to the things it did not use to
touch.** The old check answered "does this file exist", which is true of every file in the
directory. The new one answers "does what this file records exist", which is only meaningful for
entries. Nothing in the diff said "and everything here is an entry" — that assumption arrived
silently with the rewrite.

**CodeRabbit — `exists()` swallows metadata errors.** `Path::exists` reports a permission error or
an offline mount as "not there", and here that decides whether to delete a trust record. Taken, but
**not with the proposed `?`**: propagating aborts `Trust::clean` and therefore the whole
`mise prune --configs`, including `Tracker::clean` one line earlier, so one entry on a disconnected
share would stop the command cleaning anything. Prune removes records, so _unknown_ keeps:
`try_exists().unwrap_or_else(|err| { debug!(…); true })`.

**CodeRabbit — the deletion assertions were vacuous on unix.** The sharpest of the three. Each test
deletes the target and then asserts `!entry.exists()` — but `exists()` follows the symlink a unix
entry is, so it is true the moment the project is gone, **whether or not `clean_in` removed
anything**. On unix those tests could not fail; only Windows, where the entry is a plain file, was
checking. Replaced with `std::fs::symlink_metadata(...).is_ok()` behind a named helper, applied to
**all ten** entry assertions rather than the two flagged — the "kept" ones had the mirror-image
problem, passing because the target existed.

**Record — both bot findings on this PR were assertions that could pass for the wrong reason.** So
was the Pester failure earlier the same day, where a suite fell over in setup and the red looked
like the defect reproducing. Three in one day, in work that was being careful about exactly this.
**Writing the control is not the same as checking the control can fail.**

### #12341's review round — the same house rule, and the opposite answer

greptile P2, the rule it raised on #12325: `AGENTS.md:147`, e2e tests do not need cleanup. Two `rm`
lines were flagged. **One went, one stayed, and the difference is the point.**

`rm -rf mise-tasks bin .mise` — settled the way #12325's round was: the scenario asserts on
`bin/deploy*` and `bin/build*`, the scenarios above it leave `xxx*` and `work/containers/*`. **No
overlap, so the reset was only tidiness.** Removed, with a comment saying so, so the next reader
does not put one back.

`rm -f bin/deploy.sh` — **load-bearing.** The two lines above it plant a hand-written file at the
old stub path to prove mise refuses to delete what it did not write, and the assertion _is_ that the
run fails while that file exists. The next scenario opens with `assert "mise generate task-stubs"`,
which needs success. Removing the line would fail the suite one assertion later.

**Record — "cleanup" and "un-planting a fixture" look identical and are not.** Cleanup at the end of
a scenario is the harness's job; removing something the test itself planted mid-scenario is part of
the fixture, the same as the `rm` that follows a `cat >file` in a setup block. `AGENTS.md:147` is
about the first. Said so in the reply rather than just declining half.

**Said what could not be measured.** Planting a file at the stub path on the released binary did not
reproduce the block — that binary predates the validation path — so the case for keeping the line
rests on the test's own two assertions, not on a run. Reported that way.

### #12333's review round — a count that did not say which two

CodeRabbit: the count proves two `Wrote to` lines exist and the path check proves one names
`bin/xxx.cmd`; **nothing proves the other names `bin/xxx`**. Correct, and a neat continuation of
#12329's round — there the unit was wrong (lines, not occurrences), here the count was right and
_underdetermined_.

**Record — a total is not an identity.** "There are two" and "there are these two" are different
claims. When a test's subject is _which_ files were named, count and name both.

**Checked the anchor before taking it.** The suggestion used `$`, and `e2e-win/display_path_separators.Tests.ps1`
trims "the ANSI reset mise may append" off exactly this kind of line — which would have made an
end-anchor unreliable. Measured piped and with `CLICOLOR_FORCE=1`: `cat -A` shows nothing between
the path and the newline, and the anchored grep returns 1 either way. **A suggestion that looks
mechanical can still rest on an assumption the repo elsewhere says is false; the cost of checking
was one command.**

**Escaped the dot, which the suggestion did not.** `bin/xxx.cmd` as a regex also matches
`bin/xxxXcmd`. In a PR whose whole subject is assertions that cannot tell one thing from another,
accepting a loose match would have been the wrong place to save a keystroke.

**Said which assertion is not red.** `bin/xxx` passes on the unfixed binary already — it guards that
the stub keeps being named, rather than reproducing the defect. Reported that way rather than
implying all three were red.

### #12329's review round — an assertion that pinned the wrong thing

CodeRabbit: `grep -c` counts **lines**, not occurrences, so two namings on one line would still
return `1`.

Correct, and worth keeping as a lesson about assertion intent. The test's subject is "the file is
named once"; `grep -c` pins "the file is named on one line". They coincide only because the two
namings happen to land on separate lines — and on Windows the message copy already wraps, so the
line relationship is not even stable across platforms.

Swapped to `grep -oF … | wc -l`, after measuring both forms against the released binary (`2` either
way today) so the change was not blind.

**Record — when an assertion counts, check that the unit it counts is the unit the claim is about.**
Lines are not occurrences; a substring is not a count. Both mistakes pass for the right reason today
and stop meaning anything the moment the output shifts.

### #12327's review round — a dedup key I chose, and the bot found what it hides

#### Second round — two bots, one defect, and it was mine again

greptile: a queued warning can stay queued, because `flush_pending_warnings()` returns early while
`CLI_SETTINGS` is unset and a later startup step can fail before the second `logger::init()`.
CodeRabbit, separately: `clap_error` exits before `add_cli_matches` and never flushes. **Same
defect, two entrances.**

**Measured on the released binary, which is what settled it:**

```
mise --cd /nonexistent-dir env    rc=1   settings-error blocks=1
mise --badflag                    rc=2   settings-error blocks=1
mise env                          rc=1   settings-error blocks=2
```

The old `eprintln!` printed during the first build, so those paths reported the broken file. Queueing
moved the only report past **seven `?` points** — `handle_shim`, `print_version_if_requested`,
`install_state::init`, the clap parse, `validate_cd_path`, `maybe_auto_update`,
`trust_active_config`. Nothing would have printed at all.

**Record — moving a diagnostic later moves it behind every failure in between.** The whole point of
the PR was to delay the message until the logger and CLI flags exist. What I did not count was what
sits in that gap. **When you defer an output, enumerate the exits between the old point and the
new one.**

**The tempting fix was wrong.** Flushing at the _first_ `logger::init()` would cover every early
exit — and would print before CLI flags are known, so `--quiet` could not suppress it, which is the
property the PR exists to add and which its own e2e pins. **A fix that satisfies the reviewer by
undoing the PR is not a fix.**

The flush now also runs at `handle_err` in `main.rs`, the one funnel every failure passes through,
**before** the requested-exit check — because `clap_error` returns `request_exit(code)` rather than
exiting, so a flush placed after that check would miss exactly the case CodeRabbit raised.
`flush_pending_warnings_for_fast_exit` became `flush_pending_warnings_before_exit`, now that it
serves two exit paths.

CodeRabbit's third finding was a readiness/queue race: a producer can read "not ready" and insert
after the drain. **Not reachable that I could construct** — both flushes run inside `logger::init()`
at startup — and fixed anyway, because the window is real in the code and closing it is four lines.
Readiness is now read under the queue lock and stored under both. `queue_deprecated` disappeared as
a consequence: inserting has to happen under the guard that made the decision, so a helper that
takes the lock by itself no longer had a safe caller.

**Record — printing must stay outside those locks.** `warn_deprecated_env_settings()` calls back
into `warn_deprecated`, which now takes the deprecated queue's lock; emitting while holding it would
deadlock. Lock order is one-way (flush takes files then deprecated, producers take one each).

**The new e2e case is a guard, not a reproduction, and the PR says so.** `mise --cd no-such-dir env`
passes on the released binary by construction; it would have failed against the queue-only version.
Worth having, worth labelling honestly.

One finding from CodeRabbit: the queue is a `BTreeSet<String>` keyed on the message, and the message
does not name its file, so two settings files failing identically collapse into one report.

**Reproduced rather than reasoned about** — a global `config.toml` and a project `mise.toml` with
byte-identical invalid TOML, against the released binary:

```
total blocks (unfixed): 4      # 2 files x 2 settings builds
unique messages:        1
  Error loading settings file: TOML parse error at line 2, column 12
```

Four identical strings. The finding was exactly right, and **it was a regression I introduced**:
the old `eprintln!` printed every occurrence, so nothing was lost before.

**The fix answers a bigger question than the one asked.** The bot offered two options — put the path
in the message, or key the queue on the path. Keying the queue would have fixed the collapse and
left the message useless: **it never said which file was broken**, and mise reads several. Putting
the path in the message fixes both, and the distinct key falls out of it.

**Record — when a dedup key is introduced, ask what two different things it can equate.** A set is
a decision about identity. Here the identity was "the parser's complaint", which is not the same as
"the file that failed". I picked the key without asking what it merges; the bot asked for me.

**Record — a finding can be a regression _and_ expose something older.** The collapse was mine; the
pathless message was not. Fixing the older one is what made the newer one go away, which is usually
the sign the fix is in the right place.

Left standing and said so in the reply: in the rare read-failure branch, `file::read_to_string`
already wraps with the path, so that one message now names the file twice. The branch users actually
hit had no path at all, and special-casing it would cost more than it returns.

#### Third round — a Major finding that a measurement demoted

CodeRabbit: `--quiet` is not honoured by the early-exit flushes, because they run before
`add_cli_matches` applies the flag. Labelled Major, "heavy lift".

**The first thing to establish was whether this PR broke it**, and it did not:

```
mise --quiet --badflag              rc=2   blocks=1
mise --quiet --cd no-such-dir env   rc=1   blocks=1
mise --quiet env                    rc=1   blocks=2
MISE_QUIET=1 mise env                      blocks=2
```

**Nothing suppresses those blocks today** — not the flag, not the environment variable — because the
old `eprintln!` went straight to stderr. So the PR holds parity on the early-exit paths and improves
the normal one. **A remaining gap in an improvement, not a regression.**

**Record — before treating a finding as a regression, measure the same command on the old binary.**
The finding was real either way, but "you broke this" and "you did not finish fixing this" call for
different answers, and only a measurement tells them apart.

Fixed the half that is reachable: `auto_update` and `trust_active_config` fail _after_
`add_cli_matches` but before the second `logger::init()`, so the flush ran at a stale level.
`handle_err` now re-inits the logger before flushing. An untrusted config is a common way in, so
this is not a corner case.

**Declined the other half, with the reason in the test rather than only in the thread.** Honouring
`--quiet` on a parser error means interpreting argv that clap has just rejected — guessing flag
semantics from a string known to be malformed, in order to decide whether to suppress a diagnostic.
The previous round already settled that losing the diagnostic is worse. `MISE_QUIET` does work on
every path, because it is read from the environment during the first settings build, and the e2e
pins that rather than leaving it a claim.

**Record — when you decline half a finding, pin the half you kept.** The two `MISE_QUIET` assertions
put the boundary where the behaviour is; a limit that lives only in a review thread is lost the day
the thread scrolls.

#### Fourth round — an outside-diff nitpick, declined with the equivalence checked

CodeRabbit, in the review body rather than inline: `escape_task_args` repeats the escape loop that
`escape_args_after_separator` already has, and the two can drift. Rated 🔵 Trivial / 💤 Low value by
the bot itself.

**The finding is correct**, and worth confirming rather than waving at: `separator_idx` is found by
matching `"--"`, so `escape_args_after_separator(&args[separator_idx..], 0)` returns `["--"]`
followed by the same escape loop — identical to `push("--")` plus the loop. The suggestion's own
diff was clumsier than needed (a `tail` vector, a `drain`, and a `let _ = &mut tail;`); the minimal
form is three lines.

**Declined for this PR anyway.** Every line this PR changes in `src/cli/mod.rs` is one rename,
~170 lines away. The PR is about a settings diagnostic; argument escaping is behaviour-bearing code
in another subsystem. Folding it in puts a change with no connection to the subject in front of the
reviewer, and any regression in task argument handling would land in a PR nobody would think to
check for it. Offered as its own PR instead — **sent as #12343**, see below.

**Record — "the finding is right" and "it belongs here" are separate questions.** Both were answered
in the reply, in that order. Agreeing with a bot is not a reason to widen a PR, and declining is not
a reason to leave the claim unverified. That region also looked freshly reshaped by the usage-rs
refactor (#12221), which is another reason not to reach into it from an unrelated change.

#### The same nitpick landed on #12314 too — 2026-08-23

CodeRabbit raised the `escape_task_args` duplication again, this time on #12314, and **with more in
it**: a _third_ copy at ~703-708, in the task-args loop. Read all three before answering — the
predicate `arg.starts_with('-') && arg != "-"` and the `TASK_ARG_ESCAPE_PREFIX` formatting appear at
466-476, 623-629 and 703-708. The proposed `escape_flag_args` extraction collapses all three and is
a better shape than the two-site reuse I worked out on #12327.

**Corrected one thing in the note rather than accepting it whole.** It claims
`escape_args_after_separator` "cannot be reused directly" for the second site. It can —
`escape_args_after_separator(&args[separator_idx..], 0)` returns `["--"]` plus the escaped tail,
which is what that branch builds by hand. The extraction is still right, for the third site.

**Declined again, and the repetition is now part of the reason.** #12314's whole change to
`src/cli/mod.rs` is one hunk at `@@ -829,7 +829,12 @@`; the code is ~200 lines earlier and in a
different subsystem. **A finding that keeps landing on unrelated PRs is asking for its own PR**, not
for whichever change happens to touch the file next. Said so, and the offer to send it stands.

**Record — a bot repeating a finding across PRs is information, not noise.** The first time it is
"out of scope". The second time it is evidence the thing is untethered from any current change and
needs a home of its own.

#### The promise kept — #12343, 2026-08-23

Sent as its own PR: **#12343 `refactor(cli): keep one copy of the task-flag escape rule`**, off
`upstream/main`, not stacked. The shape is the singular one — `escape_flag_arg(arg: &str) -> String`
— because an iterator-returning `escape_flag_args` covers the two slice sites but **not the third**,
which applies the rule to one element inside a `while`. The slice sites `map` over it; the
separator branch stops carrying the loop at all and delegates to `escape_args_after_separator(&args[separator_idx..], 0)`,
which is the equivalence checked on #12327 and again on #12314, now actually used. The predicate
survives once: `grep -c` for it in the file returns `1`.

**One new test, for the exception nobody had asserted.** All three copies carried "a lone `-` is not
a flag" — the stdin placeholder — and none of them tested it. A rule with three homes has nowhere to
pin its own edge case; a rule with one does.

**Not compiled locally**, and said so in the body. For a refactor that is thinner than I would like
— CI is the first thing to type-check it. What stands in is the existing coverage, listed
test-by-test against the site each one reaches, plus the equivalence argument for the delegating
branch, which is a _reading_ of `args[separator_idx] == "--"` and not a run. Both distinctions are
in the PR body rather than left for a reviewer to discover.

**Record — a declined finding needs a way back.** Saying "out of scope" twice is only half an
answer; the other half is the PR that carries it. **Whether the promise was actually kept is part of
the review response, not a separate favour** — and it is checkable, which is why the PR number is
written down here next to the two declines.

### #12325's review round — a bot citing a house rule, and the rule was real

One finding from greptile: the four `rm` lines in `e2e/config/test_config_file_bom` are unnecessary
because the harness cleans up. It cited `CLAUDE.md` as its context.

**The citation checked out.** `AGENTS.md:147` says it outright: _"E2E tests do not need cleanup
steps (rm, etc.) — the test harness handles that."_ Worth noting that 218 of 893 e2e files do use
`rm` mid-test, so "everyone does it" would have been a bad reason to keep them — **a documented rule
beats a majority practice, and neither is a substitute for checking.**

**My intent was different from what the bot assumed, and that still did not save the lines.** The
`rm`s were meant as case-to-case isolation, not end-of-test cleanup: if case 3 fails I want to know
it failed on `package.json` and not on leftovers from case 1. So the question was measurable —
does a file left from an earlier case change what a later assertion sees? Measured all four present
at once against single-file controls: `jq=1.7.1 node=20.0.0 pnpm=9.0.0 earthly=0.8.15` either way.
**No interference, so they were cleanup after all.** Removed.

**Then measured the other direction**, which is the one that actually matters: could dropping them
turn a case green by accident? Re-ran against the unfixed binary — controls still pass, every BOM
case still fails, `.node-version` still `﻿20.0.0` and the rest `null`. **A "harmless" deletion in a
test file is only harmless once you have re-run the test red.**

**Record**: when a bot cites a house rule, the check is _does the rule exist and say that_, not
_do I agree_. Here it existed and the disagreement about intent was resolvable by measurement in
both directions.

### #12318's review round — a weak assertion, and following it up doubled the fix

CodeRabbit, one comment, 🟡 Minor, both halves fair:

1. **`.any(|w| w == b"\r\n")` passes on a half-converted file.** True, and half-converted is its own
   defect. Endings are now **counted** — `crlf_count == lf_count` — on both sides of the round trip.
2. **The LF fallback had one fixture for three situations.** The doc comment claims LF for _missing_,
   _empty_ and _unterminated_, and only one of those was exercised. They moved next to the function
   in `config_file/mod.rs` and each has its own fixture now, plus mixed (first one wins).

**Chasing the second half is what found `.tool-versions`** — see the surface-3 section above. A
review comment about test coverage ended up doubling the size of the fix, which is not where that
usually leads.

**Writing the test also caught a function that did not do what its name said.**
`with_line_ending(_, Lf)` passed the string through rather than normalising, so it would have
quietly kept CRLF when asked for LF. The assertion I first wrote _documented_ that as correct.
**A test can lock in behaviour nobody decided was right** — when an assertion looks odd to write,
that is the moment to check the function rather than the test.

**#12314's two comments this round were acknowledgements**, and #12312's thread was resolved by the
bot. Nothing to do on either; read them before assuming otherwise.

### #12314's review round — the right direction, and **both suggested tokens were wrong**

CodeRabbit, one inline comment, 🟡 Minor: the test only checks generic failure text; assert the
failed path and the OS reason. It proposed two lines:

```diff
+ assert_contains_text "$out" "$dir"
+ assert_contains_text "$out" "Permission denied"
```

**The point was fair — the assertions were loose. Both tokens would have failed a correct build.**
Measuring the real output settled it in one command:

```
0: failed to set current directory to ~/workdir-probe/noenter
1: Permission denied (os error 13)
```

- **`"$dir"` never appears.** `display_path` rewrites `$HOME` as `~`, and `$dir` holds the absolute
  path. Asserted the leaf (`noenter`) instead — a name only this test creates, and one that survives
  the substitution.
- **`Permission denied` is the _platform's_ half of the message.** Only `os error N` is appended by
  Rust. On this machine the Windows sibling of this exact error renders as
  `ファイル名または拡張子が長すぎます。 (os error 206)` — so any non-English locale fails that
  assertion. Asserted `os error 13` instead.

**Also checked before relying on it:** asserting the source line only works if mise prints it.
`display_friendly_err` walks `err.chain()` link by link, and the default path hands the report to
eyre, which renders the chain as above. Both include it.

**The lesson, and it is specific to review suggestions about tests.** A suggested _assertion_ is a
claim about what the program outputs, and it can be wrong in the most expensive direction: **it
fails a build that is actually correct**, which reads as "the fix does not work". A suggested code
change that is wrong usually fails loudly at compile time; a suggested assertion that is wrong
looks exactly like a real defect. **Run the thing and read the string before adopting a token.**

`shfmt -d` (without `-s` — that flag disables `.editorconfig` and would switch the file to tabs)
and `shellcheck -x` are clean.

#### Second round — greptile found the test was **vacuous in CI**, and following it up widened the PR

Two comments, and they landed very differently.

**P2 — right, and it rewrote the test.** _"The Docker-based E2E job runs as root, so this branch
bypasses the only assertions that exercise an unenterable directory."_ Verified rather than taken on
trust: `MISE_E2E_DOCKER: "1"` appears **four times** in `test.yml`, and `run_in_docker` bind-mounts
`/root`. So the `id -u` guard was honest locally and **vacuous where it mattered** — CI would have
stayed green if the panic came back.

Following it up found something bigger. Looking for a reproduction that needs no permissions turned
up **`MISE_CD`**: `validate_cd_path` reads `cli.cd`, so the _environment_ route reaches the `chdir`
with **no checks in front of it at all**. A plainly missing directory aborts, where `-C` with the
same path reports it cleanly. Measured on both platforms. That became the test — deterministic, root-safe
— and it **also made a Windows test possible**, which the previous trigger could not support because
creating a `MAX_PATH`-busting path depends on the runner's `LongPathsEnabled`. The earlier "no
Windows test, on purpose" reasoning was correct _for that trigger_ and stopped applying once the
trigger changed. **Re-check a deliberate omission when its premise moves.**

**P1 — not reproducible, and said so with evidence rather than just disagreeing.** _"`mise --version`
with `MISE_JOBS=abc` now propagates the parse error, breaking a tolerant fast path."_ Measured:
`MISE_JOBS` is a clap argument with an `env` binding, so **clap** rejects it before Settings is
consulted (`rc=2`, identical before and after). Three settings-layer values (`MISE_HTTP_TIMEOUT`,
`MISE_RAW`, `MISE_ALL_COMPILE`) are tolerated by the loader, `rc=0`. And the one failure that does
reach the changed line **already aborts today** — `mise -C <unenterable> --version` → rc=134 — so
there was no tolerance there to lose. The structural half of the claim was right (`--version` does
pass through the line), which is worth conceding in the reply rather than winning the argument.

**CodeRabbit, same round: assert a non-zero exit.** Fair — an error message on a successful exit
would have satisfied every other assertion. Added as `assert_not_contains_text "exit=$status"
"exit=0"`, "not zero" rather than a specific code, since nothing here guarantees `1`.

#### Third round — a retraction, and an asymmetry I had introduced myself

**greptile withdrew its P1** after the measurements, unprompted: _"My original comment was wrong…
`try_get()` failing on this path doesn't suppress a currently-successful path — it surfaces a failure
that was already happening, just later and as a panic."_ Left without a reply; a concession needs no
answer, and adding one is noise on a PR a maintainer has to read.

**CodeRabbit: assert the exit status in the Windows test too.** Correct, and it was **my** gap rather
than a debatable suggestion — the Linux test gained that check in the previous round and the Windows
one, written in the same push, did not. Both now assert it, in the same shape: `Should -Not -Be 0`
for the failure and a strict `Should -Be 0` for each control. **When a review earns a change, apply
it to every file the argument covers, not only the one it was left on.**

`$LASTEXITCODE` is captured on the line after the invocation, before anything else runs — a cmdlet
leaves it alone, but the next native command would overwrite it.

#### The CI "failure" was two cancelled runs

Reported as failing; checked before changing anything. **No run on the branch has a `failure`
conclusion** — the two red marks are `test` workflow runs for superseded commits, cancelled when the
next force-push landed. **A cancelled check renders like a failed one; read the conclusion, not the
colour**, and re-check after a force-push before hunting for a defect that is not there.

### #12312's review round — the bot found a second bug by pointing at an asymmetry

CodeRabbit, one inline comment, 🟡 Minor: `Val`/`Default` fold the key but **`Rm` and
`validate_required_vars` still use the literal one**, so `_.unset` can miss what `Val` stored and
`required` can report PATH as missing.

**Right on both, and the `required` half is a bug that predates the PR entirely.** Measured on
2026.8.10 with none of the branch involved:

```
[env] Path = { required = true }   → mise ERROR Required environment variable 'Path' is not defined.
[env] PATH = { required = true }   → (no error)
```

PATH is set — it is _always_ set — and only the spelling differs. So the review comment turned into
a second fix rather than just a consistency tidy. The lookup now uses the folded name while the
message still reports the name the config wrote.

**`Rm` was checked before folding it, not after.** `EnvResults.env_remove` is read by
`config_file/mise_toml.rs` (the tera `env` context) and `backend/asdf.rs`, and nothing under
`src/cli`, `src/hook_env.rs` or `src/shell` reads it — so folding it **cannot** emit an `unset` for
the variable mise is about to write. Worth the two minutes: "make it consistent" is exactly the kind
of change that quietly acquires a second effect.

**The lesson.** The bug was one gate reading keys a different gate had rewritten. **When you
normalise at one gate, walk every other gate that reads the same keys** — `Val`, `Default`, `Rm`,
`required` are four doors into one map, and fixing one of them is what created the asymmetry the bot
saw.

A test was added for each: the `required` case is a reproduction (red before), the `unset` case a
guard (green either way, there so that folding `unset` could not become a way to drop PATH).

**Rebased onto current main** (`e5a5b9ee5b7e`) in the same round, no conflicts.

### #12277's review round — a bot finding that was simply correct, and a container to check it

Greptile, one comment, **P1**, empty review body (all of it was inline — check both, the body was
`length=0` here but that is not the norm): _"Ash command-mode payload is skipped."_ `ash` is not in
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

#### Second round, after the rebase — an **outside-diff** finding, declined with measurements

CodeRabbit reviewed the rebased HEAD and posted **no inline comments at all**: the whole review was
in the body, under _"Some comments are outside the diff and can't be posted inline."_ **Read the
review body even when the inline list is empty** — a `body_len=0` review is common enough that it is
easy to assume the inverse.

The finding was against `ps1_shim` — **#12274's code, already merged, not in this PR's diff**: the
temp `.ps1` makes `$PSScriptRoot` point at the temp directory, so a task loading
`Join-Path $PSScriptRoot "config.psd1"` breaks. _"Create the secure temporary `.ps1` file in
`file.parent()`."_

**Observation right, prescription wrong — and measuring the prescription is what showed it.**

- The observation was **already measured and documented** in #12274 (`file-tasks.md`, "PowerShell
  tasks with no `.ps1` extension"). Not a new discovery.
- **`file.parent()` would make the staged copy a task.** A `.ps1` in a task directory is discovered
  by extension. Measured: dropping `mise-task-hello-a1b2c3.ps1` into `mise-tasks/` makes
  `mise task ls` print `mise-task-hello-a1b2c3`. A phantom task, in the user's project, for the
  length of every run — plus writing into the working tree, which fails on a read-only checkout and
  leaves debris in the repo rather than temp if mise is killed.
- **The scenario already has a supported answer.** mise sets `MISE_TASK_DIR` and `MISE_TASK_FILE`
  from `task.file_path()` in the context builder — a different path that runs before `exec` stages
  anything. Measured from a pwsh task with a sibling `config.psd1`:
  `sibling resolved via MISE_TASK_DIR: yes`. And unlike `$PSScriptRoot` it reads the same on Linux
  and macOS, where nothing is staged at all.

**What the finding did earn:** the docs note says "use a `.ps1` extension" as the way out and should
name `MISE_TASK_DIR` too, for a task that wants to stay extensionless. That is a change against
merged code, so it belongs in its own PR — **do not widen an open PR to absorb a review comment
aimed at something else.**

### #12274's review round — the bot's scenario was unreachable and its point was still right

CodeRabbit, one comment, 🟠 Major, against the amended HEAD (it named the commit range, so it had
seen the `-Command` change): _"Line 1451 passes the `.ps1` shim into `get_file_program_and_args`,
which resolves the shell again. For an extensionless task with no task shell or shebang, this
replaces a configured default such as `pwsh -Command` with the `.ps1` extension mapping
`pwsh -File`."_ It asked for an E2E case with `windows_default_file_shell_args = "pwsh -Command"`.

**The scenario it named cannot happen.** An extensionless file with no shebang is not a task on
Windows — discovery needs a shebang _or_ an executable extension. Measured with both fixtures in
`mise-tasks/` and that setting exported: `mise task ls` lists only the `.cmd` one. So the requested
E2E case would have asserted against a task that never runs, and I said so rather than adding it.

**But checking it found a regression I had already pushed.** The re-resolution hazard _is_ real —
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
the _next candidate_ exposed a false premise in this PR; verifying a _bot's wrong scenario_ exposed a
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
the commit _before_ the fix. **Read which commits a bot reviewed before answering it**; the reply is
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
> _historical_ answer, asking the maintainer is not caution — it is handing them work I could have
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
  options in a `mise.toml` exercises the identical code path with a _released_ binary:
  `"github:Azure/azure-cli" = { version = "…", version_prefix = "azure-cli-", asset_pattern = "…" }`.
- **The driver has to be the right architecture too.** An x64 mise under emulation would detect
  `windows-x64` and the run would prove nothing. Read mise.exe's PE header (`0xAA64`) before trusting
  a single later line.
- **`platform.machine()` answers a different question than the one asked.** It reports the host CPU —
  `ARM64` even inside an emulated x64 process. The PE header (`0x8664`) and the
  `[MSC v.1944 64 bit (AMD64)]` build tag are what say _this is the x64 build_. **When asked whether a
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
command which _succeeded_ — the false-green direction, and the one the PR body made the most noise
about. **Writing it was the interesting part.** The two natural forms both report "accepted" against
the _fixed_ helpers:

| form                                | fixed helpers | `main`'s helpers |
| ----------------------------------- | ------------- | ---------------- |
| `if ( assert_fail "true" ); then …` | accepted      | accepted         |
| `( assert_fail "true" ) \|\| rc=$?` | accepted      | accepted         |
| child shell, plain top-level call   | **rejected**  | accepted         |

`assert_fail` rejects by calling `fail`, which `exit`s, and `set -e` is suspended inside an `if`
condition and to the left of `||`. **bash behaves identically**, so the child shell is not a zsh
workaround. A test written either of the first two ways would have passed against anything.

**CodeRabbit (major), on that same child shell:** `if <child>; then` treats _any_ non-zero exit as a
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
its seven lines verbatim _minus_ the `$env:MISE_SHELL -eq "pwsh"` guard — the line that keeps
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
path returns _before_ that check, and the refresh prints nothing. `cache_ttl` defaults to `0s` and
`_mise_hook`/fish share the hole, so it is parity with a pre-existing flaw rather than a regression —
but the fallback is uniquely positioned to pass `--force`, which is what shipped.

> **A measurement taken only at default settings does not refute a claim about a code path.** The
> control I built was sound and the conclusion still didn't generalise, because I never varied the
> setting that gates the path. Next time a bot names a code path, vary the settings that reach it.

**Structural: the guarded fallback was strictly more code than either precedent.** In zsh both arms
were byte-identical (`_mise_hook` with no arguments _is_ that `eval`); in pwsh the else-branch was a
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

**Copy this habit:** jdx closed by recording two theories he chased and _ruled out_ — that the zsh
test's regression mode is not unbounded recursion, and that staleness for already-installed tools
under `--no-hook-env` is the flag working as documented. Ruled-out theories are worth writing down;
they are what stops the next reader re-chasing them.

Taken in full in one commit, rebased onto main at #12152, merged 2026-08-19 10:55. Earlier bot rounds
on the same PR: CodeRabbit also asked for a UTF-8 BOM on the Pester file (`PSUseBOMForUnicodeEncodedFile`).

### #12089's review round — three rounds, and the finding was right while the patch was wrong twice

**Round 1 — Greptile (P1), valid: the fix made a latent bug reachable.** `--no-hook-env` omits the
`_mise_hook` definition while still emitting the command-not-found block, so the branch I had just
un-deadened called a function that does not exist. Measured, with the control:

|                                    | `_mise_hook` defined | command-not-found block emitted |
| ---------------------------------- | -------------------- | ------------------------------- |
| `mise activate pwsh`               | yes                  | yes                             |
| `mise activate pwsh --no-hook-env` | **no**               | **yes**                         |

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
| ----- | ------------------------------------ | ----------------------------------- |
| bash  | **yes**                              | yes                                 |
| zsh   | no                                   | yes                                 |
| fish  | no                                   | no — runs `hook-env` inline         |
| pwsh  | no                                   | yes                                 |

`bash.rs:44-52` always renders the whole `activate.sh` and passes the flag through as
`__MISE_HOOK_ENABLED_VALUE__`, so `--no-hook-env` controls whether the hook is _installed_, not
whether the function _exists_. pwsh puts the definition inside `if !opts.no_hook_env`, which is
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

| activation                    | installed | runnable after |
| ----------------------------- | --------- | -------------- |
| `activate zsh`                | ✅        | RAN            |
| `activate zsh --no-hook-env`  | ✅        | **NOTRUN**     |
| `activate bash`               | ✅        | RAN            |
| `activate bash --no-hook-env` | ✅        | RAN            |

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
a flag set before anything can throw — keeping the exception _type_, the part of the suggestion that
survives measurement.

**Two of three patches would have broken something.** Treat a bot's diff as a hypothesis with the
same standing as its complaint: measure the suggestion, not just the objection.

### #12080's review round — both bots found the same thing, and it was the dangerous one

Greptile (P1) and CodeRabbit (minor) independently said the orphan matcher was too loose: it
accepted `.mise.<anything>.__selfdelete__.exe`, and the caller acting on it **deletes the file**. A
predicate that only has to be right about _display_ can be sloppy; one that feeds `remove_file`
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
  _not_ warn: entries are search candidates, missing ones can be deliberate, and the docs recommend
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
(it claimed install's `<short>/<version>/<filename>` was the longer path; it is _shorter_, +30
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
it was invisible to the build jobs and only `unit*`/`nightly` went red — on _every_ open PR at once,
which is what made it look like infrastructure rather than a semantic conflict.

**When every PR fails the same way at the same moment, suspect `main`, not the PRs.** Check
`main`'s own content directly (`gh api contents?ref=main`) before diagnosing anything else. Reading
the error's file:line against `main` settled it in one step.

**#11883 changed an existing test, and that is the part to watch in review.**
`e2e/tasks/test_task_edit_nested_names` captured a path with `2>&1`, so the new warning landed in
the captured value and broke an equality assertion. Changed to stdout-only — but the reason it fired
is a genuine design question, raised in the PR body rather than buried: that block tests _"select the
first existing directory in include order"_, under which a missing entry is a candidate that lost,
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

**#11826 was closed by jdx** — _"I think this goes without saying"_. That was a docs PR explaining
what `tools = true` costs. Second docs PR of the pass to be judged obvious; #11830 was written to
avoid the same fate by leading with a measurement and a wrong sentence rather than an addition.

**#11814 was closed by jdx** — _"doesn't look like an improvement to me"_. #4397 carries that
outcome plus what came out of the attempt, so nobody has to rediscover it. Draft/ready and
open/closed are the maintainer's call; do not reopen.

**Do not panic when the `triage` bookmark moves.** On 2026-08-09 it went `894bae7e` → `bc71cd5d`
without me touching it, and `sl diff` between the two showed **19 source files** changed. That is not
contamination: the triage commit gets rebased onto `upstream/main`, so a diff between two of its
revisions shows _main's_ movement. TRIAGE.md itself was identical. Check
`sl log -r "parents(<rev>)"` against `upstream/main` before assuming anything is wrong.

**`windows-e2e` flakes on a teardown file lock — diagnosed on #11796, 2026-08-09, kept because it
will recur.** Only `windows-e2e` failed;
`test-ci` is a gate job that exits 1 when it does. The failure is
`e2e-win/shim_recursion.Tests.ps1` → **Container failed** with `Tests Passed: 84, Failed: 0` —
Pester's `Remove-TestDrive` hitting _"The process cannot access the file 'mytool.exe' because it is
being used by another process"_, i.e. a teardown file lock. That file last changed 2026-07-15
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

**jdx closed #11648 with _"not sure about this, it could make users think `--force`"_ and the
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
**#11853** aggregates both tranches. It is deliberately _not_ `set -e`, because a failure in the
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
a semver comparator gets wrong. An earlier revision _did_ sort and produced
`… 7.3.4, 7.3.4rc2, 7.3.4rc1 …`, resolving a bare `pypy3.6` to `7.3.3rc1`. **The PR body still
described that deleted sort for a while** — a body that outlives its diff is the same class of error
as an unrun command; re-read it after every design change.

**CodeRabbit's `Settings::os()` finding was real and worse than stated.** Three pypy call sites took
arch from `Settings` but OS from `std::env::consts::OS`. `PlatformTarget::is_current()` compares
against `Platform::current()`, which is **built from `settings.os()`** — so in `resolve_pypy_lock_info`
the branch was _selected_ by one OS and resolved with another, and `MISE_OS=linux` on a Windows host
would record a `win64` archive URL under the linux platform key. **The control that proved the fix:**
`mise ls-remote python` listing 208 entries / 87 pypy on win64 against 215 / 94 under
`MISE_OS=linux MISE_ARCH=x64` — an override that changes the output is what shows `settings.os()` is
the one being read.

## The Windows implementation-gap pass — 2026-08-12..14

**Scope note: this is not old-band triage.** The user directed a sweep for Windows implementation
gaps, so `#11xxx`-era discussions are in scope _here_ by that direction, against the standing scope
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

**The second one is where the guessing would have gone wrong, twice.** First guess — "MAX*PATH" —
looked confirmed by a length-only control. Then a rustc probe said the opposite: plain `std::fs`
(`create_dir_all`, `write`, `read`, `rename`, `canonicalize`, `read_dir`) all succeed at **490**
characters with `LongPathsEnabled=0`, so there is no blanket wall. Bisecting the install path
found the real edge — **233 chars installs, 253 fails** — which is `MAX_PATH` after all, but only
in `write_atomic`: it goes through `tempfile`, which does not get std's extended-length handling,
and prefixes the temporary with `.{filename}.`, so the temporary crosses 260 before the final path
would. The error message naming \_persisting a temporary file* was the clue that resolved it.

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
through `handle_shim`, `which_shim` resolves the name, and `args[0] = bin` re-executes a _different_
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
   `%NAME%` _even inside double quotes_, so correct quoting at the call site is not a defence.
   `(` and `)` are deliberately **not** rejected: `C:\Program Files (x86)` is far too common, and
   measured against `&` as a control they do not inject.
3. **`\` was fixed by rewriting it to `/`, not by dropping it from the list.** The list exists to keep
   `\` out of `ctx.rootPath`, which vfox hooks interpolate into shell commands; permitting it would
   have weakened the guard rather than fixed the platform mismatch. `\\?\` and `\\.\` stay rejected
   because they are the one place Win32 does _not_ accept `/`.
4. **`Path::file_name` follows the host's path grammar, and that is correct.** `\` separates only on
   Windows; on unix it is an ordinary filename character. #11982's first push asserted the Windows
   behaviour unconditionally and `unit-macos` caught it. CodeRabbit's suggested fix — split on both
   separators always — would make a unix shim named `weird\name` resolve to `name`. The tests are now
   a **platform-split pair** so the choice is pinned in both directions rather than left implicit.
5. **Reproducing an `argv[0]` bug needs a launcher that passes it verbatim.** PowerShell's `&`
   rewrites the path to backslashes before spawning, so #11423 looks _fixed_ from a PowerShell
   prompt. `cmd /c` passes it through, as does libuv. A "does not reproduce" from the wrong launcher
   is not a measurement.
6. **Pester does not carry `Describe`-scope functions into `It` blocks**, and it runs every suite in
   one process, so env vars must be saved and restored. On #11947 a helper defined in `Describe`
   looked cleaner than repeating the assertion and was _more_ certain to break than the `-ForEach`
   it replaced.
7. **`e2e-win` convention: no `Remove-Item $TestRoot` in `AfterAll`.** `$TestRoot` lives under
   `$TestDrive` and Pester owns that; jdx's own `task_artifact_cache.Tests.ps1` is the reference
   shape. `Set-Location $script:OriginalDir` must stay — Pester cannot remove `TestDrive` while the
   process sits inside it. The same line was on `main` in three files from #11937, #11947 and
   #11948; **#11985 removed all three (merged 2026-08-14).**
8. **`clap`'s `conflicts_with` is not rendered into `mise.usage.kdl` or the generated docs**, unlike
   aliases, which are. A conflict therefore needs prose in the docs if users are to learn about it.
9. **#11981 is a deliberate behaviour change, not a regression fix.** Measured that 2026.8.2 already
   destroyed an unmanaged file on Windows, so the protection is _new_; anyone who relied on a
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
    _and_ a `.ps1` — measured, both give "not a valid application for this OS platform". On Windows
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
wrong field and the wrong answer came back confirming it. When a review disputes what a value _is_,
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
- **5498** (👍3) `mise install --lazy`. jdx engaged at length: shim names are only known _after_
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
  real directory, a config placed _above_ the mapped root — reachable through `C:\` but not through
  `Q:\` — is **not** loaded. The control is the same config being loaded when the same directory is
  entered by its real path. `mise config` also reports `Q:\proj\mise.toml`, keeping the mapped
  spelling rather than the resolved one.
- **Trust survives the mapping.** `mise trust` from `Q:\proj` records the resolved real path, and
  the config then loads from _both_ spellings. Canonicalising is the right call here.
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
  renders as `B`, i.e. `dirs::CWD` _is_ the post-`cd` directory.
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

| check                                                              | result                                                                                                                            |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| a second process running the same `mise.exe` throughout the update | fine — exit 0, the holding process survives, no `.old`/`.bak` left behind                                                         |
| `TEMP` longer than 201 characters                                  | **destroys the install — #12062**                                                                                                 |
| install directory with write denied (`icacls /deny`)               | `mise.exe` survives, because the relocation fails before it can move anything. Exit 1 with a bare `os error 5` and no explanation |
| path with spaces, Japanese, `&` and parentheses (136 chars)        | fine — exit 0                                                                                                                     |
| `self-update <version>` downgrade and back                         | fine — 2026.8.6 → 8.5 → 8.6, each step confirmed by hash. This is also what proves the swap really rewrites the file              |

**The finding.** `self-replace` renames the running exe out of its install directory _first_, then
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
`has_lockfile_integrity` is false, so install takes the _real_ verification branch rather than
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
  transient-scratch role _and_ owns the directory.
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
is _shorter_: `DOWNLOADS + 30` against `DOWNLOADS + 32`. The filename was also miscounted as 22
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
   present unrun commands as observed output — extends to _derived_ claims: if a number can be
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
   leaves it `None` and the non-aggressive branch is unreachable _whatever the setting says_. Both my
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
   user who _has_ the CLI. zsh's `-p` already forces a `$PATH` search ignoring functions/aliases —
   the inverse of bash's. jdx/usage#760 excluded zsh **deliberately**, and the change was tried and
   reverted upstream in two days: `f65a7b465` (2025-07-16) → `dfdc67b94` (2025-07-18). mise's
   `completions/_mise` is correct as-is.
5. **The "Windows-only" framing was wrong twice over — read this before re-investigating.**
   On 2026-08-01 I reported a Windows-only bug, then retracted it, and _both_ were wrong. What is
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
     across every `&` invocation _within_ one call. One scenario per call.
6. **Do NOT try to make the asdf backend work on Windows.** Deliberately unsupported, not
   unfinished: `src/main.rs` swaps in `fake_asdf_windows.rs` whose `setup()` is a no-op stub;
   `ScriptManager::run_by_line` spawns the plugin script directly and Windows `CreateProcess`
   rejects a shebang-only file (os error 193, measured); `docs/.../asdf.md` marks asdf
   `Windows Support ❌` and steers users to vfox. asdf is legacy — new asdf/vfox plugins are no
   longer accepted into the registry.

---

## Process notes

- **The account owner rebases the fork's PR branches outside this session — pull before touching
  one.** On 2026-08-24 all seven open branches, and `triage`, were rebased onto a newer `main` by
  the owner between 01:36 and 05:09 UTC. Every local Sapling head was stale afterwards, and a
  `sl push --force` from a stale head would have silently reverted their work. `sl pull` first,
  every time, and read `remote/<branch>` rather than the local bookmark.
- **A rebase can dissolve a stack without touching a diff.** #12330 was stacked on #12329; after the
  two branches were rebased separately, `ancestor()` of their heads is a `main` commit and #12330
  carries its own replay of #12329's change. Both still say "stacked" in their bodies and both are
  `MERGEABLE`, so nothing looks wrong — **`ancestor()` is the only thing that answers it.** Re-run
  it after any rebase instead of trusting the word.
- **Work of mine can be superseded between sessions; check before restoring it.** The re-init guard
  I added to `logger::init` for #12327 was extended by the owner the same night with
  `Settings::cli_log_level()`, which covers the case mine left open (a build that keeps failing, so
  `--quiet` would never apply at all). A grep for my own phrasing returned zero and read like the
  change had been lost. **Grep for the behaviour, not for the wording you wrote** — and when the
  replacement is better, say so plainly rather than reinstating your version.
- **A green check from before an infrastructure break is not evidence the break does not apply.** On
  2026-08-24 six PRs were green and two red on the same failing brew step; the six were green only
  because their runs predated the Homebrew tap-trust change. The control that settled it was a
  **stranger's branch failing on the identical step** — not the age of my own checks.
- **Build and lint on CI, not on this box — set by the user 2026-08-11.** _"出来る限りCIでビルドとか
  clippyのチェックをお願い致します… forkして一旦、pushして確認することは可能なはずです"_. A local
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
  had checked that `target/debug/mise.exe` _existed_, which is not the same as it being current. The
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
  a _registry entry_ vetoes the `pipx.uvx` setting. Reading `pipx.rs:312` proves the `&&`; running
  `ansible` and `ansible-core` back to back with neither uv nor pipx installed proves the veto is
  per package, because the two produce different branches of the same error. The second costs one
  extra command and is what makes the reply unarguable.
- **When you disagree with a maintainer's diagnosis, lead with _their_ CI, not yours.** #11865 was
  first contradicted with a local Docker reproduction (their patch applied on main, `landlock_*`
  syscalls blocked by a seccomp profile → still exit 1). That is a _model_ of the runner and carries
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
    maintainer to re-run (an in-repo run _does_ get the pool).
  - `gh run rerun` is not available to this account (`Must have admin rights to Repository`). The only
    lever is a push that changes the SHA: `sl amend --date now` does that with no content change —
    **verify with `sl diff -r old -r new --stat` that it really is empty before pushing.**
- **The mirror of the 2026-08-14 lesson, measured 2026-08-23: failures that all look alike can have
  different causes.** The report was "CI is failing on the rate limit". Grepping each log:
  - `windows-e2e` — genuinely exhausted: `github rate limit: 0/5000 (core)`,
    `API rate limit exceeded for installation`, `Resets at 2026-08-23 12:19:52 +00:00`.
  - `e2e` on #12330 — **not a rate limit at all.** The same job logged
    `GitHub core rate limit: 4749/5000` and later `4443/5000`. It failed on `cli/test_exit_status`.
  - `test-ci` — **an aggregator.** Its log is literally `windows-e2e failed or was skipped`; it
    carries no information of its own and never needs separate diagnosis.
    2026-08-14 said different-looking failures can share one cause. Both directions are real, and the
    log answers either in one grep: **the remaining count and the reset time are printed**.
- **The reset time is in the log, so it never has to be guessed.** `resets at <time>` plus the epoch
  in `github rate limit: 0/5000 (core), resets at <epoch>`. The window is rolling and hourly, and
  the token is shared across the whole installation, so it can be drained again immediately.
- **A rebase round is cheap to justify before spending it.** On 2026-08-23 eight PRs were red and
  main had gained exactly one commit: `test(windows): stop pinning the usage version banner`,
  touching **one file**, `e2e-win/exec_inactive_tool.Tests.ps1`. That explains `windows-e2e` and —
  via the aggregator above — `test-ci`, which is the whole failure set for seven of the eight.
  Checked that before pushing eight rebases rather than after.
- **`cargo clippy --all-features` cannot run on this box** (`openssl-sys` build fails), but
  `cargo clippy --all-targets` can. Beware the difference from CI, which runs both: a local clippy
  newer than CI's reports lints CI does not (2026-08-11: `collapsible_match` in `backend/cargo.rs`
  and `large_enum_variant` in `cli/bootstrap.rs`, neither in the touched file). **Check the reported
  file before assuming a finding is yours.** And `cargo fmt --all` is still the cheap gate — the one
  lint failure that _was_ mine on #11846 was a long `warn!` line rustfmt wanted wrapped.
- **A negative conclusion needs a control that has nothing to do with mise.** Three times on
  2026-08-09..10 an "X does not work" claim was wrong, and every one would have been caught by one
  extra command:
  - **`mise settings get libc` reported "not set" while the setting was in effect** — reported to
    the user as a bug, and it was not. The measurement ran mise inside `$( )` under WSL, where the
    exported `MISE_*` variables and the `cd` never arrived. `$(printenv MISE_LIBC)` returning empty
    while the direct call returned `gnu` is the control that settles it, and it involves no mise.
  - **"`update_submodules` is never called for the aqua registry, so add the call"** — the premise
    was that mise git-clones the registry. It does not: `src/aqua/` contains no git at all and
    fetches a single `registry.yaml` over HTTP. Reading the _consumer_ before calling something
    unimplemented would have shown it.
  - **"#4678 cannot be verified on Windows"** — WSL was right there and had been used for other
    checks the same day.

  Rule: before writing "does not / is not / never", produce a control that would fail if the
  _measurement apparatus_ were broken.

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
  _"failed to run git: fatal: not a git repository"_, because gh tried to resolve it as a
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
  at a ready-for-review PR returned _"does not have the correct permissions to execute
  CreatePullRequest"_ (and 404 over REST) with auth healthy, `repo` scope present, rate limits
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
  `src/` change alone, let `lint` fail its _"assert render produces no diff"_ step, pull `git diff
HEAD` out of the job log, reconstruct the patch (strip the timestamp prefix), `patch -p1`, amend.
  One extra round trip and it lands exactly. Verify with `patch --dry-run` first.
- **`isAnswered=false` is not "nobody replied."** It is only the _marked-answer_ flag, and mise's
  threads are rarely marked. Batch metadata queries are good for spotting _movement_, not for
  deciding a thread is unanswered.
- **Placement rule, set by the user 2026-08-11: when a specific comment asks a question, reply to
  that comment.** _"可視性は気にしなくて良いです。それよりも投稿者へどれだけ有益な情報を届けられるかです"_ —
  usefulness to the person waiting outranks visibility to future readers. This **narrows** the note
  below: visibility is the tie-breaker only when no single comment owns the question (#2435's two
  unanswered people in different places is still a top-level case). #4581 went as a reply under
  @gbloquel's _"I just need to know if this is a bug and what solution you propose!"_, opened by
  quoting that line.
- **A threaded reply CAN be marked as the answer.** I claimed the opposite on 2026-08-09 while
  choosing where to post the #3428 reply; the user said they had had a threaded comment accepted, and
  the measurement backed them: of 50 answered jdx/mise discussions
  (`search(query:"repo:jdx/mise is:answered", type:DISCUSSION)` reading `answer { replyTo { id } }`),
  **two have a threaded reply as the accepted answer** — #11259 and #11168. So markability is not a
  reason to prefer top-level; **visibility is** (replies collapse behind "N replies"). #3428 went
  top-level on that ground alone, because its whole problem was an answer nobody saw for ten months.
- **NEVER write a node ID you did not fetch, and verify where a post landed.** The worst mistake of
  2026-08-09: I had queried #2435/#2441 for their _structure_ but not their `id`, then supplied
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
  posting".** Set by the user 2026-08-09: _"posting something similar to what others already wrote
  is pointless — I only want to post things that mean something."_ Applied to the nine remaining
  `#413`–`#3499` candidates, **6 of 9 were dropped**: two were redundant with what the thread
  already said (#68, #607), one was too thin (#862), and two would have been half-answers to people
  still waiting (#2435, #2441). A verified fact is not automatically a comment worth making. The
  test is: **does this thread lack this answer today?**
- **A pre-measurement read is not an answer.** #2338 was written up as "wrapper still needed" from
  reading `--help`; installing watchexec and running it showed the opposite, and the posted reply
  says the wrapper _can_ go. Two other near-misses the same day: the #1764 draft claimed
  `--hook commit-msg` delivers what the reporter wanted (it drops git's arguments), and the #2107
  draft asserted `PYTHON_CONFIGURE_OPTS` still works (it is inert unless `python.compile = true`).
  **Prove passthrough with a deliberately invalid value** — `PYTHON_CONFIGURE_OPTS="--bogus-flag-xyz"`
  produced `configure: error: unrecognized option`, which is proof rather than inference.
- **Check for a resolution comment before investigating — and re-check right before you invest, not
  just before you reply.** #5357, #5655 and a 108-thread sweep were all @Marukome0743 answering
  independently while threads sat in this queue. On 2026-08-09 it went further: **#1407 was answered
  hours after I finished a full investigation of it the same day**, with a better answer (real
  Miniconda on macOS + zsh 5.9, which was the gap I could not test). That person is sweeping this
  exact region _now_, so for anything below `#5260` the check has to be immediately before starting
  work, not at draft time.
- **A fix that closes a discussion usually does not say so.** In `#5701`–`#5790`, three of four live
  threads were already fixed and **not one fixing PR referenced its discussion**: #6852 was a
  _refactor_, #6168 was _PowerShell v5 support_, #10165 was _miserc discovery_. Searching PR titles
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
- **Re-run the _analysis_, not just the citations, when a held reply comes off hold.** Both replies
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
  no words with the discussion title. Do this _first_, not after the repro succeeds; a successful
  repro is exactly the moment the check feels unnecessary.
- **Never write an assertion for output you have not seen.** #11575's e2e failed on
  `assert "cat ../to/mise.toml" "[tools]"` — `mise unuse` removing the _only_ tool empties the file
  (measured: 1 byte), and `e2e/cli/test_use:52` already encoded that. The verification run before
  that PR only checked `-match 'uv'`, never the exact contents, so the guess went unnoticed. Same
  failure mode as the `MISE_CONFIG_DIR` and `find -type f` mistakes: **a check that cannot fail is
  not a check.** Run the whole scenario and print the actual bytes. Two probe bugs of that class,
  both from the #5501/trust investigation: `find … -type f` does not match **symlinks** (the trust
  store is symlinks — use `\( -type f -o -type l \)`), and in `find … | sed … || echo "(none)"` the
  `||` binds to the _pipeline_, whose status is `sed`'s `0`, so the fallback never ran. **A probe
  that cannot distinguish "no effect" from "not measured" is not evidence.**
- **Verify what a flag _is_ at command scope, not argument scope.** #11631 added `--file` to
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

- **Docs under `docs/` are prettier-formatted — `.prettierignore` only exempts a named handful**
  (`docs/cli`, `docs/registry.md`, `docs/environments.md`, a few more). `docs/tasks/*.md` is **not**
  exempt, so a docs-only PR still has to pass it. Run it the way `hk.pkl` does, which pins the
  version: `mise x prettier -- prettier --check <file>`. Prose is safe — `proseWrap` is left at
  `preserve`, so the ~100-column lines in these files are not rewrapped.
- **`markdownlint` cannot run on this box.** `npm:markdownlint-cli` 0.49.1 is installed and resolves
  (`mise which markdownlint` answers), but every invocation dies with `ERR_MODULE_NOT_FOUND` before
  reaching a file — an incomplete npm install, not a content problem. Substitute: match the new
  markup against markup already in the same file, and check `.markdownlint.json` for what is
  switched off (`MD013` line-length, `MD004`, `MD032` and others are). CI has the real check.
- **`cargo fmt` runs fine here even though a workspace `cargo check` does not.** fmt never builds
  dependencies, so the `libz-ng-sys` failure does not apply. #11631's first CI run failed on
  `hk`/rustfmt because adding `visible_alias` pushed four `#[clap(...)]` attributes over the width
  limit; `cargo fmt --all` reproduced CI's expected output exactly. **Run it before pushing any
  attribute edit.**
- **"`cargo check` does not run here" is true of the _workspace_, not of every member crate.**
  `cargo test -p vfox --lib` builds and runs: that crate never pulls `libz-ng-sys`. Cold build
  **15m44s**, incremental rebuild of just that crate **49s**. That was enough to verify #11793
  properly instead of shipping it on reasoning: with the fix, 4 passed; with one panic put back,
  `env_keys.rs:62:18: Expected table`, 1 failed. **A test that has only ever been seen passing has
  not been shown to test anything** — break the fix, watch it fail, restore. Try `-p <crate>` on any
  change confined to `crates/`.
- **Flag aliases render into the man page only.** `usage generate markdown` does not emit visible
  aliases, so `docs/cli/*.md` never changes for one — proof on main: `mise unset` has carried
  `flag "-f --file --path"` since #11616 and `docs/cli/unset.md` still reads `### \`-f --file <FILE>\``.
Hand-adding it makes lint's "assert `mise run render`produces no diff" fail. (Short flags *do*
appear in markdown headings; aliases do not.) Corollary: **a bot patch that edits`man/man1/mise.1`directly is wrong** — the next render reverts it. Fix the doc comment in`src/cli/\*.rs` instead.
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
  `e2e-win/bootstrap.Tests.ps1`, a file _this_ branch added — and jdx's #12003 had added one with the
  same name for an unrelated feature (`mise bootstrap` the system command, not `mise generate
bootstrap`). Two disjoint `Describe` blocks. Resolved by keeping theirs untouched and renaming mine
  to `generate_bootstrap.Tests.ps1`. **Read what the other side actually is before merging the two
  together**; the resolution here is a rename, not a merge.
- **The _schema_ half of render does run here — the blanket "render is impossible on Windows" above
  is too strong.** `xtasks/render/schema.ts` is a bun script that reads `settings.toml` and
  `schema/mise.json` and spawns only `prettier`; it never asks mise for the CLI surface. `bun
xtasks/render/schema.ts` regenerated `schema/mise.json` for #11837 with a diff that was exactly
  the removal — no reformatting churn. bun, prettier and `node_modules/toml` are already present.
  So: kdl/markdown/manpage need the probe branch, JSON schema does not.
- **Most `settings.toml` edits need no render at all.** `parse_env` and the long `docs = """…"""`
  block reach no checked-in artifact: `build.rs`'s `codegen_settings` writes to `OUT_DIR`,
  `xtasks/render/schema.ts` reads only `description`/`type`/`default`/`deprecated`/`enum`, and
  `docs/settings.data.ts` reads `settings.toml` directly at VitePress build time. Adding or removing
  a _setting_ does change `schema/mise.json`; changing how one is parsed or documented does not.
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
  assertions _before_ touching mise. Same trick for #11835's settings.toml walker, with a planted
  offender so a walker that silently found nothing could not pass.
- **A GitHub Actions probe repo is the right tool for CI-only bugs.** For #5665 a throwaway
  **private** repo with a matrix over `jdx/mise-action`'s `version:` input measured four mise
  releases against one config in a single push. Two traps: (a) mise-action runs `mise install`,
  which **creates the venv before your test step** — `rm -rf .venv` immediately before measuring, or
  the path under test never executes; (b) `gh run view --log` fails while a run is in progress — use
  `gh api repos/{o}/{r}/actions/jobs/{id}/logs`, and match the step _output_ (`^exit=\d`), not the
  echoed command.
- **`tasks/test_task_broken_symlinks` blocked every PR for a while and it was nobody's fault here.**
  #11574 added the test, then main moved and the expectation went stale. **The `test` workflow does
  not run on main pushes** — only `docs`, `perf` and `release-plz` — so a broken test lands
  invisibly and only surfaces on the next PR. jdx fixed it in #11618. Before concluding a red e2e is
  yours: check whether the failing test is one you touched, and compare run _creation times_
  against when the suspect PR merged.
