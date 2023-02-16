#!/bin/bash

# required env vars to have set:
#  * WORKFLOW_NAME
#  * WORKFLOW_RUN_NUMBER: expected to be >= 1
#  * GITHUB_REPO
#  * GITHUB_TOKEN: used by `gh`

twenty_most_recent_runs=$(mktemp)
# note: default --limit when `gh run list ...` run is 20
gh run list -R $GITHUB_REPO -w $WORKFLOW_NAME --json databaseId,number \
    > $twenty_most_recent_runs

# <debug>
echo '::group::20 most recent workflow runs'
jq --compact-output . $twenty_most_recent_runs
echo '::endgroup::'
# </debug>

run_wrapped_in_array=$(jq --argjson run_number "$WORKFLOW_RUN_NUMBER" \
    'map(select(.number == $run_number))' $twenty_most_recent_runs)
if [[ $(jq 'length' <<< $run_wrapped_in_array) < 1 ]]; then
  # TODO error if was supposed to exist in latest 20
  # TODO search back further if it wasn't expected to exist in latest 20
  echo "::error::unable to find workflow run #$WORKFLOW_RUN_NUMBER in latest 20 runs"
  exit 1
fi

# assumption: only 1 run is returned with given number, and if more were returned,
#  only first in array is considered
run=$(jq 'first' <<< $run_wrapped_in_array)

# <debug>
echo "::group::workflow run #$WORKFLOW_RUN_NUMBER"
jq . <<< $run
echo '::endgroup::'
# <debug>

echo "id=$(jq --raw-output '.databaseId' <<< $run)" | tee -a $GITHUB_OUTPUT

# if found, will output "id" to be referenced by `steps` context
