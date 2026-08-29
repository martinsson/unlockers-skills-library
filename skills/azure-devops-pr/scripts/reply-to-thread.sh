#!/usr/bin/env bash
# Reply to a review thread, and optionally set its status.
# Usage: reply-to-thread.sh <pr-id> <thread-id> <reply-text> [status]
# Status is one of: active fixed wontFix closed byDesign pending
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PR_ID="${1:?Usage: reply-to-thread.sh <pr-id> <thread-id> <reply-text> [status]}"
THREAD_ID="${2:?Usage: reply-to-thread.sh <pr-id> <thread-id> <reply-text> [status]}"
REPLY="${3:?Usage: reply-to-thread.sh <pr-id> <thread-id> <reply-text> [status]}"
STATUS="${4:-}"

BODY=$(python3 -c "
import json, sys
print(json.dumps({'content': sys.argv[1], 'parentCommentId': 1, 'commentType': 'text'}))
" "$REPLY")

az rest --method post \
  --resource "$AZDO_RESOURCE" \
  --uri "${AZDO_BASE_URI}/git/repositories/${AZDO_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}/comments?api-version=7.1" \
  --body "$BODY" \
  --output json > /dev/null
echo "Replied to thread #${THREAD_ID}."

if [[ -n "$STATUS" ]]; then
  az rest --method patch \
    --resource "$AZDO_RESOURCE" \
    --uri "${AZDO_BASE_URI}/git/repositories/${AZDO_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}?api-version=7.1" \
    --body "$(python3 -c "import json,sys; print(json.dumps({'status': sys.argv[1]}))" "$STATUS")" \
    --output json > /dev/null
  echo "Thread #${THREAD_ID} set to '${STATUS}'."
fi
