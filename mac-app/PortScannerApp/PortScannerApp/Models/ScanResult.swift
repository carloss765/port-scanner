import Foundation

// MARK: - Scan State
enum ScanState: Equatable {
    case idle
    case scanning
    case finished
    case error(String)
}

// MARK: - Scan Result
struct ScanResult: Codable, Identifiable {
    let id = UUID()
    let host: String
    let start_port: Int
    let end_port: Int
    let open_ports: [Int]
    let scan_time_ms: Int64

    enum CodingKeys: String, CodingKey {
        case host
        case start_port
        case end_port
        case open_ports
        case scan_time_ms
    }
}

// MARK: - Port Entry (for Table display)
struct PortEntry: Identifiable {
    let id: Int       // the port number itself
    let port: Int
    let service: String
    let isWellKnown: Bool

    init(port: Int) {
        self.id = port
        self.port = port
        self.service = PortEntry.serviceName(for: port)
        self.isWellKnown = PortEntry.knownPorts.keys.contains(port)
    }

    static let knownPorts: [Int: String] = [
        21:    "FTP",
        22:    "SSH",
        23:    "Telnet",
        25:    "SMTP",
        53:    "DNS",
        80:    "HTTP",
        110:   "POP3",
        143:   "IMAP",
        443:   "HTTPS",
        465:   "SMTPS",
        587:   "SMTP (TLS)",
        993:   "IMAPS",
        995:   "POP3S",
        1433:  "MSSQL",
        3306:  "MySQL",
        3389:  "RDP",
        5432:  "PostgreSQL",
        5900:  "VNC",
        6379:  "Redis",
        8080:  "HTTP-Alt",
        8443:  "HTTPS-Alt",
        27017: "MongoDB",
    ]

    static func serviceName(for port: Int) -> String {
        knownPorts[port] ?? "Unknown"
    }
}
