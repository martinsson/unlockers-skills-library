#!/usr/bin/env bash
# Enable auto-complete with squash merge, using the PR title + description
# as the merge commit message.
# Usage: auto-complete-pr.sh [pr-id]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PR_ID=$(resolve_pr_id "${1:-}")

PR_JSON=$(az repos pr show --id "$PR_ID" --org "$AZDO_ORG_URL" --output json)
TITLE=$(echo "$PR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])")
DESCRIPTION=$(echo "$PR_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('description',''))")

MERGE_MESSAGE="${TITLE}

${DESCRIPTION}"

az repos pr update \
  --id "$PR_ID" \
  --org "$AZDO_ORG_URL" \
  --auto-complete true \
  --squash true \
  --merge-commit-message "$MERGE_MESSAGE"
