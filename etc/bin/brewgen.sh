#!/bin/sh

set -eu

DIR="$(cd "$(dirname "${0}")/../.." && pwd)"
cd "${DIR}"

BUILD_DIR="brew"

UNAME_OS="$(uname -s)"
UNAME_ARCH="$(uname -m)"

TMP_BASE=".tmp"
TMP="${TMP_BASE}/${UNAME_OS}/${UNAME_ARCH}"
TMP_LIB="${TMP}/lib"
TMP_BIN="${TMP}/bin"

DEP_VERSION="0.5.0"
DEP="${TMP_BIN}/dep-${DEP_VERSION}"

DEP_LIB="${TMP_LIB}/dep-${DEP_VERSION}"
if [ "${UNAME_OS}" = "Darwin" ]; then
  DEP_OS="darwin"
else
  DEP_OS="linux"
fi
if [ "${UNAME_ARCH}" = "x86_64" ]; then
  DEP_ARCH="amd64"
fi

rm -rf "${DEP_LIB}"
mkdir -p "${TMP_BIN}" "${DEP_LIB}"
curl -sSL "https://github.com/golang/dep/releases/download/v${DEP_VERSION}/dep-${DEP_OS}-${DEP_ARCH}" -o "${DEP}"
chmod +x "${DEP}"

rm -rf vendor
"${DEP}" ensure -v

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/bin"
mkdir -p "${BUILD_DIR}/etc/bash_completion.d"
mkdir -p "${BUILD_DIR}/etc/zsh/site-functions"
mkdir -p "${BUILD_DIR}/share/man/man1"
go run internal/cmd/gen-prototool-bash-completion/main.go > "${BUILD_DIR}/etc/bash_completion.d/prototool"
go run internal/cmd/gen-prototool-zsh-completion/main.go > "${BUILD_DIR}/etc/zsh/site-functions/_prototool"
go run internal/cmd/gen-prototool-manpages/main.go "${BUILD_DIR}/share/man/man1"
CGO_ENABLED=0 \
  go build \
  -a \
  -installsuffix cgo \
  -ldflags "-X 'github.com/uber/prototool/internal/vars.GitCommit=$(git rev-list -1 HEAD)' -X 'github.com/uber/prototool/internal/vars.BuiltTimestamp=$(date -u)'" \
  -o "${BUILD_DIR}/bin/prototool" \
  internal/cmd/prototool/main.go
