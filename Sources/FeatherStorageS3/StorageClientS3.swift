//
//  StorageClientS3.swift
//  feather-storage-s3
//
//  Created by Tibor Bödecs on 2023. 01. 16.

import FeatherGeneratedS3
import FeatherStorage
import Logging
import NIOCore
import SotoCore

/// S3-compatible storage driver.
public struct StorageClientS3: StorageClient {

    /// Configured Soto S3 client used to perform requests.
    public let s3: S3
    /// Target bucket name for all storage operations.
    public let bucket: String
    /// Optional request timeout applied by higher-level integrations.
    public let timeout: TimeAmount?

    /// Logger used for all S3 requests.
    public let logger: Logger

    /// Creates a storage client backed by an S3-compatible bucket.
    ///
    /// - Parameters:
    ///   - s3: Configured Soto S3 client.
    ///   - bucket: Bucket name used for object operations.
    ///   - timeout: Optional request timeout configuration.
    ///   - logger: Logger used for request logging.
    public init(
        s3: S3,
        bucket: String,
        timeout: TimeAmount? = nil,
        logger: Logger = .init(label: "feather.storage.s3")
    ) {
        self.s3 = s3
        self.bucket = bucket
        self.timeout = timeout
        self.logger = logger
    }

    /// Uploads a full object from a storage sequence.
    ///
    /// - Parameters:
    ///   - key: Object key to write.
    ///   - sequence: Sequence of bytes to upload.
    /// - Throws: `StorageClientError` when the upload fails.
    public func upload(
        key: String,
        sequence: StorageSequence
    ) async throws(StorageClientError) {
        do {
            _ = try await s3.putObject(
                .init(
                    body: .init(
                        asyncSequence: sequence,
                        length: sequence.length.map(Int.init)
                    ),
                    bucket: bucket,
                    key: key
                ),
                logger: logger
            )
        }
        catch {
            throw mapError(error)
        }
    }

    /// Downloads an object, optionally constrained to a byte range.
    ///
    /// - Parameters:
    ///   - key: Object key to read.
    ///   - range: Inclusive byte range to request.
    /// - Returns: A storage sequence streaming the object body.
    /// - Throws: `StorageClientError` when the download fails.
    public func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws(StorageClientError) -> StorageSequence {
        do {
            let byteRange = range.map {
                "bytes=\($0.lowerBound)-\($0.upperBound)"
            }
            let response = try await s3.getObject(
                .init(bucket: bucket, key: key, range: byteRange),
                logger: logger
            )
            return .init(
                asyncSequence: response.body,
                length: response.contentLength.map(UInt64.init)
            )
        }
        catch {
            throw mapError(error)
        }
    }

    /// Checks whether an object exists at the given key.
    ///
    /// - Parameter key: Object key to check.
    /// - Returns: `true` when the object exists.
    /// - Throws: `StorageClientError` when the request fails.
    public func exists(
        key: String
    ) async throws(StorageClientError) -> Bool {
        do {
            _ = try await s3.headObject(
                .init(bucket: bucket, key: key),
                logger: logger
            )
            return true
        }
        catch let error as StorageClientError {
            throw error
        }
        catch {
            throw .unknown(error)
        }
    }

    /// Retrieves the object size for a key.
    ///
    /// - Parameter key: Object key to inspect.
    /// - Returns: Size in bytes.
    /// - Throws: `StorageClientError` when the request fails.
    public func size(
        key: String
    ) async throws(StorageClientError) -> UInt64 {
        do {
            let response = try await s3.headObject(
                .init(bucket: bucket, key: key),
                logger: logger
            )
            return UInt64(response.contentLength ?? 0)
        }
        catch let error as StorageClientError {
            throw error
        }
        catch {
            throw .unknown(error)
        }
    }

    /// Copies an object to another key in the same bucket.
    ///
    /// - Parameters:
    ///   - source: Source object key.
    ///   - destination: Destination object key.
    /// - Throws: `StorageClientError` when the copy fails.
    public func copy(
        key source: String,
        to destination: String
    ) async throws(StorageClientError) {
        do {
            _ = try await s3.copyObject(
                .init(
                    bucket: bucket,
                    copySource: "\(bucket)/\(source)",
                    key: destination
                ),
                logger: logger
            )
        }
        catch {
            throw mapError(error)
        }
    }

    /// Lists immediate child names for a prefix.
    ///
    /// - Parameter key: Optional prefix to list from.
    /// - Returns: Sorted unique child key components.
    /// - Throws: `StorageClientError` when listing fails.
    public func list(
        key: String?
    ) async throws(StorageClientError) -> [String] {
        do {
            let prefix = key
            let response = try await s3.listObjectsV2(
                .init(
                    bucket: bucket,
                    prefix: prefix
                ),
                logger: logger
            )

            let keys = (response.contents ?? []).compactMap(\.key)
            let dropCount = prefix?.split(separator: "/").count ?? 0
            return
                keys.compactMap { fullKey in
                    fullKey.split(separator: "/")
                        .dropFirst(dropCount)
                        .first
                        .map(String.init)
                }
                .uniqued()
                .sorted()
        }
        catch {
            throw mapError(error)
        }
    }

    /// Deletes an object by key.
    ///
    /// - Parameter key: Object key to remove.
    /// - Throws: `StorageClientError` when deletion fails.
    public func delete(
        key: String
    ) async throws(StorageClientError) {
        do {
            _ = try await s3.deleteObject(
                .init(bucket: bucket, key: key),
                logger: logger
            )
        }
        catch {
            throw mapError(error)
        }
    }

    /// Creates a directory marker object for the provided key.
    ///
    /// - Parameter key: Prefix key to create.
    /// - Throws: `StorageClientError` when creation fails.
    public func create(
        key: String
    ) async throws(StorageClientError) {
        do {
            let safeKey = key.hasSuffix("/") ? key : key + "/"
            _ = try await s3.putObject(
                .init(bucket: bucket, contentLength: 0, key: safeKey),
                logger: logger
            )
        }
        catch {
            throw mapError(error)
        }
    }

    /// Starts a multipart upload session.
    ///
    /// - Parameter key: Object key for the multipart upload.
    /// - Returns: Multipart upload identifier.
    /// - Throws: `StorageClientError` when initialization fails.
    public func createMultipartId(
        key: String
    ) async throws(StorageClientError) -> String {
        do {
            let response = try await s3.createMultipartUpload(
                .init(bucket: bucket, key: key),
                logger: logger
            )
            guard let uploadId = response.uploadId else {
                throw StorageClientError.invalidMultipartId
            }
            return uploadId
        }
        catch {
            throw mapError(error)
        }
    }

    /// Uploads a multipart chunk.
    ///
    /// - Parameters:
    ///   - multipartId: Multipart upload identifier.
    ///   - key: Object key being uploaded.
    ///   - number: Part number for the chunk.
    ///   - sequence: Byte sequence for the chunk payload.
    /// - Returns: Uploaded multipart chunk metadata.
    /// - Throws: `StorageClientError` when upload fails.
    public func upload(
        multipartId: String,
        key: String,
        number: Int,
        sequence: StorageSequence
    ) async throws(StorageClientError) -> StorageMultipartChunk {
        do {
            let response = try await s3.uploadPart(
                .init(
                    body: .init(
                        asyncSequence: sequence,
                        length: sequence.length.map(Int.init)
                    ),
                    bucket: bucket,
                    key: key,
                    partNumber: number,
                    uploadId: multipartId
                ),
                logger: logger
            )
            guard let etag = response.eTag else {
                throw StorageClientError.invalidMultipartChunk
            }
            return .init(id: etag, number: number)
        }
        catch {
            throw mapError(error)
        }
    }

    /// Aborts an active multipart upload.
    ///
    /// - Parameters:
    ///   - multipartId: Multipart upload identifier.
    ///   - key: Object key associated with the upload.
    /// - Throws: `StorageClientError` when abort fails.
    public func abort(
        multipartId: String,
        key: String
    ) async throws(StorageClientError) {
        do {
            _ = try await s3.abortMultipartUpload(
                .init(
                    bucket: bucket,
                    key: key,
                    uploadId: multipartId
                ),
                logger: logger
            )
        }
        catch {
            throw mapError(error)
        }
    }

    /// Completes a multipart upload with the provided chunks.
    ///
    /// - Parameters:
    ///   - multipartId: Multipart upload identifier.
    ///   - key: Object key being finalized.
    ///   - chunks: Uploaded chunk metadata to assemble.
    /// - Throws: `StorageClientError` when completion fails.
    public func finish(
        multipartId: String,
        key: String,
        chunks: [StorageMultipartChunk]
    ) async throws(StorageClientError) {
        do {
            let parts: [S3.CompletedPart] =
                chunks
                .sorted(by: { $0.number < $1.number })
                .map {
                    .init(
                        eTag: $0.id,
                        partNumber: $0.number
                    )
                }

            _ = try await s3.completeMultipartUpload(
                .init(
                    bucket: bucket,
                    key: key,
                    multipartUpload: .init(parts: parts),
                    uploadId: multipartId
                ),
                logger: logger
            )
        }
        catch {
            throw mapError(error)
        }
    }
}

extension StorageClientS3 {

    private func mapError(_ error: Error) -> StorageClientError {
        if let storageError = error as? StorageClientError {
            return storageError
        }

        if let s3Error = error as? S3ErrorType {
            switch s3Error {
            case .noSuchKey, .notFound:
                return .invalidKey
            default:
                return .unknown(s3Error)
            }
        }

        return .unknown(error)
    }
}

extension Array where Element: Hashable {
    fileprivate func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
