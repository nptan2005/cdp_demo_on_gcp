# dags/dag_sync_silver_to_gcs.py
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from datetime import timedelta

GCS_BUCKET = "my-cdp-demo-gcs"
MINIO_SILVER_PREFIX = "s3a://silver/customer/"

with DAG("sync_silver_to_gcs",
         start_date=days_ago(1),
         schedule_interval="@hourly",
         catchup=False) as dag:

    sync = BashOperator(
        task_id="sync_minio_to_gcs",
        bash_command=f"mc alias set local http://minio:9000 admin admin123 && mc cp --recursive local/bronze/ {MINIO_SILVER_PREFIX} && gsutil -m rsync -r /tmp/silver gs://{GCS_BUCKET}/silver",
    )