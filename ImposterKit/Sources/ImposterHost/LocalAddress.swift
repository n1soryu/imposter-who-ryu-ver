import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Finds the address phones can use to reach this device.
public enum LocalAddress {
    public struct Interface: Equatable, Sendable {
        public var name: String
        public var address: String

        public init(name: String, address: String) {
            self.name = name
            self.address = address
        }
    }

    /// Hotspot (`bridge*`) first, then Wi-Fi (`en0`), then any other non-loopback interface.
    public static func choose(from interfaces: [Interface]) -> String? {
        let usable = interfaces.filter { $0.name.hasPrefix("lo") == false && $0.address.hasPrefix("169.254.") == false }
        return usable.first { $0.name.hasPrefix("bridge") }?.address
            ?? usable.first { $0.name == "en0" }?.address
            ?? usable.first?.address
    }

    /// Every up, non-loopback IPv4 interface.
    public static func interfaces() -> [Interface] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }
        var result: [Interface] = []
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            let flags = Int32(entry.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0,
                  let sockaddr = entry.ifa_addr, sockaddr.pointee.sa_family == UInt8(AF_INET)
            else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let status = getnameinfo(sockaddr, socklen_t(sockaddr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            guard status == 0 else { continue }
            result.append(Interface(name: String(validatingCString: entry.ifa_name) ?? "", address: String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)))
        }
        return result
    }

    public static func ipv4() -> String? {
        choose(from: interfaces())
    }

    public static func joinURL(port: UInt16) -> URL? {
        ipv4().flatMap { URL(string: "http://\($0):\(port)/") }
    }
}
