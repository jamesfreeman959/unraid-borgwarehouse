#!/bin/bash
#description=Runs BorgWarehouse's scheduled status and storage checks. Schedule it hourly (custom cron: 0 * * * *).
#name=BorgWarehouse checks

# For the User Scripts plugin on Unraid. The checks run inside the container, using
# the CRONJOB_KEY already set in the container's template, so the key is not copied here.

# Change this if you renamed the container.
CONTAINER=BorgWarehouse

if ! docker container inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
  echo "Container '$CONTAINER' is not running, skipping."
  exit 0
fi

rc=0
for job in status storage; do
  # $CRONJOB_KEY is expanded inside the container, not here.
  if docker exec "$CONTAINER" sh -c \
    'curl -sf --max-time 300 --data "" -H "Authorization: Bearer $CRONJOB_KEY" "http://localhost:3000/api/v1/cron/'"$job"'"' \
    >/dev/null; then
    echo "BorgWarehouse $job check: OK"
  else
    echo "BorgWarehouse $job check: FAILED (is CRONJOB_KEY set in the container template?)"
    rc=1
  fi
done
exit $rc
