#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEQL="${CODEQL:-codeql}"
DATABASE="$ROOT/.codeql/demo-db"
ARTIFACTS="$ROOT/artifacts/codeql"
SARIF="$ARTIFACTS/codeql-demo.sarif"

cd "$ROOT"

if ! command -v "$CODEQL" >/dev/null 2>&1; then
  echo "CodeQL CLI was not found. Install it or set CODEQL to its executable path." >&2
  exit 1
fi

SDK_VERSION="$(dotnet --version)"
if [[ "$SDK_VERSION" != 10.* ]]; then
  echo ".NET 10 SDK is required; found '$SDK_VERSION'." >&2
  exit 1
fi

dotnet restore CodeQLDemo.sln
"$CODEQL" pack download codeql/csharp-queries@1.9.2
"$CODEQL" pack install codeql/demo-queries
"$CODEQL" pack install codeql/demo-query-tests
"$CODEQL" query compile --check-only codeql/demo-queries/src
"$CODEQL" test run codeql/demo-query-tests
dotnet test CodeQLDemo.sln --configuration Release --no-restore
dotnet clean CodeQLDemo.sln --configuration Release

rm -rf "$DATABASE" "$ARTIFACTS"
mkdir -p "$(dirname "$DATABASE")" "$ARTIFACTS"

"$CODEQL" database create "$DATABASE" \
  --language=csharp \
  --source-root="$ROOT" \
  --command="dotnet build CodeQLDemo.sln --configuration Release --no-restore"

"$CODEQL" database analyze "$DATABASE" \
  codeql/csharp-queries@1.9.2:codeql-suites/csharp-security-and-quality.qls \
  codeql/demo-queries/suites/engagement.qls \
  --format=sarif-latest \
  --output="$SARIF" \
  --sarif-add-baseline-file-info \
  --threads=0

echo "CodeQL analysis complete: $SARIF"
