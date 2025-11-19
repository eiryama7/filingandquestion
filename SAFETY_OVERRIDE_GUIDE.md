# Safety Override 機能ガイド

このドキュメントでは、Foundation Models の安全チェック緩和機能（safetyOverride）について説明します。

## 概要

Foundation Models API には、デフォルトで安全性チェック機能が組み込まれています。これは、不適切なコンテンツや有害な内容を検出してブロックするためのものです。しかし、長文テキストや文学作品（小説、詩、古典文学など）を入力する場合、誤検知によりエラーが発生することがあります。

`safetyOverride` パラメータを有効にすることで、このような誤検知を防ぎ、正当なコンテンツを処理できるようになります。

## 実装内容

### コード変更

#### LLMChatService.swift

```swift
// セッション初期化時に safetyOverride を指定
func initializeSession(safetyOverride: Bool = true) throws {
    guard checkAvailability() else {
        throw LLMError.modelUnavailable
    }
    
    let model = SystemLanguageModel.default
    session = try model.makeSession(safetyOverride: safetyOverride)
}
```

**デフォルト動作**:
- `safetyOverride` は `true` がデフォルト値として設定されています
- すべての新しいセッションで自動的に安全チェックが緩和されます
- 必要に応じて `false` を指定して、標準の安全チェックを使用することもできます

### 影響を受ける箇所

1. **initializeSession(safetyOverride:)** - セッション初期化メソッド
2. **sendMessage(_:)** - メッセージ送信時の自動初期化
3. **resetSession()** - セッションリセット時の再初期化

## 使用例

### 長文テキストの入力

```swift
// 長い小説の一節を入力
let longText = """
吾輩は猫である。名前はまだ無い。
どこで生れたかとんと見当がつかぬ。
何でも薄暗いじめじめした所でニャーニャー泣いていた事だけは記憶している。
吾輩はここで始めて人間というものを見た。
しかもあとで聞くとそれは書生という人間中で一番獰悪な種族であったそうだ。
この書生というのは時々我々を捕えて煮て食うという話である。
しかしその当時は何という考もなかったから別段恐しいとも思わなかった。
ただ彼の掌に載せられてスーと持ち上げられた時何だかフワフワした感じが
あったばかりである。
"""

// safetyOverride が有効なので、長文でもエラーにならない
let response = try await llmService.sendMessage(longText)
```

### 文学作品の引用

```swift
// シェイクスピアの引用
let shakespeareQuote = """
To be, or not to be, that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune,
Or to take arms against a sea of troubles
And by opposing end them.
"""

let response = try await llmService.sendMessage(shakespeareQuote)
```

### 詩や歌詞の入力

```swift
// 詩の入力
let poem = """
春はあけぼの。やうやう白くなりゆく山ぎは、
すこしあかりて、紫だちたる雲のほそくたなびきたる。
夏は夜。月のころはさらなり、闇もなほ、
蛍の多く飛びちがひたる。
"""

let response = try await llmService.sendMessage(poem)
```

## API バリエーション

Foundation Models API のバージョンや実装により、以下のいずれかの形式が使用される可能性があります:

### パターン1: safetyOverride パラメータ
```swift
session = try model.makeSession(safetyOverride: true)
```

### パターン2: overrideSafety パラメータ
```swift
session = try model.makeSession(overrideSafety: true)
```

### パターン3: safety enum
```swift
session = try model.makeSession(safety: .allow)
// または
session = try model.makeSession(safety: .relaxed)
```

### パターン4: 設定オブジェクト
```swift
let config = LanguageModelSessionConfiguration()
config.safetyOverride = true
session = try model.makeSession(configuration: config)
```

**現在の実装**: このプロジェクトでは **パターン1** (`safetyOverride` パラメータ) を使用しています。実際の API に合わせて調整してください。

## テスト方法

### 1. 基本的な動作確認

1. アプリを起動
2. 短いメッセージを送信して、通常の動作を確認
3. 長文テキスト（1000文字以上）を入力
4. エラーが発生せず、正常に応答が返ることを確認

### 2. 文学作品のテスト

以下のようなコンテンツをテストしてください:

- 古典文学の一節（夏目漱石、シェイクスピアなど）
- 詩や和歌
- 長い引用文
- 複数段落にわたるテキスト

### 3. エラーケースの確認

`safetyOverride: false` を設定した場合の動作も確認:

```swift
try llmService.initializeSession(safetyOverride: false)
```

長文テキストでエラーが発生する可能性があることを確認します。

## トラブルシューティング

### コンパイルエラーが発生する場合

**エラー**: `Extra argument 'safetyOverride' in call`

**原因**: 使用している Foundation Models API のバージョンが異なる可能性があります。

**解決方法**:
1. Xcode のバージョンを確認（16.0以降）
2. iOS のバージョンを確認（18.1以降）
3. API ドキュメントで正しいパラメータ名を確認
4. 必要に応じて、パラメータ名を変更（例: `overrideSafety`）

### 実行時エラーが発生する場合

**エラー**: `Unrecognized argument label in call`

**解決方法**:
LLMChatService.swift の initializeSession メソッドで、異なる API パターンを試してください:

```swift
// 元のコード
session = try model.makeSession(safetyOverride: safetyOverride)

// 代替案1
session = try model.makeSession(overrideSafety: safetyOverride)

// 代替案2（パラメータなし）
session = try model.makeSession()
```

## 注意事項

### セキュリティ上の考慮事項

`safetyOverride` を有効にすると、安全性チェックが緩和されます。これは以下を意味します:

- ✅ **メリット**: 長文テキストや文学作品を正常に処理できる
- ⚠️ **注意点**: 不適切なコンテンツの検出が弱まる可能性がある

**推奨事項**:
- 信頼できるコンテンツのみを入力してください
- ユーザー生成コンテンツを扱う場合は、別途コンテンツフィルタリングを検討してください
- プロダクション環境では、適切なコンテンツポリシーを設定してください

### プライバシーへの影響

Foundation Models はオンデバイスで実行されるため、`safetyOverride` の有効化によるプライバシーへの影響はありません。すべての処理はデバイス上で完結し、外部サーバーにデータは送信されません。

## 参考資料

- [Apple Intelligence Documentation](https://developer.apple.com/apple-intelligence/)
- [Foundation Models Framework](https://developer.apple.com/documentation/foundationmodels)
- [WWDC セッション: Apple Intelligence の紹介](https://developer.apple.com/videos/)

## バージョン履歴

- **v1.0** (2025-11-19): 初版作成
  - safetyOverride パラメータの追加
  - 長文テキスト対応
  - ドキュメント整備

## フィードバック

この機能に関するフィードバックや問題報告は、GitHub Issues でお願いします。

---

**重要**: Foundation Models API は進化し続けているため、このドキュメントの内容は最新の API 仕様と異なる可能性があります。常に公式ドキュメントを参照し、最新情報を確認してください。
