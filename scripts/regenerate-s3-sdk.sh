#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_directory="$(cd "${script_directory}/.." && pwd)"
generator_directory="${SOTO_CODEGENERATOR_DIRECTORY:-${package_directory}/../soto-codegenerator}"
source_directory="${package_directory}/Sources/FeatherSotoS3"

if [[ ! -f "${generator_directory}/Package.swift" ]]; then
    echo "Soto code generator package not found: ${generator_directory}" >&2
    echo "Set SOTO_CODEGENERATOR_DIRECTORY to a local soto-codegenerator checkout." >&2
    exit 1
fi

swift run \
    --package-path "${generator_directory}" \
    SotoCodeGenerator \
    --input-file "${source_directory}/s3-2006-03-01.json" \
    --config "${source_directory}/soto.config.json" \
    --prefix s3_2006_03_01 \
    --output-folder "${source_directory}"

# The generated API exposes Foundation types such as Date. Keep those imports
# public because this package enables InternalImportsByDefault for all targets.
for generated_file in "${source_directory}"/s3_2006_03_01_*.swift; do
    perl -pi -e 's/^import FoundationEssentials$/public import FoundationEssentials/; s/^import Foundation$/public import Foundation/; s/from decoder: Decoder/from decoder: any Decoder/g; s/to encoder: Encoder/to encoder: any Encoder/g; s/AWSErrorShape\.Type/any AWSErrorShape.Type/g' "${generated_file}"
done
