import sys
import os
import glob
import json
import math
from junitparser import JUnitXml, TestSuite, Skipped
from utils import utils

CANARY_TEST_FAILURE_RATE = "Canary Test Failure Rate"

"""
parse_junit combines all JUnit XML files in a given directory
into a single JUnit XML with all skipped tests stripped out.
It returns a serialized JSON payload that will be sent to
Geneva via Docker.
"""
def parse_junit(junit_dir):
    test_suite = TestSuite("Combined TestSuite")
    for junit_xml in glob.glob(os.path.join(junit_dir, "junit_*.xml")):
        if "junit_runner.xml" not in junit_xml:
            parsed = JUnitXml.fromfile(junit_xml)
            for testcase in parsed:
                if isinstance(testcase, TestSuite) or isinstance(testcase.result, Skipped):
                    continue
                test_suite.add_testcase(testcase)
        os.remove(junit_xml)

    xml = JUnitXml()
    xml.add_testsuite(test_suite)
    xml.write(os.path.join(junit_dir, "junit_combined.xml"))
    xml.update_statistics()

    test_failure_rate = 0
    if xml.tests != 0:
        test_failure_rate = int(math.ceil(((xml.failures + xml.errors) * 100) / xml.tests))

    return utils.generate_payload(CANARY_TEST_FAILURE_RATE, test_failure_rate)

if __name__ == "__main__":
    if len(sys.argv) <= 1:
        print("python generate_test_failure_rate.py <JUnit XML Directory>")
        sys.exit(1)
    print(parse_junit(sys.argv[1]))
