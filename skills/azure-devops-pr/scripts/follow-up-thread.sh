#!/usr/bin/env bash
# Turn a review thread into a tracked follow-up: create a work item as a child
# of the PR's linked story, reply to the thread with a cross-reference, and
# resolve it.
# Usage: follow-up-thread.sh <pr-id> <thread-id> <task-title> <task-description> <reply-comment>
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

USAGE="Usage: follow-up-thread.sh <pr-id> <thread-id> <task-title> <task-description> <reply-comment>"
PR_ID="${1:?$USAGE}"
THREAD_ID="${2:?$USAGE}"
TASK_TITLE="${3:?$USAGE}"
TASK_DESCRIPTION="${4:?$USAGE}"
REPLY_COMMENT="${5:?$USAGE}"

WORK_ITEM_TYPE="${AZDO_FOLLOWUP_WORK_ITEM_TYPE:-Task}"

echo "Fetching PR work items..."
PR_WORKITEMS=$(az rest --method get \
  --resource "$AZDO_RESOURCE" \
  --uri "${AZDO_BASE_URI}/git/repositories/${AZDO_REPO}/pullRequests/${PR_ID}/workitems?api-version=7.1" \
  --output json)

PARENT_ID=$(echo "$PR_WORKITEMS" | python3 -c "
import json, sys
items = json.load(sys.stdin).get('value', [])
print(items[0]['id'] if items else '')
")

if [ -z "$PARENT_ID" ]; then
  echo "ERROR: No work items linked to PR #${PR_ID}. Cannot determine parent story." >&2
  exit 1
fi
echo "Found parent work item: #${PARENT_ID}"

echo "Creating follow-up ${WORK_ITEM_TYPE}..."
TASK_JSON=$(az boards work-item create \
  --type "$WORK_ITEM_TYPE" \
  --org "$AZDO_ORG_URL" \
  --project "$AZDO_PROJECT" \
  --title "$TASK_TITLE" \
  --description "${TASK_DESCRIPTION}

Related to PR #${PR_ID} thread #${THREAD_ID}.
Parent work item: #${PARENT_ID}" \
  --output json)

TASK_ID=$(echo "$TASK_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "Created work item: #${TASK_ID}"

echo "Linking #${TASK_ID} as child of #${PARENT_ID}..."
az boards work-item relation add \
  --id "$TASK_ID" \
  --org "$AZDO_ORG_URL" \
  --relation-type "Parent" \
  --target-id "$PARENT_ID" \
  --output json > /dev/null

echo "Replying to thread #${THREAD_ID}..."
COMMENT_BODY=$(python3 -c "
import json, sys
reply, task_id, parent_id, title = sys.argv[1:5]
content = f'{reply}\n\nCreated follow-up work item #{task_id} (child of #{parent_id}): **{title}**'
print(json.dumps({'content': content, 'parentCommentId': 1, 'commentType': 'text'}))
" "$REPLY_COMMENT" "$TASK_ID" "$PARENT_ID" "$TASK_TITLE")

az rest --method post \
  --resource "$AZDO_RESOURCE" \
  --uri "${AZDO_BASE_URI}/git/repositories/${AZDO_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}/comments?api-version=7.1" \
  --body "$COMMENT_BODY" \
  --output json > /dev/null

echo "Resolving thread #${THREAD_ID}..."
az rest --method patch \
  --resource "$AZDO_RESOURCE" \
  --uri "${AZDO_BASE_URI}/git/repositories/${AZDO_REPO}/pullRequests/${PR_ID}/threads/${THREAD_ID}?api-version=7.1" \
  --body '{"status": 2}' \
  --output json > /dev/null

echo ""
echo "Done. Thread #${THREAD_ID} resolved with follow-up #${TASK_ID} (child of #${PARENT_ID})."
