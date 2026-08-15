
#!/bin/bash
set -e

cd "$(dirname "$0")"

OUT="WalletKit/Sources/WalletContracts/Generated"

protoc \
  --proto_path=Proto \
  --swift_out="$OUT" \
  --grpc-swift-2_out="$OUT" \
  --swift_opt=Visibility=Public \
  --grpc-swift-2_opt=Visibility=Public \
  Proto/wallet.proto

echo "Generated into $OUT"
