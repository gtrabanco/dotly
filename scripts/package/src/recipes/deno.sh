#!/usr/bin/env bash

deno::install() {
  if platform::command_exists cargo; then
    cargo install deno
  else
    "${SLOTH_PATH:-$DOTLY_PATH}/bin/dot" package add --skip-recipe deno
  fi

  if ! platform::command_exists deno &&
    ! platform::command_exists curl; then
    script::depends_on curl unzip
  fi

  if platform::command_exists curl; then
    curl -fsSL https://deno.land/x/install/install.sh | sh
  fi

  if platform::command_exists deno; then
    return
  fi

  return 1
}

deno::is_installed() {
  platform::command_exists deno
}

deno::is_outdated() {
  ! deno upgrade --dry-run | tail -n 1 | grep -q "recent release$"
}

deno::upgrade() {
  deno upgrade
}

deno::description() {
  echo "Deno is a simple, modern and secure runtime for JavaScript and TypeScript that uses V8 and is built in Rust."
}

deno::url() {
  echo "https://deno.land/"
}

deno::version() {
  deno --version | head -n1 | awk '{print $2}'
}

deno::latest() {
  if deno::is_outdated; then
    deno upgrade --dry-run | head -n2 | tail -n1 | awk '{print $NF}'
  else
    deno::version
  fi
}
