# Feather Storage S3

S3 compatible driver implementation for the abstract [Feather Storage](https://github.com/feather-framework/feather-storage) Swift API package.

[![Release: 1.0.0-beta.2](https://img.shields.io/badge/Release-1%2E0%2E0--beta%2E2-F05138)](
https://github.com/feather-framework/feather-storage-s3/releases/tag/1.0.0-beta.2)

## Features

- S3 compatible driver for Feather Storage
- Designed for modern Swift concurrency
- DocC-based API Documentation
- Unit tests and code coverage

## Requirements

![Swift 6.1+](https://img.shields.io/badge/Swift-6%2E1%2B-F05138)
![Platforms: Linux, macOS, iOS, tvOS, watchOS, visionOS](https://img.shields.io/badge/Platforms-Linux_%7C_macOS_%7C_iOS_%7C_tvOS_%7C_watchOS_%7C_visionOS-F05138)

- Swift 6.1+
- Platforms:
  - Linux
  - macOS 15+
  - iOS 18+
  - tvOS 18+
  - watchOS 11+
  - visionOS 2+

## Installation

Add the dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/feather-framework/feather-storage-s3", exact: "1.0.0-beta.2"),
```

Then add `FeatherStorageS3` to your target dependencies:

```swift
.product(name: "FeatherStorageS3", package: "feather-storage-s3"),
```

## Usage

API documentation is available at the link below:

[![DocC API documentation](https://img.shields.io/badge/DocC-API_documentation-F05138)](https://feather-framework.github.io/feather-storage-s3/)

Here is a brief example:

```swift
import NIOCore
import FeatherStorage
import FeatherStorageS3



let text = "Hello, World"
var buffer = ByteBufferAllocator().buffer(capacity: text.utf8.count)
buffer.writeString(text)
    
try await storage.upload(
    key: "docs/hello.txt",
    sequence: StorageSequence(
        asyncSequence: ByteBufferSequence(buffer: buffer),
        length: UInt64(buffer.readableBytes)
    )
)

try await storage.exists(key: "docs/hello.txt")
try await storage.size(key: "docs/hello.txt")

let result = try await storage.download(key: "docs/hello.txt", range: nil)
let buffer = try await result.collect(upTo: .max)
let value = buffer.getString(at: 0, length: buffer.readableBytes)
print(value)
```

> [!WARNING]  
> This repository is a work in progress, things can break until it reaches v1.0.0.

## Other storage drivers

The following storage client implementations are also available for use:

- [FS](https://github.com/feather-framework/feather-storage-fs)
- [Ephemeral](https://github.com/feather-framework/feather-storage-ephemeral)

## Development

- Build: `swift build`
- Test:
  - local: `swift test`
  - using Docker: `make docker-test`
- Format: `make format`
- Check: `make check`

## Contributing

[Pull requests](https://github.com/feather-framework/feather-storage-s3/pulls) are welcome. Please keep changes focused and include tests for new logic.
