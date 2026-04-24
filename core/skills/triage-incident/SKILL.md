---
name: triage-incident
description: Use when the user says "triage this alert", "what's on fire", "incident", or "/triage". Structures an incident triage: severity, blast radius, likely cause, immediate mitigation steps, and who to page.
---

# triage-incident

## When to use

- "triage this alert" / "/triage"
- "what's on fire?" / "we have an incident"
- "page is firing" / "alert from <service>"
- Pasting a PagerDuty / Alertmanager / Datadog alert body

## Inputs

- Alert text, error logs, or a description of symptoms.
- Optionally: service name, environment (prod/staging), start time.

## Procedure

1. **Extract signal.** From the alert/log, identify:
   - Affected service(s) and environment.
   - Error type (latency spike, error rate, resource exhaustion, data loss, security event).
   - Start time and duration.

2. **Assign severity** using this scale:
   | SEV | Condition |
   |-----|-----------|
   | 1 | Production down or data loss — page on-call lead immediately |
   | 2 | Production degraded, significant user impact |
   | 3 | Partial failure, workaround exists |
   | 4 | Non-prod, minor impact |

3. **Assess blast radius:**
   - How many users / services are affected?
   - Is there cascading failure risk to downstream services?
   - Is data integrity at risk?

4. **Hypothesize causes** (pick top 2-3):
   - Recent deploys: `git log --since="2 hours ago" --oneline`
   - Config changes, infra changes, traffic spike, upstream dependency.

5. **Immediate mitigation steps** (stop the bleeding first):
   - Rollback candidate? (`gh run list --workflow=deploy`)
   - Feature flag to disable?
   - Scale up / circuit breaker to trip?
   - Traffic reroute?

6. **Output:**
   ```markdown
   ## Incident Triage — <service> — <timestamp>

   **Severity:** SEV-X — <one line why>
   **Blast radius:** <who/what is affected>
   **Duration:** <how long>

   ### Likely causes
   1. <most likely> — evidence: ...
   2. <alternative>

   ### Immediate actions
   - [ ] <rollback / disable / scale>
   - [ ] Page <team/person> if SEV 1-2
   - [ ] Open incident channel #inc-<service>-<date>

   ### Investigate next
   - [ ] Check dashboards: <links if known>
   - [ ] Review recent deploys
   - [ ] Check upstream dependencies
   ```

## Guardrails

- Do not execute mitigation actions without user confirmation.
- If severity cannot be determined, default to SEV-2 (err cautious).
- Always record timeline — ask user for start time if not in the alert.
