//
//  FeatherStorageS3TestSuite.swift
//  feather-storage-s3
//
//  Created by Tibor Bödecs on 2023. 01. 16.

import FeatherGeneratedS3
import FeatherStorage
import NIOCore
import SotoCore
import Testing

@testable import FeatherStorageS3

@Suite
struct FeatherStorageS3TestSuite {

    private func runUsingTestStorageClient(
        _ closure: @escaping (@Sendable (StorageClient) async throws -> Void)
    ) async throws {
        var logger = Logger(label: "test")
        logger.logLevel = .info

        let awsClient = AWSClient(
            credentialProvider: .static(
                accessKeyId: "cHXky6PdP5WGhrC5MMyd",
                secretAccessKey: "7diqcEnfBESz9MurK4HiNd4WgVydhj6AIZw1Hj9Q"
            ),
        )
        let region = "us-east-1"

        let s3 = S3(
            client: awsClient,
            region: .init(rawValue: region),
            endpoint: "http://localhost:9000"
        )

        let storageClient = StorageClientS3(
            s3: s3,
            bucket: "miniobucket"
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await awsClient.run()
            }
            group.addTask {
                try await closure(storageClient)
            }
            try await group.next()
            group.cancelAll()
        }
    }

    @Test
    func uploadDownloadWhenConfigured() async throws {
        try await runUsingTestStorageClient { storage in
            let key = "test.txt"
            let contents = "s3 test file contents"
            var payload = ByteBufferAllocator()
                .buffer(capacity: contents.utf8.count)
            payload.writeString(contents)

            let sequence = ByteBufferSequence(buffer: payload)

            do {
                try await storage.upload(
                    key: key,
                    sequence: .init(
                        asyncSequence: sequence,
                        length: UInt64(payload.readableBytes)
                    )
                )

                let downloaded = try await storage.download(
                    key: key,
                    range: nil
                )

                let buffer = try await downloaded.collect(upTo: .max)
                let value = buffer.getString(
                    at: 0,
                    length: buffer.readableBytes
                )
                #expect(value == contents)

            }
            catch {
                Issue.record(error)
            }
        }
    }
}
