# Recovery entry in tweak details

Date: 2026-10-26. Local functional UI tests; no CMU or physical USB operations.

The detail dialog now checks recovery eligibility without changing the page or
focus. A valid response adds Restore original between Back and the normal action.
Clicking it opens confirmation; Back returns to the same tweak. Denied/malformed
responses produce no button. Managed installation protections remain enforced
by the unchanged backend. No attempted installation is required.

UI checks passed: broken tweaks retain Retry status and gain the conditional
button, focus stays on Back, multicontroller navigation reaches Restore, no
automatic confirmation or install occurs, stale detail-view responses are ignored,
successful restore removes eligibility, and critical restore errors block actions.
A blocked install returns to details after OK instead of opening confirmation.
Browser transport checks and repository validation also passed.

The desktop preview opens the simulated broken No More Disclaimer detail view.
Vehicle display/layout confirmation remains pending. Backend recovery behavior
and safety checks are unchanged by this UI-only follow-up.
