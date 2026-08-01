# Android native floating overlay

The Riderzz floating icon is Android-only and does not use an overlay package.
Flutter never renders the icon. It reports debounced lifecycle state and shows
the in-app rationale; Android owns the permission, foreground service,
`WindowManager` view, drag state, stored position, and activity restoration.

## Channel contract

Channel: `com.example.riderzz_app/overlay`

| Flutter → Android | Result |
| --- | --- |
| `showOverlay` | Request the native overlay, subject to permission. |
| `hideOverlay` | Stop the overlay service and remove the window. |
| `isOverlayVisible` | Returns the current native window state. |
| `isOverlayPermissionGranted` | Returns `Settings.canDrawOverlays`. |
| `requestOverlayPermission` | Opens the Android per-app settings page. |
| `onAppLifecycle` | `{ state: foreground|background }`; lifecycle signal only. |

Android may emit `permissionRequired` and `overlayError`. The former is
remembered by Flutter and its rationale is shown only after the Riderzz
activity is foregrounded again. This avoids presenting a dialog behind another
application. Choosing **Not now**, or returning from Settings without granting
permission, is persisted as a suppression flag.

## Lifecycle sequence

```text
Flutter WidgetsBinding                 Kotlin / Android
-----------------------                ---------------------------------
paused + hidden ──350 ms debounce──▶  onAppLifecycle(background)
                                      ──300 ms native debounce──▶ check permission
                                                                    │
                                  absent ──permissionRequired──────┘
resumed ─────────────────────────▶  stop/remove service
show Flutter rationale
Allow ───────────────────────────▶  open Android overlay settings
next background ─────────────────▶  startForegroundService
                                      OverlayService adds WindowManager view

native bubble tap ───────────────▶  ActivityLauncher restores task
                                      service stops and view is removed
```

Both Flutter and Kotlin debounce because Android can send closely spaced
`inactive`, `hidden`, and `paused` notifications. Kotlin also tracks actual
`MainActivity` visibility; a delayed show is discarded if the activity becomes
visible again. `OverlayService` has one view, a volatile visibility guard, and
always removes the view in `onDestroy`.

## Native components

- `OverlayChannelHandler`: the complete platform-channel boundary.
- `OverlayPermissionManager`: checks `SYSTEM_ALERT_WINDOW`, launches settings,
  and persists the denial/suppression choice.
- `OverlayManager`: lifecycle debouncing, duplicate prevention, service start
  and stop, and native-to-Flutter events.
- `OverlayService`: foreground-service notification and the actual native
  `TYPE_APPLICATION_OVERLAY` window.
- `OverlayView`: Canvas-free Android `FrameLayout` with drag/tap recognition
  and an application-icon bubble.
- `ActivityLauncher`: brings the current launcher task forward without
  rebuilding Flutter state when the task is still alive.

The service uses `startForegroundService` on Android 8+ and promotes itself
immediately in `onCreate`. It is deliberately `START_NOT_STICKY` and
`stopWithTask=true`: after an app task is swiped away or the process is killed,
there is no longer a trustworthy Flutter navigation state to restore, so a
stale bubble is not retained.

## Manifest rationale

- `SYSTEM_ALERT_WINDOW`: user-granted special access required by
  `TYPE_APPLICATION_OVERLAY`.
- `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SPECIAL_USE`: required for the
  visible, long-running overlay service on modern Android.
- `foregroundServiceType="specialUse"` and its subtype property: declare why
  this service exists on Android 14+.
- `stopWithTask="true"`: prevents a stale icon after an explicit task swipe.

## Android 10–15 validation checklist

- Fresh install: background once, return to app, decline the rationale, and
  verify no further prompt appears after relaunch.
- Fresh install: allow in Settings, then background via Home, gesture, Recents,
  and launching another app; verify exactly one bubble and notification.
- Tap the bubble from each path; verify the existing route is restored and the
  bubble disappears.
- Drag to all four edges, rotate, background again, and verify the bounded
  position persists.
- Rapid Home/resume switching, split-screen transitions, permission revocation,
  lock/unlock, incoming call UI, and notification shade: verify no duplicate
  windows or crashes.
- Swipe Riderzz away from Recents and force-stop it: verify its bubble is
  removed. Relaunch normally and verify the feature can be used again.
- Test Android API levels 29, 31, 33, 34, and 35/15 on at least one physical
  device; inspect Logcat for `RiderzzOverlay` and foreground-service start
  restrictions.
