import json
import threading
from concurrent import futures
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

import grpc

import wallet_pb2
import wallet_pb2_grpc


# ---------------------------------------------------------------------------
# Shared fake data — both endpoints return exactly the same content,
# so the comparison is about encoding, not about different payloads.
# ---------------------------------------------------------------------------

def make_transactions(count):
    return [
        {
            "id": f"txn_{i:08d}",
            "amount_minor": 1000 + i,
            "currency": "KZT",
            "description": f"Payment to merchant number {i}",
            "timestamp": 1754000000 + i,
            "counterparty": f"Merchant Company Number {i} LLP",
        }
        for i in range(count)
    ]


# ---------------------------------------------------------------------------
# gRPC side
# ---------------------------------------------------------------------------

class WalletServiceServicer(wallet_pb2_grpc.WalletServiceServicer):
    def GetBalance(self, request, context):
        print(f"[gRPC] GetBalance for account_id={request.account_id!r}")
        return wallet_pb2.GetBalanceResponse(
            balance_minor=150050,
            currency="KZT",
        )

    def GetTransactions(self, request, context):
        rows = make_transactions(request.count)

        response = wallet_pb2.GetTransactionsResponse(
            transactions=[wallet_pb2.Transaction(**row) for row in rows]
        )

        size = len(response.SerializeToString())
        print(f"[gRPC] GetTransactions count={request.count} -> {size} bytes on the wire")

        return response


def serve_grpc():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
    wallet_pb2_grpc.add_WalletServiceServicer_to_server(
        WalletServiceServicer(), server
    )
    server.add_insecure_port("[::]:50051")
    server.start()
    print("gRPC server listening on port 50051")
    server.wait_for_termination()


# ---------------------------------------------------------------------------
# JSON / HTTP side — same data, classic REST style
# ---------------------------------------------------------------------------

class JSONHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        count = int(params.get("count", ["100"])[0])

        payload = json.dumps({"transactions": make_transactions(count)}).encode()

        print(f"[JSON] GetTransactions count={count} -> {len(payload)} bytes on the wire")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        pass  # silence the default per-request logging


def serve_json():
    server = HTTPServer(("", 50052), JSONHandler)
    print("JSON server listening on port 50052")
    server.serve_forever()


if __name__ == "__main__":
    threading.Thread(target=serve_json, daemon=True).start()
    serve_grpc()
