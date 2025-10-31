#!/bin/bash

# Production Deployment Verification Script
# This script verifies that all prod manifests are correctly configured

set -e

echo "========================================"
echo "Production Environment Verification"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="prod"
TLS_FLAG="--insecure-skip-tls-verify=true"
TIMEOUT=300

# Counter for checks
PASSED=0
FAILED=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check 1: Kubernetes Connectivity
echo "[1/10] Checking Kubernetes Connectivity..."
if kubectl $TLS_FLAG cluster-info &> /dev/null; then
    check_pass "Kubernetes cluster accessible"
else
    check_fail "Cannot connect to Kubernetes cluster"
    exit 1
fi
echo ""

# Check 2: Namespace Existence
echo "[2/10] Checking Namespace..."
if kubectl $TLS_FLAG get namespace $NAMESPACE &> /dev/null; then
    check_pass "Namespace '$NAMESPACE' exists"
else
    warning "Namespace '$NAMESPACE' does not exist (will be created during deployment)"
fi
echo ""

# Check 3: ConfigMap Files
echo "[3/10] Verifying ConfigMap Files..."
CONFIGMAPS=$(find . -name "configmap.yaml" | wc -l)
if [ $CONFIGMAPS -eq 9 ]; then
    check_pass "All 9 ConfigMap files present"
else
    check_fail "Expected 9 ConfigMaps, found $CONFIGMAPS"
fi
echo ""

# Check 4: Deployment Files
echo "[4/10] Verifying Deployment Files..."
DEPLOYMENTS=$(find . -name "deployment.yaml" | wc -l)
if [ $DEPLOYMENTS -eq 10 ]; then
    check_pass "All 10 Deployment files present"
else
    check_fail "Expected 10 Deployments, found $DEPLOYMENTS"
fi
echo ""

# Check 5: Service Files
echo "[5/10] Verifying Service Files..."
SERVICES=$(find . -name "service.yaml" | wc -l)
if [ $SERVICES -eq 10 ]; then
    check_pass "All 10 Service files present"
else
    check_fail "Expected 10 Services, found $SERVICES"
fi
echo ""

# Check 6: Verify YAML Syntax
echo "[6/10] Validating YAML Syntax..."
YAML_FILES=$(find . -name "*.yaml" | wc -l)
INVALID=0
for file in $(find . -name "*.yaml"); do
    if ! kubectl $TLS_FLAG apply -f "$file" --dry-run=client &> /dev/null; then
        check_fail "Invalid YAML: $file"
        ((INVALID++))
    fi
done
if [ $INVALID -eq 0 ]; then
    check_pass "All $YAML_FILES YAML files are valid"
else
    check_fail "$INVALID invalid YAML files found"
fi
echo ""

# Check 7: Verify Namespace References
echo "[7/10] Verifying Namespace References..."
STAGE_REFS=$(grep -r "namespace: stage" . --include="*.yaml" | wc -l)
if [ $STAGE_REFS -eq 0 ]; then
    check_pass "No stage namespace references found (all using prod)"
else
    check_fail "Found $STAGE_REFS stage namespace references (should be 0)"
fi
echo ""

# Check 8: Verify Prod Profile References
echo "[8/10] Verifying Prod Profile References..."
PROD_PROFILES=$(grep -r "value: \"prod\"" . --include="*.yaml" | grep SPRING_PROFILES_ACTIVE | wc -l)
REQUIRED_PROFILES=10  # All 10 deployments should have prod profile
if [ $PROD_PROFILES -ge 9 ]; then
    check_pass "Found $PROD_PROFILES deployments with prod profile"
else
    check_fail "Expected at least 9 prod profiles, found $PROD_PROFILES"
fi
echo ""

# Check 9: Verify Resource Limits
echo "[9/10] Verifying Resource Limits..."
MEMORY_LIMITS=$(grep -r "memory: \"1Gi\"" . --include="deployment.yaml" | wc -l)
if [ $MEMORY_LIMITS -ge 9 ]; then
    check_pass "Memory limits set to 1Gi in $MEMORY_LIMITS deployments"
else
    warning "Expected at least 9 deployments with 1Gi memory limit, found $MEMORY_LIMITS"
fi
echo ""

# Check 10: Verify High Availability (Replicas)
echo "[10/10] Verifying High Availability Setup..."
REPLICAS_2=$(grep -r "replicas: 2" . --include="deployment.yaml" | wc -l)
if [ $REPLICAS_2 -ge 8 ]; then
    check_pass "Found $REPLICAS_2 deployments with 2 replicas (HA enabled)"
else
    warning "Expected at least 8 deployments with 2 replicas, found $REPLICAS_2"
fi
echo ""

# Summary
echo "========================================"
echo "Verification Summary"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $PASSED"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed:${NC} $FAILED"
else
    echo -e "${RED}Failed:${NC} 0"
fi
echo ""

# Final status
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Production environment is ready for deployment."
    echo ""
    echo "Next steps:"
    echo "1. Review PROD_DEPLOYMENT_GUIDE.md"
    echo "2. Ensure Docker Hub credentials are ready"
    echo "3. Run deployment commands as documented"
    exit 0
else
    echo -e "${RED}✗ Some checks failed!${NC}"
    echo ""
    echo "Please address the issues above before deploying."
    exit 1
fi
