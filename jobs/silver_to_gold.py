# jobs/silver_to_gold.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import col
import logging, os

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("silver_to_gold")

def spark_session():
    return SparkSession.builder \
        .appName("silver_to_gold") \
        .config("spark.jars", "/opt/spark/jars/openlineage-spark_2.12-1.40.1.jar") \
        .config("spark.extraListeners", "io.openlineage.spark.agent.OpenLineageSparkListener") \
        .config("spark.openlineage.transport.url", os.getenv("OPENLINEAGE_URL","http://openlineage:5000")) \
        .config("spark.openlineage.namespace", os.getenv("OPENLINEAGE_NAMESPACE","dataproc-spark")) \
        .getOrCreate()

def main():
    silver_path = os.getenv("SILVER_PATH","s3a://silver/customer/")
    gold_gcs_path = os.getenv("GOLD_GCS_PATH","gs://my-cdp-demo-gcs/gold/customer/")
    target_bigquery = os.getenv("BQ_TABLE","my_dataset.customer_gold")

    spark = spark_session()
    spark.sparkContext.setLogLevel("WARN")

    df = spark.read.parquet(silver_path)
    # transformations or aggregations
    res = df.groupBy("customer_id", "event_date").agg({"amount":"sum"}).withColumnRenamed("sum(amount)","total_amount")
    # write to GCS partitioned by event_date
    res.write.mode("overwrite").partitionBy("event_date").parquet(gold_gcs_path)

    # Optional: write to BigQuery (if spark-bigquery-connector available)
    if os.getenv("WRITE_TO_BQ","false").lower() == "true":
        res.write.format("bigquery").option("table", target_bigquery).mode("append").save()

    spark.stop()

if __name__ == "__main__":
    main()