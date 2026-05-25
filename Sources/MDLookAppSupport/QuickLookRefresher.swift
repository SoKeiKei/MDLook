import Foundation

public struct QuickLookCommand: Equatable, Sendable {
    public let executable: String
    public let arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }
}

public struct CommandResult: Equatable, Sendable {
    public let output: String
    public let terminationStatus: Int32

    public init(output: String, terminationStatus: Int32) {
        self.output = output
        self.terminationStatus = terminationStatus
    }
}

public enum CommandExecutionError: Error, Equatable {
    case launchFailed(QuickLookCommand, String)
    case nonZeroExit(QuickLookCommand, Int32, String)
}

public struct QuickLookRefresher {
    public typealias Executor = (QuickLookCommand) throws -> CommandResult

    public static let refreshCommands = [
        QuickLookCommand(executable: "/usr/bin/qlmanage", arguments: ["-r"]),
        QuickLookCommand(executable: "/usr/bin/qlmanage", arguments: ["-r", "cache"]),
        QuickLookCommand(executable: "/usr/bin/killall", arguments: ["Finder"])
    ]

    private let execute: Executor

    public init(execute: @escaping Executor = ProcessCommandExecutor.run) {
        self.execute = execute
    }

    public func refresh() throws {
        for command in Self.refreshCommands {
            let result = try execute(command)
            guard result.terminationStatus == 0 else {
                throw CommandExecutionError.nonZeroExit(command, result.terminationStatus, result.output)
            }
        }
    }
}

public enum ProcessCommandExecutor {
    public static func run(_ command: QuickLookCommand) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            throw CommandExecutionError.launchFailed(command, error.localizedDescription)
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? "no utf8 output"
        return CommandResult(output: output, terminationStatus: process.terminationStatus)
    }
}
