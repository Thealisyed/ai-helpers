#!/bin/bash
# Demo teardown script for openshift:visualize-gateway-topology
# Cleans up all demo resources

set -e

echo "Cleaning up Gateway API demo resources..."

# Delete namespaces (this deletes all resources within them)
oc delete namespace gateway-demo --ignore-not-found
oc delete namespace backend-services --ignore-not-found

echo ""
echo "Demo cleanup complete!"
echo ""
