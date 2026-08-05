# jdx/mise Discussions triage

Working notes for triaging old, unanswered GitHub Discussions in jdx/mise.

**This file lives only on the `triage` branch.** It is never part of a PR — PR branches are cut from
`remote/main`, which does not contain it. Updates are made by amending the single commit on `triage`
and force-pushing.

**Scope policy:** old discussions only. New `#10xxx`-era discussions are left alone — maintainers
and other contributors pick those up. **Closed discussions are out of scope entirely.**

**Resolved entries are deleted from this file**, not archived here; the compact history lives in the
`mise-discussions-triage` memory.

---

## Standing directive — 2026-08-01

**Every defect this write-target work turned up is to be fixed.** The user said so explicitly and
asked that it not be forgotten, so treat the candidate list below as a work queue, not a set of
options. Shipped so far: #11571, #11575, #11609 — plus #11633, which came out of the same reading of
`first_config_file` and was reported independently as #5842.

### Candidate queue

| id | what | evidence | blocked on |
|---|---|---|---|
| **A1** | `$HOME/mise.toml` is read but is never a write target; `use` and `set` create a new file instead. `first_config_file` returns `$HOME/.config/mise/config.toml`, it is global, and the guard skips **the whole directory** | measured (alpine): remove the global config and `~/mise.toml` is chosen immediately | #11571 — same line, now inside `nearest_local_config_file` |
| **A2** | `--path`/`--file` pointing at a **non-existent directory**: `mise use` panics in `config_file::init` ("Unknown config file type"); `mise set --file` instead writes an **extension-less file** named after the directory. Two commands, one input shape, two different wrong answers | measured on v2026.7.18, and unchanged on the #11575 branch | #11575 |
| **B1** | `unuse`'s target ladder is a second implementation of `use`'s. Not a drop-in: its default arm searches the *loaded* configs for the tool and returns early via `config_file::parse` (`unuse.rs:170-180`), which `resolve_target_config_path` cannot express. Same "duplicated resolvers drift" class as #11571 | code reading only | #11575 |
| **B2** | `config_file_from_dir`'s name is a lie — after #11575 it is only ever asked about the cwd. Fold the rename into B1 | code reading only | B1 |
| ~~**B3**~~ | `mise use` had no `--file` and `mise set` no `--path` | **PR #11577, merged.** The ladder that followed it (#11616, #11631, #11640) covers every remaining command | — |
| **B3b** | `use`/`unuse` declare `value_hint = FilePath` although both accept directories (`set` uses `AnyPath`). Dropped from #11577 after measuring that `value_hint` never reaches `mise.usage.kdl`, so it changes no generated output — possibly inert entirely, since completions come from the kdl | measured | verify it does anything first |
| ~~**C2**~~ | Should an explicit `--path` honour the ignore filters? **Answered by #11609 (merged): yes, and it warns rather than erroring.** `config_file_in_dir` now scans through `loadable_config_files_in_dir`; `config_files_in_dir` stays unfiltered for `trust`/`fmt`/task discovery | measured | — |
| **C3** | `mise fmt` reformats configs that config loading excludes | measured; defensible for a formatter — probably a docs sentence, not code | — |

**C1 is closed: not a defect.** See "Checked and found sound" below.

## Where to start next

1. **`#5431`–`#5520` is closed out.** Replied: #5471, #5501, #5509, #5484, #5517, #5458, #5494,
   #5452. Only the four design threads (#5454, #5498, #5475, #5516) remain, deliberately.
2. **Now in `#5521`–`#5610`** (34 exist, **24 open**, all 2025-07-06..13; all read). Replied: #5530,
   #5531. **#5531 was held until #11580 merged**, then answered with the fix — that is the pattern
   for "do not reply, implement instead": reply *after* it lands, not never.
3. ~~#5523~~ — replied. **#5570 is drafted-in-principle but blocked**: the fix it needs (#11531)
   is merged and unreleased, so replying now would give advice that does not yet work. **Re-check
   after the next release**, then reply. See the band row for the full analysis.
4. `#5521`–`#5610` is done bar feature requests. **`#5611`–`#5700` is read in full** (26 exist, 22
   open). Replied: #5660, #5665, #5663, #5612. **#5686 is taken by #11572 — do not implement it.**
   #5664 is fixed on main but unreleased, so hold that reply. **#5646 is investigated but must not
   be posted** (user's call — already reported elsewhere).
5. **`#5611`–`#5700` is closed out.** Also replied: #5683, #5655 note below, #5630, #5653, #5654.
   - **#5683** — **not a bug.** `$HOME` moves `MISE_STATE_DIR`, so the whole trust store moves with
     it. Neither jdx's guess (hash algorithm) nor the reporter's (unexpanded `~`) was right; see the
     section below. Replied, and the user closed it with **no further action**.
   - **#5655** — **blocked on #11632, which already `Addresses` it.** Linux is verified:
     `brew:fswatch` installs with no brew present; `brew:watchman` failed at relocate and that is
     exactly what #11632 fixes. A macOS check was also handed to the user's Mac. **Reply once
     #11632 merges** — do not implement anything here.
   - #5611 / #5613 / #5633 / #5643 / #5670 need nothing — already answered adequately by others.
     (typescript-language-server is still absent from the registry, checked 2026-08-01.)
6. **`#5701`–`#5790` — the four threads with substance are all answered** (30 exist, 24 open).
   Everything else in the band is unread Q&A/Ideas: #5710 erlang, #5712 php PEAR, #5716 maven,
   #5728 sha256-vs-blake3, #5733, #5742 ubi executable bit, #5762 ruby, #5789 Docker generator.
   The transient 2025.7.15 release incident (#5701 / #5702 / #5703 / #5706) needs nothing.
   **Three of the four were already fixed and nobody had said so, and not one of the fixing PRs
   referenced its discussion** — title search would never have found them:
   - **#5723** (👍4, `raw = true`) — fixed by **#6852**, a *refactor* commit. Bisected on release
     binaries: v2025.11.1 broken, **v2025.11.2** works. #6852 added
     `task.is_some_and(|t| t.raw)` to `OutputHandler::raw()`, which is what guards
     `cmd.stdin(Stdio::inherit())`. **#7286 looks like the fix from its title and is not** —
     the repro already passes on v2025.12.6, which predates it.
   - **#5743** (ceiling paths) — the feature is **the reporter's own PR #6041** (v2025.10.7), and
     the `.miserc.toml` regression a second user reported is fixed by **#10165** (v2026.5.18).
   - **#5759** (`double_dash="required"`) — **not a mise bug**: the spec parser never consulted
     `SpecDoubleDashChoices::Required`. Fixed upstream in **jdx/usage#762** (the user's own PR),
     merged 2026-08-02. **Two hops from users**: usage has not released since, and mise pins
     `usage-lib` 4.0.0.
   - **#5779** (pwsh indentation) — fixed by **#6168** (v2025.9.0). The old activation sliced the
     raw line with `$MyInvocation.Statement.Substring($MyInvocation.OffsetInLine - 1)`, eating one
     char per leading space; `mise` is four characters, which is exactly why 0–3 spaces worked.
7. **`#5791`–`#5880` is opened, not closed out.** Replied: #5831. Implemented **and** replied:
   #5842 → #11633, #5840 → #11639. Still unread and worth a pass: **#5830** (👍5, Windows PATH too
   long — testable on this machine), #5876 flutter, #5797 Mason backend, #5813, #5821, #5833,
   #5869, #5855, #5860, #5871, #5850, #5820, #5825, #5798, #5801, #5791, #5839.
8. **The #11116 ladder is finished** — #11577, #11616, #11631, and **#11640 (open)** for the last
   two commands. **Reply to #4881 once #11640 merges**: my comment there names `config get`,
   `config set`, `dotfiles add` and the four `bootstrap packages` commands as what would follow, so
   the series needs a closing note. Nothing further to implement for it.
9. **#5840's second half is unbuilt and was promised as worth doing.** #11639 shipped `--no-prune`
   only; the reporter also asked for `auto_prune_old_versions = false`, and the reply says it is the
   half that matters for unattended upgrades. A `--prune` flag only has meaning once the setting
   exists, so both belong in one change.
10. **Linux bottle relocation — TAKEN BY SOMEONE ELSE, do not implement. #11632 MERGED
   2026-08-02 13:12, unreleased, so #5655 is now unblocked — reply to it naming the next release.**
   #11632 (@Marukome0743) fixes it and its body says
   `Addresses …/discussions/5655`, so **it covers #5655 too** — it was the only PR referencing that
   discussion. The failure I measured: `brew:watchman` dies at
   `cannot relocate .../bin/watchman-diag: replacement for @@HOMEBREW_PREFIX@@ does not fit
   (64 > 61 bytes)` because `relocate.rs:196` treats any non-ELF file containing NULs as an opaque
   fixed-width binary, and `/home/linuxbrew/.linuxbrew` (26 bytes) overflows the 19-byte
   placeholder that `/opt/homebrew` (13) never can. **#11632 answers the question I had left open**
   — `watchman-diag` is a **Python zipapp** (shebang + ZIP payload + NULs), and they verified
   against the real arm64 bottle that the placeholder occurs **only in the shebang**, so extending
   it is safe. Their fix classifies shebang executables as text before the NUL fallback, which is
   what Homebrew itself does; that is a better answer than the source-build fallback I had been
   considering.

### PRs — 2026-08-02

**Nine merged, one open.** Only #11575 made **v2026.8.0** (cut 2026-08-01 20:42); everything else
merged on 08-02, so it ships in the **next** release — the release PR (#11592, 2026.8.1) is still
open. Every discussion comment written about them says so explicitly.

| PR | state | from |
|---|---|---|
| ~~#11575~~ | **MERGED 2026-08-01** — in v2026.8.0 | bug B (`--path` ignored) |
| ~~#11571~~ | **MERGED 2026-08-02** — unreleased | #5458 investigation → #7015 |
| ~~#11577~~ | **MERGED 2026-08-02** — unreleased | #4881 / the #11116 retry |
| ~~#11580~~ | **MERGED 2026-08-02** — unreleased | #5531 |
| ~~#11609~~ | **MERGED 2026-08-02** — unreleased | the `--path <dir>` half of #11571 |
| ~~#11616~~ | **MERGED 2026-08-02** — unreleased | #11116 ladder step 2 (`unuse`/`unset`) |
| ~~#11631~~ | **MERGED 2026-08-02** — unreleased | #11116 ladder step 3 (seven `--path` commands) |
| ~~#11633~~ | **MERGED 2026-08-02** — unreleased | #5842 (global write lands in a conf.d drop-in) |
| ~~#11639~~ | **MERGED 2026-08-02** — unreleased | #5840 (`upgrade` prunes the old version) |
| #11640 | **open, ready for review** | #11116 ladder step 4 — `config get` / `config set` |

All of it is unreleased: v2026.8.0 was cut 2026-08-01 20:42 and everything else landed on 08-02.

**`tasks/test_task_broken_symlinks` blocked every PR for a while and it was nobody's fault here.**
#11574 added the test, then main moved and the expectation went stale (it asserted quoted command
names; usage KDL renders bare identifiers). **The `test` workflow does not run on main pushes** —
only `docs`, `perf` and `release-plz` — so a broken test lands invisibly and only surfaces on the
next PR. jdx fixed it in #11618. Before concluding a red e2e is yours: check whether the failing
test is one you touched, and compare run *creation times* against when the suspect PR merged.

**#11575 merging broke both #11571 and #11577** (`CONFLICTING`); both were rebased on 2026-08-02
and merged. #11577's conflict was #11598 (canonical domain → `mise.jdx.dev`) landing on the same
line as its `visible_alias`; resolution keeps the new domain **and** the alias, and the generated
`mise.usage.kdl` / `man/man1/mise.1` diffs stay at the 4 alias lines with no `mise.en.dev` left
behind. #11571's conflict was #11575's new `config_file_in_dir` landing where
`nearest_local_config_file` goes — both are kept.

### Comments posted for the merged PRs — 2026-08-02

- **#4881** (glasser, 👍1, **15 months with zero comments**) → #11577 shipped their exact ask.
  Records that #11116 did it across eleven commands and was closed with no review comments, that
  #11577 narrowed it to the two commands the discussion names and merged, so **the objection was
  scope, not the idea**. Their second ask (`mise set --env local`) was **measured working on
  v2026.7.15** and reported as already handled.
- **#5531** (tchernomax, 👍2) → #11580. Adds two things the investigation found: it is **not
  template-specific** (`"npm:cowsay" = "1.2.3:x"` fails identically) and **not a regression**
  (colon-free templates work back to v2025.7.0).
- **#7015** (ccjmne, 👍3) → #11571. The **reading** half was fixed by #7271 (risu729 said so); the
  **writing** half stayed broken and silent until #11571. Points at #11609 for the remaining
  `--path <dir>` case.

- **#5842** (parera10) → #11633. States the thing the reporter will hit next: the file *created*
  when no global config exists is `config.toml`, not the `mise.toml` they had been using — that is
  the name `mise use --help` documents for `--global`, and `MISE_GLOBAL_CONFIG_FILE` overrides it.
  Also lists the other commands the same change fixes (`set -g`, `settings set`, `unuse -g`,
  `edit`), since the report only names `use`.
- **#5840** (justinmayer, 👍7, **zero comments in a year**) → #11639. Separates the reporter's two
  asks explicitly — the flag shipped, the setting did not — and explains **why their case was not
  already covered**: `upgrade` does spare versions a tracked config or tool stub still needs, and a
  virtualenv is neither. Ends with the workaround that works on the current release (`mise use`
  does not prune, measured).
- **#5831** — replied 2026-08-02.

No comment for **#11575** (no originating discussion — found in my own investigation) or **#5458**
(already answered; nothing in these merges changes that answer). **No comment for #11631** either —
the user's call; #4881 gets one closing note when #11640 lands instead of one per rung.

### PR #11640 — `#11116` ladder, final step (`config get` / `config set`)

The two commands were file-only while the other nine resolve a directory, and
`e2e/cli/test_config_target_aliases` already pins "all four accept a directory as well as a file,
under either name". Adding `--path` alone would have created a new inconsistency, so the PR also
routes an **explicitly named** target through `resolve_target_config_path(prefer_toml: true)`.

Two things that must not be undone by a later refactor:

- **The default stays on `top_toml_config()`.** The resolver's own no-path default is
  `local_toml_config_path_from_dir`, a different rule; routing the default through it would change
  behaviour for everyone not passing the option.
- **`prefer_toml: true` is load-bearing.** `config_file_in_dir` can return `.tool-versions` under
  `asdf_compat`, and these two feed the path straight to a TOML parser.

Measured before implementing (v2026.8.0): `--path` → `unexpected argument`; `-f <dir>` →
`Is a directory (os error 21)`; `-f <missing>` → `No such file or directory (os error 2)`. Both raw
errors collapse into one `config file not found: <path>`. **The file is still never created** —
these two have always required an existing file, and creating one is a separate behaviour change.

CodeRabbit, three findings, one taken:

- **Declined — "document `--path` in the Markdown pages."** usage-lib renders visible aliases into
  the **man page only**. Proof on main: `mise unset` has carried `flag "-f --file --path"` since
  #11616 and `docs/cli/unset.md` still reads `### \`-f --file <FILE>\``. Hand-adding it would make
  lint's "assert render produces no diff" fail.
- **Declined — "the nearest mise.toml" contradicts `top_toml_config()`.** Argument from the
  function name. `top_toml_config()` → `load_config_paths()` → `all_dirs()` → `Path::ancestors()`,
  i.e. nearest first. Measured with `env.WHICH` set differently in parent/child/global: from
  `parent/child` → `child`, from a config-less `grandchild` → `child`, with nothing local →
  `global`. The sentence's only gap is that last fallback, and it is shared verbatim with the other
  commands.
- **Declined — "`Can be a file path or directory` is a sentence fragment."** It is the exact string
  `src/cli/set.rs:70` and `src/cli/unset.rs:22` already print. Rewording two of six would trade a
  fragment for the inconsistency this whole series exists to remove.
- **Accepted (nitpick) — assert the resolved path, not just the message.** Right, and it earns its
  keep: for the directory cases the path is the only thing showing the argument reached the config
  file *inside* the directory rather than being used as-is.

### PR #11639 — `mise upgrade --no-prune` (#5840)

`upgrade` deleted the version it upgraded away from, install directory and all, with no way to stop
it. Measured on v2026.8.0 with `jq = "1"` and 1.7 installed: `mise upgrade jq` removes
`~/.local/share/mise/installs/jq/1.7` and the cache entry. Same with `--bump` — removal is driven by
`outdated`, not by whether the config gets rewritten.

`mise unuse` already had a `--no-prune` with the same meaning, which made the name and the doc
wording a non-question.

**It empties `to_remove` rather than guarding the uninstall loop**, so `--dry-run` stops announcing
a removal it will not perform. Guarding the loop would have made the dry-run lie.

Second change: the two `await`s that resolve tracked configs and stubs are skipped when `to_remove`
is empty. That path was already reachable before this PR whenever every upgrade was in-place.

**The existing guard is worth remembering**: `upgrade` keeps any version a *tracked config* or
*tool stub* still needs (built up by #10790 and #11501). It cannot see a reference held outside
mise, which is exactly why a virtualenv broke.

### PR #11633 — global write lands in a conf.d drop-in (#5842)

`first_config_file` skips conf.d while choosing but falls back to `files.first()`, and
`config_files_from_dir` inserts conf.d entries **first** — so a config dir holding only drop-ins
handed one back to `global_config_path`, whose own doc says "the preferred global config file to
write to". One `.filter` on the return value. All nine callers are write-target resolution, so
`set -g`, `settings set`, `unuse -g` and `edit` are fixed by the same line.

CodeRabbit claimed the filter breaks `.tool-versions` + conf.d. **Invalid, and measured on
v2026.8.0**: `global_config_files()` inserts `~/.tool-versions` *before* the conf.d entries, so with
both present unpatched mise already targets `~/.tool-versions`, and the filter only rejects conf.d.
Declined the code change, **took the test it asked for** — the fix leans on an insert order declared
~65 lines away with nothing guarding it.

### PR #11616 — `#11116` ladder, step 2 of 5

`mise unuse --file` / `mise unset --path`. **#11577 itself created the asymmetry** — the command
that adds a tool took both spellings and the one that removes it did not — which is a much easier
argument than "widen the scope". Remaining after this: `config get`, `config set`, `dotfiles add`,
and the four `bootstrap packages` commands (`use`, `import`, `brew tap`, `brew untap`).

CodeRabbit review handled on 2026-08-02:

- **Accepted (real):** `mise unset` was the only one of the four whose help did not mention
  directories, while resolving through the same `path.is_dir()` branch. Fixed **at the source**
  (`src/cli/unset.rs` doc comment) — CodeRabbit's patch edited the generated `man/man1/mise.1`
  directly, which the next `mise run render` would revert.
- **Declined:** renaming the placeholder `<FILE>` → `<PATH>`. `mise set --file` — the counterpart
  merged in #11577 — renders `<FILE>` and documents directory support in prose. Matching it keeps
  the pair consistent; renaming only `unset` would make it the odd one out in the other direction.
- **Accepted (nitpick):** directory-target coverage added to `e2e/cli/test_config_target_aliases`,
  which also makes the new help text checkable rather than merely asserted.

### PR #11609 — `--path <dir>` writes into an excluded config

Found while resolving #11571's conflict: **#11575's `config_file_in_dir` has the same defect
#11571 fixes for the other two resolvers.** It picks with `config_files_in_dir` +
`first_config_file`, neither of which applies `config_dir_is_ignored` / `config_path_is_ignored`.

**Reproduced on v2026.7.15 (Windows, isolated scratch env)**: with the dir excluded,
`mise config ls` lists only the global config, `mise set --file <dir> FOO=bar` succeeds silently
with exit 0, `FOO = "bar"` lands in `<dir>/mise.toml`, and `mise env` never surfaces it. Control
without the exclusion round-trips fine.

Fix adds `loadable_config_files_in_dir(dir, filenames)` (same scan, ignore filters applied) and
uses it in `config_file_in_dir`; the fallback still returns the default name — the directory was
named explicitly — but warns. **`config_files_in_dir` stays unfiltered on purpose**: `cli/trust.rs`
has to see a file to un-ignore it, and `cli/fmt.rs` / `task/task_list.rs` want everything on disk.
`mise unuse --path` (`cli/unuse.rs:156`) resolves through the same function and is fixed too.

Deliberately **branched from `main`, not stacked on #11571**, so the two merge in either order.
Once both land, `nearest_local_config_file`'s loop body can call the new helper — do that in
whichever merges second. PR body asks the maintainer whether an explicitly-named excluded
directory should warn (chosen) or be a hard error.

**Duplicate check before implementing**: PR search on `config_file_in_dir` / `ignored config write` /
`config_dir_is_ignored`, plus a GraphQL pass over all 26 open PRs — none touch `src/config/mod.rs`
except #11571.

### PR #11571 — found while investigating #5458 (not from a discussion)

`mise use` could pick a write target that config loading deliberately skips. The two write-target
resolvers are separate implementations of one rule and only `local_toml_config_path_from_dir` kept
the #7015 exclusion; `config_file_from_dir` applied only `!is_global_config`. With `MISE_CONFIG_DIR`
relocated, `mise use` walked to `$HOME`, stopped recognising `~/.config/mise/config.toml` as global,
and wrote the tool there — into a file `mise config ls` refuses to load, so the write did nothing.

Reproduced on **v2026.7.15 and v2026.7.18, Linux (alpine) and Windows**. Fix extracts
`nearest_local_config_file(start, filenames)` and puts both resolvers on it. `mise set` unchanged
(verified across 3 scenarios against the released binary); `mise use` additionally starts honouring
`MISE_IGNORED_CONFIG_PATHS` and `MISE_NO_CONFIG`, stated explicitly in the PR body.

### Two more write-target defects, measured on v2026.7.18 (Linux + Windows). Neither is reported upstream.

**B — FIXED, PR #11575 (draft). `--path` was silently ignored by `use`/`unuse`, and `unuse` deleted
from the wrong file.**
`config_file_from_dir(p)` ignores `p` and walks `all_dirs()` (ancestors of **cwd**). `use.rs:255`
then checks `from_dir.starts_with(&cwd)` — which is *true*, because `from_dir` is cwd's own config —
so the guard enables the bug instead of preventing it. Measured with `here/mise.toml` and
`other/mise.toml`, run from `here`:

| command | wrote to |
|---|---|
| `mise use --path <base>/other` | `here/mise.toml` ❌ |
| `mise use --path <base>/here/sub` | `here/mise.toml` ❌ |
| `mise unuse --path <base>/other uv` | **removed `uv` from `here/mise.toml`** ❌ destructive |
| `mise use --path <base>/other` from a dir whose walk finds nothing | `other/mise.toml` ✅ |
| `mise use --path <base>/other/mise.toml` (a *file*) | `other/mise.toml` ✅ |

So `--path <dir>` only works when cwd has no config in scope. `mise use` has no `--file` (#11116 was
never merged), so the pre-fix workaround is to pass a file path to `--path`.

**The obvious fix — `all_dirs()` → `all_dirs_from(p)` — is wrong, and this is worth remembering.**
`Path::ancestors()` on a relative path ends at the **empty path**, and `config::glob` resolves
`"".join("mise.toml")` against the process cwd. So `--path ../other` would still land on the cwd's
config; `sub/../other` would scan `sub/`; `..` never reaches the real grandparent. Any upward-walk
design needs `p` absolutized first, and even then `unuse --path ./sub` can still delete from the
repo root.

What shipped instead: a new `config_file_in_dir(dir)` that looks **only inside `dir`** (lowest
precedence non-global config, else `dir/mise.toml`, or `.tool-versions` under `asdf_compat`), with
the `--path` arms routed through `resolve_target_config_path`, which now absolutizes once.
**`config_file_from_dir` is untouched**, so nothing that omits `--path` changes — and it does not
collide with #11571, which rewrites that function's body.

The no-walk semantics are the documented ones, not a new invention: `use.rs:35` "the config file at
the given path", `use.rs:79-82` "look for a config file **in that directory** following the rules
above" (those rules being `mise.toml` over `mise.local.toml`), and issue #3033's reporter asking for
"a config file **in the PWD**". The one behaviour change is that `mise use -p .` in a config-less
directory now creates `./mise.toml` instead of walking to the project root — flagged in the PR body.

Measured against released v2026.7.18 on Windows: the 4 `--path <dir>` rows flip; `--path <file>`,
`--path .`, all three no-`--path` `use` shapes, `use -g`, and all three `mise set` shapes are
byte-identical. `unuse --no-prune --path ../to` now leaves the cwd's config intact.

**Also confirmed unchanged by this PR:** `mise use --path <directory that does not exist>` panics in
`config_file::init` ("Unknown config file type"). Measured on both v2026.7.18 and the fix branch —
pre-existing, out of scope, noted in the PR body.

**D — `$HOME/mise.toml` is readable but unwritable.** With both `~/mise.toml` and
`~/.config/mise/config.toml` present, `mise config ls` lists **both**, yet neither `mise use` nor
`mise set` will ever write to `~/mise.toml`; from `~/work/proj` they create `~/work/proj/mise.toml`.
Isolated: delete `~/.config/mise/config.toml` and `~/mise.toml` is chosen immediately; an
intermediate `~/work/mise.toml` is chosen normally. Cause: at the `$HOME` level `first_config_file`
returns `.config/mise/config.toml` (it precedes `mise.toml` in `LOCAL_CONFIG_FILENAMES`), that is
the global config, and the `!is_global_config` guard then skips **the whole directory**. Same
read/write asymmetry family as #11571 and it touches the same line, now in
`nearest_local_config_file` — worth doing after #11571 lands, not alongside it.

**C — investigated to a conclusion; neither half is a defect.**

*`mise fmt`* does rewrite configs that `mise config ls` excludes — verified for both a relocated
`MISE_CONFIG_DIR` and `MISE_IGNORED_CONFIG_PATHS` (`go="1.26"` → `go = "1.26"`). It only reformats,
and a formatter arguably should format the mise configs that are in the directory regardless of
whether they get loaded. Not worth filing.

*`mise trust <dir>`* is **correct**. It does resolve through the unfiltered `config_files_in_dir`
(`trust.rs:144`) and so can pick a config that loading excludes, but the consequences are benign,
measured end to end:

- `mise trust /root` writes `~/.local/state/mise/trusted-configs/root-ce059025bec8c360 -> /root`
  (`config_file::trust` → `file::make_symlink_or_file`, `config_file/mod.rs:555-561`).
- It does **not** over-trust descendants: `/root/proj` reads `untrusted` from `mise trust --show`
  both before and after. Confirmed against a control (`mise trust /root/other` adds its own entry).
- `--show` legitimately omits the excluded config: `config_path_is_ignored` returns true from
  `is_default_config_dir_override_filtered` **before** the `include_ignored` early-return
  (`mod.rs:2012`), so `include_ignored: true` does not resurrect it.

**Why I first called this inconclusive — two probe bugs, same class as the env-var mistake:**
1. `find … -type f` does not match **symlinks**, and the trust store is symlinks. Use
   `\( -type f -o -type l \)`.
2. `find … | sed … || echo "(none)"` — `||` binds to the *pipeline*, whose status is `sed`'s `0`,
   so the fallback never ran. Empty output read as "nothing was written" when it meant "I did not
   look correctly." **A probe that cannot distinguish "no effect" from "not measured" is not
   evidence.**

## Status — 2026-07-31

**The 2025-06 band (`#52xx`–`#54xx`) is closed out.** Every implementation candidate it produced has
shipped, and the reply queue is empty:

- Implemented: #5283 → #11536, #5288 → #11553, #5281 → **#11567 (merged, replied)**, plus the
  spin-offs `parallel.rs` → #11532 and UTF-16 checksums → #11552 (corrected by #11558). `type -p` →
  upstream jdx/usage#760.
- Replied: #5263, #5369, #5414, #5349, #5298, #5397, #5418, #7193, #5399, #5292, #5295, #5362,
  #5365, #5288, #5301, #5326, #5430, #5304, #5302, #5331, #5358.
- **Checked and deliberately not replied to:** #5287, #5367, #5274, #5286, #5395. Each already
  carries a correct answer from another contributor; verified against current main (see below).
  Adding a "this shipped in vX" note would be noise.

### Why those five need nothing

| # | existing answer | verification |
|---|---|---|
| 5287 | risu729: aqua-registry added `cosign.bundle`; #5314 | #5314 + #7314 merged; bundle support live at `aqua.rs:1103`/`:1696`/`:1728` |
| 5367 | roele: needs `compression-zip-deflate`; #5391; "manual update to 2025.6.6 required" | #5391 merged; **compare API: absent from v2025.6.5, present in v2025.6.6** — roele's version is exact |
| 5274 | risu729: old versions have no assets; #5303 excludes them from `ls-remote` | **measured**: `mise ls-remote kubectx` now lists 0.9.0–0.11.0 only; 0.7.x/0.8.x gone |
| 5286 | jdx answered | not re-checked (user's call) |
| 5395 | risu729: PATH precedence, 2026-07-10 | correct; only residual is that `mise doctor` self-diagnoses this since #10919 / v2026.7.6 |

---

## Next band — `#5431`–`#5520` (all 33 open threads read, 2026-07-31)

44 discussions exist in the range; **33 open**, and every one has now been read in full — body and
all comments.

Closed, out of scope: 5431, 5432, 5437, 5445, 5451, 5464, 5472, 5499, 5500, 5506, 5514.

**Headline: this band contains no implementation candidate.** Every thread with a concrete,
reproducible defect has already been fixed — several by contributors who then never told the
thread. That is the opposite of the 2025-06 band, and it means the value here is almost entirely in
*replies*, not code.

**One small candidate did fall out of the #5517 reply**, though it is a papercut, not a defect:
`backend_arg.rs:329-335` builds "Did you mean?" from a 0.8-threshold fuzzy match over
`REGISTRY.keys()` plus aqua ids, so `mise use cargo` is offered `argo` / `cargo-make` and never
`rust`. A curated component→toolchain hint (`cargo`/`rustc`/`clippy` → `rust`, `gem` → `ruby`)
would close it. **Do this as a suggestion, not a registry alias** — an alias would mean "I asked for
cargo and got all of rustup", reintroducing the surprise #9608 deliberately turned into an error.

### Verified fixed, thread never told — best reply candidates

| # | 👍 | what it reported | verification |
|---|----|------------------|--------------|
| ~~**5471**~~ | 1 | tar sparse extension (`GNUSparseFile.0`) yields a "successful" install with no usable binary | **REPLIED 2026-07-31.** Fixed in stages: #6380 (first release **v2025.9.16**, bisected), then #10821 PAX sparse, #10978 malformed PAX metadata, #11028 move to the `jdx-tar` fork. `file.rs:3272` `test_extract_archive_handles_pax_sparse_tar` asserts no `GNUSparseFile.*` survives extraction — the reported symptom exactly. **Reporter's account is deleted (`author.login` null), so no @-mention.** |
| ~~**5501**~~ | 3 | `mise set` writes to the parent directory's config, not the current one | **REPLIED.** Fixed — measured on v2026.7.15 across 6 cases: with a child config, `set` *and* `unset` both hit the child (the reporter's 3rd observation was that inconsistency). `set.rs:396` passes `prefer_toml: true` → `local_toml_config_path_from_dir`. **Their 2nd observation still holds**: with *no* config in cwd, `set` silently walks up and does not create one; `set` has `--file` but no `-p`, while `mise use -p .` does create. `mise set --file mise.toml` *creates* the file, so the behaviour is reachable — a `-p` on `set` would be a reasonable follow-up |
| ~~**5484**~~ | 1 | ".NET as a core tool — would you be open to a PR?" | **REPLIED 2026-08-01.** Shipped: #8326 added `src/plugins/core/dotnet.rs`, first release **v2026.2.22** (bisected; merged 02-24, no release until 02-27). `registry/dotnet.toml` lists `core:dotnet` **first**, so plain `dotnet` resolves to it — **measured**: `mise tool dotnet` → `Backend: core:dotnet`. Also aliases `dotnet-core` (#9807) and registers `global.json` as an idiomatic file. **My earlier one-line note here was wrong**: it cited `src/backend/dotnet.rs`, which is a *different* thing (NuGet `dotnet tool install`, needs an SDK first — `:79`, `:101`, `:116`). The reply separates the two explicitly because the names collide |
| ~~**5517**~~ | 1 | `mise use -g cargo` fails confusingly; risu729: "`cargo` is treated as `cargo:cargo` — unexpected behaviour" | **REPLIED 2026-08-01.** Fixed by **#9608** (risu729, "reject bare package backend names", `Fixes` this discussion), first release **v2026.5.2** (bisected: v2026.5.1 `behind=11`). **Measured**: `mise use -g cargo` errors and writes no config; `gem` likewise; `cargo:ripgrep` unaffected. e2e `e2e/backend/test_bare_backend_names` asserts both bare names. `rust` is the answer — `core:rust` runs rustup and `list_bin_paths` returns `cargo_bindir()` (`rust.rs:397-402`). **Corrected texastoland's premise**: `npm` is *not* an alias for `node` — `mise tool npm` → `npm:npm` (measured); `registry/npm.toml` was added by #7557 *ahead of* the fix precisely because npm only worked via this bug |

### Answerable now (no code needed)

| # | answer |
|---|---|
| ~~**5509**~~ | **REPLIED.** Wanted a `tool_bin_path()` tera function instead of `exec(command='mise bin-paths …')`. Already exists. **Measured** which key forms resolve: `tools['aqua:Owner/repo'].path` ✅ and `tools['Owner/repo'].path` ✅ — the map is keyed by `ba().tool_name` *and* `ba().short` (`toolset/mod.rs:406-434`); a differing registry short name ✗. Bracket syntax is required, `:`/`/` are not valid in tera dot paths. `tools = true` is mandatory or you get ``Field `path` is not defined``. **Residual gap stated in the reply:** `.path` is the install *root*, so there is still no template equivalent of `mise bin-paths` |
| **5458** | **Investigated, draft written, NOT posted.** Does not reproduce: **measured** on v2026.7.15 that `mise use pipx:kraken-wrapper` installs `krakenw` (uv prints `Installed 1 executable: krakenw`), `<install>/bin/` holds only `krakenw.exe`, `mise which krakenw` resolves, and a `krakenw` shim is created without a manual reshim. mise never derives the executable name: `pipx.rs` sets `UV_TOOL_BIN_DIR`/`PIPX_BIN_DIR` to `<install_path>/bin` and has no `list_bin_paths` override, so the default `runtime_path()/bin` (`backend/mod.rs:2974-2983`) exposes the dir wholesale — **and the same was true at v2025.6.5**, the release current when they posted. Their `uvx_args = "--from …"` attempt cannot work for a different reason: **measured** `pipx:krakenw` 404s at `pypi.org/pypi/krakenw/json` during version resolution, before uv runs; also `uv tool install` has no `--from` (only `uv tool run`). Docs gap: `docs/dev-tools/backends/pipx.md` never says the executable name comes from entry points |
| ~~**5494**~~ | **REPLIED 2026-08-01. Does not reproduce, at any version.** With `_.python.venv = { path = ".venv" }` declared, `-C` and `cd` are identical — `VIRTUAL_ENV`, the resolved `python`, and the import all match. **Measured across v2025.6.5 / 7.0 / 10.0 / 12.0, v2026.3.0 / 7.18** on Linux, plus Windows. So `-C` never dropped the venv. The likely real cause is what #5213's trace shows for the same era — `config_paths: []` under `--cd`, i.e. **no config loaded at all**; risu729's #9923 for it was **closed unmerged**. Reply gives `mise config ls -C <dir>` / `mise env -C <dir>` as the split. Their `mise.toml` contents are unknown, so it may simply never have declared the venv to mise (`uv pip list` finds `.venv` from uv's own cwd regardless) |
| ~~**5452**~~ | **REPLIED 2026-08-01. Reproduced — it is the trust prompt, not `_.source`.** Under a pty on Rocky 9.3, an untrusted config makes `mise env` sit on `mise config files in … are not trusted. Trust them? Yes/No/All` until killed. The prompt is drawn with a clear-screen escape (`ESC[2J ESC[H`), so as a side effect of `cd` it wipes the screen and blocks — indistinguishable from a hang. **Measured**: `[env] PLAIN = "x"` with **no `_.source`** blocks identically; trusted configs return in 0s (and adding `_.source` to an already-trusted file does *not* re-prompt); v2026.7.18 behaves the same; **without a TTY mise warns and continues**, which is why it never shows in CI. My earlier guess that it was #5433/#11458 was wrong. **The reply was edited on 2026-08-01 to remove a second wrong claim of mine**: I had written that the prompt fires as a side effect of `cd`. It does not — `hook-env` is excluded in code (`config_file/mod.rs:354`, `if cmd != "hook-env" && …`) and measured: interactive bash + `mise activate` + `cd` warns and returns in 0s. What blocks is any **foreground** command (`env`, `ls`, `current`, `install`, `exec`, `doctor` — all measured). **So the reporter's literal symptom is still unexplained**; the edited reply asks whether a bare `cd` hangs or only the next mise command, and which shell (I could test bash only; zsh/fish were not installable in the Rocky image) |

### Open design questions — no clean answer, low value to reply

- **5454** (👍5) pyenv-virtualenv-style named central venvs. mise has no equivalent; syhol pointed at
  automatic virtualenv activation, which the reporter had already discounted.
- **5498** (👍3) `mise install --lazy`. jdx engaged at length: shim names are only known *after*
  install, unlike aqua — but softened to "might be feasible if mise-versions stored possible names",
  and risu729 supports it. This is a design thread, not a question.
- **5475** (👍3) OCaml OPAM backend. 0 comments.
- **5516** `mise install --tasks a,b`. 0 comments.

### Already answered by others — no action

5433 (Marukome0743 → #11458), 5438 (risu729 → #5504), 5442 (dup of #6053), 5455 (eitamal:
`fetch_remote_versions_timeout` default was raised), 5457 (jdx: MITM proxy), 5460 (jamesanto →
`raw_args`, #9118), 5469, 5470, 5473 (a thank-you note, not a question), 5477 (risu729 #5479 +
roele #5503), 5478 (upstream luarocks#1851), 5481 (jdx → #8058), 5482 (risu729: must be an env
var), 5489, 5497 (jdx), 5505 (roele + jdx), 5507, 5510, 5513 (jdx), 5515 (risu729 → #5899).

All referenced PRs confirmed merged: #5479, #5503, #5504, #5899, #11458, #8058, #9118.

---

### PR #11577 (draft) — `--file`/`--path` aliases, and what happened to #11116

#4881 (glasser, 2025-04-18, 0 comments in over a year) asks for one thing: `--file` and `--path` as
synonyms on `use` and `set`. @Marukome0743 implemented it in **#11116**, and **jdx closed it the next
day with no comment at all** — no review comments, and the CI runs are `cancelled` by the close
rather than failed. The PR itself was sound: its `src/cli/mod.rs` +51 was a clap-introspection test,
not machinery. The one visible difference from the request is scope — it aliased **nine** commands.

#11577 is therefore the two commands the discussion names and nothing else (`unuse` deliberately
excluded), with the PR body asking outright whether the objection was scope or the idea. If it is
closed too, ask jdx directly.

**Generating the docs for a CLI change cannot be done on Windows.** `mise usage` emits the live CLI
surface, and Windows does not register the Homebrew subcommands, so regenerating `mise.usage.kdl`
here drops them and produces a huge spurious diff. `usage generate markdown|manpage` only read the
kdl and are safe anywhere; `markdownlint-cli` installed through mise is currently broken
(`ERR_MODULE_NOT_FOUND: commander`). The route that worked: push a **probe branch** to the fork with
a throwaway workflow that runs `mise run render` on ubuntu and uploads `git diff` as an artifact,
then `git apply` that patch to the real branch. The probe branch and its workflow never touch the PR
branch, and both were deleted afterwards. Result for this change: **4 lines across
`mise.usage.kdl` + `man/man1/mise.1`; `docs/cli/*.md` does not change** because
`usage generate markdown` does not render flag aliases — which is why #11116 didn't touch it either.

**Watch `mise.lock`.** `mise exec <tool>@latest` rewrites it (it bumped `usage` 4.0.0→4.1.0 and
`markdownlint-cli` 0.48.0→0.49.1 during this work) and it silently rode along into a commit. Check
`sl status` for it before every commit, and prefer the pinned versions the lockfile already names.

## Checked and found sound — do not re-open

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
happens after the `cd`. `MISE_ORIGINAL_CWD` is consistent for the same reason — `watch_files.rs` and
`hooks.rs` feed it from `dirs::CWD` while `task_executor.rs:490` uses a live cwd, and post-`cd` those
agree. Re-opening this needs a caller that reads `dirs::CWD` during the first settings pass; none
exists.

## Band `#5521`–`#5610` (34 exist, 24 open, all read 2026-08-01)

Closed, out of scope: 5550, 5559, 5569, 5576, 5580, 5582, 5583, 5585, 5586, 5594.

**Unlike the previous band, this one contains a live bug.**

| # | state |
|---|---|
| ~~**5530**~~ | **REPLIED.** `ubi` `tag_regex` docs example was invalid TOML (`"^\d+\."` — `\d` read as an escape). Fixed by the reporter's own **#5529, merged 2025-07-07**; `docs/dev-tools/backends/ubi.md:153` now uses a literal string `'^\d+\.'`. Nobody had told the thread |
| **5531** | **FIXED — PR #11580 (draft). Still do not reply; the fix is the answer.** `MiseTomlTool` now holds the version as a raw `String` until it is rendered, matching what `[tasks.*.tools]` and `.tool-versions` already do — `mise.toml`'s `[tools]` was the only place that parsed first and rendered second. **`ToolVersionType` deliberately untouched**: it is also the remote-listing version filter (`backend/mod.rs:1923`, `backend/github.rs:526`), so guarding *it* on `contains_template_syntax` would be a smaller diff with a wider blast radius. Folding `From<ToolRequest> for MiseTomlTool` onto `ToolRequest::version()` also killed a latent `Ref(ref_, ref_type)` argument swap (`branch:main` → `main:branch`). Deferring the parse moves the failure behind five `.ok()` call sites, so the error now names file + template + rendered value |
| **5531 (original diagnosis)** | **LIVE BUG — implementation target, do not reply.** A `:` anywhere in a tool version makes mise split it as `backend:tool` *before* templates render. Reporter's template contained one in `'ANSIBLE_VERSION: '`. **Measured on v2026.7.18**: `version = '''{{ exec(command='echo VER: 1.2.3') \| split(pat=': ') \| last }}'''` → `invalid prefix: {{ exec(command='echo VER`. Not template-specific — `"npm:cowsay" = "1.2.3:x"` gives `invalid tool: invalid prefix: 1.2.3`. Not a regression: colon-free templates work back to v2025.7.0, colon ones fail on every version tried. Reporter's own pointer `tool_arg.rs:71` is right |
| ~~**5523**~~ | **REPLIED 2026-08-01. Fixed three days after it was posted** by **#5546** (risu729, "do not overwrite github tokens environment variables"), first release **v2025.7.3** (bisected: v2025.7.2 `behind=7`). Nobody told the thread because the PR said `Fixes #5524`. **Measured on v2026.7.18**: with `MISE_GITHUB_TOKEN` and `GITHUB_TOKEN` set differently, the child sees `GITHUB_TOKEN` unchanged and `GITHUB_API_TOKEN` unset; `mise env` exports no `GITHUB_*`; `src/shims.rs` never touches them. Writes are now child-process-scoped only: `cargo.rs:259` (`cmd.env`) and `asdf_plugin.rs:487-489` (`.with_env`), so their private-asdf-plugin use still works — the reply says so explicitly, since that is the obvious worry when told the overwrite was removed |
| **5570** | 👍5, **no maintainer answer. Hold the reply until #11531 ships.** Root cause is not what the reporter assumed: `jobs = 1` serialises installs but gives no dependency *ordering*. Two pieces were needed and both postdate the report: **#8776** (`depends` field, first release **v2026.4.4**) for declaring it, and **#11531** ("fix(asdf): expose dependencies to install scripts", merged 2026-07-31) so an asdf `bin/install` can actually see the just-installed tool — `asdf.rs:438-457` explains why (`ctx.ts` is the *unresolved* install toolset during a combined install). **#11531 is not released yet** (v2026.7.18 is `behind=21`), so replying now would tell them to write `depends = ["java"]` and it still would not work. `registry/jib.toml` declares no dependency, and registry-level `depends` was removed by #9571, so the user declaration is required |

Answered by others, no action: 5521, 5522, 5526, 5527 (risu729 → #5537), 5533 (same), 5535 (→ #5545),
5539 (Marukome0743 → #5543, v2025.7.3), 5552, 5553, 5555, 5563 (jdx), 5564 (jdx declined), 5588
(W1M0R: fixed by #5790/#5815 in v2025.7.29; also notes the upstream duct.rs 1.1.0 fix may help beyond
`mise x` — a possible follow-up), 5599 (dup of #6053).

Design/feature requests, low reply value: 5528, 5541, 5544, 5554, 5575 (👍6, scoop backend).

## Band `#5611`–`#5700` (26 exist, 22 open, surveyed 2026-08-01; 5 read in full)

| # | state |
|---|---|
| **5664** | **Fixed on main, not yet released — hold the reply.** GNU Parallel sanitises the env and can leave `XDG_DATA_HOME` *empty*; `var_path` used to return `Some("")`, so `MISE_DATA_DIR` became the **relative** path `mise`, producing the reported `<cwd>/mise/aqua-registry/…/mise/aqua-registry/…` doubling and a stray `mise/` dir. **Measured on alpine, v2026.7.18**: `XDG_DATA_HOME=` → `"data": "mise"` and a `mise` directory appears in cwd; on a main build it falls back correctly. Fixed by **#11508**'s `var_path` empty-as-unset filter (merged 2026-07-30, after the v2026.7.18 tag) |
| ~~**5686**~~ | **ALREADY BEING FIXED BY SOMEONE ELSE — do not implement.** #11572 (Marukome0743, draft, 2026-08-01 04:01) "fix(upgrade): apply all config bumps", `Addresses …/discussions/5686`. Same diagnosis and same fix I had planned (parse each config path once, save once), plus a case I had not covered: preserving successful bumps when a sibling tool fails to install. **I got as far as a full plan before checking — see the process note below.** Two things my investigation found that the PR does not mention, if a comment is ever wanted: (a) `mise.toml` survives the double-open only *by accident* — `MiseToml::doc` is a `OnceCell` read on first mutation, so instance B reads after instance A's save; any earlier `dump()` would break it too; (b) `tool_versions.rs` has **no test module at all**, while `mise_toml.rs` has ~20 `replace_versions` tests |
| ~~**5612**~~ | **REPLIED 2026-08-01**. Was a real regression and is **fixed**: **#9143** (@jdx, "fix(env): use runtime symlink paths for fuzzy versions"), first release **v2026.4.16** (compare: v2026.4.15 `behind=8`). Its PR body uses the same example the reporter gave. **Measured in the official images**: `jdxcode/mise:2025.7.7` → `/mise/installs/python/3.12.13/bin`; `jdxcode/mise:2026.7.18` → `/mise/installs/python/3.12/bin`; the `3.12 -> ./3.12.13` symlink existed in **both**, it just was not what went on PATH. Cause: `install_path()` (resolved version — backs install dirs, downloads, cache, uninstall state) was also used by `list_bin_paths()`; #9143 adds `runtime_path()` and switches only the PATH-facing callers. Two caveats included in the reply: lockfile-resolved versions deliberately stay on the concrete path, and Windows file-based pseudo-symlinks resolve back to the concrete dir. **Text search found nothing** — the PR was located by fetching `tool_version.rs` at successive tags and bisecting on the presence of `pub fn runtime_path`, then listing PRs merged in the resulting one-day window |
| ~~**5646**~~ | **DO NOT POST — user's call, already reported by someone else.** Investigation is done and the answer was drafted, so if it ever needs posting: fixed by **#5822** (@syhol, body says `Fixes: …/discussions/5646`), first release **v2025.7.30** (compare: v2025.7.29 `behind`). Measured in the reporter's own images — 2025.7.10 and 2025.7.29 print an empty `mise.toml tools:` and exit 0, 2025.7.30 installs `pipx:commitizen@4.17.0` and `which cz` → `/mise/shims/cz`. Cause: `backend_arg.rs` consulted `install_state::get_plugin_type("pipx")` **before** checking for a built-in backend, so `pipx:commitizen` routed to a plugin backend; #5822 checks `BackendType::guess(short) != Unknown` first. Also measured: on 2026.7.18 with `mise-plugins/mise-pipx` deliberately installed it works, so **@risu729's "uninstall the plugin" workaround is obsolete**. @mnowotnik's leftover TLS complaint is separate — uv does not read `REQUESTS_CA_BUNDLE`; it has `--system-certs` (`UV_SYSTEM_CERTS`, formerly `--native-tls`, both spellings accepted on uv 0.12.0), forwardable via the `uvx_args` tool option |
| ~~**5663**~~ | **REPLIED 2026-08-01** (👍7, 0 comments — the most neglected thread in the band). Already implemented, and the reporter's guessed syntax is the shipped syntax: **#7582** (@vmaleze), first release **v2026.1.1** (bisect: v2026.1.0 `behind`, v2026.1.1 `ahead`). `config/mod.rs:4269` branches on `include.starts_with("git::")` → `resolve_git_url_to_path`; `remote_source.rs:5` SSH regex matches their exact string. **Measured on mise 2026.7.15** by running e2e's own `e2e/helpers/scripts/git_http_backend_server.py` on Windows: both the single-`.toml` and the directory form load and run. Windows gotcha for reruns — the script's `git tag` fails under this machine's signing config; override per-child with `GIT_CONFIG_COUNT=2` + `tag.gpgSign=false` + `tag.forceSignAnnotated=false`. Two extra facts found and included: the docs' **experimental badge is not enforced** (no `ensure_experimental` on this path; verified with `MISE_EXPERIMENTAL=false`), and task includes only require trust when the file **contains template syntax** (`task_include_requires_trust`), so plain shared task files load unprompted in CI |
| 5648 | feature request (task-docs header level) |
| ~~**5660**~~ | **REPLIED 2026-08-01** (👍6). @ThomasSteinbach had pointed at **#6207 while it was still open** and nobody said it landed: merged 2025-09-06, first release **v2025.9.3** (bisected: v2025.9.2 `behind=12`), PR body says `Solves #5660`. Adds the `url_replacements` setting plus `docs/url-replacements.md`, whose regex example is an Artifactory GitHub-releases rewrite — the reporter's exact shape. **Verified it also covers API calls**, which matters because their API and download hosts differ: `apply_url_replacements(&mut url)` runs at the top of the request path in `src/http.rs`, before `http_host_key`. Docs route confirmed via `docs/.vitepress/sidebar.ts:247`. Caveat recorded in the reply's phrasing: the two-hostname example is extrapolated from the docs, not run against a real mirror |
| ~~**5665**~~ | **REPLIED 2026-08-01** (👍3). Shim re-entry, exactly as the reporter guessed, by **two** independent routes: (a) legacy `uv_venv_auto = true` passed `UV_PYTHON=<bare version>` to the `uv venv` child, so uv searched PATH for an interpreter and could hit mise's `python` shim → **#7905, first release v2026.2.2** (`compare` bisect: v2026.2.1 `behind=8`, v2026.2.2 `ahead=7`); (b) mise resolved the `uv` binary with `which_non_pristine` → **#8402, v2026.3.0** (`which_no_shims`; all v2026.2.x are `behind`). **Measured** on a throwaway private Actions repo (`JamBalaya56562/mise-probe-5665`) replicating the reporter's repo exactly, uv pinned to 0.7.21: v2026.2.2 / v2026.7.18 log `Using Python request /…/installs/python/3.13.5/bin/python **from explicit request**` and return instantly. **The old version did not hang reliably** — on the reporter's own v2025.7.11 it passed; an earlier attempt (uv 0.12.1 + mise 2025.7.10) reproduced their exact error with the tell `A virtual environment already exists at: .venv` while the outer mise was still creating it. Reported honestly as such rather than as a clean before/after. Bonus bug found and reported: `uv_venv_create_args = ["--verbose"]` was dead between **#7310 (v2025.12.8)** and **#7905 (v2026.2.2)** — mise still added `--quiet` and uv rejects both. **#4600 confirmed nonexistent** (issues 410); answered @rsyring's question about the dead link |
| 5659 | risu729 pointed at **#5682** (merged 2025-07-18). Thread already answered |
| 5692 | transient — a release was missing artifacts. Community answered; the rest is a version-pinning feature request (#3515) |
| 5620 | jdx's backend-plugins announcement, not a triage target |
| ~~**5683**~~ | **REPLIED 2026-08-02 — not a bug, and neither guess was right.** jdx suspected the trust hash algorithm, the reporter an unexpanded `~`. Both ruled out by experiment on **mise 2026.8.0, linux**: trust records are named from the **canonicalized absolute path** (`hashed_path_filename`), so the name is HOME-independent — and copying that same record file into the new HOME's store restores trust with nothing else changed. What moves is the **store**: `$HOME` → `homedir::my_home()` (its `unix.rs:79` returns `$HOME` when set) → `XDG_STATE_HOME` → `MISE_STATE_DIR` → `trusted-configs`. A **second, separate effect** explains the odd `/Users/deivid: untrusted` line — once `$HOME` moves, the old `~/.config/mise/config.toml` stops being *the global config*, and since `.config/mise/config.toml` is also a recognised **project** filename it reappears as an ordinary untrusted config found walking up from cwd (reproduced). Workarounds measured: `MISE_TRUSTED_CONFIG_PATHS` (env, independent of the state dir) and `MISE_STATE_DIR`; `CI=1` bypasses trust entirely, so this only bites local runs. **Not a regression from a dependency bump** — `homedir` has been 0.3.x since ≥ v2024.12.1 |
| ~~**5630**~~ | **REPLIED 2026-08-02.** Fixed by removing the cause, not by piping it: **#6332** replaced the external `cosign` binary with in-process sigstore verification, first release **v2025.9.13**. v2025.9.0's `aqua.rs:625` still did `dependency_which(&ctx.config, "cosign")` → `CmdLineRunner`; the current tree spawns no cosign process at all (only a comment "cosign CLI which we don't shell out to"). Caveat stated in the reply: risu729's `npm.bun` variant is a **different child process** and was not checked |
| ~~**5653**~~ | **REPLIED 2026-08-02.** **#9109** merged 2026-04-29, first release **v2026.4.27**; adds `npm_args` / `pnpm_args` / `bun_args` / `aube_args`, so `--registry` goes per tool. risu729's last word in the thread was "opened draft PR" and it sat three months. The merged version **dropped the env-alias support** that was in the first draft |
| ~~**5654**~~ | **REPLIED 2026-08-02.** **#5656** merged two days after the report, first release **v2025.7.12**; nobody said so. One line: `-.arg("--cwd").arg(tv.install_path())` → `+.current_dir(tv.install_path())` — bun had been getting `--cwd` while its own process cwd stayed wherever mise ran, and the lockfile followed the process cwd |
| ~~**5655**~~ | **BLOCKED on #11632 — do not implement, reply after it merges.** jdx's "nothing mise can do about bottles" is outdated: `[bootstrap.packages]`'s `brew:` manager pours bottles without Homebrew (#10326, first release **v2026.6.4**). **Measured on Linux with no brew on PATH**: `brew:fswatch` completes download → checksum → extract → **relocate** → link and `fswatch --version` runs — the `relocate` step answers jdx's hardcoded-prefix objection directly. `brew:watchman` failed at relocate (dependency closure pcre2/sqlite/python@3.14 poured fine); **#11632 (@Marukome0743) fixes exactly that and its body `Addresses` this discussion**. A macOS check is also out with the user's Mac — macOS should be structurally immune (13-byte prefix vs 19-byte placeholder), but that was inference, not measurement. Version pinning is genuinely unsupported for brew entries — that half of jdx's objection stands |
| unread | 12 threads with comments |

## Band `#5701`–`#5790` (30 exist, 24 open, surveyed 2026-08-02; the four with substance all answered)

| # | state |
|---|---|
| ~~**5723**~~ | **REPLIED 2026-08-02** (👍4). Both halves fixed. **Measured on 2026.8.0 linux** with the reporter's repro: `printf 'alpha\nbeta\n' \| mise run reads` → `r1 got: [alpha]` / `r2 got: [beta]`, and with a `sleep 1` in each the two do not overlap (`s1 end 749.135` → `s2 start 749.145`), which is the RWMutex write lock the docs promise. **Bisected on release binaries: v2025.11.1 broken (mise prints the command lines and timings but neither task's own output ever appears), v2025.11.2 works.** Cause: **#6852** `refactor(task): split run.rs into modular task execution pipeline` added `task.is_some_and(\|t\| t.raw)` to `OutputHandler::raw()`, the predicate guarding `cmd.stdin(Stdio::inherit())`; before it, only the CLI flag and the global setting counted, so with two `depends` the style became `Prefix` and nothing consulted `#MISE raw=true`. riseshia's diagnosis was right; his line refs are stale (the logic left `run.rs`). **#7286 is not the fix** despite its title — the repro already passes on v2025.12.6 |
| ~~**5743**~~ | **REPLIED 2026-08-02.** Two things closed at once. The feature is **the reporter's own PR #6041** (merged 2025-10-08, first release **v2025.10.7**) — jdx had said in-thread it would have to be an env var, and it is. The `.miserc.toml` regression **@probberechts** reported (hook-env up to ~30s) is fixed by **#10165** (@risu729), merged 2026-05-31, first release **v2026.5.18** (v2026.5.17 `behind`). Reply also states the ceiling-excludes-itself semantics (#8283 documented it) because it is easy to get backwards |
| ~~**5759**~~ | **REPLIED 2026-08-02 — not a mise bug.** The spec parser never consulted `SpecDoubleDashChoices::Required`; a `--` only flipped `enable_flags` off. Fixed upstream in **jdx/usage#762** (own PR), merged 2026-08-02, whose body says `Fixes the root cause behind jdx/mise#5759`. **Two hops from users**: usage has not released since (latest v4.1.0, 2026-07-30) and mise pins `usage-lib` **4.0.0**. Reproduced on v2026.7.15 first. Bonus from that PR worth knowing: an arg requiring `--` behind a greedy variadic was **never** reachable — in mise's own spec that is `[-- TASK_ARGS_LAST]...`, `[-- ARGS_LAST]...` and `exec`'s `[-- COMMAND]...`, all declared and none ever filled |
| ~~**5779**~~ | **REPLIED 2026-08-02 — does not reproduce, and the cause is exact.** The pwsh activation used to slice the raw line: `$MyInvocation.Statement.Substring($MyInvocation.OffsetInLine - 1)`. `OffsetInLine` grows with indentation while `Statement` does not, so it ate one character per leading space — and `mise` is four characters, which is precisely why 0–3 spaces worked and 4 discarded the command name. **#6168** (@L0RD-ZER0, aimed at PowerShell v5) replaced it with `param(... ValueFromRemainingArguments ...)`, first release **v2025.9.0** (v2025.8.0 still has `OffsetInLine`). Measured on 2026.7.15 / pwsh 7.6.4 at 0/2/4/8 spaces from a script file |
| 5702 / 5701 / 5703 / 5706 | the transient 2025.7.15 release incident — nothing to do |
| unread | #5710 erlang, #5712 php PEAR, #5716 maven, #5728 sha256-vs-blake3, #5733, #5742 ubi executable bit, #5762 ruby, #5789 Docker generator, plus assorted answered Q&A |

## Band `#5791`–`#5880` (opened 2026-08-02 — three answered, the rest unread)

| # | state |
|---|---|
| ~~**5842**~~ | **REPLIED 2026-08-02, fixed by #11633.** `mise use --global` wrote into `~/.config/mise/conf.d/*.toml` once `~/.config/mise/mise.toml` was gone. jdx had answered "yes, but it's probably easier said than done" and stopped; it was one predicate, because the intent was already encoded in `first_config_file` and only the fallback leaked past it |
| ~~**5840**~~ | **REPLIED 2026-08-02, half-fixed by #11639** (👍7, zero comments in a year). `--no-prune` shipped; the requested `auto_prune_old_versions` setting did **not** and is still open work — see "Where to start next" |
| ~~**5831**~~ | **REPLIED 2026-08-02** |
| unread | **#5830** (👍5, Windows PATH too long — reproducible on this machine, best next candidate), #5876 flutter, #5797 Mason backend, #5813, #5821, #5833, #5869, #5855, #5860, #5871, #5850, #5820, #5825, #5798, #5801, #5791, #5839 |

## Landmines — do not re-propose these

Candidates that look attractive on a fresh read and are **not** work. Each cost real time to
disprove.

1. **Do NOT extend `file::decode_text` to other backends' checksum reads.** reqwest's `text()` →
   `text_with_charset("utf-8")` → `encoding_rs::Encoding::decode`, whose first act is
   `Encoding::for_bom(bytes)`: a BOM overrides the declared encoding and is stripped
   (`encoding_rs-0.8.35/src/lib.rs:3009`). Every `get_text`/`get_text_cached` path already decodes
   UTF-16. Only reads from **disk** need help, because `std::fs::read_to_string` is UTF-8-only.
   #11552 got this wrong for its HTTP third; #11558 corrected it, and
   `file::read_to_string_bom`'s doc comment now records the asymmetry in-tree.
2. **Do NOT change zsh's completion guard to `type -P`.** `-p`/`-P` do not mean the same thing
   across shells. Measured in zsh 5.9: `type -P` is `bad option: -P` and **always** exits 1, so
   `if ! type -P usage &> /dev/null` (error swallowed) would print "usage CLI not found" for every
   user who *has* the CLI. zsh's `-p` already forces a `$PATH` search ignoring functions/aliases —
   the inverse of bash's. jdx/usage#760 excluded zsh **deliberately**, and the change was tried and
   reverted upstream in two days: `f65a7b465` (2025-07-16) → `dfdc67b94` (2025-07-18). mise's
   `completions/_mise` is correct as-is.
3. **The "Windows-only" framing was wrong twice over — read this before re-investigating.**
   On 2026-08-01 I reported a Windows-only bug, then retracted it, and *both* were wrong. What is
   actually true: an **empty** `MISE_CONFIG_DIR` (`export MISE_CONFIG_DIR=`) makes `dirs::CONFIG`
   the empty path, so `global_config_files()` is empty, `~/.config/mise/config.toml` stops being
   recognised as global, and `mise use` writes into it. **Measured on Linux and Windows alike** on
   v2026.7.18 (`mise doctor --json` reports `"config": ""`). It is **already fixed on main** — not
   by #11571 but by **#11508**, which added `.filter(|p| !p.as_os_str().is_empty())` to
   `env::var_path` for the gh/glab lookup and landed just after the v2026.7.18 tag was cut. So it
   is a released-versions-only defect with a fix already queued; nothing to report.
   **Two measurement lessons, both of which cost hours:**
   - `[Environment]::SetEnvironmentVariable('X', $null)` in PowerShell **creates `X=` (defined,
     empty) in the child environment block** when `X` was never set. `cmd /c echo %X%` still
     reports it undefined — only `cmd /c set` shows it. That is what silently switched the variable
     under test. Diff the child env (`Compare-Object (cmd /c set) …`) before trusting an A/B.
   - Env vars do **not** persist across PowerShell tool calls (verified), but they do persist
     across every `&` invocation *within* one call. One scenario per call.
4. **Do NOT try to make the asdf backend work on Windows.** Deliberately unsupported, not
   unfinished: `src/main.rs` swaps in `fake_asdf_windows.rs` whose `setup()` is a no-op stub;
   `ScriptManager::run_by_line` spawns the plugin script directly and Windows `CreateProcess`
   rejects a shebang-only file (os error 193, measured); `docs/.../asdf.md` marks asdf
   `Windows Support ❌` and steers users to vfox. asdf is legacy — new asdf/vfox plugins are no
   longer accepted into the registry.

---

## Process notes

- **`isAnswered=false` is not "nobody replied."** It is only the *marked-answer* flag, and mise's
  threads are rarely marked. Batch metadata queries are good for spotting *movement*, not for
  deciding a thread is unanswered.
- **Re-check every citation at draft time.** `main` moves fast; two line refs in this file went
  stale within days (`which_no_shims` `:1094`→`:1144`, venv `--python` arms `:57-66`→`:67-74`).
- **Check for a resolution comment before investigating.** #5357 was dropped when @Marukome0743
  answered it independently while it sat in this queue.
- **Never write an assertion for output you have not seen.** #11575's e2e failed on
  `assert "cat ../to/mise.toml" "[tools]"` — `mise unuse` removing the *only* tool empties the file
  (measured: 1 byte), and `e2e/cli/test_use:52` already encoded that. The verification run before
  that PR only checked `-match 'uv'`, never the exact contents, so the guess went unnoticed. Same
  failure mode as the `MISE_CONFIG_DIR` and `find -type f` mistakes: **a check that cannot fail is
  not a check.** Run the whole scenario and print the actual bytes.
- **Search for an existing PR before planning any implementation.** #5686 was reproduced, diagnosed,
  and fully planned before I noticed #11572 had covered it hours earlier. The reliable query is by
  **discussion number in the PR body** — `repo:jdx/mise 5686 in:body` — because the PR title
  ("fix(upgrade): apply all config bumps") shares no words with the discussion title. Title searches
  would have missed it. Do this *first*, not after the repro succeeds; a successful repro is exactly
  the moment the check feels unnecessary.
- **Attribute a fix to the PR that actually contains it, not the one you found first.** The #5362
  and #5365 replies credited #8402 with both halves of the uv-shim recursion fix. Reading the #8402
  diff shows it only adds `which_no_shims` and the `Ok(false)` arm; the `--python <abs path>` half
  is #7905, one release train earlier. **Read the PR's own diff before naming what it changed** —
  the PR body describing a mechanism is not proof it introduced the code that handles it. Both
  comments were edited in place on 2026-08-01 (`updateDiscussionComment`), rewritten to read as if
  correct from the start, per the same handling as #5452.
- **A GitHub Actions probe repo is the right tool for CI-only bugs.** For #5665 a throwaway
  **private** repo with a matrix over `jdx/mise-action`'s `version:` input measured four mise
  releases against one config in a single push. Two traps: (a) mise-action runs `mise install`,
  which **creates the venv before your test step** — `rm -rf .venv` immediately before measuring, or
  the path under test never executes; (b) `gh run view --log` fails while a run is in progress — use
  `gh api repos/{o}/{r}/actions/jobs/{id}/logs`, and match the step *output* (`^exit=\d`), not the
  echoed command.
- **`cargo fmt` runs fine on this machine even though `cargo check` does not.** fmt never builds
  dependencies, so the `libz-ng-sys` failure does not apply. #11631's first CI run failed on
  `hk`/rustfmt because adding `visible_alias` pushed four `#[clap(...)]` attributes over the width
  limit; `cargo fmt --all` reproduced CI's expected output exactly. **Run it before pushing any
  attribute edit.** (#11116 already had the multi-line form — copying a prior PR's shape would have
  avoided the round trip.)
- **A fix that closes a discussion usually does not say so.** In `#5701`–`#5790`, three of four
  live threads were already fixed and **not one fixing PR referenced its discussion**: #6852 was a
  *refactor*, #6168 was *PowerShell v5 support*, #10165 was *miserc discovery*. Searching PR titles
  or `<number> in:body` finds none of them. What works: reproduce on an old release binary, then
  **bisect the published binaries** — `https://github.com/jdx/mise/releases/download/v<ver>/mise-v<ver>-linux-x64`
  runs standalone from `/tmp`, so a five-version sweep costs a minute. Then read the commit list
  between the two adjacent releases (`compare/vA...vB`) and match against the symptom.
- **Verify the "obvious" candidate before naming it.** #5723's fix looked like #7286
  ("prioritize raw task output over task_output setting") from the title alone. It was not — the
  repro already passed on v2025.12.6, which predates it. Two extra binary downloads settled it.
- **WSL is the fallback when wslc locks up.** `wslc` spent this whole session returning
  `ERROR_SHARING_VIOLATION`, and Docker Desktop's engine was not running. `wsl.exe -d <distro> --
  bash <script>` needs neither. Two gotchas: pass a **script file** (a multi-line `-c` string gets
  mangled by PowerShell/wsl argument handling — variables come through empty), and write that file
  with **LF endings**, or `<<'EOF'` heredocs never terminate and swallow the rest of the script.
- **The fork's `main` lags upstream — rebase onto `upstream/main`, not `remote/main`.** `sl pull`
  with no argument pulls `default`, which is `JamBalaya56562/mise`, and that only advances when the
  fork is synced. On 2026-08-02 `remote/main` sat at #11580 while `upstream/main` had #11581.
  Rebasing onto the stale one silently leaves the PR behind. Use `sl pull upstream` and
  `sl rebase -s <rev> -d upstream/main`. `sl paths` shows both.
- **CI hands you the generated-file diff — no probe branch needed.** `.github/workflows/test.yml`'s
  **`lint`** job runs `mise run render` and, if `git status --porcelain` is non-empty, fails with
  `git diff HEAD` printed. So `mise.usage.kdl` / `man/man1/mise.1` / `docs/cli/*.md` can be
  hand-edited and CI will state the exact expected output. The #11577 probe-branch dance existed
  only to *obtain* that diff; it is unnecessary. Better still, a merged sibling change is a
  transformation template — #11577's output shape for `set`/`use` was copied verbatim for
  `unset`/`unuse` in #11616.
- **Hand-writing the generated files works — #11639's lint passed first try** with `mise.usage.kdl`,
  `man/man1/mise.1` and `docs/cli/upgrade.md` all written by hand. Three rules make it reliable:
  1. **A visible alias reaches the man page only.** `\fB\-f, \-\-file, \-\-path\fR` in
     `man/man1/mise.1`, `flag "-f --file --path"` in the kdl, and **nothing** in `docs/cli/*.md` —
     its heading keeps the canonical spelling. Confirmed against `unset` on main. CodeRabbit asked
     twice for the alias in the Markdown; obeying it would fail the render check.
  2. **`completions/` never enumerate flags** — they call `mise` at runtime, so a new flag changes
     nothing there. `docs/public/llms.txt` is a per-command index, also unaffected.
  3. **Write doc-comment paragraphs as single lines.** Without `verbatim_doc_comment` clap joins
     the lines inside a paragraph with spaces, so a two-line source comment produces one line of
     generated text — hand-write the source the way it will render and the guess disappears.
- **Never clear `MISE_TRUSTED_CONFIG_PATHS` in an e2e test.** `e2e/run_test:111` sets it to
  `$TEST_ISOLATED_DIR` and `:114` sets `MISE_YES=1`. #11609's first e2e cleared it (copying
  `test_config_ignore`, which needs it cleared for its own reasons) and every write then failed the
  trust check. Copy a neighbouring test's *premise* only after checking whether it applies.
- **`mise trust --ignore` cannot produce "ignored but writable".** It is directory-level — ignoring
  `dir/mise.toml` logs `mise ignored .../dir` — and `config_path_is_ignored` overrides a persisted
  ignore whenever `trusted_config_paths` covers the path; without that override the write fails the
  trust check loudly. **Only `ignored_config_paths` / `MISE_IGNORED_CONFIG_PATHS` creates the silent
  case**, and because `is_ignored_via_setting` compares with `starts_with`, it accepts a **file**
  path — which is how #11609's test excludes `mise.toml` while leaving `mise.local.toml` live.
- **When text search cannot find the fixing PR, bisect the source instead.** #5612's fix (#9143)
  matches no obvious search terms. What worked: pick the function the fix must have added
  (`pub fn runtime_path`), fetch that file at successive tags via
  `gh api repos/jdx/mise/contents/<path>?ref=<tag> -H "Accept: …raw"`, bisect on its presence down
  to a one-day window, then `search/issues` with `merged:<from>..<to>` and read the titles.
  Roughly ten cheap API calls, no builds.
- **`jdxcode/mise` images need `--entrypoint /bin/bash`.** The image ENTRYPOINT is `mise`, so
  `wslc run <image> bash -c '…'` silently becomes `mise bash -c …` and prints mise's help — it
  looks like the command failed rather than never running. The reporter in #5646 had `--entrypoint ''`
  in their repro for exactly this reason. wslc otherwise works fine for these one-shot runs.
  Also: this machine's git config makes the e2e git server script's `git tag` fail
  ("no tag message?"); override per-child with `GIT_CONFIG_COUNT=2` + `tag.gpgSign=false` +
  `tag.forceSignAnnotated=false`.
- **Do not force a bisect into a clean before/after.** #5665's old-version leg passed on a current
  runner image; the failure depends on how uv orders PATH discovery. The reply says so explicitly
  and leans on the source diff plus the one run that did reproduce, rather than on a tidy table.
- **Surfacing a defect is not owning it — check again before implementing.** The Linux bottle
  relocation failure was found here on 2026-08-02 and @Marukome0743 had a PR up (#11632) within
  hours, with a better fix than the one being weighed: they identified `watchman-diag` as a Python
  zipapp, verified against the real bottle that the placeholder sits only in the shebang, and
  matched Homebrew's own classification order instead of adding a source-build fallback. **Re-run
  the duplicate check right before writing code, not only when planning.**
- **@Marukome0743 and @risu729 work the same ground, fast.** Both were opening discussion-derived
  fixes on 2026-08-01 while this queue was being worked. Assume any obvious defect in a recent
  discussion may already be taken.
- **Watch for conflicts, not just duplicates.** Six open PRs touch `src/config/mod.rs`
  (#11574, #11570, #11205, #11206, #11203, #11222 — all task/env/trust work) and **#11481**
  (risu729, backend version ordering) touches `mise_toml.rs` and `tool_request.rs`, so it may
  conflict with **#11580**. None duplicate my four PRs — verified individually — but merge order
  matters. Re-check before rebasing.
- **Some of this repo cannot be tested on this machine at all — use a fork-CI probe branch.** The
  `mise_toml.rs` test module is `#[cfg(test)] #[cfg(unix)]`, so new tests there are not even
  *compiled* on Windows, and mise is a binary-only crate (`cargo test --lib` → "no library targets
  found"; use `--bin mise`). e2e is bash. The working pattern, used for both #11577 and #11580:
  push a **probe branch** carrying the change plus a throwaway workflow that runs the unit tests and
  the specific e2e files on ubuntu, read the result, then push the change to a clean PR branch from
  `remote/main` and delete the probe. **The workflow must never touch the PR branch** (#11517 was a
  real leak). And **check the log, not just the green tick** — a filtered-out test also passes;
  grep for the test names.
- **`assert_snapshot!` is unusable here** for the same reason: the `.snap` cannot be generated on
  Windows, and a missing snapshot fails CI. Write explicit assertions instead — for #11580 that
  meant asserting the resulting `ToolRequest` versions rather than snapshotting the debug output,
  which is a better test anyway (it pins the behaviour, not the representation).
- **Reproducing *a* symptom is not reproducing *the* symptom.** In #5452 I found a real blocking
  trust prompt, and then wrote the reply as though it explained the reporter's `cd` hang — without
  measuring the `cd` path at all. It does not: `hook-env` is excluded from the prompt in code. The
  data to catch this was already in my own earlier run (the activate+cd arm warned instead of
  blocking) and I read past it because the headline result looked conclusive. **When a repro
  explains a *related* failure, check it against the reporter's exact steps before writing.**
- **Editing beats appending when nobody has read it yet.** GitHub marks the comment edited either
  way, and a corrected single comment is easier to act on than a comment plus a retraction. Use
  `updateDiscussionComment` with the comment's node id, then re-fetch the body and assert both that
  the wrong claims are gone and the new ones are present.
- **A prompt only exists when there is a terminal.** #5452 ("hangs on `cd`") could not be reproduced
  until the command was run under a pty via `script -qec "<cmd>" /dev/null`. Without a TTY mise
  warns and continues; with one it blocks on the trust prompt. **Any report of a hang, a prompt, or
  a "nothing happens" needs a pty to reproduce** — and conversely, trusting the fixture up front (as
  the bisect note below says to do) will hide exactly this class of bug. Decide per investigation
  which of the two you need.
- **Set `MISE_TRUSTED_CONFIG_PATHS` before any version bisect.** The first #5494 bisect showed
  v2025.6.5 through v2025.12.0 all "failing" and v2026.3.0+ passing — a clean-looking regression
  window that was entirely the **trust prompt** on an untrusted fixture config. The tell was that
  `-C` and `cd` failed *identically*, when the whole point was to find a difference between them.
  **If both arms of a comparison fail the same way, the harness is what failed.**
- **Local fixtures fail silently too.** While re-verifying, `Set-Content -NoNewline` (unsupported
  here) left the fixture files uncreated, and `dummy` is an e2e-only fixture tool that does not
  resolve outside the harness — both produced runs that *looked* like results. Assert the fixture
  exists before trusting what follows, and use a real tool (`uv`) for local measurement.
- **A one-line summary in this file is a lead, not a finding.** Re-derive it from the tree before
  drafting. #5484's row said "`src/backend/dotnet.rs` exists" and that would have been a wrong
  reply: the thread asked for a **core tool**, which is `src/plugins/core/dotnet.rs` — a different
  file that already existed. Exactly two names exist in **both** `src/backend/` and
  `src/plugins/core/` — `dotnet` and `go` — and in both cases `core:` installs the *toolchain* while
  the backend installs *packages built with it*. `mise tool <name>` prints which the registry picks.
- Reply mechanics, PR conventions and the completed-work log live in the `mise-discussions-triage`
  memory.
