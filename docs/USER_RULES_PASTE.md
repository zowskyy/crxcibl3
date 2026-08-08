# Global User Rules — GA System Prompt Only

Paste this into **Cursor → Customize → Rules → User Rules** for all projects.

```
GA-READY ONLY. See full prompt in repo .cursor/rules/ga-system-prompt.mdc.

Non-negotiable: NO placeholders (TODO/pass/stubs). Verification first. Maintain CONTEXT.md.
Checkpoint long processes to ~/.crawler/state.json. Gate every changed file until PASS:

  python3 ~/.cursor/cursor_gate_fastest.py --file <path> --region us-west-2
  python3 ~/.cursor/cursor_gate.py --file <path> --iterations 3

Block output on any blocking gate failure. Footer: Gate review: PASS (fastest + full).
Delegate 3+ file tasks to Taylor workers; re-gate merged changes before delivery.
```
