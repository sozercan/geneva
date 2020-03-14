import os
import sys
from utils import utils

CANARY_CLUSTER_PROVISION_DURATION = "Canary Cluster Provision Duration"

"""
parse_junit combines all JUnit XML files in a given directory
into a single JUnit XML with all skipped tests stripped out.
It returns a serialized JSON payload that will be sent to
Geneva via Docker.
"""
def get_cluster_provision_duration(cluster_provision_log):
    last_line = 0
    with open(cluster_provision_log, 'r') as f:
        lines = f.read().splitlines()
        last_line = float(lines[-1])
    return utils.generate_payload(CANARY_CLUSTER_PROVISION_DURATION, int(last_line))

if __name__ == "__main__":
    if len(sys.argv) <= 1:
        print("python generate_cluster_provision_duration.py <cluster-provision.log>")
        sys.exit(1)
    print(get_cluster_provision_duration(sys.argv[1]))
