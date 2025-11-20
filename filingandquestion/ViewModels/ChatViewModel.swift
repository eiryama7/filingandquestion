//
//  ChatViewModel.swift
//  filingandquestion
//
//  チャット画面のビジネスロジックを管理するViewModel
//  MVVM パターンにおける ViewModel として、View と Model（LLMChatService）の橋渡しを行います
//

import Foundation
import SwiftUI
import Combine

/// チャット画面の状態管理を行うViewModel
///
/// このクラスの役割:
/// - チャットメッセージの一覧管理
/// - ユーザー入力の管理
/// - LLMChatService を使った AI との通信
/// - エラー状態の管理と UI へのフィードバック
/// - ローディング状態の管理
///
/// @MainActor により UI スレッドでの実行を保証
/// ObservableObject により SwiftUI との自動バインディングを実現
@MainActor
class ChatViewModel: ObservableObject {
    
    /// チャットメッセージの配列
    /// @Published により、変更時に自動的に View が更新されます
    @Published var messages: [ChatMessage] = []
    
    /// 現在のユーザー入力テキスト
    @Published var currentInput: String = ""
    
    /// AI 応答生成中かどうかのフラグ
    @Published var isLoading: Bool = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    /// エラーアラートを表示するかどうか
    @Published var showError: Bool = false
    
    /// LLM との通信を行うサービスインスタンス
    private let llmService = LLMChatService()
    
    /// 初期化時にモデルの利用可能性をチェック
    init() {
        checkModelAvailability()
    }
    
    /// モデルの利用可能性を確認
    ///
    /// アプリ起動時に Apple Intelligence が利用可能かチェックし、
    /// 利用できない場合はユーザーに通知します
    private func checkModelAvailability() {
        if !llmService.checkAvailability() {
            errorMessage = "Apple Intelligenceのモデルが利用できません。iOS 18.1以降かつ対応デバイス（iPhone 15 Pro以降など）が必要です。"
            showError = true
        } else {
            do {
                try llmService.initializeSession()
            } catch {
                errorMessage = "セッションの初期化に失敗しました: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    /// メッセージを送信
    ///
    /// ユーザーがメッセージを送信したときの処理フロー:
    /// 1. 入力テキストが空でないか確認
    /// 2. ユーザーメッセージを messages 配列に追加
    /// 3. LLM に問い合わせ（非同期処理）
    /// 4. AI の応答を messages 配列に追加
    /// 5. エラーが発生した場合はエラーメッセージを表示
    func sendMessage() {
        // 空白のみのメッセージは送信しない
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 入力テキストを保存して、入力欄をクリア
        let userMessageText = currentInput
        currentInput = ""

        // ユーザーメッセージをチャット履歴に追加
        let userMessage = ChatMessage(role: .user, text: userMessageText)
        messages.append(userMessage)

        // LLM に問い合わせ（非同期タスク）
        Task {
            await generateAssistantResponse(for: userMessageText)
        }
    }

    /// 既存のユーザー入力から再生成を行う
    /// - Parameter message: 再生成元のアシスタントメッセージ
    func regenerateResponse(for message: ChatMessage) {
        guard !isLoading else { return }
        guard message.role == .assistant, let prompt = message.originalPrompt else { return }

        Task {
            await generateAssistantResponse(for: prompt)
        }
    }
    
    /// 会話履歴をクリア
    ///
    /// チャット履歴を削除し、LLM セッションもリセットします。
    /// これにより新しい会話を開始できます。
    func clearMessages() {
        messages.removeAll()
        llmService.resetSession()
    }
    
    /// エラーアラートを閉じる
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    /// 共通の応答生成処理
    /// - Parameter prompt: 送信するユーザープロンプト
    private func generateAssistantResponse(for prompt: String) async {
        // ローディング状態を表示
        isLoading = true
        // defer でタスク終了時に必ずローディングを解除
        defer { isLoading = false }

        do {
            // LLM サービスを使って応答を取得
            // await により、応答が返ってくるまで待機
            let llmResponse = try await llmService.sendMessage(prompt)

            // AI の応答をチャット履歴に追加（メタデータ付き）
            let assistantMessage = ChatMessage(
                role: .assistant,
                text: llmResponse.text,
                responseTime: llmResponse.responseTime,
                outputTokens: llmResponse.outputTokens,
                tokensPerSecond: llmResponse.tokensPerSecond,
                originalPrompt: prompt
            )
            messages.append(assistantMessage)

        } catch {
            // エラー発生時の処理
            errorMessage = error.localizedDescription
            showError = true

            // エラーメッセージもチャットに表示して、ユーザーに視覚的にフィードバック
            let errorChatMessage = ChatMessage(
                role: .assistant,
                text: "エラーが発生しました: \(error.localizedDescription)"
            )
            messages.append(errorChatMessage)
        }
    }
}

