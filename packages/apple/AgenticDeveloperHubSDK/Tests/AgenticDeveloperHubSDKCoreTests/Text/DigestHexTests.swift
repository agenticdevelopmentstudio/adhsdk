import CryptoKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct DigestHexTests {

    @Test func sha256OfAKnownStringIsItsLowercaseHex() {
        #expect(SHA256.hash(data: Data("abc".utf8)).hexString
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test("V2: the empty SHA-256 digest is 64 characters")
    func v2EmptySHA256() {
        let hex = SHA256.hash(data: Data()).hexString
        #expect(hex == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(hex.count == 64)
    }

    @Test("V3: SHA-1 renders as 40 characters")
    func v3SHA1() {
        let hex = Insecure.SHA1.hash(data: Data("abc".utf8)).hexString
        #expect(hex == "a9993e364706816aba3e25717850c26c9cd0d89d")
        #expect(hex.count == 40)
    }

    @Test("V4: MD5 renders as 32 characters")
    func v4MD5() {
        let hex = Insecure.MD5.hash(data: Data("abc".utf8)).hexString
        #expect(hex == "900150983cd24fb0d6963f7d28e17f72")
        #expect(hex.count == 32)
    }

    @Test("V5: SHA-512 renders as 128 lowercase characters")
    func v5SHA512() {
        let hex = SHA512.hash(data: Data("abc".utf8)).hexString
        let expected = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
            + "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
        #expect(hex == expected)
        #expect(hex.count == 128)
        #expect(hex == hex.lowercased())
    }

    @Test("V6: a byte below 0x10 keeps its leading zero")
    func v6LeadingZero() {
        let hex = Insecure.MD5.hash(data: Data("a".utf8)).hexString
        #expect(hex == "0cc175b9c0f1b6a831c399e269772661")
        #expect(hex.count == 32)
    }

    @Test("V7: hexString is pure")
    func v7Pure() {
        let digest = SHA256.hash(data: Data("abc".utf8))
        #expect(digest.hexString == digest.hexString)
    }
}
