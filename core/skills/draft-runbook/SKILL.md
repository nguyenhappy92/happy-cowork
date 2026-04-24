---
name: draft-runbook
description: Use when asked to write a runbook, document a procedure, or create an ops playbook for a service or alert. Produces a structured runbook with context, steps, rollback, and escalation.
---

# draft-runbook

## When to use

- "write a runbook for X"
- "document how to restart the service"
- "create a playbook for this alert"
- "what should on-call do when Y happens?"

## Inputs

- Service or alert name.
- Description of the problem scenario or procedure to document.
- Optionally: existing notes, past incident postmortems, alert config.

## Procedure

1. **Gather context.** Ask for (or infer from available files):
   - What triggers this runbook (alert name, symptom, or scheduled task).
   - Which environment(s) it applies to.
   - What tools are needed (kubectl, aws cli, psql, etc.).

2. **Draft the runbook** in this structure:

   ```markdown
   # Runbook: <Title>

   **Service:** <name>
   **Alert / Trigger:** <alert name or condition>
   **Owner:** <team>
   **Last updated:** <date>

   ## Overview
   <2-3 sentences: what this service does and why this matters>

   ## Prerequisites
   - Access to <system> (request via <link>)
   - Tools: <list>

   ## Symptoms
   - <what the alert / user report looks like>

   ## Diagnosis
   1. <first check — command + expected output>
   2. <second check>
   ...

   ## Resolution steps
   ### Option A: <common fix>
   1. <step>
   2. <step>

   ### Option B: <fallback>
   1. <step>

   ## Rollback
   <how to undo the resolution if it makes things worse>

   ## Escalation
   - If unresolved after 30 min: page <person/team>
   - Slack: #<channel>
   - PagerDuty: <policy name>

   ## Post-incident
   - [ ] File postmortem if SEV 1-2
   - [ ] Update this runbook if steps changed
   ```

3. **Fill in real commands** wherever possible from the context provided. Prefer copy-pasteable commands over prose descriptions.

4. **Mark gaps** with `<!-- TODO: confirm with <team> -->` rather than guessing.

## Guardrails

- Do not invent commands — mark them as `# verify this` if unsure.
- Keep diagnosis steps ordered from fastest/cheapest check to slowest.
- One runbook per alert or procedure — don't combine unrelated scenarios.
