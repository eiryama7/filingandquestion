# クイックリファレンス

このプロジェクトの主要なコードスニペットと設定をまとめたクイックリファレンスです。

## 📱 最小要件

| 項目 | 要件 |
|------|------|
| **iOS** | 18.1+ |
| **Xcode** | 16.0+ |
| **デバイス** | iPhone 15 Pro 以降 |
| **言語** | Swift 5.9+ |

## 🏗 プロジェクト構造

```
filingandquestion/
├── Models/
│   └── ChatMessage.swift          # メッセージデータモデル
├── Services/
│   └── LLMChatService.swift       # LLM通信サービス ⭐ 重要
├── ViewModels/
│   └── ChatViewModel.swift        # 状態管理
├── Views/
│   └── ChatView.swift             # チャットUI
└── filingandquestionApp.swift     # エントリポイント
```

## 🔑 重要なコードスニペット

### LLM の利用可否チェック

```swift
// LLMChatService.swift
func checkAvailability() -> Bool {
    guard SystemLanguageModel.isSupported else {
        return false
    }
    
    let availability = SystemLanguageModel.default.availability
    return availability == .available
}
```

### セッションの初期化

```swift
// LLMChatService.swift
func initializeSession(safetyOverride: Bool = true) throws {
    let model = SystemLanguageModel.default
    // safetyOverride を有効にして長文テキストや文学作品にも対応
    session = try model.makeSession(safetyOverride: safetyOverride)
}
```

**重要**: `safetyOverride` パラメータを `true` に設定することで、長文テキストや文学作品などのコンテンツに対する安全チェックが緩和され、エラーを防ぐことができます。

### メッセージの送信

```swift
// LLMChatService.swift
func sendMessage(_ userMessage: String) async throws -> String {
    let response = try await session.respond(to: userMessage)
    return response
}
```

### UI からの呼び出し

```swift
// ChatViewModel.swift
func sendMessage() {
    Task {
        isLoading = true
        defer { isLoading = false }
        
        let responseText = try await llmService.sendMessage(userMessageText)
        let assistantMessage = ChatMessage(role: .assistant, text: responseText)
        messages.append(assistantMessage)
    }
}
```

## 🎨 UI カスタマイズ

### メッセージバブルの色変更

```swift
// ChatView.swift の MessageBubbleView
private var backgroundColor: Color {
    message.role == .user ? Color.blue : Color(UIColor.systemGray5)
}
```

カスタマイズ例:
```swift
// ユーザー: 緑、アシスタント: 紫
message.role == .user ? Color.green : Color.purple
```

### タイトルの変更

```swift
// ChatView.swift
.navigationTitle("AI チャット")  // ← ここを変更
```

## ⚙️ 設定項目

### Xcode プロジェクト設定

1. **Deployment Target**
   - Project > filingandquestion > General > Deployment Info
   - iOS 18.1 以降に設定

2. **Bundle Identifier**
   - Signing & Capabilities タブ
   - 例: `com.yourname.filingandquestion`

3. **Team**
   - Signing & Capabilities タブ
   - Apple Developer アカウントのチームを選択

### Info.plist（必要に応じて）

現在のプロジェクトでは特別な設定は不要ですが、将来的に追加する可能性がある設定:

```xml
<!-- マイク使用許可（音声入力機能を追加する場合） -->
<key>NSMicrophoneUsageDescription</key>
<string>音声入力のためにマイクを使用します</string>

<!-- カメラ使用許可（画像入力機能を追加する場合） -->
<key>NSCameraUsageDescription</key>
<string>画像を送信するためにカメラを使用します</string>
```

## 🐛 よくあるエラーと解決方法

### エラー: "No such module 'FoundationModels'"

**原因**: Xcode のバージョンが古い

**解決方法**: 
```bash
# Xcode を 16.0 以降に更新
# App Store から Xcode をアップデート
```

### エラー: "Apple Intelligence のモデルが利用できません"

**原因**: デバイスが非対応、または設定が不完全

**解決方法**:
1. デバイスが iPhone 15 Pro 以降か確認
2. iOS 18.1 以降にアップデート
3. 設定 > Apple Intelligence で有効化
4. デバイスの言語を対応言語（英語など）に設定

### エラー: ビルドは成功するが応答がない

**原因**: セッションの初期化失敗

**デバッグ方法**:
```swift
// LLMChatService.swift に追加
print("Availability: \(SystemLanguageModel.default.availability)")
print("Session: \(session != nil ? "initialized" : "nil")")
```

## 🔧 拡張アイデア

### 1. 会話履歴の保存

```swift
// ChatViewModel.swift
func saveMessages() {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(messages) {
        UserDefaults.standard.set(data, forKey: "chatHistory")
    }
}

func loadMessages() {
    let decoder = JSONDecoder()
    if let data = UserDefaults.standard.data(forKey: "chatHistory"),
       let decoded = try? decoder.decode([ChatMessage].self, from: data) {
        messages = decoded
    }
}
```

### 2. システムプロンプトの設定

```swift
// 将来のAPI更新で可能になる可能性がある実装例
let session = try model.makeSession(
    systemPrompt: "あなたは親切で丁寧なアシスタントです。"
)
```

### 3. ストリーミング応答

```swift
// 将来のAPI更新で可能になる可能性がある実装例
for try await chunk in session.stream(userMessage) {
    // 逐次的に応答を表示
    partialResponse += chunk
}
```

### 4. メッセージのコピー機能

```swift
// MessageBubbleView に追加
.contextMenu {
    Button(action: {
        UIPasteboard.general.string = message.text
    }) {
        Label("コピー", systemImage: "doc.on.doc")
    }
}
```

## 📊 パフォーマンス最適化

### LazyVStack の使用

```swift
// ChatView.swift ですでに実装済み
LazyVStack {
    ForEach(viewModel.messages) { message in
        MessageBubbleView(message: message)
    }
}
```

これにより、画面に表示されるメッセージのみがレンダリングされ、長い会話でもスムーズに動作します。

### メモリ管理

大量のメッセージが蓄積された場合:

```swift
// ChatViewModel.swift
func limitMessageHistory(to limit: Int = 100) {
    if messages.count > limit {
        messages = Array(messages.suffix(limit))
    }
}
```

## 🧪 テスト方法

### 手動テスト項目

- [ ] メッセージ送信が正常に動作する
- [ ] AI からの応答が表示される
- [ ] ローディングインジケータが表示される
- [ ] エラーハンドリングが機能する
- [ ] 会話履歴のクリアが動作する
- [ ] 長文メッセージが正しく表示される
- [ ] 自動スクロールが機能する
- [ ] ダークモードで正常に表示される

### デバッグログの追加

```swift
// 各重要ポイントにログを追加
print("📤 Sending message: \(userMessage)")
print("📥 Received response: \(response)")
print("❌ Error occurred: \(error)")
```

## 📚 参考資料

- [Apple Intelligence](https://developer.apple.com/apple-intelligence/)
- [Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## 💡 ヒント

1. **開発中は実機でテスト**: シミュレータでは Apple Intelligence が動作しません
2. **モデルのダウンロードに注意**: 初回は数GB のダウンロードが必要です
3. **会話履歴の管理**: セッションは自動的に会話履歴を保持します
4. **エラーハンドリング**: 必ず try-catch で例外処理を実装しましょう
5. **UI の応答性**: @MainActor を使用してメインスレッドで UI を更新

## 🆘 サポート

問題が発生した場合:
1. この QuickReference を確認
2. SETUP.md の詳細な手順を参照
3. GitHub Issues で質問を投稿
