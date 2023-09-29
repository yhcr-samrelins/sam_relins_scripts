# Retrieves information about the access entries of Connected Yorkshire project. 
# Stores dataset ID, entity ID, and role for each access entry and uploads to a 
# table in BigQuery.
from google.cloud import bigquery
import pandas as pd

client = bigquery.Client()
data = {
    "dataset": [],
    "entity_id": [],
    "role": []
}
for dataset in client.list_datasets():
    dataset = client.get_dataset(dataset.dataset_id)
    for entry in dataset.access_entries:
        if entry.entity_type == "userByEmail":
            data["dataset"].append(dataset.dataset_id)
            data["entity_id"].append(entry.entity_id)
            data["role"].append(entry.role)
            
##### Change dataset_id and table_id to adjust upload location for roles table
dataset_id = "CB_SAM_TEST"
table_id = "gbq_dataset_permissions"
#####

pd.DataFrame(data).to_gbq(f"yhcr-prd-phm-bia-core.{dataset_id}.{table_id}")