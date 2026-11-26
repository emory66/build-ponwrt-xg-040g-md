#!/bin/sh
set -eu

die() {
	printf '%s\n' "apply-patches: $*" >&2
	exit 1
}

[ "$#" -eq 2 ] || die "usage: $0 {source|feeds} <directory>"
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

mode="$1"
target_dir="$2"

[ -d "$target_dir" ] || die "directory is missing: $target_dir"
target_dir=$(CDPATH= cd -- "$target_dir" && pwd -P)

apply_patches() {
	patch_dir="$1"
	git_dir="$2"
	name="$3"

	set -- "$patch_dir"/*.patch
	[ -f "$1" ] || return 0

	[ -d "$git_dir" ] || die "directory is missing: $git_dir"
	git_dir=$(CDPATH= cd -- "$git_dir" && pwd -P)

	git_root=$(git -C "$git_dir" rev-parse --show-toplevel 2>/dev/null) \
		|| die "$git_dir is not a Git checkout"

	[ "$git_root" = "$git_dir" ] \
		|| die "expected a separate Git checkout at $git_dir"

	git_head=$(git -C "$git_dir" rev-parse HEAD)

	if git -C "$git_dir" apply --check --whitespace=error-all "$@" 2>/dev/null; then
		git -C "$git_dir" apply --whitespace=error-all "$@"
		printf '%s\n' "$name patches applied at $git_head"
	elif git -C "$git_dir" apply --reverse --check --whitespace=nowarn "$@" 2>/dev/null; then
		printf '%s\n' "$name patches are already applied at $git_head"
	else
		git -C "$git_dir" apply --check --whitespace=error-all "$@" >&2 || :
		die "$name patches conflict or are only partly applied; nothing was reset or discarded"
	fi
}

case "$mode" in
	source)
		apply_patches "$repo_root/patches/openwrt" "$target_dir" "openwrt"
		;;

	feeds)
		for patch_dir in "$repo_root"/patches/feeds/*; do
			[ -d "$patch_dir" ] || continue

			feed_name=${patch_dir##*/}
			apply_patches "$patch_dir" "$target_dir/$feed_name" "$feed_name"
		done
		;;

	*)
		die "unknown mode: $mode"
		;;
esac
