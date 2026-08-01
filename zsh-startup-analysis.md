# Zsh startup analysis

Date: 2026-07-31 (Europe/London)

> These measurements describe the configuration before Oh My Zsh and a prompt
> framework were installed. The Spaceship setup measured 175.74 ms median over 60
> warm launches. Spaceship was replaced by Starship on 2026-08-01; the Starship
> setup measures 225.54 ms median over 25 warm launches, of which roughly 10 ms
> is the `starship init zsh` subprocess and 1.4 ms is the OS label built in
> `dot-zprompt`. The Spaceship and Starship numbers were taken with different
> harnesses, so treat the delta as indicative only. Portable
> configuration lives in the tracked `config/shell/dot-zprofile`; local
> `.zprofile` sources it and retains internal Codex configuration.

## Summary

A configured interactive login shell starts in **103.60 ms median** and **113.95 ms at p95**. The macOS/global startup-file baseline is **27.88 ms median**, so the user configuration adds about **75.72 ms** on the warm-cache path.

The main contributors are:

1. `brew shellenv`: approximately **27.35 ms**.
2. Completion initialization: **20.78 ms** with a warm `.zcompdump`, but **246.60 ms** when rebuilding it.
3. The two `uname` subprocesses in `.zprofile`: approximately **12.34 ms**. A third `uname` is run by `config/shell/dot-profile`.
4. Completion security auditing: **10.97 ms** of the warm `compinit` time.

The startup time is reasonable when the completion cache is warm, but avoidable external processes and completion-cache instability leave useful room for improvement. A practical target after optimization is roughly 50–65 ms median; that estimate must be confirmed by rerunning the benchmark after changes.

## Profiling correction at measurement time

At the time of measurement, the comment in `~/.zprofile` said:

```sh
time ZSH_DEBUGRC=1 zsh -i -c exit
```

That started an interactive **non-login** shell when no `~/.zshrc` existed. Zsh
therefore did not load `.zprofile` or enable `zprof`. The subsequently added
guarded `.zshrc` now delegates non-login shells to `.zprofile`, but the direct
login-shell command remains:

```sh
time ZSH_DEBUGRC=1 /bin/zsh -lic 'exit 0'
```

The explicit status in `exit 0` is useful because the final false `if` condition in `.zprofile` otherwise leaves a normal, non-profiled startup with status 1.

## Test environment

- Hardware: Apple M4 Pro, 24 GiB RAM (`Mac16,8`)
- OS: macOS 26.5.2, build 25F84
- Zsh: 5.9 (`arm64-apple-darwin25.0`)
- Output from measured shells was redirected to `/dev/null`.
- Each final wall-clock scenario used five warm-ups followed by 60 runs in randomized order.
- Timing used Python's monotonic `time.perf_counter()` around `/bin/zsh` subprocesses.
- Results describe subprocess startup without an attached terminal. Terminal rendering time is not included.

## Wall-clock results

These are the final warm-cache measurements.

| Scenario | Median | Mean | p95 | Min | Max |
|---|---:|---:|---:|---:|---:|
| Configured interactive login: `/bin/zsh -lic 'exit 0'` | 103.60 ms | 101.75 ms | 113.95 ms | 83.62 ms | 116.52 ms |
| macOS/global files only, using an empty `ZDOTDIR` | 27.88 ms | 26.29 ms | 29.97 ms | 19.10 ms | 31.34 ms |
| Configured login with `ZSH_DEBUGRC=1` | 111.38 ms | 107.03 ms | 116.10 ms | 82.70 ms | 120.02 ms |
| Interactive non-login: `/bin/zsh -ic 'exit 0'` | 22.01 ms | 20.82 ms | 23.21 ms | 15.75 ms | 23.51 ms |

At measurement time, the non-login result was not a valid measurement of the configuration because there was no `~/.zshrc`; the configuration was sourced from `.zprofile` only.

## `zprof` results

`zprof` reports shell-function time, not all wall-clock time. It does not attribute top-level statements or external programs such as `brew` and `uname`.

### Warm `.zcompdump`

| Function | Calls | Total | Self | Share of profiled time |
|---|---:|---:|---:|---:|
| `compinit` | 1 | 20.78 ms | 9.81 ms | 100.00% inclusive |
| `compaudit` | 2 | 10.97 ms | 10.97 ms | 52.77% |

### `.zcompdump` rebuild

| Function | Calls | Total | Self | Share of profiled time |
|---|---:|---:|---:|---:|
| `compinit` | 1 | 246.60 ms | 95.20 ms | 100.00% inclusive |
| `compdef` | 807 | 84.18 ms | 84.18 ms | 34.14% |
| `compdump` | 1 | 52.39 ms | 52.39 ms | 21.25% |
| `compaudit` | 2 | 14.83 ms | 14.83 ms | 6.01% |

The presence of `compdef` and `compdump` in the slow profile identifies it as a cache-rebuild path. The immediately following run used the cache and reduced `compinit` from 246.60 ms to 20.78 ms.

## What `.zcompdump` is

`~/.zcompdump` is the generated cache used by Zsh's completion system. `compinit` scans completion definitions, registers them, and stores the resulting metadata in this file. Later shells source the dump instead of repeating the full scan. It is safe for Zsh to regenerate the file, but that regeneration explains occasional slow startups.

At the time of testing, the file was 49,774 bytes. Profiling regenerated it as part of the analysis.

## Component measurements

Isolated subprocess measurements used a clean shell with a 7.14 ms median baseline:

| Operation | Process median | Approximate increment over baseline |
|---|---:|---:|
| `eval "$(/opt/homebrew/bin/brew shellenv)"` | 34.49 ms | 27.35 ms |
| `case "$(uname -s),$(uname -m)" ...` | 19.48 ms | 12.34 ms |

The API-key environment file had no measurable cost above benchmark noise. Its contents were not printed or inspected.

## Completion-cache instability

`brew shellenv` unconditionally prepends `/opt/homebrew/share/zsh/site-functions` to `fpath`. In the test environment:

- the parent shell contained that directory twice;
- a configured child login shell contained it three times.

When profiling contexts with different duplicate counts were alternated, `compinit` repeatedly decided that `.zcompdump` needed rebuilding. Re-running a consistent configured shell rebuilt the cache once and then returned to the 20.78 ms warm path.

This matters most for nested login shells or any startup path that inherits an already modified `FPATH`.

## Recommendations

### 1. Stabilize `fpath`

De-duplicate `fpath` before `compinit`, for example with Zsh's unique-array attribute:

```zsh
typeset -U fpath FPATH
```

Place it after `brew shellenv` or set the attribute before additions are made. This should prevent duplicate completion paths and unnecessary cache-signature changes.

### 2. Avoid rerunning `brew shellenv` in nested shells

Guard the external command when Homebrew is already initialized:

```zsh
if [[ -z ${HOMEBREW_PREFIX-} ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
```

This retains initialization for a fresh environment while avoiding about 27 ms in children that inherit `HOMEBREW_PREFIX`.

### 3. Replace `uname` subprocesses

Use Zsh's existing `$OSTYPE` and `$MACHTYPE` values rather than starting three external `uname` processes across `.zprofile` and `config/shell/dot-profile`. The pair in `.zprofile` alone costs about 12 ms.

### 4. Reduce repeated completion auditing carefully

`compinit -C` skips the security audit and saved roughly 11 ms in the warm profile. Do not disable the audit permanently without accepting the security trade-off. A common compromise is to run full `compinit` periodically, such as once per day, and use `compinit -C` while a recent dump exists.

### 5. Correct the profiler comment

Change the documented command to the login-shell form shown above so future measurements actually exercise `.zprofile`.

## Verification after changes

Repeat both checks:

```sh
time /bin/zsh -lic 'exit 0'
time ZSH_DEBUGRC=1 /bin/zsh -lic 'exit 0'
```

For reliable wall-clock comparisons, use at least 30 launches and report median and p95. Run one separate test after moving `.zcompdump` aside if the cold-cache experience is important; moving it is preferable to deleting it because it remains recoverable.
