# Chat Testing Checklist (Manual)

1) Direct chat uniqueness: start chats with the same user twice; ensure only one chat exists and opens.
2) Chat list ordering: send a new message and confirm the chat bubbles to the top with updated preview.
3) New message send: send a message in a direct chat; confirm it appears immediately and persists on reload.
4) Empty state: open chat list with no chats; verify empty state copy and CTA are shown.
5) Game chat open: open a game chat from a game card; confirm it loads the correct thread.
6) Unread badge increment: send a message from a second device; confirm unread badge increments.
7) Mark read: open the chat; verify unread badge clears after opening.
8) Message ordering: send multiple messages quickly; verify descending time order is stable.
9) Pagination (if wired): scroll up to load more; confirm older messages appear without duplicates.
10) Error state on send: simulate offline and send; confirm error message and retry path.
11) Error state on list: force Firestore permission error; confirm list shows failure state.
12) Rules enforcement: attempt to read a chat where user is not a member; confirm permission denied.
13) Sender validation: attempt to write a message with a forged senderId; confirm permission denied.
14) Migration parity: run verify script; confirm report has zero mismatches.
15) Legacy compatibility: open chat list during migration; confirm no crashes if legacy fields exist.
16) Navigation flow: open chat from profile/golfers/friends; ensure back returns to previous screen.
