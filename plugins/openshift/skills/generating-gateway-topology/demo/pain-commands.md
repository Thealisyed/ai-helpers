# Demo Pain Commands

Run these commands **before** showing `/openshift:visualize-gateway-topology` to illustrate the pain of manual inspection.

---

## Command 1: "What's in my cluster?"

```bash
oc get gateways,httproutes,svc -n gateway-demo
```

**Pain point:** Flat list with no relationship info. You can't tell:
- Which routes attach to which gateway
- Which services back which routes
- How traffic flows through the system

---

## Command 2: "What are the traffic weights?"

```bash
oc get httproute api-v2-route -n gateway-demo -o yaml | grep -A 15 backendRefs
```

**Pain point:**
- Have to parse raw YAML output
- Weights are buried in the spec
- No visual representation of the 80/20 split

---

## Command 3: "Trace the full path"

```bash
# First, find what services the route points to
oc get httproute api-v2-route -n gateway-demo -o jsonpath='{.spec.rules[*].backendRefs[*].name}' && echo

# Then, check the endpoints for each service
oc get endpoints api-v2-svc -n gateway-demo
```

**Pain point:**
- Multiple commands needed just to trace one route
- Still no visual of the full topology
- Imagine doing this for 10+ routes

---

## The Solution

```
/openshift:visualize-gateway-topology
```

**One command shows everything:**
- All gateways with listeners
- All routes with path/header matches
- Traffic weights visualized
- Services and pod endpoints
- Cross-namespace references
- Color-coded by resource type

---

## Quick Reference

| What you want | Manual way | Our way |
|---------------|------------|---------|
| See all relationships | 5+ commands, mental mapping | 1 diagram |
| Traffic weights | Parse YAML, calculate % | Visual arrows with weights |
| Trace route to pods | Multiple get/describe commands | Follow the lines |
| Cross-namespace refs | Check ReferenceGrants manually | Dashed lines show it |
