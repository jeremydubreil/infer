# Running Infer, language by language

In all the commands below, `$PROJECT` is the project's root directory, `$OUT` the results
directory, and `$OPTIONS` the analysis options chosen in the skill (for a security scan:
`--pulse-only --pulse-default-taint-config --pulse-taint-policy-as-issue-type --sarif
--no-progress-bar`).

## Java

### From the compiled classes

This works with any build system, and does not slow the build down. Build the project first,
then point Infer at what the build produced:

| Build | Build command | `--generated-classes` |
| ----- | ------------- | --------------------- |
| Maven | `mvn clean compile` | `target/classes` |
| Maven, web application | `mvn clean package` | `target/<name>.war` |
| Gradle | `./gradlew clean classes` | `build/classes/java/main` |

```sh
infer $OPTIONS --results-dir "$OUT" --project-root "$PROJECT" --sourcepath "$PROJECT" \
  --generated-classes "$PROJECT/target/classes"
```

- `--sourcepath` lets Infer find the sources of the classes, to report findings with their source
  locations.
- For a multi-module project, run Infer once per module that contains application code, or pass
  the archive that contains all of them, such as the application's `.war`.
- Add `-Dspotless.apply.skip=true` or similar options to the build if a formatting or linting
  plugin would otherwise change the sources or fail the build.

### Through the build

```sh
infer $OPTIONS --results-dir "$OUT" -- mvn clean compile
infer $OPTIONS --results-dir "$OUT" -- ./gradlew clean build
infer $OPTIONS --results-dir "$OUT" -- javac -cp "$CLASSPATH" $(find src -name '*.java')
```

Infer runs the build and captures every `javac` invocation it makes. Use `clean`, or Infer may
capture nothing because the build had nothing to compile. If Maven fails under Infer, try
`--java-version <version>`.

## C#

Infer analyzes C# through [InferSharp](https://github.com/microsoft/infersharp), whose `Cilsil`
tool translates compiled .NET assemblies to Infer's intermediate representation:

```sh
dotnet build "$PROJECT"                                  # produce the assemblies
tmp=$(mktemp -d)
dotnet Cilsil.dll translate "$PROJECT" \
  --outcfg "$tmp/out.cfg" --outtenv "$tmp/out.tenv" --cfgtxt "$tmp/cfg.txt"
infer $OPTIONS --results-dir "$OUT" --project-root "$PROJECT" \
  --cfg-json "$tmp/out.cfg" --tenv-json "$tmp/out.tenv"
```

`Cilsil.dll` comes from building InferSharp's `Cilsil` project
(`dotnet build <infersharp>/Cilsil -c Release -o <dir>`). Translate to a temporary directory, so as
not to leave intermediate files in the project.

## C, C++ and Objective-C

```sh
make clean
infer $OPTIONS --results-dir "$OUT" -- make -j
```

Or, with a compilation database (as produced by CMake with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`):

```sh
infer $OPTIONS --results-dir "$OUT" --compilation-database build/compile_commands.json
```

The default taint configuration only covers some of Objective-C's Foundation classes. For security
scans of C and C++ code, a taint configuration describing the project's sources and sinks has to
be passed with `--pulse-taint-config <file>`. Without one, run the default checkers to look for
memory and resource bugs.

## Writing a taint configuration

A taint configuration is a JSON file, or a directory of them, passed with `--pulse-taint-config`.
The models that ship with Infer, in Infer's `infer/config/taint/` directory, are examples of the
format: sources (`pulse-taint-sources`), sinks (`pulse-taint-sinks`), sanitizers
(`pulse-taint-sanitizers`) and the policies that connect them (`pulse-taint-policies`). Add the
project's own entry points, sinks and sanitizers there when the default models do not know them.
