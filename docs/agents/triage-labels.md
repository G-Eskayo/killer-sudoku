# Triage Labels

The `triage` skill moves an issue through five canonical roles. Each maps to a string this repo
actually uses — override any that differ from the default.

| Canonical role    | This repo's label/status | Meaning                                                                        |
|--------------------|---------------------------|---------------------------------------------------------------------------------|
| `needs-triage`     | `needs-triage`             | Maintainer needs to evaluate                                                     |
| `needs-info`       | `needs-info`               | Waiting on reporter for more detail                                              |
| `ready-for-agent`  | `ready-for-agent`          | Fully specified — an AFK agent can pick this up with no further human context    |
| `ready-for-human`  | `ready-for-human`          | Needs human implementation, not agent-suitable                                   |
| `wontfix`          | `wontfix`                  | Will not be actioned                                                             |

## Consumer rules

- `triage` only ever applies one of these five — if a case doesn't clearly fit one, that's a sign
  the issue needs more information (`needs-info`), not a reason to invent a sixth label.
- This repo had no existing custom label set — the defaults above are created as real GitHub
  labels, not left purely conventional.
- `ready-for-agent` specifically means "no further human context needed" — don't apply it to an
  issue that's well-written but still assumes tribal knowledge only a human maintainer has.
