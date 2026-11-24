import Foundation
import Testing
import AgenticDeveloperHubSDKCore

@Suite("PersonInitials")
struct PersonInitialsTests {
    @Test("the first letters of the name's first two words, uppercased")
    func twoWords() {
        #expect(PersonInitials.of(name: "ada lovelace byron", fallback: "a@b.c") == "AL")
        #expect(PersonInitials.of(name: "Ada", fallback: "a@b.c") == "A")
    }

    @Test("a blank name falls back to the fallback's first letter, then ?")
    func fallbacks() {
        #expect(PersonInitials.of(name: "   ", fallback: "zed@b.c") == "Z")
        #expect(PersonInitials.of(name: "", fallback: "") == "?")
    }

    @Test("AccountUser's initials are PersonInitials with the email as the fallback")
    func accountUser() {
        #expect(AccountUser(id: "1", name: "ada lovelace", email: "a@b.c", avatarURL: nil).initials == "AL")
        #expect(AccountUser(id: "1", name: " ", email: "zed@b.c", avatarURL: nil).initials == "Z")
        #expect(AccountUser(id: "1", name: "", email: "", avatarURL: nil).initials == "?")
    }
}

@Suite("AvatarContent")
struct AvatarContentTests {
    @Test("initials follow PersonInitials with the seed as the fallback")
    func initials() {
        #expect(AvatarContent(name: "ada lovelace byron", seed: "a@b.c", imageURL: nil).initials == "AL")
        #expect(AvatarContent(name: "   ", seed: "zed@b.c", imageURL: nil).initials == "Z")
        #expect(AvatarContent(name: "", seed: "", imageURL: nil).initials == "?")
    }

    @Test("an account user's avatar is seeded by the email and tries the avatar URL")
    func fromAccountUser() {
        let url = URL(string: "https://example.com/a.png")
        let user = AccountUser(id: "1", name: "Ada Lovelace", email: "ada@x.y", avatarURL: url)
        #expect(AvatarContent(user: user) == AvatarContent(name: "Ada Lovelace", seed: "ada@x.y", imageURL: url))
    }
}
