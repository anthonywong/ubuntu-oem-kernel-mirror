#!/bin/bash

# 1. Setup paths
source debian/debian.env
chlog_file="${DEBIAN}/changelog"

# 2. Extract current Package and Version
# Input: linux-oem-6.17 (6.17.0-1006.6) noble; urgency=medium
# Output: pkg=linux-oem-6.17, ver=6.17.0-1006.6
read -r pkg ver <<< "$(head -n1 "$chlog_file" | awk '{print $1, $2}' | tr -d '()')"

# 3. Construct New Version
# Injection: 6.17.0-1006.6 -> 6.17.0-91006.6 + Timestamp
timestamp=$(date +%Y%m%d-%H%M)
new_ver=$(echo "$ver" | sed 's/-\([0-9]\)/-9\1/')+${timestamp}

# 4. Construct Git Tag
# Based on example: Ubuntu-oem-6.17-6.17.0-1006.6
# We strip 'linux-' from the package name to match the "Ubuntu-" prefix convention
tag="Ubuntu-${pkg#linux-}-${ver}"

# 5. Execute dch commands
# Initialize new entry
DEBFULLNAME="Launchpad CI" DEBEMAIL="$USER@`hostname`" \
dch --changelog "$chlog_file" --newversion "$new_ver" "Automated version bump for CI build"

# Append git log subjects
git log --pretty=format:"%s" "${tag}..HEAD" | while read -r line; do
DEBFULLNAME="Launchpad CI" DEBEMAIL="$USER@`hostname`" \
    dch --changelog "$chlog_file" --append "$line"
done
