import Foundation
import Testing
import AgenticDeveloperHubSDKDesktop

@Suite("DesktopAppDescriptor")
struct DesktopAppDescriptorTests {

    private func makeDescriptor(
        icon: DesktopAppIcon,
        integration: DesktopAppIntegrationBinding?
    ) -> DesktopAppDescriptor {
        DesktopAppDescriptor(
            identifier: "com.example.test",
            displayName: "Test",
            version: "1.0",
            summary: "A test app",
            icon: icon,
            attribution: DesktopAppAttribution(
                author: "Author",
                copyright: "(c) Author",
                url: URL(string: "https://example.com")
            ),
            integration: integration,
            defaultWindowSize: CGSize(width: 400, height: 300),
            minimumWindowSize: CGSize(width: 200, height: 150)
        )
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    @Test func test_descriptor_roundTripsThroughJSON_withSymbolIcon_andBinding() throws {
        let descriptor = makeDescriptor(
            icon: .symbol(name: "hand.wave.fill", tint: "#F28C28"),
            integration: DesktopAppIntegrationBinding(serviceType: "messages", provider: "gmail")
        )
        #expect(try roundTrip(descriptor) == descriptor)
    }

    @Test func test_descriptor_roundTripsThroughJSON_withResourceIcon_andNoBinding() throws {
        let descriptor = makeDescriptor(icon: .resource(name: "AppIcon"), integration: nil)
        let decoded = try roundTrip(descriptor)
        #expect(decoded == descriptor)
        #expect(decoded.integration == nil)
    }

    @Test func test_descriptor_schemaVersion_isCurrent() {
        let descriptor = makeDescriptor(icon: .resource(name: "x"), integration: nil)
        #expect(descriptor.schemaVersion == DesktopAppDescriptor.currentSchemaVersion)
        #expect(descriptor.settingsSchema == .empty)
    }

    @Test func test_schema_duplicateKeys_reportsRepeatedKey() {
        let schema = DesktopAppSettingsSchema(fields: [
            .init(key: "a", label: "A", help: nil, kind: .toggle(default: true)),
            .init(key: "a", label: "A again", help: nil, kind: .toggle(default: false)),
            .init(key: "b", label: "B", help: nil, kind: .toggle(default: false))
        ])
        #expect(schema.duplicateKeys == ["a"])
        #expect(DesktopAppSettingsSchema.empty.duplicateKeys.isEmpty)
    }

    @Test func test_schema_allKinds_roundTrip() throws {
        let schema = DesktopAppSettingsSchema(fields: [
            .init(key: "t", label: "Toggle", help: "h", kind: .toggle(default: true)),
            .init(key: "x", label: "Text", help: nil, kind: .text(default: "d", placeholder: "p")),
            .init(key: "i", label: "Int", help: nil, kind: .integer(default: 5, range: 1...10)),
            .init(key: "c", label: "Choice", help: nil, kind: .choice(
                default: "one",
                options: [
                    .init(id: "one", label: "One"),
                    .init(id: "two", label: "Two")
                ]
            ))
        ])
        #expect(try roundTrip(schema) == schema)
    }
}
