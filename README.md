# gRPC_Wallet_Demo

## Проблема

Небольшой iOS-скелет банковского приложения, чтобы на практике пройти полный сеньорский стек:
свой gRPC-контракт, модульную архитектуру, реальные security-примитивы и локальный CI/CD —
не туториал, а рабочий код.

## Архитектура

- `Proto/wallet.proto` — gRPC-контракт, написан вручную.
- `WalletKit/` — локальный Swift-пакет, пять модулей:
  - `WalletContracts` — код, сгенерированный `protoc` из `wallet.proto` (Swift-типы сообщений + gRPC-клиент).
  - `WalletNetworking` — единственный модуль, которому разрешено импортировать `WalletContracts`. Маппит сгенерированные типы в доменные модели (`Balance`, `Transaction`). Держит `GRPCClient` внутри `actor`, создаётся один раз (single-flight, без `await` между проверкой и записью).
  - `CoreSecurity` — `KeychainStore` с правильными access-флагами, `JailbreakDetector`.
  - `CoreUI` — мини-дизайн-система.
  - `FeatureAuth` — единственный модуль, которому разрешено зависеть больше чем от одного Core-модуля сразу; собирает `CoreSecurity` + `WalletNetworking` в login-флоу.
- `gRPC_Wallet_Demo/` — SwiftUI-приложение: `AppContainer` как единая точка сборки зависимостей (composition root), `Coordinator` поверх `NavigationStack`, `SecureContainerView` (защита чувствительного контента при screen recording через secure `UITextField`-слой).
- `server/` — локальный Python-сервер, отдаёт те же данные и по gRPC, и по JSON — для бенчмарка.
- `Jenkinsfile` + `fastlane/Fastfile` — локальный CI/CD: test → build → release, release-стадия только для `main`.

Стек: Swift 6, SwiftUI, `grpc-swift-2` + `swift-protobuf`, SPM (модульный граф с зависимостью в одну сторону — SPM сам ловит cyclic-dependency при нарушении), Jenkins + Fastlane.

## Как запустить

```bash
# 1. Поднять серверы (gRPC на 50051, JSON на 50052)
cd server && source venv/bin/activate && python server.py

# 2. Собрать и запустить приложение
open gRPC_Wallet_Demo.xcodeproj   # или: fastlane ios build_simulator
```
