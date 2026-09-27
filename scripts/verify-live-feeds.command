#!/bin/zsh
set -euo pipefail
project_dir="${0:A:h:h}"
work_dir="$(mktemp -d "${TMPDIR:-/tmp/}aifrontier-feeds.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
cat "$project_dir/AIFrontier/Models/AppModels.swift" \
    "$project_dir/AIFrontier/Models/CurriculumCatalog.swift" \
    "$project_dir/AIFrontier/Services/LocalStore.swift" \
    "$project_dir/AIFrontier/Services/NewsService.swift" \
    "$project_dir/scripts/verify-live-feeds.swift" > "$work_dir/check.swift"
xcrun swiftc -swift-version 6 -parse-as-library "$work_dir/check.swift" -o "$work_dir/check"
cp "$project_dir/AIFrontier/Resources/Curriculum.json" "$work_dir/Curriculum.json"
"$work_dir/check"
