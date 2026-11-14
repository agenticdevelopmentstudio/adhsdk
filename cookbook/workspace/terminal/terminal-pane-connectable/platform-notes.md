
- **SwiftUI**: Express the contract as a protocol with an observable terminal property and an async start; use a Combine publisher or an observation stream in place of the notification.
- **Compose**: Use an interface exposing a StateFlow of the terminal session and a suspend start function; the StateFlow replaces the change notification.
- **React/Web**: Use a TypeScript interface with a getter, an async start method and an event emitter or subscribe function; a React context can hold the connectable pane registry.
- **AppKit / UIKit**: Source platform. The file is `TerminalPaneConnectable.swift`: a main-actor class-bound protocol with a default async start, a notification name extension and a conformance extension for the terminal pane's content view controller. UIKit would use the same protocol and a notification.
- **WinUI 3**: Define a C# interface ITerminalPaneConnectable with a ConnectableTerminal property and Task StartConnectableTerminalAsync() with a default interface method returning the property; raise ConnectableTerminalChanged as a typed event or publish it through a WeakReferenceMessenger from the CommunityToolkit.Mvvm; marshal calls through the DispatcherQueue because the conforming UserControl is UI-thread-bound.

