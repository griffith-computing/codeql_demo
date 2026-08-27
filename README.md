# CodeQL .NET 10 engagement demo

This repository is a hands-on companion to **Using CodeQL in a C# Code Review
Engagement**. It turns a deliberately vulnerable .NET 10 application into a
CodeQL database, runs GitHub's complete C# `security-and-quality` suite, adds a
tested engagement-specific query, and preserves the results as SARIF.

> [!CAUTION]
> The application is intentionally vulnerable. Use it only on a local
> development machine. Do not deploy it, expose it to a network, or call the
> `/demo` routes with untrusted input. Automated tests call only safe routes.

## What the demo covers

```text
C# source + real build -> CodeQL database -> public and custom queries -> SARIF
```

| Presentation stage | Repository evidence |
| --- | --- |
| Frame | Each `/demo` endpoint expresses a concrete security review question. |
| Baseline | `csharp-security-and-quality.qls` runs against the .NET 10 build. |
| Triage | SARIF contains paths, locations, query IDs, messages, and rule metadata. |
| Customize | `codeql/demo-queries` contains an engagement-specific C# query. |
| Prove | `codeql/demo-query-tests` has reviewed positive and negative fixtures. |
| Deliver | GitHub Actions uploads alerts and retains the generated SARIF. |

The app includes data flows representative of SQL injection, command injection,
path traversal, server-side request forgery, unsafe HTML output, and open
redirects. `ReviewExamples.cs` also contains reliability patterns for the custom
query and the public quality suite.

## Repository map

```text
.
|-- src/CodeQLDemo.Api/                 .NET 10 Minimal API
|-- tests/CodeQLDemo.Api.Tests/         safe application smoke tests
|-- codeql/demo-queries/
|   |-- qlpack.yml                      query pack identity and dependencies
|   |-- codeql-pack.lock.yml            resolved dependency versions
|   |-- src/PublicAsyncVoid.ql          executable review query
|   |-- src/lib/ReviewModel.qll         reusable C# model
|   `-- suites/engagement.qls           engagement query selection
|-- codeql/demo-query-tests/
|   |-- qlpack.yml                      C# test pack
|   |-- codeql-pack.lock.yml            resolved test dependencies
|   `-- PublicAsyncVoid/
|       |-- PublicAsyncVoid.qlref        query under test
|       |-- BadExamples.cs              expected positive
|       |-- GoodExamples.cs             expected negatives
|       `-- PublicAsyncVoid.expected     reviewed result contract
|-- scripts/run-codeql.ps1              complete Windows flow
|-- scripts/run-codeql.sh               complete macOS/Linux flow
`-- .github/workflows/                  PR scan and upstream regression suite
```

## Prerequisites

- [.NET SDK 10.0.400](https://dotnet.microsoft.com/download/dotnet/10.0), as
  pinned by `global.json`
- [CodeQL CLI 2.26.4 bundle](https://github.com/github/codeql-cli-binaries/releases/tag/v2.26.4)
- Git

Use the full CodeQL bundle for your operating system rather than the standalone
CLI archive. The bundle includes the C# extractor and standard query packs.
Add the extracted `codeql` executable to `PATH`, then confirm:

```console
dotnet --version
codeql version
```

## Build and run the sample app

Build and execute only the safe smoke tests:

```console
dotnet restore CodeQLDemo.sln
dotnet test CodeQLDemo.sln --configuration Release
```

To show the app metadata locally:

```console
dotnet run --project src/CodeQLDemo.Api
```

Open the root URL printed by ASP.NET Core or request `/health`. The `/demo`
routes exist to provide static-analysis sinks and must not be exercised.

## Run the complete local demo

The scripts install pinned query dependencies, compile and test the custom
query, test the application, create a fresh database with the real Release
build, run the full public `security-and-quality` suite and engagement suite,
then write `artifacts/codeql/codeql-demo.sarif`.

Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-codeql.ps1
```

If CodeQL is not on `PATH`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-codeql.ps1 `
  -CodeQL C:\tools\codeql\codeql.exe
```

macOS or Linux:

```bash
chmod +x scripts/run-codeql.sh
./scripts/run-codeql.sh
```

If CodeQL is not on `PATH`:

```bash
CODEQL=/opt/codeql/codeql ./scripts/run-codeql.sh
```

Generated databases and evidence are ignored by Git. Open the SARIF file in a
SARIF viewer or the CodeQL extension for Visual Studio Code. Alert counts may
change when the pinned CodeQL version is updated because
`security-and-quality` is selection-driven; query IDs and source paths are more
durable evidence than a fixed total.

With the pinned versions, the checked-in sample currently demonstrates these
results:

| Query ID | Demonstration |
| --- | --- |
| `cs/sql-injection` | HTTP query input reaches `SqliteCommand.CommandText`. |
| `cs/command-line-injection` | HTTP query input reaches Windows and Unix process arguments. |
| `cs/path-injection` | HTTP query input reaches `File.ReadAllText`. |
| `cs/lock-this` | Publicly accessible state is used as a lock object. |
| `codeql-demo/public-async-void` | A public `*Async` API returns `void`. |

The outbound HTTP, HTML, and redirect routes remain useful review hypotheses
even when the pinned public suite does not select or model them as findings.
That gap is the point where triage and application-specific modeling begin.

## Work with the custom query

The custom rule finds public methods whose names end in `Async` but whose return
type is `void`. It reports `ReviewExamples.RefreshCacheAsync` and ignores the
`Task`-returning alternative.

Run only the query contract:

```console
codeql pack install codeql/demo-queries
codeql pack install codeql/demo-query-tests
codeql query compile --check-only codeql/demo-queries/src
codeql test run codeql/demo-query-tests
```

When intentionally changing query behavior, inspect the actual result before
accepting it. Only then update the contract with:

```console
codeql test run --learn codeql/demo-query-tests
```

Review the resulting `.expected` diff and rerun without `--learn`.

## Run GitHub's full upstream C# regression suite

This is separate from analyzing the demo application. It validates the complete
upstream C# library/query test tree and can consume substantial CPU time and
disk space.

```console
git clone --depth 1 --branch codeql-cli/v2.26.4 https://github.com/github/codeql.git upstream-codeql
cd upstream-codeql
codeql test run --threads=0 csharp/ql/test
```

The **CodeQL upstream C# regression suite** workflow runs the same command on
Monday mornings and on manual dispatch. It is deliberately not run for every
pull request.

## GitHub Actions

`.github/workflows/codeql-demo.yml` runs on pull requests, pushes to `main`, and
manual dispatch. It:

1. installs .NET 10,
2. initializes CodeQL Action v4 with `.github/codeql/codeql-config.yml`,
3. restores, builds, and safely tests the application,
4. runs `security-and-quality` plus the local engagement suite,
5. uploads results to code scanning and retains SARIF for 14 days.

The repository must have GitHub code scanning enabled for SARIF upload. Pull
requests from forks may have read-only tokens; GitHub applies its normal CodeQL
upload protections in that context.

## Troubleshooting

**No C# source was extracted**

Run `dotnet clean CodeQLDemo.sln --configuration Release` before database
creation. A compiled language database needs a traced build that actually
invokes the compiler; an up-to-date incremental build can produce no work.

**The CodeQL CLI cannot resolve a pack**

Use the full 2.26.4 bundle, run commands from the repository root, and rerun both
`codeql pack install` commands. The complete script also downloads the pinned
`codeql/csharp-queries@1.9.2` baseline pack. Do not delete the committed lock
files.

**A query test changed unexpectedly**

Read the `.actual`/`.expected` diff. Check both `BadExamples.cs` and
`GoodExamples.cs` before using `--learn`; never accept expected output only to
make a test green.

**The public suite returns a different number of alerts**

Confirm `codeql version` and the lock files first. The public suite's selectors
evolve, so document the analyzed version and triage findings by query ID rather
than relying on a historic count.

**Database creation fails**

Run the exact build independently:

```console
dotnet restore CodeQLDemo.sln
dotnet build CodeQLDemo.sln --configuration Release --no-restore
```

Fix build or restore failures before retrying CodeQL; do not hide them with a
fallback build.
