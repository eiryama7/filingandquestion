# セットアップガイド

このドキュメントでは、プロジェクトのセットアップ手順と、実機でのテスト方法について詳しく説明します。

## 前提条件の確認

### 1. 開発環境

- **macOS**: macOS Sequoia 15.1 以降
- **Xcode**: バージョン 16.0 以降
- **Apple Developer アカウント**: 実機でテストする場合は必須（無料アカウントでも可）

### 2. デバイス要件

Apple Intelligence（Foundation Models）を使用するには、以下のデバイスが必要です:

#### 対応デバイス
- iPhone 15 Pro
- iPhone 15 Pro Max
- iPhone 16 全モデル
- iPhone 16 Pro 全モデル
- 今後リリースされる対応デバイス

#### OS バージョン
- iOS 18.1 以降

**注意**: iPhone 15（無印）や iPhone 14 以前のモデルでは Apple Intelligence が利用できません。

## プロジェクトのセットアップ

### ステップ 1: リポジトリのクローン

```bash
git clone https://github.com/eiryama7/filingandquestion.git
cd filingandquestion
```

### ステップ 2: Xcode でプロジェクトを開く

```bash
open filingandquestion.xcodeproj
```

または Finder から `filingandquestion.xcodeproj` をダブルクリックします。

### ステップ 3: 開発チームの設定

1. Xcode のプロジェクトナビゲータ（左側のペイン）で `filingandquestion` プロジェクトアイコンをクリック
2. 中央のペインで `TARGETS` セクションから `filingandquestion` を選択
3. `Signing & Capabilities` タブを開く
4. `Automatically manage signing` にチェックが入っていることを確認
5. `Team` ドロップダウンメニューから、あなたの Apple ID または開発チームを選択

**トラブルシューティング**:
- チームが表示されない場合: Xcode > Settings > Accounts から Apple ID を追加
- 無料アカウントの場合: Personal Team として表示されます

### ステップ 4: Bundle Identifier の変更（必要に応じて）

無料の Apple Developer アカウントを使用する場合、Bundle Identifier が他の開発者と重複しないように変更する必要があります:

1. `Signing & Capabilities` タブで `Bundle Identifier` を確認
2. デフォルトは `eiryama7.filingandquestion` ですが、これを変更:
   - 例: `yourname.filingandquestion`
   - または: `com.yourcompany.filingandquestion`

## Apple Intelligence の有効化

### デバイス側の設定

アプリを実行する前に、デバイスで Apple Intelligence を有効にする必要があります:

1. **言語設定の確認**
   - 設定 > 一般 > 言語と地域
   - デバイスの言語が対応言語（英語など）に設定されていることを確認
   - ※ 執筆時点では日本語は未対応の可能性があります

2. **Apple Intelligence の有効化**
   - 設定 > Apple Intelligence & Siri
   - 「Apple Intelligence」をオンにする
   - 初回は利用規約への同意が必要
   - モデルのダウンロードが開始される場合があります（数GB）

3. **Siri の言語設定**
   - 設定 > Siri & Search > Language
   - 英語（米国）など、Apple Intelligence 対応言語を選択

4. **デバイスの再起動**
   - 設定変更後、デバイスを再起動することをお勧めします

### モデルのダウンロード確認

- Apple Intelligence のモデルは自動的にダウンロードされます
- ダウンロードには時間がかかる場合があります（Wi-Fi 接続推奨）
- 設定 > 一般 > iPhone ストレージで、モデルのダウンロード状況を確認できます

## ビルドと実行

### シミュレータでの実行（制限あり）

```bash
# コマンドラインから
xcodebuild -project filingandquestion.xcodeproj \
           -scheme filingandquestion \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**注意**: Apple Intelligence は実機専用の機能です。シミュレータで実行すると、「モデルが利用できません」というエラーメッセージが表示されます。

### 実機での実行

1. **デバイスを Mac に接続**
   - USB ケーブルでデバイスを接続
   - デバイスで「このコンピュータを信頼しますか？」が表示されたら「信頼」をタップ

2. **ターゲットデバイスの選択**
   - Xcode のツールバーで、スキームセレクタ（画面上部中央）をクリック
   - 接続したデバイス名を選択

3. **ビルドと実行**
   - `Command + R` を押す、または ▶️（Run）ボタンをクリック
   - 初回実行時、デバイスにアプリがインストールされます

4. **開発者モードの有効化（iOS 16 以降）**
   - 初回実行時、デバイスで開発者モードを有効にするよう求められる場合があります
   - 設定 > プライバシーとセキュリティ > Developer Mode をオンにする
   - デバイスを再起動

5. **アプリの信頼**
   - 無料の Apple Developer アカウントを使用している場合:
   - 設定 > 一般 > VPN とデバイス管理
   - あなたの開発者プロファイルをタップ
   - 「<あなたのメール>を信頼」をタップ

## 動作確認

アプリが正常に起動したら:

1. チャット画面が表示される
2. 下部のテキストフィールドにメッセージを入力
3. 送信ボタン（↑）をタップ
4. AI からの応答が表示される

### エラーが表示される場合

**「Apple Intelligence のモデルが利用できません」と表示される場合**:

1. デバイスが対応機種か確認（iPhone 15 Pro 以降）
2. iOS バージョンが 18.1 以降か確認
3. Apple Intelligence が有効になっているか確認
4. モデルのダウンロードが完了しているか確認
5. デバイスの言語設定を確認
6. デバイスを再起動

## コードの理解

### アーキテクチャ

このプロジェクトは MVVM パターンを採用しています:

- **Model** (`ChatMessage.swift`): データ構造の定義
- **View** (`ChatView.swift`): UI の表示
- **ViewModel** (`ChatViewModel.swift`): ビジネスロジックと状態管理
- **Service** (`LLMChatService.swift`): LLM との通信

### Foundation Models の使い方

重要なコードは `LLMChatService.swift` にあります:

```swift
// 1. モデルの利用可否チェック
SystemLanguageModel.isSupported
SystemLanguageModel.default.availability

// 2. セッションの作成
let model = SystemLanguageModel.default
let session = try model.makeSession()

// 3. メッセージの送信と応答の受信
let response = try await session.respond(to: userMessage)
```

### カスタマイズのヒント

- **システムプロンプトの追加**: 現在は実装されていませんが、セッション初期化時にシステムプロンプトを設定可能
- **ストリーミング応答**: 応答を逐次表示する場合、ストリーミング API を使用
- **会話履歴の永続化**: `messages` 配列を UserDefaults や CoreData に保存

## トラブルシューティング

### ビルドエラー

**"No such module 'FoundationModels'"**
- Xcode バージョンが古い可能性があります
- Xcode 16.0 以降に更新してください

**"Signing for 'filingandquestion' requires a development team"**
- Signing & Capabilities で Team を選択してください

### 実行時エラー

**アプリがクラッシュする**
- Xcode のコンソールでエラーメッセージを確認
- デバイスの iOS バージョンを確認

**応答が返ってこない**
- デバイスが Apple Intelligence に対応しているか確認
- モデルのダウンロードが完了しているか確認

## 参考リンク

- [Apple Intelligence Documentation](https://developer.apple.com/apple-intelligence/)
- [Foundation Models Framework](https://developer.apple.com/documentation/foundationmodels)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Xcode Help](https://developer.apple.com/documentation/xcode)

## サポート

問題が解決しない場合:
1. GitHub の Issues セクションで質問を投稿
2. Apple Developer Forums で検索
3. Xcode のコンソール出力を確認し、エラーメッセージを記録
