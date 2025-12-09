FROM apache/airflow:2.10.5-python3.10

# Switch to root để cài packages
USER root

# Copy requirements
COPY requirements.txt /requirements.txt
USER airflow
# Install packages globally (được phép)
RUN pip install --no-cache-dir -r /requirements.txt

# Quay lại user airflow
