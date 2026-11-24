//
//  SettingsPanelDescriptor.swift
//  AgenticDeveloperHubSDK
//
//  Created by Mike Fullerton on 4/29/26.
//

import AppKit
import Combine

extension ComposableSettings {

    public class SettingsPanelDescriptor: ObservableObject {

        @Published public var title: String
        @Published public var icon: NSImage?
        @Published public var isDisabled: Bool = false

        /// The topic a panel is one row of (a sidebar topic listing its panels).
        @Published public var section: String?

        /// The sidebar header a topic sits under, above `section`: a heading groups
        /// topics, a section groups panels. Nil heads the topic by its section.
        @Published public var heading: String?

        public init(
            title: String, icon: NSImage? = nil, isDisabled: Bool = false,
            section: String? = nil, heading: String? = nil
        ) {
            self.heading = heading
            self.title = title
            self.icon = icon
            self.isDisabled = isDisabled
            self.section = section
        }

        public convenience init() {
            self.init(title: "")
        }
    }
}
