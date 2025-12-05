# jobs/Dockerfile
FROM gcr.io/distroless/python3-debian11:nonroot

# nếu bạn cần JVM/Spark client, dùng base image khác (ví dụ openjdk + spark client)
# For simple PySpark job submission we can include Python only; for spark-submit container you might use full Spark image.

# Copy job files
WORKDIR /app
COPY . /app

# Install requirements if any
# nếu có file requirements.txt, uncomment:
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt

# Default command: print usage
CMD ["python", "bronze_to_silver.py"]