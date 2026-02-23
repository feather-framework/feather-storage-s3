//
//  ByteBufferSequence.swift
//  feather-storage-ephemeral
//
//  Created by Tibor Bödecs on 2023. 01. 16.

import NIOCore

/// An async sequence that streams a `ByteBuffer` in fixed-size chunks.
public struct ByteBufferSequence: AsyncSequence, Sendable {
    private let buffer: ByteBuffer
    private let chunkSize: Int

    /// Creates a chunked byte buffer async sequence.
    ///
    /// - Parameters:
    ///   - buffer: The source buffer to stream from.
    ///   - chunkSize: The maximum number of bytes emitted per iteration.
    public init(
        buffer: ByteBuffer,
        chunkSize: Int = 32 * 1024
    ) {
        self.buffer = buffer
        self.chunkSize = chunkSize
    }

    /// The async iterator for `ByteBufferSequence`.
    public struct AsyncIterator: AsyncIteratorProtocol {
        var buffer: ByteBuffer
        let chunkSize: Int

        /// Returns the next chunk from the underlying buffer.
        ///
        /// - Returns: A buffer slice up to `chunkSize` bytes, or `nil` when the stream is exhausted.
        public mutating func next() async -> ByteBuffer? {
            guard buffer.readableBytes > 0 else {
                return nil
            }
            return buffer.readSlice(
                length: Swift.min(chunkSize, buffer.readableBytes)
            )
        }
    }

    /// Creates an async iterator over the byte buffer chunks.
    ///
    /// - Returns: A new async iterator instance.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(
            buffer: buffer,
            chunkSize: chunkSize
        )
    }
}
