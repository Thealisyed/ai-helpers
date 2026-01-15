#!/bin/bash
# Demo setup script for openshift:visualize-gateway-topology
# Creates a realistic Gateway API topology for demonstration purposes

set -e

echo "Setting up Gateway API demo resources..."

# Create namespaces
echo "Creating namespaces..."
oc create namespace gateway-demo --dry-run=client -o yaml | oc apply -f -
oc create namespace backend-services --dry-run=client -o yaml | oc apply -f -

# Wait for namespaces
sleep 2

# Apply all resources
echo "Creating Gateway API resources..."

oc apply -f - <<'EOF'
---
# =============================================================================
# GATEWAY CLASS (required - creates the controller reference)
# =============================================================================
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ocp-default
spec:
  controllerName: openshift.io/gateway-controller
  description: "OpenShift default Gateway controller for demo"
---
# =============================================================================
# DEPLOYMENTS & SERVICES
# =============================================================================

# API v1 Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v1
  namespace: gateway-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-v1
  template:
    metadata:
      labels:
        app: api-v1
    spec:
      containers:
      - name: api
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api-v1-svc
  namespace: gateway-demo
spec:
  selector:
    app: api-v1
  ports:
  - port: 8080
    targetPort: 8080
---
# API v2 Stable Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v2
  namespace: gateway-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-v2
  template:
    metadata:
      labels:
        app: api-v2
    spec:
      containers:
      - name: api
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api-v2-svc
  namespace: gateway-demo
spec:
  selector:
    app: api-v2
  ports:
  - port: 8080
    targetPort: 8080
---
# API v2 Canary Service (for weighted traffic demo)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v2-canary
  namespace: gateway-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-v2-canary
  template:
    metadata:
      labels:
        app: api-v2-canary
    spec:
      containers:
      - name: api
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api-v2-canary-svc
  namespace: gateway-demo
spec:
  selector:
    app: api-v2-canary
  ports:
  - port: 8080
    targetPort: 8080
---
# Health Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health
  namespace: gateway-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health
  template:
    metadata:
      labels:
        app: health
    spec:
      containers:
      - name: health
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: health-svc
  namespace: gateway-demo
spec:
  selector:
    app: health
  ports:
  - port: 8080
    targetPort: 8080
---
# Web Frontend Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: gateway-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
    spec:
      containers:
      - name: web
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: web-frontend-svc
  namespace: gateway-demo
spec:
  selector:
    app: web-frontend
  ports:
  - port: 80
    targetPort: 8080
---
# Static Assets Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: static-assets
  namespace: gateway-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: static-assets
  template:
    metadata:
      labels:
        app: static-assets
    spec:
      containers:
      - name: static
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: static-assets-svc
  namespace: gateway-demo
spec:
  selector:
    app: static-assets
  ports:
  - port: 80
    targetPort: 8080
---
# Cross-namespace backend service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-backend
  namespace: backend-services
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shared-backend
  template:
    metadata:
      labels:
        app: shared-backend
    spec:
      containers:
      - name: backend
        image: registry.k8s.io/e2e-test-images/agnhost:2.39
        args: ["netexec", "--http-port=8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: shared-backend-svc
  namespace: backend-services
spec:
  selector:
    app: shared-backend
  ports:
  - port: 8080
    targetPort: 8080
---
# =============================================================================
# GATEWAYS
# =============================================================================

# API Gateway - main API traffic with HTTP and HTTPS
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: api-gateway
  namespace: gateway-demo
spec:
  gatewayClassName: ocp-default
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
      - name: api-gateway-cert
        kind: Secret
    allowedRoutes:
      namespaces:
        from: Same
---
# Web Gateway - frontend traffic
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: gateway-demo
spec:
  gatewayClassName: ocp-default
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "*.example.com"
    allowedRoutes:
      namespaces:
        from: Same
---
# Internal Gateway - internal services
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: internal-gateway
  namespace: gateway-demo
spec:
  gatewayClassName: ocp-default
  listeners:
  - name: internal
    protocol: HTTP
    port: 8080
    allowedRoutes:
      namespaces:
        from: Same
---
# =============================================================================
# HTTP ROUTES
# =============================================================================

# API v1 Route - with header matching
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-v1-route
  namespace: gateway-demo
spec:
  parentRefs:
  - name: api-gateway
    sectionName: http
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api/v1
      headers:
      - name: x-api-version
        value: v1
    backendRefs:
    - name: api-v1-svc
      port: 8080
---
# API v2 Route - with canary weights (80/20 split)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-v2-route
  namespace: gateway-demo
spec:
  parentRefs:
  - name: api-gateway
    sectionName: http
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api/v2
    backendRefs:
    - name: api-v2-svc
      port: 8080
      weight: 80
    - name: api-v2-canary-svc
      port: 8080
      weight: 20
---
# Health Route
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-health-route
  namespace: gateway-demo
spec:
  parentRefs:
  - name: api-gateway
    sectionName: http
  rules:
  - matches:
    - path:
        type: Exact
        value: /health
    backendRefs:
    - name: health-svc
      port: 8080
---
# Web Route - hostname based
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: gateway-demo
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "www.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-frontend-svc
      port: 80
---
# Static Assets Route
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: static-route
  namespace: gateway-demo
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "www.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /static
    backendRefs:
    - name: static-assets-svc
      port: 80
---
# Internal Route - cross-namespace reference
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: internal-route
  namespace: gateway-demo
spec:
  parentRefs:
  - name: internal-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /internal
    backendRefs:
    - name: shared-backend-svc
      namespace: backend-services
      port: 8080
---
# =============================================================================
# REFERENCE GRANT (for cross-namespace access)
# =============================================================================

apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-gateway-demo
  namespace: backend-services
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: gateway-demo
  to:
  - group: ""
    kind: Service
EOF

echo ""
echo "Waiting for deployments to be ready..."
oc wait --for=condition=available deployment --all -n gateway-demo --timeout=120s || true
oc wait --for=condition=available deployment --all -n backend-services --timeout=120s || true

echo ""
echo "============================================="
echo "Demo setup complete!"
echo "============================================="
echo ""
echo "Created resources:"
echo "  - 2 namespaces: gateway-demo, backend-services"
echo "  - 3 gateways: api-gateway, web-gateway, internal-gateway"
echo "  - 6 HTTPRoutes with various features:"
echo "      - api-v1-route: header matching (x-api-version: v1)"
echo "      - api-v2-route: canary weights (80%/20%)"
echo "      - api-health-route: exact path match"
echo "      - web-route: hostname-based routing"
echo "      - static-route: path prefix routing"
echo "      - internal-route: cross-namespace reference"
echo "  - 7 services with deployments"
echo "  - 1 ReferenceGrant for cross-namespace access"
echo ""
echo "Run the demo pain commands or use:"
echo "  /openshift:visualize-gateway-topology"
echo ""
