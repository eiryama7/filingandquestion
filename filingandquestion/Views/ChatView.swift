//
//  ChatView.swift
//  filingandquestion
//
//  メインのチャット画面UI
//  SwiftUI を使用したチャットインターフェースの実装
//

import SwiftUI
import UIKit

/// チャット画面のメインビュー
///
/// UI構成:
/// - 上部: スクロール可能なメッセージ一覧
/// - 下部: テキスト入力欄と送信ボタン
/// - ナビゲーションバー: タイトルと会話クリアボタン
///
/// 機能:
/// - メッセージの送受信
/// - 自動スクロール（最新メッセージまで）
/// - ローディングインジケータ表示
/// - エラーアラート表示
struct ChatView: View {
    /// ViewModel（チャット状態を管理）
    /// @StateObject により、このビューのライフサイクルで保持されます
    @StateObject private var viewModel = ChatViewModel()
    
    /// スクロール制御用のプロキシ
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // メッセージ一覧エリア
                // ScrollViewReader により、特定のメッセージまでスクロール可能
                ScrollViewReader { proxy in
                    ScrollView {
                        // LazyVStack でパフォーマンスを最適化
                        // （表示される部分だけレンダリング）
                        LazyVStack(spacing: 12) {
                            // 各メッセージを表示
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message) { target in
                                    viewModel.regenerateResponse(for: target)
                                }
                                .id(message.id) // スクロール制御用にIDを設定
                            }
                            
                            // AI応答生成中のローディングインジケータ
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("生成中...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        // スクロールプロキシを保存
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // メッセージが追加されたら自動スクロール
                        scrollToBottom()
                    }
                }
                
                Divider()
                
                // 入力エリア（画面下部に固定）
                HStack(alignment: .bottom, spacing: 12) {
                    // マルチラインテキスト入力
                    TextField("メッセージを入力...", text: $viewModel.currentInput, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...5) // 最大5行まで
                        .disabled(viewModel.isLoading) // 生成中は入力を無効化
                    
                    // 送信ボタン
                    Button(action: {
                        viewModel.sendMessage()
                        scrollToBottom()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend) // 送信不可時は無効化
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("AI チャット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 右上にクリアボタンを配置
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.clearMessages()
                    }) {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
            // エラーアラート
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    /// 送信可能かどうか
    /// 
    /// 条件:
    /// - 入力テキストが空でない
    /// - かつ、AI応答生成中でない
    private var canSend: Bool {
        !viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
    }
    
    /// 最新メッセージまでスクロール
    ///
    /// 新しいメッセージが追加されたときに、
    /// 自動的に一番下までスクロールする
    private func scrollToBottom() {
        guard let lastMessage = viewModel.messages.last else { return }
        // 少し遅延させることで、レイアウト完了後に確実にスクロール
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

/// メッセージバブル表示用のビュー
///
/// ユーザーとアシスタントで見た目を変えています:
/// - ユーザー: 右寄せ、青色背景、白文字
/// - アシスタント: 左寄せ、グレー背景、黒文字
struct MessageBubbleView: View {
    let message: ChatMessage
    let onRegenerate: ((ChatMessage) -> Void)?
    
    var body: some View {
        HStack {
            // ユーザーメッセージの場合は左側にスペーサーを配置（右寄せ）
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // メッセージテキスト
                Text(message.text)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                    .overlay(alignment: .topTrailing) {
                        if shouldShowRegenerateButton {
                            Button {
                                onRegenerate?(message)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2)
                                    .padding(6)
                                    .foregroundColor(.secondary)
                            }
                            .background(.thinMaterial, in: Circle())
                            .padding(4)
                        }
                    }
                    .contextMenu {
                        if message.role == .assistant {
                            Button(action: copyToClipboard) {
                                Label("コピー", systemImage: "doc.on.doc")
                            }
                        }
                    }
                
                // タイムスタンプ
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // メタデータ（アシスタントメッセージのみ）
                if message.role == .assistant, let responseTime = message.responseTime {
                    VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            // 応答時間
                            Text(String(format: "Response time: %.2f sec", responseTime))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            // 出力トークン数
                            if let outputTokens = message.outputTokens {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(outputTokens) tokens")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // トークン生成速度
                            if let tokensPerSecond = message.tokensPerSecond {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f tokens/sec", tokensPerSecond))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // アシスタントメッセージの場合は右側にスペーサーを配置（左寄せ）
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    /// メッセージの背景色
    /// ユーザー: 青、アシスタント: グレー
    private var backgroundColor: Color {
        message.role == .user ? Color.blue : Color(UIColor.systemGray5)
    }
    
    /// メッセージのテキスト色
    /// ユーザー: 白、アシスタント: プライマリ（ダークモード対応）
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }
    
    /// フォーマットされた時刻（HH:mm形式）
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

private extension MessageBubbleView {
    var shouldShowRegenerateButton: Bool {
        message.role == .assistant && message.originalPrompt != nil && onRegenerate != nil
    }

    func copyToClipboard() {
        UIPasteboard.general.string = message.text
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
}

// SwiftUI プレビュー
#Preview {
    ChatView()
}
