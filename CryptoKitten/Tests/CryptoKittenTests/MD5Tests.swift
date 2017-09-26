import XCTest
import CryptoKitten

class MD5Tests: XCTestCase {
    static var allTests = [
        ("testBasic", testBasic),
        ("testPerformance", testPerformance),
        ("testHMAC", testHMAC),
    ]

    func testBasic() throws {
        // Source: https://github.com/bcgit/bc-java/blob/adecd89d33edf278a5c601af2de696f0a6f65251/core/src/test/java/org/bouncycastle/crypto/test/MD5DigestTest.java
        let tests = [
            ("", "d41d8cd98f00b204e9800998ecf8427e"),
            ("a", "0cc175b9c0f1b6a831c399e269772661"),
            ("abc", "900150983cd24fb0d6963f7d28e17f72"),
            ("message digest", "f96b697d7cb7938d525a2f31aaf161d0"),
            ("abcdefghijklmnopqrstuvwxyz", "c3fcd3d76192e4007dfb496cca67e13b"),
            ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", "d174ab98d277d9f5a5611c2c9f419d9f"),
            ("12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57edf4a22be3c955ac49da2e2107b67a"),
        ]
        
        for test in tests {
            let result = MD5.hash([UInt8](test.0.utf8)).hexString.lowercased()
            XCTAssertEqual(result, test.1.lowercased())
        }
    }

    func testPerformance() {
        let data = [UInt8](repeating: 0x63, count: 10_000_000)

        // ~0.121 release
        measure {
            _ = MD5.hash(data)
        }
    }

    func testHMAC() throws {
        let tests: [(key: String, message: String, expected: String)] = [
            (
                "vapor",
                "hello",
                "bbd98ab1dbed72cdf3e924ae7eaf7943"
            ),
            (
                "true",
                "2+2=4",
                "37bda9a2b521d4623883b3acb7d9c3f7"
            )
        ]

        for test in tests {
            let result = HMAC<MD5>.authenticate(
                [UInt8](test.message.utf8),
                withKey: [UInt8](test.key.utf8)
                ).hexString.lowercased()
            XCTAssertEqual(result, test.expected.lowercased())
        }
    }
}
