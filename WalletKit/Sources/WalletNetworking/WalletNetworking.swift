import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2TransportServices
import GRPCProtobuf
import WalletContracts

// MARK: - Domain models

// This is what the rest of the app sees. It never sees the generated
// `Wallet_GetBalanceResponse` type — that stays inside this file.
public struct Balance: Sendable {
    public let amountMinor: Int64
    public let currency: String
}

public struct Transaction: Sendable {
    public let id: String
    public let amountMinor: Int64
    public let currency: String
    public let description: String
    public let timestamp: Int64
    public let counterparty: String
}

/// Result of one benchmark run.
public struct BenchmarkResult: Sendable {
    public let label: String
    public let count: Int
    public let seconds: Double
}

// MARK: - Public interface

public protocol WalletServicing: Sendable {
    func getBalance(accountID: String) async throws -> Balance
    func getTransactionsViaGRPC(accountID: String, count: Int) async throws -> (
        [Transaction], BenchmarkResult
    )
    func getTransactionsViaJSON(accountID: String, count: Int) async throws -> (
        [Transaction], BenchmarkResult
    )
}

// MARK: - JSON wire model (used only for decoding, stays private to this file)

private struct JSONTransactionList: Decodable {
    let transactions: [JSONTransaction]
}

private struct JSONTransaction: Decodable {
    let id: String
    let amount_minor: Int64
    let currency: String
    let description: String
    let timestamp: Int64
    let counterparty: String
}

// MARK: - gRPC implementation

public actor GRPCWalletService: WalletServicing {
    private let host: String
    private let port: Int
    private let jsonPort: Int

    /// The long-lived client. Created once, reused for every call.
    private var client: GRPCClient<HTTP2ClientTransport.TransportServices>?

    /// The background task keeping connections alive.
    private var connectionTask: Task<Void, Never>?

    /// One session, reused — same principle as the long-lived gRPC client.
    private let urlSession = URLSession(configuration: .default)

    public init(host: String = "localhost", port: Int = 50051, jsonPort: Int = 50052) {
        self.host = host
        self.port = port
        self.jsonPort = jsonPort
    }

    /// Returns the existing client, or creates and starts one.
    ///
    /// Note: this method is NOT async. There is no `await` between checking
    /// `client` and storing the new one, so the actor runs it as one
    /// uninterrupted step — two concurrent calls can never create two clients.
    private func existingOrNewClient() throws -> GRPCClient<HTTP2ClientTransport.TransportServices> {
        if let client {
            return client
        }

        let transport = try HTTP2ClientTransport.TransportServices(
            target: .dns(host: host, port: port),
            transportSecurity: .plaintext
        )

        let newClient = GRPCClient(transport: transport)
        self.client = newClient

        // `runConnections()` does not return until shutdown, so it has to live
        // in its own task rather than being awaited here.
        connectionTask = Task {
            try? await newClient.runConnections()
        }

        return newClient
    }

    public func getBalance(accountID: String) async throws -> Balance {
        let client = try existingOrNewClient()
        let walletClient = Wallet_WalletService.Client(wrapping: client)

        let response = try await walletClient.getBalance(
            .with { $0.accountID = accountID }
        )

        // Mapping happens right here — generated type in, domain type out.
        return Balance(
            amountMinor: response.balanceMinor,
            currency: response.currency
        )
    }

    // MARK: Benchmark — same data, two encodings

    public func getTransactionsViaGRPC(
        accountID: String,
        count: Int
    ) async throws -> ([Transaction], BenchmarkResult) {
        let client = try existingOrNewClient()
        let walletClient = Wallet_WalletService.Client(wrapping: client)

        let start = ContinuousClock.now

        let response = try await walletClient.getTransactions(
            .with {
                $0.accountID = accountID
                $0.count = Int32(count)
            }
        )

        let transactions = response.transactions.map {
            Transaction(
                id: $0.id,
                amountMinor: $0.amountMinor,
                currency: $0.currency,
                description: $0.description_p,
                timestamp: $0.timestamp,
                counterparty: $0.counterparty
            )
        }

        let elapsed = ContinuousClock.now - start

        return (
            transactions,
            BenchmarkResult(
                label: "gRPC / protobuf",
                count: transactions.count,
                seconds: Double(elapsed.components.seconds)
                    + Double(elapsed.components.attoseconds) / 1e18
            )
        )
    }

    public func getTransactionsViaJSON(
        accountID: String,
        count: Int
    ) async throws -> ([Transaction], BenchmarkResult) {
        let url = URL(string: "http://\(host):\(jsonPort)/transactions?count=\(count)")!

        let start = ContinuousClock.now

        let (data, _) = try await urlSession.data(from: url)
        let decoded = try JSONDecoder().decode(JSONTransactionList.self, from: data)

        let transactions = decoded.transactions.map {
            Transaction(
                id: $0.id,
                amountMinor: $0.amount_minor,
                currency: $0.currency,
                description: $0.description,
                timestamp: $0.timestamp,
                counterparty: $0.counterparty
            )
        }

        let elapsed = ContinuousClock.now - start

        return (
            transactions,
            BenchmarkResult(
                label: "REST / JSON",
                count: transactions.count,
                seconds: Double(elapsed.components.seconds)
                    + Double(elapsed.components.attoseconds) / 1e18
            )
        )
    }

    /// Closes the connection. Call when the app no longer needs the service.
    public func shutdown() {
        client?.beginGracefulShutdown()
        client = nil
        connectionTask = nil
    }
}
