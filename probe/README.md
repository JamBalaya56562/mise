# Windows PATH probe — evidence for #12696

Throwaway branch. Not for merge into `main`; kept until #12696 is decided so the
runs stay linkable from the PR.

The question is narrow: when mise on Windows spawns a POSIX shell for a task,
does mise need to convert `PATH` first? #9547 / #10147 / #10190 assumed yes.
This measures whether that is true, and whether converting is actively harmful.

## What runs

`.github/workflows/win-path-probe.yml` — only these measurements, nothing else,
so a run is readable on its own and finishes without the full suite.

| job | what it measures | needs a build |
|---|---|---|
| `runtime-truth` | Git Bash, MSYS2 and Cygwin themselves, no mise anywhere | no |
| `mise-in-loop`  | the same instrument driven through `mise run`, released 2026.9.0 (pre-converts) vs this branch (does not) | yes |

Both are driven from **pwsh**, never from `shell: bash`. A bash-driven probe is
already inside MSYS, so its parent process is the wrong one and every number it
produces is about a case mise never hits.

## The instrument

One script, `inside_bash.sh`, is used by every row, so the rows are comparable.
It is *sourced* rather than executed, because in the broken case the shell
cannot resolve `sh` from `PATH` and the measurement still has to run.

It reports, for one (shell, inbound PATH form) pair:

- `PATH` as the shell sees it — inbound conversion
- whether the shell can find **and run** `zzzmarker.exe` from `PATH`
  (a copy of `whoami.exe`: exits 0 with no arguments, so the test measures
  lookup and launch and nothing else)
- `PATH` as a **native** grandchild sees it, read twice by independent readers
  (`powershell.exe` reading the process environment, and `cmd.exe`), so a
  disagreement between readers is visible rather than silently trusted
- whether that native grandchild can find and run the marker
- a non-`PATH` variable in POSIX form and one in Windows form, which separates
  MSYS's argument/environment conversion from Cygwin's `PATH`-only conversion

Both readers are launched by absolute path. In the broken case `PATH` cannot
resolve them, and the outbound measurement is exactly what we came for.

## Inbound forms

| label | what it stands for |
|---|---|
| `win` | Windows form — what mise passes after this PR |
| `posix-cygpath` | the shell's own `cygpath -u -p` output — the *best case* a converter could produce, and what mise's Rust converter aimed at |
| `posix-naive-slashc` | `/c/...` regardless of shell — what a basename-matching converter does to Cygwin or WSL |

`posix-cygpath` matters: if even a perfectly converted PATH breaks the round
trip, then no amount of fixing mise's converter would have helped.

## Reading the result

The job fails if a claim stops holding, so a green run is the evidence.

| id | claim |
|---|---|
| C1 | Windows-form PATH in → the shell sees POSIX form, unaided |
| C2 | …and the shell can run a binary found on that PATH |
| C3 | …and a native grandchild gets a usable Windows PATH |
| C3b | …and nothing is lost on the way, UNC entries included |
| C4 | **MSYSTEM set** + pre-converted PATH → the native round trip is destroyed |
| C5 | **MSYSTEM unset** + correctly converted PATH → the round trip survives |
| C5b | …but a `cygpath` conversion still loses entries that pass-through keeps |
| C6 | Cygwin given the Git Bash `/c/` form → the shell resolves nothing at all |
| C7 | MSYS rewrites an arbitrary POSIX-valued variable for a native child; Cygwin does not |
| C8 | MSYS rewrites POSIX-looking *arguments* to a native program, the `/c` switch included; Cygwin does not |
| N/O/D | the same, through `mise run`, for this branch and for released 2026.9.0 |

## What the first run found

Run [33699311927](https://github.com/JamBalaya56562/mise/actions/runs/33699311927)
was written to assert that a pre-converted PATH always breaks the round trip.
The runtime disagreed, and the disagreement is the useful part:

- Pass-through (C1–C3b) holds on all four shells. Nothing is lost, UNC included.
- Pre-conversion destroys the round trip **only where the shell sets `MSYSTEM`**
  — `C:\Program Files\Git\bin\bash.exe`. It prepends its own entries and keeps
  the inherited POSIX string as a single opaque element: 78 entries become 4,
  the rest survive inside one of them, and a native grandchild resolves nothing.
- Where `MSYSTEM` is unset (`Git\usr\bin\bash.exe`, MSYS2, Cygwin) the runtime
  re-parses a converted PATH and the round trip survives — so the conversion was
  never load-bearing there.
- `Get-Command bash.exe` and mise's own resolution both land on the `MSYSTEM`
  shell, so the broken case is the default one, not a corner case.
- Even a `cygpath -u -p` conversion corrupts UNC entries (`\\server\share\bin`
  came back as `D:\server\share\bin`), which pass-through preserves.
- A converter that guesses the prefix from the program name takes Cygwin out
  entirely — the failure mode @pjeby raised for WSL.

Three instrument bugs were found and fixed across the first two runs, which is
why they are worth recording:

- `uname` was resolved through the PATH under test, so a Cygwin shell reported
  `Msys` -- it was running Git Bash's `uname`.
- `cmd.exe /c` had its switch rewritten to `C:/` by MSYS argument conversion, so
  the cross-check reader was reading nothing at all.
- `$OSTYPE` reports `cygwin` for Git Bash and MSYS2 as well, so it cannot tell
  the runtimes apart either.

The shell's identity now comes from the driver, which chose the binary. Nothing
that identifies or cross-checks a measurement may depend on the value being
measured.

The `/c` mangling is itself recorded as C8: MSYS rewrites `/c` to `C:/` and
`/usr/bin` to `C:/Program Files/Git/usr/bin`, while Cygwin passes both through
untouched -- the argument-conversion difference @pjeby described, measured.

Raw per-row JSON is uploaded as an artifact for anything the table elides.
