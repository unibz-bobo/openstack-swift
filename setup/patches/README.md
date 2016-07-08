This folder contains patch files (diffs) against specific files or programs.
These patches are applied right after the deployment, but before starting the server instances - as one expects.

A patch is "enabled" and will then be "patched" if its extension equals to:
.diff
It is otherwise "disabled" if the previous extension does not match. A common
way to disable it is using the following extension:
.diff.disabled

Lorenzo
