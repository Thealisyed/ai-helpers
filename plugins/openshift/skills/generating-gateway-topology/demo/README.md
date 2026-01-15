# Gateway Topology Visualization Demo

Demo scripts for showcasing the `/openshift:visualize-gateway-topology` command.

## Prerequisites

- OpenShift cluster with Gateway API enabled
- `oc` CLI configured and logged in
- Claude Code with the openshift plugin installed

## Quick Start

```bash
# 1. Run setup (creates demo resources)
./setup.sh

# 2. Show the pain (run commands from pain-commands.md)
# See pain-commands.md for copy-paste commands

# 3. Show the solution
/openshift:visualize-gateway-topology

# 4. Cleanup when done
./teardown.sh
```

## Demo Flow

### Before the Demo
Run `./setup.sh` to create all resources. This takes ~1-2 minutes for pods to be ready.

### During the Demo

**Part 1: Show the Pain** (~2 min)

Open `pain-commands.md` and run the 3 commands:

1. `oc get gateways,httproutes,svc -n gateway-demo`
   - "Here's everything... but how do they connect?"

2. `oc get httproute api-v2-route -n gateway-demo -o yaml | grep -A 15 backendRefs`
   - "Want to see traffic weights? Parse this YAML..."

3. `oc get httproute ... -o jsonpath` + `oc get endpoints`
   - "Tracing one route takes multiple commands"

**Part 2: The Solution** (~1 min)

```
/openshift:visualize-gateway-topology
```

Open the generated `gateway-topology-diagram.md` in VS Code or any Markdown viewer.

**Key points to highlight:**
- One command shows the entire topology
- Color-coded resources (green=GatewayClass, blue=Gateway, orange=Routes, purple=Services)
- Traffic weights shown on arrows (80%/20% for canary)
- Cross-namespace reference shown with dashed line
- Pod endpoints with ready status

### After the Demo
Run `./teardown.sh` to clean up.

## What Gets Created

| Resource Type | Count | Examples |
|--------------|-------|----------|
| Namespaces | 2 | gateway-demo, backend-services |
| Gateways | 3 | api-gateway, web-gateway, internal-gateway |
| HTTPRoutes | 6 | api-v1-route (headers), api-v2-route (weights), etc. |
| Services | 7 | api-v1-svc, api-v2-svc, api-v2-canary-svc, etc. |
| Deployments | 7 | Matching deployments for each service |
| ReferenceGrant | 1 | Allows cross-namespace reference |

## Demo Highlights

| Feature | Route | What to Show |
|---------|-------|--------------|
| Header matching | api-v1-route | `x-api-version: v1` header required |
| Traffic weights | api-v2-route | 80% stable, 20% canary |
| Exact path | api-health-route | `/health` exact match |
| Hostname routing | web-route | `www.example.com` |
| Cross-namespace | internal-route | References service in different namespace |

## Troubleshooting

**Gateways not ready?**
```bash
oc get gateways -n gateway-demo
```
Check if GatewayClass `ocp-default` exists. If using a different controller, update `setup.sh`.

**Pods not starting?**
```bash
oc get pods -n gateway-demo
oc describe pod <pod-name> -n gateway-demo
```

**Visualization command not found?**
Ensure the openshift plugin is installed:
```bash
/plugin install openshift@ai-helpers
```
