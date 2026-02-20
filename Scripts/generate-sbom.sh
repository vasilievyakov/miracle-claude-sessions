#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION=$(cd "$REPO_ROOT" && git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0")
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$REPO_ROOT/sbom.spdx.json" << EOF
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "$DATE",
    "creators": ["Tool: generate-sbom.sh", "Organization: vasilievyakov"],
    "licenseListVersion": "3.21"
  },
  "name": "ClaudeSessions-$VERSION",
  "dataLicense": "CC0-1.0",
  "documentNamespace": "https://github.com/vasilievyakov/ClaudeSessions/sbom-$VERSION",
  "packages": [
    {
      "SPDXID": "SPDXRef-Package",
      "name": "ClaudeSessions",
      "versionInfo": "$VERSION",
      "downloadLocation": "https://github.com/vasilievyakov/ClaudeSessions",
      "filesAnalyzed": true,
      "licenseConcluded": "MIT",
      "licenseDeclared": "MIT",
      "copyrightText": "2026 Yakov Vasiliev",
      "externalRefs": [
        {
          "referenceCategory": "SECURITY",
          "referenceType": "cpe23Type",
          "referenceLocator": "cpe:2.3:a:vasilievyakov:claudesessions:$VERSION:*:*:*:*:macos:*:*"
        }
      ],
      "comment": "Zero external dependencies. Reads only ~/.claude/ directory. No network access."
    }
  ],
  "relationships": [
    {
      "spdxElementId": "SPDXRef-DOCUMENT",
      "relationshipType": "DESCRIBES",
      "relatedSpdxElement": "SPDXRef-Package"
    }
  ]
}
EOF

echo "SBOM generated: sbom.spdx.json (version: $VERSION)"
