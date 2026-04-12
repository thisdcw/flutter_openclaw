# Flutter OpenClaw Chat Reset And Pairing Guidance Design

## Goal

Adjust the chat experience so session reset feels local and immediate, hidden model controls stay out of the normal client UI, and pairing-related connection failures guide users toward the admin authorization flow instead of retrying blindly.

## Scope

This design covers three user-facing changes on the chat page:

1. Sending `/new` should still go to the gateway, but the current chat page history should be cleared locally at the same time.
2. `/model` and `/think` should no longer appear in chat command discovery or slash suggestions for ordinary users.
3. Connection failures that look like missing pairing authorization, including `"no pair"`, should stop offering reconnect and instead instruct the user to copy the device ID from Settings and send it to an administrator for authorization.

## Design

### Local Session Reset

The local reset belongs in `ChatController`, not only in `ChatScreen`, so every send path gets the same behavior. Before adding the new outbound user message, the controller should detect whether the normalized draft text is exactly `/new` and clear the current local message list. The command is still sent through the existing gateway send pipeline unchanged.

### Hidden Command Discovery

The command assist layer already centralizes discovery chips and slash suggestions in `chat_command_assist.dart`. Remove `/model` and `/think` from the displayed command lists and update the empty-state discovery prompt copy so the visible guidance matches the actual UI. This is a presentation-only change; manual command entry does not need to be blocked by this task.

### Pairing Failure Guidance

Pairing-related failures should be recognized from both existing pairing keywords and `"no pair"` style errors. Once recognized, the chat connection strip should:

- show the localized pairing failure title,
- show a localized subtitle telling the user to open Settings, copy the device ID, and send it to an administrator for authorization,
- hide the reconnect button.

Other failures should keep the current reconnect CTA.

## Testing

- Add a controller test proving `/new` clears prior local messages before the new command message is added.
- Add a command assist test proving `/model` and `/think` are absent from discovery and slash suggestions.
- Add a widget test proving `"no pair"` shows the pairing guidance subtitle and no reconnect button.
