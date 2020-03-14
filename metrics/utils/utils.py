import os
import json

def generate_payload(metric_name, metric_value):
    # JSON payload to be sent to Geneva
    payload = {
        "Account": "AzureUpstreamInfra",
        "Namespace": "AzureUpstreamInfra",
        "Metric": metric_name,
        "Dims": {
            "JobName": os.getenv("AGENT_JOBNAME"),
            "ClusterName": os.getenv("RESOURCE_GROUP")
        }
    }
    return "{}:{}|g".format(json.dumps(payload).replace("\n", ""), metric_value)
