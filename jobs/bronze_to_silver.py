# jobs/bronze_to_silver.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date
import logging
import sys
import os

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("bronze_to_silver")

def spark_session():
    return SparkSession.builder \
        .appName("bronze_to_silver") \
        .config("spark.jars", "/opt/spark/jars/openlineage-spark_2.12-1.40.1.jar") \
        .config("spark.extraListeners", "io.openlineage.spark.agent.OpenLineageSparkListener") \
        .config("spark.openlineage.transport.url", os.getenv("OPENLINEAGE_URL","http://openlineage:5000")) \
        .config("spark.openlineage.namespace", os.getenv("OPENLINEAGE_NAMESPACE","local-spark")) \
        .getOrCreate()

def validate_df(df):
    # basic validation: required columns exist and not null counts
    required = ["customer_id", "event_ts", "amount"]
    for c in required:
        if c not in df.columns:
            raise ValueError(f"Missing required column: {c}")
    return df

def main():
    s3a_endpoint = os.getenv("MINIO_S3A_ENDPOINT", "http://minio:9000")
    access_key = os.getenv("MINIO_ROOT_USER", "admin")
    secret_key = os.getenv("MINIO_ROOT_PASSWORD", "admin123")
    bronze_path = os.getenv("BRONZE_PATH","s3a://bronze/customer/")
    silver_path = os.getenv("SILVER_PATH","s3a://silver/customer/")

    spark = spark_session()
    spark.sparkContext.setLogLevel("WARN")
    sc = spark.sparkContext
    hadoop_conf = sc._jsc.hadoopConfiguration()
    hadoop_conf.set("fs.s3a.endpoint", s3a_endpoint)
    hadoop_conf.set("fs.s3a.access.key", access_key)
    hadoop_conf.set("fs.s3a.secret.key", secret_key)
    hadoop_conf.set("fs.s3a.path.style.access","true")
    hadoop_conf.set("fs.s3a.connection.ssl.enabled","false")

    log.info("Reading bronze data from %s", bronze_path)
    df = spark.read.option("header",True).csv(bronze_path)
    df = validate_df(df)
    # sample cleanup
    df = df.withColumn("event_date", to_date(col("event_ts")))
    df = df.withColumn("amount", col("amount").cast("double"))

    # Partition by date for efficient reads
    log.info("Writing cleaned data to silver at %s", silver_path)
    df.write.mode("append").partitionBy("event_date").parquet(silver_path)

    log.info("Done")
    spark.stop()

if __name__ == "__main__":
    main()