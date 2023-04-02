#!/bin/bash
# run prefect agent
prefect agent start -q 'default'
prefect server start