#!/bin/sh
set -eu

die() {
	printf '%s\n' "apply-feed-patches: $*" >&2
	exit 1
}

[ "$#" -le 1 ] || die "usage: $0 [feeds-directory]"
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
feeds_dir=${1:-"$repo_root/feeds"}
[ -d "$feeds_dir" ] || die "feeds directory is missing; run ./scripts/feeds update -a first"
feeds_dir=$(CDPATH= cd -- "$feeds_dir" && pwd -P)

for patch_dir in "$repo_root"/patches/feeds/*; do
	[ -d "$patch_dir" ] || continue
	set -- "$patch_dir"/*.patch
	[ -f "$1" ] || continue

	feed_name=${patch_dir##*/}
	feed_dir="$feeds_dir/$feed_name"
	[ -d "$feed_dir" ] || die "$feed_name feed is missing; run ./scripts/feeds update -a first"
	feed_dir=$(CDPATH= cd -- "$feed_dir" && pwd -P)
	feed_root=$(git -C "$feed_dir" rev-parse --show-toplevel 2>/dev/null) || die "$feed_name feed is not a Git checkout"
	[ "$feed_root" = "$feed_dir" ] || die "expected a separate Git checkout at $feed_dir"
	feed_head=$(git -C "$feed_dir" rev-parse HEAD)

	if git -C "$feed_dir" apply --check --whitespace=error-all "$@" 2>/dev/null; then
		git -C "$feed_dir" apply --whitespace=error-all "$@"
		printf '%s\n' "$feed_name patches applied at $feed_head"
	elif git -C "$feed_dir" apply --reverse --check --whitespace=error-all "$@" 2>/dev/null; then
		printf '%s\n' "$feed_name patches are already applied at $feed_head"
	else
		git -C "$feed_dir" apply --check --whitespace=error-all "$@" >&2 || :
		die "$feed_name patches conflict or are only partly applied; inspect the feed changes (nothing was reset or discarded)"
	fi
done
