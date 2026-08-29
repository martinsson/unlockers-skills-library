#!/usr/bin/env bash
# Print all review threads on a PR as JSON.
# Usage: fetch-pr-comments.sh [pr-id]
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PR_ID=$(resolve_pr_id "${1:-}")

az devops invoke \
  --area git \
  --resource pullRequestThreads \
  --route-parameters \
    project="$AZDO_PROJECT" \
    repositoryId="$AZDO_REPO" \
    pullRequestId="$PR_ID" \
  --org "$AZDO_ORG_URL" \
  --api-version 7.1
