#!/usr/bin/env nix-shell
#!nix-shell -p bash -p subversion -p common-updater-scripts -i bash

die() {
    echo "error: $1" >&2
    exit 1
}

attr=ohrrpgce.unstable
svnRoot=https://rpg.hamsterrepublic.com/source

oldRev=$(nix-instantiate --eval -E "with import ./. {}; $attr.src.rev" | tr -d '"')
if [[ -z "$oldRev" ]]; then
    die "Could not extract old revision."
fi
echo "Current rev: $oldRev" >&2

latestRev=$(svn info --show-item "last-changed-revision" "$svnRoot")
if [[ -z "$latestRev" ]]; then
    die "Could not find out last changed revision."
fi
echo "Latest rev: $latestRev" >&2

nixFile=$(nix-instantiate --eval --strict -A "$attr.meta.position" | sed -re 's/^"(.*):[0-9]+"$/\1/' -e 's/common.nix$/default.nix/')
if [[ ! -f "$nixFile" ]]; then
    die "Could not evaluate '$attr.meta.position' to locate the .nix file!"
fi
echo ".nix file: $nixFile" >&2

# h remembers if we found the pattern; on the last line, if a pattern was previously found, we exit with 1
# https://stackoverflow.com/a/12145797/160386
#sed -i "$nixFile" -re '/(\brev\b\s*=\s*)"'"$oldRev"'"/{ s||\1"'"$latestRev"'"|; h }; ${x; /./{x; q1}; x}' && die "Unable to update revision."

set -x
update-source-version "$attr" "$latestRev" "" --file="$nixFile" --version-key="rev"
