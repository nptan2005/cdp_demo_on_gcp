#!/usr/bin/env bash
set -euo pipefail

PROJECT="cdp-tan-project"   # update theo project bạn vừa tạo
REGION="asia-southeast1"
ZONE="asia-southeast1-c"

echo "Project: $PROJECT"

# 1) list resources (để review trước khi xóa)
echo "==== List compute instances ===="
gcloud compute instances list --project="$PROJECT" || true

echo "==== List disks ===="
gcloud compute disks list --project="$PROJECT" || true

echo "==== List GKE clusters ===="
gcloud container clusters list --region="$REGION" --project="$PROJECT" || true

echo "==== List Dataproc clusters ===="
gcloud dataproc clusters list --region="$REGION" --project="$PROJECT" || true

echo "==== List Composer envs ===="
gcloud composer environments list --locations="$REGION" --project="$PROJECT" || true

echo "==== List Artifact Registry repos ===="
gcloud artifacts repositories list --location="$REGION" --project="$PROJECT" || true

echo "==== List GCS buckets ===="
gsutil ls -p "$PROJECT" || true

# 2) Delete GKE clusters (safe: delete)
echo "==== Deleting GKE clusters (region=$REGION) ===="
for C in $(gcloud container clusters list --region="$REGION" --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  echo "Deleting cluster $C"
  gcloud container clusters delete "$C" --region="$REGION" --project="$PROJECT" --quiet || true
done

# 3) Delete Dataproc clusters
echo "==== Deleting Dataproc clusters (region=$REGION) ===="
for C in $(gcloud dataproc clusters list --region="$REGION" --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  echo "Deleting dataproc $C"
  gcloud dataproc clusters delete "$C" --region="$REGION" --project="$PROJECT" --quiet || true
done

# 4) Delete Composer environments
echo "==== Deleting Cloud Composer envs ===="
for E in $(gcloud composer environments list --locations="$REGION" --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  echo "Deleting composer $E"
  gcloud composer environments delete "$E" --location="$REGION" --project="$PROJECT" --quiet || true
done

# 5) Stop & delete Compute Engine VMs
echo "==== Stopping & deleting VMs ===="
gcloud compute instances list --project="$PROJECT" --format="value(name,zone)" | while read -r NAME ZONE; do
  if [[ -z "$NAME" ]]; then continue; fi
  echo "Stopping VM $NAME in $ZONE"
  gcloud compute instances stop "$NAME" --zone="$ZONE" --project="$PROJECT" --quiet || true
  echo "Deleting VM $NAME in $ZONE"
  gcloud compute instances delete "$NAME" --zone="$ZONE" --project="$PROJECT" --quiet || true
done

# 6) Delete persistent disks (if remain)
echo "==== Deleting disks ===="
gcloud compute disks list --project="$PROJECT" --format="value(name,zone)" | while read -r NAME ZONE; do
  if [[ -z "$NAME" ]]; then continue; fi
  echo "Deleting disk $NAME in $ZONE"
  gcloud compute disks delete "$NAME" --zone="$ZONE" --project="$PROJECT" --quiet || true
done

# 7) Release static external IPs
echo "==== Deleting static external IP addresses ===="
gcloud compute addresses list --project="$PROJECT" --format="value(name,region)" | while read -r NAME R; do
  if [[ -z "$NAME" ]]; then continue; fi
  echo "Deleting address $NAME in $R"
  gcloud compute addresses delete "$NAME" --region="$R" --project="$PROJECT" --quiet || true
done

# 8) Delete Artifact Registry images (repository airflow example)
echo "==== Deleting Artifact Registry images in repo airflow ===="
REPO="airflow"
LOCATION="$REGION"
# list images then delete by digest
gcloud artifacts docker images list "${LOCATION}-docker.pkg.dev/${PROJECT}/${REPO}" --project="$PROJECT" --format="value(name,digest)" 2>/dev/null | \
while read -r NAME DIGEST; do
  if [[ -z "$DIGEST" ]]; then continue; fi
  FULL="${NAME}@${DIGEST}"
  echo "Deleting $FULL"
  gcloud artifacts docker images delete "$FULL" --project="$PROJECT" --quiet || true
done

# 9) Delete Artifact Registry repos if desired
echo "==== Deleting Artifact Registry repo (optionally) ===="
gcloud artifacts repositories list --location="$LOCATION" --project="$PROJECT" --format="value(repositoryId)" 2>/dev/null | while read -r R; do
  if [[ -z "$R" ]]; then continue; fi
  echo "Deleting artifact repository $R"
  gcloud artifacts repositories delete "$R" --location="$LOCATION" --project="$PROJECT" --quiet || true
done

# 10) Empty / delete GCS buckets (be careful!)
echo "==== Deleting GCS buckets (will rm -r) ===="
for B in $(gsutil ls -p "$PROJECT" 2>/dev/null || true); do
  if [[ -z "$B" ]]; then continue; fi
  echo "Deleting bucket $B (and all objects) — this is destructive!"
  gsutil -m rm -r "$B" || true
done

# 11) Disable APIs that you don't need (compute last)
echo "==== Disabling services ===="
for S in dataproc.googleapis.com composer.googleapis.com container.googleapis.com compute.googleapis.com run.googleapis.com; do
  echo "Disabling $S"
  gcloud services disable $S --project="$PROJECT" --quiet || true
done

echo "==== DONE ===="