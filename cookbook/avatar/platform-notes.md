
- **React/Web**: The reference implementation. `useAvatarEngine` (`engine.ts`)
  composes `useArbitration` (`arbitration.ts`), `useBlink`/`useIdleLadder`/
  `useSpeech` (`reflexes.ts`), `useGaze` (`gaze.ts`), `useIdleFidget`
  (`idleLife.ts`), `useSpeechBubble` (`speechBubble.ts`), and `applyPose`
  (`pose.ts`) against the shape defined in `types.ts`. Every file is marked
  `"use client"` (a Next.js App Router boundary — this code never runs on
  the server render pass). Tweening is GSAP (`gsap.to`, `gsap.quickTo`,
  `gsap.timeline`) with the `MorphSVGPlugin` registered once, guarded by a
  `typeof window !== "undefined"` check at module scope. Cursor tracking
  uses `window`/`document` pointer events throttled to one recomputation per
  `requestAnimationFrame`; all other scheduling uses `setTimeout`/
  `setInterval`. The engine's own package is
  `packages/web/packages/avatar/src/`.
- **SwiftUI**: There is no direct SwiftUI equivalent of a headless React
  hook, so port the contract as an `@Observable` (or `ObservableObject`)
  class exposing `effective`/`resting`/`speech` and a `poke()` method, owned
  by whatever `View` renders the persona. Replace GSAP tweens with
  `withAnimation`/`Animation` on `AnimatableData`, or drive continuous loops
  (breathing, sway, wander) from a `TimelineView(.animation)` or a
  `Task`-based loop using `Task.sleep`. There is no MorphSVG equivalent for
  the mouth/antenna/descender path morphs — interpolate `Shape.path(in:)`
  via `AnimatableData`, or fall back to `CAShapeLayer` path animation
  through `UIViewRepresentable`/`NSViewRepresentable`. Cursor-follow gaze is
  macOS-only (`onContinuousHover`/`NSTrackingArea`); there is no pointer
  concept on iOS to mirror it. Model `Record<E, Pose>` as
  `[E: Pose]`/a `Dictionary`, and `MoodMap<E>` as a small `struct` with one
  required and two optional `E` properties, matching `types.ts` exactly.
- **Compose**: Model the engine as a `ViewModel`/plain class holding
  `mutableStateOf` for `effective`/`resting`/`speech`, with `poke()` as a
  method. Use `LaunchedEffect`/`rememberCoroutineScope` with `delay()` in
  place of `setTimeout`/`setInterval` for the reaction, waking, blink,
  ladder-poll, wander, and mutter timers, and `Animatable`/
  `animateFloatAsState` in place of GSAP's `quickTo`/`to`. There is no
  MorphSVG equivalent; approximate mouth/antenna/descender morphs with
  `AnimatedVectorDrawable` keyframes or manual point interpolation over a
  `Path`. Cursor-follow gaze has no direct mobile analogue (pointer-hover
  input); reserve it for a pointer-capable target (e.g. Compose for
  Desktop's `PointerInputScope`) and treat wander as the primary gaze
  behavior on touch-only targets.
- **AppKit / UIKit**: Replace `requestAnimationFrame`-throttled pointer
  tracking with `NSTrackingArea` mouse-moved events (AppKit) or
  `UIHoverGestureRecognizer` (iOS 13.4+, pointer-capable devices only,
  otherwise omit cursor-follow gaze entirely and rely on wander). Use
  `CADisplayLink` for the continuous loops (breathing, antenna sway, face
  bob/wiggle) and `Timer`/`DispatchQueue.main.asyncAfter` for one-shot and
  polled schedules (reaction clear, waking clear, blink cadence, ladder
  poll, wander, mutter) — mirroring GSAP's `to()`/`quickTo()` with
  `CABasicAnimation`/`CAKeyframeAnimation` on `CALayer` transforms, and
  path morphs with `CAShapeLayer.path` animations (`CGPath`
  interpolation) in place of MorphSVGPlugin. `AvatarRig`'s transform layers
  (`body`, `tiltLayer`, `leanLayer`, `idleLayer`) map to distinct
  `CALayer`s so their transforms compose the same way `svgOrigin`-scoped
  GSAP tweens do here.
- **WinUI 3**: This is the reason this recipe exists — there is no existing
  Windows port. Model `AvatarEngineConfig`/`AvatarEngine` as a class
  implementing `INotifyPropertyChanged` (or a `CommunityToolkit.Mvvm`
  `ObservableObject`) exposing `Effective`, `Resting`, `Speech` properties
  and a `Poke()` method, in place of the hook's return value. Use
  `DispatcherQueueTimer`/`DispatcherTimer` for every scheduled/polled
  callback (`setTimeout`→one-shot `DispatcherTimer`, `setInterval`→repeating
  `DispatcherTimer`): the reaction/waking clear timers, the `400`ms ladder
  poll, the blink cadence, the wander schedule, and the sleep-mutter loop.
  Use `Microsoft.UI.Composition`'s `ScalarKeyFrameAnimation`/
  `Vector3KeyFrameAnimation` (or XAML `Storyboard`s) as the `gsap.to`/
  `quickTo` equivalent for scale, rotation, and translate tweens on
  `Visual`/`CompositionVisual` layers standing in for `AvatarRig`'s
  `body`/`tiltLayer`/`leanLayer`/`idleLayer`. There is no MorphSVGPlugin
  equivalent in WinUI 3: animate between two `CanvasGeometry` path strings
  (Win2D) with a custom point-interpolating `ICompositionAnimationBase`, or
  swap discrete `PathIcon`/`Path` `Data` values if true point-for-point
  morphing is not required. Handle `PointerMoved`/`PointerExited` on the
  root `Grid`/`Canvas` for cursor-follow gaze — a plain `PointerMoved` on
  `Window.Content` fires far more often than GSAP's rAF throttle, so debounce
  it to one recomputation per `CompositionTarget.Rendering` tick to match
  **gaze-cursor-follow**'s cadence. Model `Record<E, Pose>` as
  `IReadOnlyDictionary<TExpression, Pose>` and `Tuning` as a plain record
  type with the same 15 fields.

