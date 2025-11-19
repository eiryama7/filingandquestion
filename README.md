# Apple オンデバイス LLM チャットボットアプリ

このプロジェクトは、Apple の Foundation Models フレームワークを使用したシンプルなチャットボットアプリケーションのサンプル実装です。

> 📚 **ドキュメント**: [セットアップガイド](SETUP.md) | [クイックリファレンス](QUICKREF.md)

## 概要

Apple Intelligence の Foundation Models（オンデバイス LLM）を使用して、デバイス上で動作する AI チャットアシスタントを実装しています。ユーザーがテキストを入力すると、Apple の言語モデルが応答を生成し、会話履歴として画面に表示されます。

### 主な機能

- ✅ Apple の SystemLanguageModel を使用したオンデバイス AI チャット
- ✅ SwiftUI による直感的なチャット UI
- ✅ ユーザーとアシスタントのメッセージを区別した表示
- ✅ 会話履歴の管理とマルチターン対話
- ✅ リアルタイムローディングインジケータ
- ✅ エラーハンドリングと利用可否チェック
- ✅ 会話履歴のクリア機能
- ✅ **安全チェック緩和機能（safetyOverride）** - 長文テキストや文学作品の入力に対応

## クイックスタート

```bash
# 1. リポジトリをクローン
git clone https://github.com/eiryama7/filingandquestion.git
cd filingandquestion

# 2. Xcode でプロジェクトを開く
open filingandquestion.xcodeproj

# 3. 対応デバイス（iPhone 15 Pro 以降）を接続してビルド
```

> ⚠️ **重要**: Apple Intelligence は iPhone 15 Pro 以降の実機でのみ動作します。シミュレータでは利用できません。

詳細な手順は [セットアップガイド（SETUP.md）](SETUP.md) をご覧ください。

## 必要な環境

### ハードウェア要件

- **対応デバイス**: iPhone 15 Pro、iPhone 15 Pro Max、iPhone 16 シリーズ以降
  - Apple Intelligence（Apple Silicon A17 Pro 以降）搭載デバイスが必要です

### ソフトウェア要件

- **Xcode**: 16.0 以降
- **iOS**: 18.1 以降（Apple Intelligence 対応バージョン）
- **macOS**: macOS Sequoia 15.1 以降（Xcode 16 の実行に必要）

### 地域とデバイス設定

- デバイスの言語と地域が Apple Intelligence に対応している必要があります
- 設定 > Apple Intelligence で機能が有効になっている必要があります

## ビルド・実行手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/eiryama7/filingandquestion.git
cd filingandquestion
```

### 2. Xcode でプロジェクトを開く

```bash
open filingandquestion.xcodeproj
```

または、Finder から `filingandquestion.xcodeproj` をダブルクリックして開きます。

### 3. 開発チームの設定

1. Xcode のプロジェクトナビゲータで `filingandquestion` プロジェクトを選択
2. `TARGETS` > `filingandquestion` を選択
3. `Signing & Capabilities` タブを開く
4. `Team` ドロップダウンから開発チームを選択

### 4. ビルドと実行

1. **シミュレータでの実行**: 
   - 注意: Apple Intelligence は実機でのみ動作します。シミュレータではモデルが利用できない旨のエラーが表示されます。
   
2. **実機での実行**:
   - 対応デバイス（iPhone 15 Pro 以降）を接続
   - Xcode のスキームセレクタで接続したデバイスを選択
   - `Command + R` または ▶️ ボタンでビルド・実行

### 5. Apple Intelligence の有効化

アプリを初めて実行する際、以下を確認してください:

1. デバイスで **設定 > Apple Intelligence** を開く
2. Apple Intelligence が有効になっていることを確認
3. 必要に応じて利用規約に同意し、機能をオンにする

## プロジェクト構成

```
filingandquestion/
├── Models/
│   └── ChatMessage.swift          # チャットメッセージのデータモデル
├── Views/
│   └── ChatView.swift             # メインのチャット画面UI
├── ViewModels/
│   └── ChatViewModel.swift        # チャット画面のロジック管理
├── Services/
│   └── LLMChatService.swift       # Foundation Models との通信サービス
├── filingandquestionApp.swift     # アプリのエントリポイント
└── Assets.xcassets                # アセットカタログ
```

### ファイル説明

#### Models/ChatMessage.swift
- チャットメッセージを表現するデータ構造
- ユーザーとアシスタントの役割を区別
- タイムスタンプを含む

#### Services/LLMChatService.swift
- **Foundation Models フレームワークとの通信を担当**
- `SystemLanguageModel` を使用してモデルへのアクセスを管理
- セッションの初期化と会話履歴の維持
- エラーハンドリングと利用可否チェック

#### ViewModels/ChatViewModel.swift
- チャット画面の状態管理（メッセージ一覧、入力テキスト、ローディング状態）
- LLMChatService を呼び出してメッセージを送受信
- エラー処理とユーザーフィードバック

#### Views/ChatView.swift
- SwiftUI によるチャット UI の実装
- メッセージバブルの表示（ユーザー/アシスタントで見た目を変更）
- 入力欄と送信ボタン
- 自動スクロール機能

## Foundation Models によるチャット処理の概要

### 1. モデルの利用可否チェック

```swift
SystemLanguageModel.isSupported  // デバイスがサポートしているか
SystemLanguageModel.default.availability  // モデルが利用可能か
```

### 2. セッションの初期化（安全チェック緩和機能付き）

```swift
let model = SystemLanguageModel.default
// safetyOverride を有効にして、長文テキストや文学作品にも対応
let session = try model.makeSession(safetyOverride: true)
```

`safetyOverride` パラメータを `true` に設定することで、長文テキストや文学作品などのコンテンツに対する安全チェックが緩和され、エラーが発生しにくくなります。これにより、小説の一節や長い引用文などを入力しても正常に処理できます。

### 3. メッセージの送信と応答取得

```swift
let response = try await session.respond(to: userMessage)
```

セッションは会話履歴を自動的に管理し、マルチターンの対話を可能にします。

### エラーハンドリング

- モデルが利用できない場合: デバイスや OS バージョンの確認を促すメッセージを表示
- 推論エラー: エラーメッセージをチャット内に表示し、ユーザーに通知

## 使い方

1. アプリを起動すると、チャット画面が表示されます
2. 下部のテキストフィールドにメッセージを入力
3. 送信ボタン（↑）をタップ
4. AI が応答を生成し、チャット画面に表示されます
5. 会話を続けることで、文脈を理解した応答を得られます
6. 右上のゴミ箱アイコンで会話履歴をクリアできます

## トラブルシューティング

### 「Apple Intelligence のモデルが利用できません」と表示される

**原因**:
- 非対応デバイスを使用している
- iOS バージョンが 18.1 未満
- Apple Intelligence が有効になっていない

**解決方法**:
1. デバイスが iPhone 15 Pro 以降であることを確認
2. iOS を 18.1 以降にアップデート
3. 設定 > Apple Intelligence で機能を有効化

### シミュレータで動作しない

Apple Intelligence は実機専用の機能です。対応デバイスで実行してください。

### ビルドエラーが発生する

1. Xcode が 16.0 以降であることを確認
2. iOS Deployment Target が 18.1 以降に設定されていることを確認
3. プロジェクトをクリーン（`Command + Shift + K`）してから再ビルド

## 技術スタック

- **言語**: Swift 5.9+
- **UI フレームワーク**: SwiftUI
- **AI フレームワーク**: Foundation Models (Apple Intelligence)
- **アーキテクチャ**: MVVM (Model-View-ViewModel)
- **非同期処理**: Swift Concurrency (async/await)

## ドキュメント

- 📘 [README（このファイル）](README.md) - プロジェクト概要と基本情報
- 📗 [セットアップガイド（SETUP.md）](SETUP.md) - 詳細なセットアップ手順とトラブルシューティング
- 📙 [クイックリファレンス（QUICKREF.md）](QUICKREF.md) - コードスニペットとカスタマイズ方法

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](LICENSE) をご覧ください。

## 注意事項

- Foundation Models API は Apple の公式ドキュメントに基づいて実装していますが、API は変更される可能性があります
- オンデバイス処理のため、インターネット接続は不要です
- プライバシー: すべての処理がデバイス上で完結し、外部サーバーにデータは送信されません

## 今後の拡張案

- [ ] ストリーミング応答の実装（逐次表示）
- [ ] 会話履歴の永続化（UserDefaults/CoreData）
- [ ] メッセージのコピー機能
- [ ] ダークモード対応の UI 改善
- [ ] システムプロンプトのカスタマイズ機能
- [ ] 音声入力対応

## 参考資料

- [Apple Intelligence Documentation](https://developer.apple.com/apple-intelligence/)
- [Foundation Models Framework](https://developer.apple.com/documentation/foundationmodels)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

---

**開発者**: このプロジェクトはサンプル実装として提供されています。自由に使用・改変・配布していただけます。
