#!/usr/bin/env bash
# Shared configuration and helpers for the azure-devops-pr scripts.
# Source this; do not run it.

: "${AZDO_ORG:?Set AZDO_ORG to your Azure DevOps organisation name}"
: "${AZDO_PROJECT:?Set AZDO_PROJECT to your Azure DevOps project name}"
: "${AZDO_REPO:?Set AZDO_REPO to your repository name}"

AZDO_ORG_URL="https://dev.azure.com/${AZDO_ORG}"
# Azure DevOps' own resource GUID — the same for every organisation.
AZDO_RESOURCE="499b84ac-1321-427f-aa17-267ca6975798"
AZDO_BASE_URI="${AZDO_ORG_URL}/${AZDO_PROJECT// /%20}/_apis"

# resolve_pr_id [explicit-id] — echo the PR id, falling back to the active PR
# for the current branch.
resolve_pr_id() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"
    return 0
  fi
  local branch pr_id
  branch=$(git rev-parse --abbrev-ref HEAD)
  pr_id=$(az repos pr list \
    --repository "$AZDO_REPO" \
    --org "$AZDO_ORG_URL" \
    --project "$AZDO_PROJECT" \
    --source-branch "$branch" \
    --status active \
    --query "[0].pullRequestId" \
    --output tsv) || true
  if [[ -z "$pr_id" || "$pr_id" == "None" ]]; then
    echo "No active PR found for branch '$branch'" >&2
    return 1
  fi
  echo "Found PR #$pr_id for branch '$branch'" >&2
  echo "$pr_id"
}
