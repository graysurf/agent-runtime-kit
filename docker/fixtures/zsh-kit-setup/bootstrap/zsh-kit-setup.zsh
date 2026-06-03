#!/usr/bin/env zsh

emulate -L zsh
set -e
set -u

features=""
install_tools=""

while (( $# > 0 )); do
  case "$1" in
    --features)
      features="$2"
      shift 2
      ;;
    --install-tools)
      install_tools="$2"
      shift 2
      ;;
    *)
      print -u2 -- "unexpected argument: $1"
      exit 64
      ;;
  esac
done

mkdir -p .zsh-kit-smoke
print -r -- "ran" > .zsh-kit-smoke/hook-ran.txt
print -r -- "features=${features}" > .zsh-kit-smoke/result.txt
print -r -- "install_tools=${install_tools}" >> .zsh-kit-smoke/result.txt
