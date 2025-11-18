//
//  ChatViewModel.swift
//  filingandquestion
//
//  チャット画面のビジネスロジックを管理するViewModel
//

import Foundation
import SwiftUI

/// チャット画面の状態管理を行うViewModel
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let llmService = LLMChatService()
    
    init() {
        checkModelAvailability()
    }
    
    /// モデルの利用可能性を確認
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
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessageText = currentInput
        currentInput = ""
        
        // ユーザーメッセージを追加
        let userMessage = ChatMessage(role: .user, text: userMessageText)
        messages.append(userMessage)
        
        // LLMに問い合わせ
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let responseText = try await llmService.sendMessage(userMessageText)
                
                // アシスタントの応答を追加
                let assistantMessage = ChatMessage(role: .assistant, text: responseText)
                messages.append(assistantMessage)
                
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                
                // エラーメッセージもチャットに表示
                let errorChatMessage = ChatMessage(
                    role: .assistant,
                    text: "エラーが発生しました: \(error.localizedDescription)"
                )
                messages.append(errorChatMessage)
            }
        }
    }
    
    /// 会話履歴をクリア
    func clearMessages() {
        messages.removeAll()
        llmService.resetSession()
    }
    
    /// エラーアラートを閉じる
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
