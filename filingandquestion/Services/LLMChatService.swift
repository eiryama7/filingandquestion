//
//  LLMChatService.swift
//  filingandquestion
//
//  Apple Foundation Models フレームワークを使ったチャットサービス
//

import Foundation
import FoundationModels

/// LLMとの通信を管理するサービスクラス
@MainActor
class LLMChatService: ObservableObject {
    private var session: LanguageModelSession?
    
    /// モデルの利用可能性を確認
    func checkAvailability() -> Bool {
        guard SystemLanguageModel.isSupported else {
            return false
        }
        
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            return true
        case .unavailable:
            return false
        @unknown default:
            return false
        }
    }
    
    /// セッションを初期化
    func initializeSession() throws {
        guard checkAvailability() else {
            throw LLMError.modelUnavailable
        }
        
        let model = SystemLanguageModel.default
        session = try model.makeSession()
    }
    
    /// ユーザーメッセージに対する応答を取得
    /// - Parameter userMessage: ユーザーからのメッセージテキスト
    /// - Returns: モデルからの応答テキスト
    func sendMessage(_ userMessage: String) async throws -> String {
        guard let session = session else {
            try initializeSession()
            guard let session = session else {
                throw LLMError.sessionNotInitialized
            }
        }
        
        do {
            // ユーザーメッセージを送信し、応答を取得
            let response = try await session.respond(to: userMessage)
            return response
        } catch {
            throw LLMError.responseError(error.localizedDescription)
        }
    }
    
    /// セッションをリセット（会話履歴をクリア）
    func resetSession() {
        session = nil
        try? initializeSession()
    }
}

/// LLM関連のエラー定義
enum LLMError: LocalizedError {
    case modelUnavailable
    case sessionNotInitialized
    case responseError(String)
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligenceのモデルが利用できません。iOS 18.1以降かつ対応デバイスが必要です。"
        case .sessionNotInitialized:
            return "セッションの初期化に失敗しました。"
        case .responseError(let message):
            return "応答の取得中にエラーが発生しました: \(message)"
        }
    }
}
