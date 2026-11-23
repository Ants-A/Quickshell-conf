# Niri-home-made-conf

Codex notifications sent through Kitty are cleared from history when a Kitty
window gains focus. This is an approximation: Kitty does not identify which
window sent an OSC 9/777 notification, and focus does not prove an approval
was answered. To identify all Codex alerts (including arbitrary response
previews), set `notification_method = "osc777"` under `[tui]` in
`~/.codex/config.toml` and restart Codex. Older OSC 9 approval and question
alerts are recognized by their text and may match similar Kitty notifications.
