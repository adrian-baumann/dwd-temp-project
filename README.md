# NOTES
## Setup

## Prefect

### Blocks
With GCS:
```bash
prefect block register -m prefect_gc
```
1. Add service accout credentials to credentials block
2. Add credentials block to bucket block

### Deployment code

```bash
prefect deployment build ./pipeline_web_to_gcs_bucket.py:etl_parent_flow \
-n "Github Storage Flow" \
-sb github/gh-dtc-storage/week7/ \
-o ./pipeline-deployment.yaml \
--apply
```

`-n`: deployment name \
`-sb`: storage block, refers to the created github block. Also, appending subfolders is possible \
`-o` : output, location and filename \
`--apply` : saves and updates deployment in prefect orion/cloud
