---
name: k8s-health-check
description: Use when asked to check cluster health, "what's wrong in k8s", "check pods", or "/k8s-health". Runs a structured Kubernetes health check across nodes, workloads, and recent events.
---

# k8s-health-check

## When to use

- "check cluster health" / "/k8s-health"
- "what's wrong in Kubernetes?"
- "why are pods crashing?"
- "check the namespace <X>"

## Inputs

- Optionally: namespace (default: all namespaces), cluster context, or a specific workload name.

## Procedure

1. **Confirm context.** Verify the target cluster before running any commands:
   ```bash
   kubectl config current-context
   ```
   If it doesn't match the user's intent, ask before proceeding.

2. **Cluster-level checks** (run in parallel):
   ```bash
   kubectl get nodes -o wide                          # node status + roles
   kubectl top nodes                                  # CPU/mem pressure
   kubectl get events --all-namespaces \
     --field-selector type=Warning \
     --sort-by='.lastTimestamp' | tail -20            # recent warnings
   ```

3. **Workload checks:**
   ```bash
   # Not-running pods
   kubectl get pods -A --field-selector='status.phase!=Running,status.phase!=Succeeded'

   # Recent restarts (>3 restarts is a signal)
   kubectl get pods -A --sort-by='.status.containerStatuses[0].restartCount' | tail -20

   # Pending pods (scheduling issues)
   kubectl get pods -A --field-selector=status.phase=Pending
   ```

4. **If a specific pod is unhealthy:**
   ```bash
   kubectl describe pod <name> -n <ns>    # events, resource limits, node assignment
   kubectl logs <pod> -n <ns> --tail=50  # recent log output
   kubectl logs <pod> -n <ns> --previous # logs from crashed container
   ```

5. **Report:**
   ```markdown
   ## Kubernetes Health Check — <context> — <timestamp>

   ### Nodes
   - X/Y nodes Ready
   - <any NotReady nodes and reason>

   ### Workload issues
   | Namespace | Pod | Status | Restarts | Issue |
   |---|---|---|---|---|
   | <ns> | <pod> | CrashLoopBackOff | 12 | OOMKilled |

   ### Recent warnings
   - <top 3-5 warning events>

   ### Recommended actions
   - [ ] <describe pod X for OOMKilled details>
   - [ ] <increase memory limit or fix leak>
   ```

## Guardrails

- Always confirm `kubectl config current-context` matches the intended cluster.
- Never run `kubectl delete` or any mutating command without explicit user confirmation.
- `kubectl exec` into pods only if the user explicitly asks.
- If `kubectl top` is unavailable (metrics-server not installed), note it and skip resource pressure checks.
