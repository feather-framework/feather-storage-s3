import Foundation
import FeatherStorage
import NIOCore
import SotoCore
import Testing

@testable import FeatherStorageS3

@Suite
struct FeatherStorageS3TestSuite {

    @Test
    func uploadDownloadWhenConfigured() async throws {
        let env = ProcessInfo.processInfo.environment

        guard
            let accessKeyId = env["S3_ID"],
            let secretAccessKey = env["S3_SECRET"],
            let region = env["S3_REGION"],
            let bucket = env["S3_BUCKET"]
        else {
            return
        }

        let awsClient = AWSClient(
            credentialProvider: .static(
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey
            )
        )
        defer {
            Task {
                try? await awsClient.shutdown()
            }
        }

        let storage = StorageClientS3(
            client: awsClient,
            region: .init(rawValue: region),
            bucket: bucket
        )

        let key = "codex-tests/\(UUID().uuidString).txt"
        var payload = ByteBufferAllocator().buffer(capacity: 0)
        payload.writeString("s3-test")

        try await storage.upload(key: key, buffer: payload)
        let downloaded = try await storage.download(key: key)

        #expect(downloaded.getString(at: downloaded.readerIndex, length: downloaded.readableBytes) == "s3-test")

        try await storage.delete(key: key)
    }
}
