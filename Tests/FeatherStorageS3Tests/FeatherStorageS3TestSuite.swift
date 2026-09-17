//
//  FeatherStorageS3TestSuite.swift
//  feather-storage-s3
//
//  Created by Tibor Bödecs on 2023. 01. 16.

import FeatherStorage
import Foundation
import Logging
import NIOCore
import SotoCore
import Testing

@testable import FeatherStorageS3

private let testEndpoint = ProcessInfo.processInfo.environment[
    "FEATHER_STORAGE_S3_TEST_ENDPOINT"
]

@Suite
struct FeatherStorageS3TestSuite {

    private func runUsingTestStorageClient(
        _ closure: @escaping (@Sendable (StorageClient) async throws -> Void)
    ) async throws {
        guard let testEndpoint else {
            return
        }
        try await withLogger(Logger(label: "feather.storage.s3")) { _ in
            let awsClient = AWSClient(
                credentialProvider: .static(
                    accessKeyId: "cHXky6PdP5WGhrC5MMyd",
                    secretAccessKey: "7diqcEnfBESz9MurK4HiNd4WgVydhj6AIZw1Hj9Q"
                ),
                logger: Logger.current
            )
            let region = "us-east-1"

            let storageClient = StorageClientS3(
                awsClient: awsClient,
                region: region,
                endpoint: testEndpoint,
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
    }

    @Test(
        .enabled(
            if: testEndpoint != nil,
            "Set FEATHER_STORAGE_S3_TEST_ENDPOINT to run the MinIO integration test."
        )
    )
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
