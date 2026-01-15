# Gateway Topology Visualization Demo Script

**Total time: ~5 minutes**

---

## PART 1: Introduction (30 seconds)

### What to show:
- Terminal window

### What to say:
> "Today I'm going to show you a new Claude Code skill that visualizes Kubernetes Gateway API topology. 
>
> If you've worked with Gateway API, you know it can be hard to understand how all the pieces connect - GatewayClasses, Gateways, HTTPRoutes, Services, and Pods.
>
> Let me show you the problem first, then the solution."

---

## PART 2: Show the Pain (1.5 minutes)

### Command 1: List resources

```bash
oc get gateways,httproutes,svc -n gateway-demo
```

### What to say:
> "Here's what we typically do - run oc get to see what's in the cluster.
>
> We can see 3 gateways, 6 routes, and 6 services... but there's no relationship information. Which routes attach to which gateway? Which services back which routes? We can't tell."

**Pause 5 seconds to let viewer read the output**

---

### Command 2: Find traffic weights

```bash
oc get httproute api-v2-route -n gateway-demo -o yaml | grep -A 15 backendRefs
```

### What to say:
> "What if I want to see traffic weights for a canary deployment?
>
> I have to dump the YAML and grep through it. Here you can see weight 80 and weight 20 buried in the output. Not very readable."

**Pause 5 seconds**

---

### Command 3: Trace the path

```bash
oc get httproute api-v2-route -n gateway-demo -o jsonpath='{.spec.rules[*].backendRefs[*].name}' && echo
```

```bash
oc get endpoints api-v2-svc -n gateway-demo
```

### What to say:
> "Now if I want to trace from a route all the way to the pods, I need multiple commands.
>
> First get the backend service names, then query each endpoint separately. Imagine doing this for 10 or 20 routes. It's tedious and error-prone."

**Pause 3 seconds**

---

## PART 3: The Solution (1 minute)

### What to show:
- Switch to Claude Code terminal

### What to say:
> "Now let me show you the solution - a single Claude Code command that visualizes everything."

### Command:

```
/openshift:visualize-gateway-topology
```

### What to say while it runs:
> "The skill automatically detects the cluster, collects all Gateway API resources, analyzes the relationships, and generates a visual diagram.
>
> It uses gwctl if available, falls back to kubectl if not. All read-only operations - nothing is modified in the cluster."

**Wait for command to complete (~30 seconds)**

---

## PART 4: Show the Diagram (1.5 minutes)

### What to do:
- Open the generated `gateway-topology-diagram.md` in VS Code or a Markdown viewer

### What to say:
> "Here's the generated diagram. Let me walk you through it."

### Point out (top to bottom):

1. **GatewayClass at top**
> "At the top we have our GatewayClass - ocp-default - which is the controller."

2. **Three Gateway subgraphs**
> "Below that, three Gateways, each in their own box with all their components."

3. **Listeners layer**
> "Each gateway shows its listeners - HTTP on port 80, HTTPS on 443, etc."

4. **Routes layer**
> "Then the HTTPRoutes attached to each gateway."

5. **Canary weights (KEY FEATURE)**
> "Look at api-v2-route - you can clearly see the 80/20 traffic split to the stable and canary services. Much clearer than grepping YAML."

6. **Header matching (KEY FEATURE)**
> "And api-v1-route shows the header match condition - x-api-version equals v1."

7. **Cross-namespace (KEY FEATURE)**
> "The internal-gateway has a dashed line showing a cross-namespace reference - the route in gateway-demo namespace points to a service in backend-services namespace."

8. **ReferenceGrant**
> "And we can see the ReferenceGrant that permits this cross-namespace access."

9. **Pod endpoints**
> "Finally, at the bottom, all the pod endpoints with their ready status."

---

## PART 5: Wrap Up (30 seconds)

### What to say:
> "So to summarize - instead of running multiple oc commands and mentally mapping relationships, one Claude Code command gives you a complete visual topology.
>
> This is useful for:
> - Debugging routing issues
> - Understanding traffic splits for canary deployments  
> - Onboarding new team members
> - Documenting your Gateway API setup
>
> The skill is available in the openshift plugin. Thanks for watching!"

---

## Quick Reference - Commands to Run

```bash
# Pain commands (copy-paste these)
oc get gateways,httproutes,svc -n gateway-demo
oc get httproute api-v2-route -n gateway-demo -o yaml | grep -A 15 backendRefs
oc get httproute api-v2-route -n gateway-demo -o jsonpath='{.spec.rules[*].backendRefs[*].name}' && echo
oc get endpoints api-v2-svc -n gateway-demo

# Solution
/openshift:visualize-gateway-topology
```

---

## Pre-Demo Checklist

- [ ] Cluster is logged in: `oc whoami`
- [ ] Demo resources exist: `oc get gateways -n gateway-demo`
- [ ] Delete old diagram if exists: `rm -f gateway-topology-diagram.md`
- [ ] VS Code or Markdown viewer ready
- [ ] Terminal font size large enough for recording
