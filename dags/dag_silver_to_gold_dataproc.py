# dags/dag_silver_to_gold_dataproc.py
from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitJobOperator
from airflow.providers.google.cloud.sensors.gcs import GCSObjectExistenceSensor
from airflow.operators.empty import EmptyOperator
from datetime import timedelta

PROJECT_ID = "my-cdp-demo-01"
REGION = "asia-southeast1"
GCS_BUCKET = "my-cdp-demo-gcs"
PY_FILE_GCS = f"gs://{GCS_BUCKET}/jobs/silver_to_gold.py"

default_args = {
    "owner": "data-eng",
    "depends_on_past": False,
    "email_on_failure": True,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG("silver_to_gold_dataproc",
         default_args=default_args,
         start_date=days_ago(1),
         schedule_interval=None,
         catchup=False) as dag:

    start = EmptyOperator(task_id="start")

    wait_silver = GCSObjectExistenceSensor(
        task_id="wait_silver_parquet",
        bucket=GCS_BUCKET,
        object="silver/customer/_SUCCESS",
        google_cloud_conn_id="google_cloud_default",
        timeout=60*60,
        poke_interval=60
    )

    # Dataproc Serverless job definition
    job = {
        "pyspark_batch": {
            "main_python_file_uri": PY_FILE_GCS,
            "args": [],
            "properties": {
                "spark.openlineage.transport.url": "http://openlineage:5000",
                "spark.openlineage.namespace": "dataproc-serverless"
            }
        }
    }

    submit = DataprocSubmitJobOperator(
        task_id="submit_dataproc_serverless",
        job=job,
        region=REGION,
        project_id=PROJECT_ID
    )

    end = EmptyOperator(task_id="end")

    start >> wait_silver >> submit >> end