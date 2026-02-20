import Combine
import Foundation
import SwiftUI

@MainActor
class ScanViewModel: ObservableObject {

    // MARK: - Inputs
    @Published var host: String = "127.0.0.1"
    @Published var startPort: String = "1"
    @Published var endPort: String = "1024"
    @Published var verbose: Bool = false

    // MARK: - Outputs
    @Published var logs: String = ""
    @Published var openPorts: [PortEntry] = []
    @Published var scanResult: ScanResult? = nil
    @Published var state: ScanState = .idle

    // MARK: - Private
    private var process: Process?

    // MARK: - Binary Resolution
    private func binaryPath() -> String? {
        // 1. Check app bundle resources (for production / distribution)
        if let bundled = Bundle.main.path(forResource: "port-scanner", ofType: nil) {
            return bundled
        }

        // 2. Development: walk up from source file to repo root
        //    #file = .../mac-app/PortScannerApp/PortScannerApp/ViewModels/ScanViewModel.swift
        //    delete: ScanViewModel.swift → ViewModels → PortScannerApp(src) → PortScannerApp(proj) → mac-app → repoRoot
        let dev = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()  // remove ScanViewModel.swift → …/ViewModels
            .deletingLastPathComponent()  // remove ViewModels           → …/PortScannerApp (source)
            .deletingLastPathComponent()  // remove PortScannerApp (src) → …/PortScannerApp (project)
            .deletingLastPathComponent()  // remove PortScannerApp (proj)→ …/mac-app
            .deletingLastPathComponent()  // remove mac-app              → repo root
            .appendingPathComponent("backend/port-scanner")

        if FileManager.default.fileExists(atPath: dev.path) {
            return dev.path
        }

        // 3. Absolute fallback for this machine's dev layout
        let absolute = "/Users/carlosz/Devs/port-scanner/backend/port-scanner"
        if FileManager.default.fileExists(atPath: absolute) {
            return absolute
        }

        return nil
    }

    // MARK: - Scan Actions
    func startScan() {
        guard state != .scanning else { return }

        guard let start = Int(startPort), let end = Int(endPort),
              start >= 1, end <= 65535, start <= end else {
            logs = "[ERROR] Invalid port range. Use 1–65535 with start ≤ end.\n"
            state = .error("Invalid port range")
            return
        }

        guard let binaryPath = binaryPath() else {
            logs = "[ERROR] Could not locate port-scanner binary.\n" +
                   "Build it first:\n  cd backend && go build -o port-scanner .\n"
            state = .error("Binary not found")
            return
        }

        // Reset state
        logs = ""
        openPorts = []
        scanResult = nil
        state = .scanning

        logs += "[INFO]   Binary path: \(binaryPath)\n"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binaryPath)
        proc.arguments = [
            "-host",    host,
            "-start",   "\(start)",
            "-end",     "\(end)",
            "-verbose", verbose ? "true" : "false"
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        proc.standardOutput = stdoutPipe
        proc.standardError  = stderrPipe

        // Real-time stderr streaming
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.logs += line
            }
        }

        proc.terminationHandler = { [weak self] terminatedProcess in
            // Read stdout for JSON
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            stderrPipe.fileHandleForReading.readabilityHandler = nil

            Task { @MainActor [weak self] in
                guard let self else { return }
                if terminatedProcess.terminationReason == .exit,
                   terminatedProcess.terminationStatus == 0 {
                    do {
                        let result = try JSONDecoder().decode(ScanResult.self, from: stdoutData)
                        self.scanResult = result
                        self.openPorts = result.open_ports.map { PortEntry(port: $0) }
                        self.state = .finished
                    } catch {
                        self.logs += "[ERROR] Failed to decode JSON: \(error.localizedDescription)\n"
                        self.state = .error("JSON decode failed")
                    }
                } else if terminatedProcess.terminationReason == .uncaughtSignal {
                    self.logs += "[INFO]  Scan cancelled.\n"
                    self.state = .idle
                } else {
                    self.logs += "[ERROR] Process exited with code \(terminatedProcess.terminationStatus)\n"
                    self.state = .error("Process error (\(terminatedProcess.terminationStatus))")
                }
            }
        }

        do {
            try proc.run()
            process = proc
        } catch {
            logs = "[ERROR] Failed to start process: \(error.localizedDescription)\n"
            state = .error("Launch failed")
        }
    }

    func cancelScan() {
        process?.terminate()
        process = nil
    }
}
