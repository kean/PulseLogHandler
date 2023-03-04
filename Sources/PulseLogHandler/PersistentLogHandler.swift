// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import Logging

public typealias NetworkLogger = Pulse.NetworkLogger
public typealias LoggerStore = Pulse.LoggerStore
public typealias URLSessionProxyDelegate = Pulse.URLSessionProxyDelegate

/// Allows ``LoggerStore`` to be used with with [SwiftLog](https://github.com/apple/swift-log).
///
/// ```swift
/// import PulseLogHandler
/// import Logging
///
/// LoggingSystem.bootstrap(PersistentLogHandler.init)
/// ```
///
/// If used this way, you never need to interact with the store directly. To log
/// messages, you'll interact only with the SwiftLog APIs.
///
/// ```swift
/// let logger = Logger(label: "com.yourcompany.yourapp")
/// logger.info("This message will be stored persistently")
/// ```
public struct PersistentLogHandler {
    public var metadata = Logger.Metadata()
    public var logLevel = Logger.Level.info

    private let store: LoggerStore
    private let label: String
    private let metadataProvider: Logger.MetadataProvider?

    public init(label: String) {
        self.init(label: label, store: .shared)
    }

    public init(label: String, store: LoggerStore) {
        self.init(label: label, metadataProvider: nil, store: store)
    }
    
    public init(label: String, metadataProvider: Logger.MetadataProvider?) {
        self.init(label: label, metadataProvider: nil, store: .shared)
    }
    
    public init(label: String, metadataProvider: Logger.MetadataProvider?, store: LoggerStore) {
        self.label = label
        self.metadataProvider = metadataProvider
        self.store = store
    }
}

extension PersistentLogHandler: LogHandler {
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        } set(newValue) {
            metadata[key] = newValue
        }
    }

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        store.storeMessage(
            label: label,
            level: .init(level),
            message: message.description,
            metadata: .init(mergedMetadata(with: metadata)),
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Merges metadata from a log entry metadata with the following priority order:
    ///
    /// * The metadata explicitly set on this log handler.
    /// * The metadata returned from the metadata provider.
    /// * The individual log entry metadata.
    ///
    private func mergedMetadata(with metadata: Logger.Metadata?) -> Logger.Metadata {
        var mergedMetadata = self.metadata
        if let metadataProvider {
            for (key, value) in metadataProvider.get() {
                mergedMetadata[key] = value // Override keys if necessary
            }
        }
        if let metadata {
            for (key, value) in metadata {
                mergedMetadata[key] = value // Override keys if necessary
            }
        }
        return mergedMetadata
    }
}

// MARK: - Private (Logger.Level <-> LoggerStore.Level)

private extension LoggerStore.Level {
    init(_ level: Logger.Level) {
        switch level {
        case .trace: self = .trace
        case .debug: self = .debug
        case .info: self = .info
        case .notice: self = .notice
        case .warning: self = .warning
        case .error: self = .error
        case .critical: self = .critical
        }
    }
}

// MARK: - Private (Logger.Metadata <-> LoggerStore.Metadata)

private extension LoggerStore.Metadata {
    init(_ metadata: Logger.Metadata) {
        self = metadata.compactMapValues(LoggerStore.MetadataValue.init)
    }
}

private extension LoggerStore.MetadataValue {
    init?(_ value: Logger.MetadataValue) {
        switch value {
        case .string(let value): self = .string(value)
        case .stringConvertible(let value): self = .stringConvertible(value)
        case .dictionary: return nil // Unsupported
        case .array: return nil // Unsupported
        }
    }
}
