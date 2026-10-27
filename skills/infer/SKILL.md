---
name: infer
description: Run the Infer static analyzer on a project to find bugs and security vulnerabilities, then triage the results. Use when asked to run Infer, scan a project with Infer, or find null dereferences, resource leaks, or taint-style vulnerabilities (SQL injection, command injection, path traversal, cross-site scripting, ...) in Java, C#, C, C++ or Objective-C code. Also use when asked to "scan for bugs", "find security vulnerabilities", "run a SAST scan", or "taint analysis" on such a project, even if Infer is not named.
license: MIT
compatibility: Requires infer on the PATH, the project's build tools, and jq to summarize the results.
---

# Infer

Infer analyzes a project in two phases: it first *captures* the code, by following the project's
build or by reading its compiled output, then *analyzes* the capture and writes a report. Both
phases run with a single `infer` command. This skill covers choosing that command, running it, and
triaging the results.

## Principles

1. **Build first.** Infer only analyzes what it captures. Make sure the project builds before
   running Infer, and analyze the build output that was actually produced.
2. **Zero findings needs checking, not celebrating.** An empty report can also mean an empty or
   partial capture. Check the capture (step 4) before reporting that a project is clean.
3. **Every finding is a lead, not a verdict.** Read the trace and the code before calling a finding
   a bug or a false positive.
4. **Keep the results directory.** Pass `--results-dir` explicitly, outside the project's sources,
   and do not delete it until the triage is done: `infer explore` reads it.

## 1. Check that Infer is installed

```sh
infer --version
```

If `infer` is not on the `PATH`, ask the user where it is installed, or point them to
<https://github.com/facebook/infer/blob/main/INSTALL.md>. Do not try to build Infer from sources
unless asked: it takes a long time.

## 2. Choose what to look for

| Goal | Options |
| ---- | ------- |
| Security vulnerabilities (taint analysis) | `--pulse-only --pulse-default-taint-config --pulse-taint-policy-as-issue-type` |
| General bugs (null dereferences, resource leaks, ...) | the default checkers: no extra options |

- `--pulse-default-taint-config` loads the sources, sinks and sanitizers that ship with Infer for
  standard libraries and common frameworks. They cover Java and C#, and some of Objective-C's
  Foundation classes; for other languages, the user has to provide a taint configuration with
  `--pulse-taint-config <file>`.
- `--pulse-taint-policy-as-issue-type` reports each finding under the name of the taint policy it
  violates (for example `SQLInjection` or `CommandInjection`) instead of a generic taint issue
  type, which makes the results much easier to group and triage.
- Always add `--sarif`, so that the results are also written to `report.sarif`, and
  `--no-progress-bar`, as the progress bar is meant for an interactive terminal.

## 3. Run the capture and the analysis

Pick the section for the project's language and build system. See
[references/languages.md](references/languages.md) for the details of each one.

In all the commands below, `$PROJECT` is the project's root directory, `$OUT` the results
directory, and `$OPTIONS` the options chosen in step 2 plus `--sarif --no-progress-bar`.

**Java, from the compiled classes** (preferred: it works with any build system):

```sh
mvn clean compile        # or: ./gradlew classes, mvn package for a .war or .jar, ...
infer $OPTIONS --results-dir "$OUT" --project-root "$PROJECT" --sourcepath "$PROJECT" \
  --generated-classes "$PROJECT/target/classes"
```

`--generated-classes` accepts a directory of `.class` files, a `.jar` or a `.war`.

**Java, through the build:** `infer $OPTIONS --results-dir "$OUT" -- mvn clean compile` (or
`-- ./gradlew build`, `-- javac ...`). Use this when the compiled classes are hard to locate.

**C#:** C# is captured with InferSharp's `Cilsil`, which translates the compiled assemblies, then
analyzed with `infer $OPTIONS --results-dir "$OUT" --project-root "$PROJECT" --cfg-json
<out.cfg> --tenv-json <out.tenv>`. See [references/languages.md](references/languages.md#c).

**C, C++ and Objective-C:** `infer $OPTIONS --results-dir "$OUT" -- make` (or another build
command), or `infer $OPTIONS --results-dir "$OUT" --compilation-database compile_commands.json`.
Start from a clean build, so that every file is compiled during the capture.

The analysis of a large project can take a long time: run it in the background when the
environment allows it, and tell the user.

## 4. Check the capture

Before trusting the results, especially an empty report:

```sh
infer debug --results-dir "$OUT" --source-files | wc -l    # source files captured
infer debug --results-dir "$OUT" --procedures | wc -l      # methods and functions captured
```

If these are zero or much smaller than expected, the capture failed or missed part of the project:
read `$OUT/logs`, check that the build produced the classes or binaries passed to Infer, and that
the build was not skipped because its outputs were up to date.

## 5. Read the results

The results are in `$OUT/report.sarif` (with `--sarif`), `$OUT/report.json` and `$OUT/report.txt`.

Summarize the findings by issue type, and by file:

```sh
jq -r '.runs[].results[].ruleId' "$OUT/report.sarif" | sort | uniq -c | sort -rn
jq -r '.runs[].results[].locations[0].physicalLocation.artifactLocation.uri' "$OUT/report.sarif" \
  | sort | uniq -c | sort -rn | head -20
```

To see a finding with its trace, from the source to the sink for a taint issue:

```sh
infer explore --results-dir "$OUT"                            # list the findings, numbered
infer explore --results-dir "$OUT" --select 3 --no-source-preview  # the trace of finding 3
infer explore --results-dir "$OUT" --html                     # an HTML report, with traces
```

## 6. Triage

For each finding, or for a representative sample when there are many of the same type:

1. Read the trace, then the code at each step, starting from the source (where the untrusted data
   comes from) to the sink (where it is used).
2. Check whether the data is validated, escaped or otherwise sanitized on the way in a way Infer
   does not know about. If so, the finding is likely a false positive, and the sanitizer could be
   added to a taint configuration.
3. Check whether the source is really controlled by an attacker in this application.

Report to the user:
- what was analyzed (languages, modules, number of source files captured) and with which options;
- the number of findings by issue type;
- the findings that look real, with their location, trace and a short explanation, most severe
  first;
- the ones that look like false positives, and why;
- anything that limited the analysis: a partial capture, missing classes, a language without
  taint models.
