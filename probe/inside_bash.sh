#!/bin/sh
# Runs INSIDE the POSIX shell under test. Emits `##B##KEY=value` lines.
# Absolute Windows paths are used for the native readers on purpose: in the
# broken case the shell cannot resolve anything from PATH, and we still need
# the outbound measurement.

p() { printf '##B##%s=%s\n' "$1" "$2"; }

# $OSTYPE is compiled into the shell: "msys" or "cygwin". uname would be
# resolved through PATH, and a Cygwin shell reported "Msys" because Git's uname
# came first -- the identity of the shell must not depend on the value we are
# measuring.
p OSTYPE "${OSTYPE:-<unset>}"
p UNAME_O "$(uname -o 2>/dev/null || uname -s 2>/dev/null)"
p UNAME_R "$(uname -r 2>/dev/null)"
p BASH_EXE "${BASH:-<unset>}"
p MSYSTEM "${MSYSTEM-<unset>}"
p PATH_IN "$PATH"
p ZZZ_VAR_IN "${ZZZ_PROBE_VAR-<unset>}"
p ZZZ_WINVAR_IN "${ZZZ_PROBE_WINVAR-<unset>}"

# --- can the shell itself use the PATH it was given? -----------------------
if command -v zzzmarker.exe >/dev/null 2>&1; then
  p BASH_FINDS_MARKER 1
  p BASH_MARKER_PATH "$(command -v zzzmarker.exe)"
else
  p BASH_FINDS_MARKER 0
  p BASH_MARKER_PATH "<none>"
fi
if zzzmarker.exe >/dev/null 2>&1; then p BASH_EXEC_MARKER 1; else p BASH_EXEC_MARKER 0; fi
if command -v powershell.exe >/dev/null 2>&1; then p BASH_FINDS_PS 1; else p BASH_FINDS_PS 0; fi

# --- what does a NATIVE grandchild receive? --------------------------------
PS_ABS='C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
CMD_ABS='C:/Windows/System32/cmd.exe'

if [ -x "$PS_ABS" ] || [ -f "$PS_ABS" ]; then
  "$PS_ABS" -NoProfile -ExecutionPolicy Bypass -File 'C:\zzzprobe\native_reader.ps1' 2>/dev/null | tr -d '\r'
else
  p NATIVE_READER_MISSING 1
fi

# Second, independent native reader, so a disagreement between readers is
# visible rather than silently trusted. Argument conversion is suppressed for
# this call only: MSYS rewrites the `/c` switch into a path, which made the
# first version of this probe start cmd with no command at all.
cmd_out=$(MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "$CMD_ABS" /c "echo %PATH%" 2>/dev/null | tr -d '\r')
p CMD_PATH_OUT "$cmd_out"

# Argument conversion itself, measured on purpose rather than inferred: a
# switch, a POSIX path, and a plain word, as a native program receives them.
args_seen=$("$PS_ABS" -NoProfile -ExecutionPolicy Bypass -File 'C:\zzzprobe\echo_args.ps1' /c /usr/bin plain 2>/dev/null | tr -d '\r' | tr '\n' '|')
p ARGS_SEEN "$args_seen"
