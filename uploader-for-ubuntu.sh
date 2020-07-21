#!/bin/sh -l

set -e

# --- This script is deprecated.
# --- Please upgrade to the BuildPulse Test Reporter for a faster experience!
echo "📣👋📰 A faster BuildPulse integration is now available"
echo "📣👋📰"
echo "📣👋📰 Upgrade to the BuildPulse Test Reporter"
echo "📣👋📰"
echo "📣👋📰 See details at https://github.com/Workshop64/buildpulse-semaphore"
echo

if [ -z "$BUILDPULSE_ACCESS_KEY_ID" ]
then
  echo "🐛 BUILDPULSE_ACCESS_KEY_ID is missing."
  echo "🧰 To resolve this issue, set the BUILDPULSE_ACCESS_KEY_ID environment variable to your BuildPulse access key ID using a Semaphore secret (https://docs.semaphoreci.com/essentials/using-secrets/)."
  exit 1
fi

if [ -z "$BUILDPULSE_SECRET_ACCESS_KEY" ]
then
  echo "🐛 BUILDPULSE_SECRET_ACCESS_KEY is missing."
  echo "🧰 To resolve this issue, set the BUILDPULSE_SECRET_ACCESS_KEY environment variable to your BuildPulse secret access key using a Semaphore secret (https://docs.semaphoreci.com/essentials/using-secrets/)."
  exit 1
fi

if ! echo $BUILDPULSE_ACCOUNT_ID | egrep -q '^[0-9]+$'
then
  echo "🐛 The given value is not a valid account ID: ${BUILDPULSE_ACCOUNT_ID}"
  echo "🧰 To resolve this issue, set the BUILDPULSE_ACCOUNT_ID environment variable to your numeric BuildPulse Account ID."
  exit 1
fi
ACCOUNT_ID=$BUILDPULSE_ACCOUNT_ID

if ! echo $BUILDPULSE_REPOSITORY_ID | egrep -q '^[0-9]+$'
then
  echo "🐛 The given value is not a valid repository ID: ${BUILDPULSE_REPOSITORY_ID}"
  echo "🧰 To resolve this issue, set the BUILDPULSE_REPOSITORY_ID environment variable to your numeric BuildPulse Repository ID."
  exit 1
fi
REPOSITORY_ID=$BUILDPULSE_REPOSITORY_ID

if [ ! -d "$BUILDPULSE_REPORT_PATH" ]
then
  echo "🐛 The given path is not a directory: ${BUILDPULSE_REPORT_PATH}"
  echo "🧰 To resolve this issue, set the BUILDPULSE_REPORT_PATH environment variable to the directory that contains your test report(s)."
  exit 1
fi
REPORT_PATH="${BUILDPULSE_REPORT_PATH}"

METADATA_PATH=${REPORT_PATH}/buildpulse.yml
TIMESTAMP=$(date -Iseconds)
UUID=$(cat /proc/sys/kernel/random/uuid)
cat << EOF > "$METADATA_PATH"
---
:branch: $SEMAPHORE_GIT_BRANCH
:build_url: $SEMAPHORE_ORGANIZATION_URL/workflows/$SEMAPHORE_WORKFLOW_ID
:check: ${BUILDPULSE_CHECK_NAME:-semaphore}
:ci_provider: semaphore
:commit: $SEMAPHORE_GIT_SHA
:job: $SEMAPHORE_JOB_NAME
:ref_type: $SEMAPHORE_GIT_REF_TYPE
:ref: $SEMAPHORE_GIT_REF
:repo_name_with_owner: $SEMAPHORE_GIT_REPO_SLUG
:repo_name: $SEMAPHORE_PROJECT_NAME
:repo_url: $SEMAPHORE_GIT_URL
:semaphore_agent_machine_environment_type: $SEMAPHORE_AGENT_MACHINE_ENVIRONMENT_TYPE
:semaphore_agent_machine_os_image: $SEMAPHORE_AGENT_MACHINE_OS_IMAGE
:semaphore_agent_machine_type: $SEMAPHORE_AGENT_MACHINE_TYPE
:semaphore_git_commit_range: $SEMAPHORE_GIT_COMMIT_RANGE
:semaphore_git_dir: $SEMAPHORE_GIT_DIR
:semaphore_job_id: $SEMAPHORE_JOB_ID
:semaphore_job_result: $SEMAPHORE_JOB_RESULT
:semaphore_organization_url: $SEMAPHORE_ORGANIZATION_URL
:semaphore_project_id: $SEMAPHORE_PROJECT_ID
:semaphore_workflow_number: $SEMAPHORE_WORKFLOW_NUMBER
:timestamp: '$TIMESTAMP'
:workflow_id: $SEMAPHORE_WORKFLOW_ID
EOF

ARCHIVE_PATH=/tmp/buildpulse-${UUID}.gz
tar -zcf "${ARCHIVE_PATH}" "${REPORT_PATH}"
S3_URL=s3://$ACCOUNT_ID.buildpulse-uploads/$REPOSITORY_ID/

sudo apt-get -qq update
sudo apt-get -qq install awscli > /dev/null

AWS_ACCESS_KEY_ID="${BUILDPULSE_ACCESS_KEY_ID}" \
  AWS_SECRET_ACCESS_KEY="${BUILDPULSE_SECRET_ACCESS_KEY}" \
  AWS_DEFAULT_REGION=us-east-2 \
  aws s3 cp "${ARCHIVE_PATH}" "${S3_URL}"
