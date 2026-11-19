# `import Quickshell.Services.Notifications` (Quickshell 0.3.2)

## Notification : QtObject
- `id: int` (readonly)
- `tracked: bool`
- `lastGeneration: bool` (readonly)
- `expireTimeout: real` (readonly)
- `appName: string` (readonly)
- `appIcon: string` (readonly)
- `summary: string` (readonly)
- `body: string` (readonly)
- `urgency: NotificationUrgency` (readonly)
- `actions: list<NotificationAction>` (readonly)
- `hasActionIcons: bool` (readonly)
- `resident: bool` (readonly)
- `transient: bool` (readonly)
- `desktopEntry: string` (readonly)
- `image: string` (readonly)
- `hasInlineReply: bool` (readonly)
- `inlineReplyPlaceholder: string` (readonly)
- `hints: object` (readonly)
- signal `closed(reason: NotificationCloseReason)`
- `expire()`
- `dismiss()`
- `sendInlineReply(replyText: string)`

## NotificationAction : QtObject
- `identifier: string` (readonly)
- `text: string` (readonly)
- `invoke()`

## NotificationCloseReason : QtObject
*singleton*
- `toString(value: NotificationCloseReason): string`
- enum `Enum`: Expired, Dismissed, CloseRequested

## NotificationServer : PostReloadHook
- `keepOnReload: bool`
- `persistenceSupported: bool`
- `bodySupported: bool`
- `bodyMarkupSupported: bool`
- `bodyHyperlinksSupported: bool`
- `bodyImagesSupported: bool`
- `actionsSupported: bool`
- `actionIconsSupported: bool`
- `imageSupported: bool`
- `inlineReplySupported: bool`
- `trackedNotifications: ObjectModel` (readonly)
- `extraHints: list<string>`
- signal `notification(notification: Notification)`

## NotificationUrgency : QtObject
*singleton*
- `toString(value: NotificationUrgency): string`
- enum `Enum`: Low, Normal, Critical
