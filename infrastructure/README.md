# GKE CDP Helm Chart Skeleton — Bronze→Silver→Gold (Production-ready)
GKE CDP Helm Chart Skeleton — Bronze→Silver→Gold (Production-ready)

## Repo layout (suggested)

````text
infrastructure/
├─ charts/
│  ├─ cdp-core/               # umbrella chart (depends on smaller charts)
│  │  ├─ Chart.yaml
│  │  ├─ values.yaml
│  │  └─ templates/
│  ├─ airflow/                # airflow helm chart (customized or wrapper)
│  │  ├─ Chart.yaml
│  │  ├─ values.yaml
│  │  └─ templates/
│  ├─ spark-operator/
│  ├─ openlineage/
│  ├─ openmetadata/
│  ├─ minio/
│  └─ observability/          # prometheus+grafana+loki
├─ envs/
│  ├─ dev.yaml
│  └─ prod.yaml
├─ scripts/
│  ├─ bootstrap-gke.sh
│  └─ create-sa-bindings.sh
└─ README.md
```

