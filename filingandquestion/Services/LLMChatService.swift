//
//  LLMChatService.swift
//  filingandquestion
//
//  Apple Foundation Models フレームワークを使ったチャットサービス
//  このクラスは Apple Intelligence のオンデバイス LLM との通信を管理します
//

import Foundation
import Combine
import FoundationModels

/// LLM応答のメタデータを含む構造体
struct LLMResponse {
    /// 応答テキスト
    let text: String
    /// 応答時間（秒）
    let responseTime: Double
    /// 出力トークン数（推定値）
    let outputTokens: Int
    /// 1秒あたりのトークン生成速度
    let tokensPerSecond: Double
}

/// LLMとの通信を管理するサービスクラス
/// 
/// このクラスの主な役割:
/// - SystemLanguageModel の利用可能性チェック
/// - LanguageModelSession の初期化と管理
/// - ユーザーメッセージの送信と応答の受信
/// - 会話履歴の維持（セッション内で自動管理）
///
/// @MainActor を使用してメインスレッドで実行することで、
/// UI更新との同期を確保しています
@MainActor
class LLMChatService: ObservableObject {
    /// Foundation Models のセッション
    /// このセッションは会話履歴を内部で保持し、マルチターン対話を可能にします
    private var session: LanguageModelSession?

    /// unsafe コンテンツ関連のエラーを検出するためのキーワード
    private let unsafeKeyword = "unsafe"
    
    /// モデルの利用可能性を確認
    /// 
    /// Apple Intelligence が使用可能かどうかをチェックします:
    /// - デバイスがサポートしているか (SystemLanguageModel.isSupported)
    /// - モデルが利用可能な状態か (availability)
    ///
    /// - Returns: モデルが利用可能な場合は true、それ以外は false
    func checkAvailability() -> Bool {
        // デフォルトモデルの利用可能性を確認
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable:
            return false
        @unknown default:
            return false
        }
    }
    
    /// セッションを初期化
    ///
    /// SystemLanguageModel.default から新しいセッションを作成します。
    /// セッションは会話の文脈を保持するために使用されます。
    /// 
    /// safetyOverride を有効にすることで、長文テキストや文学作品などの
    /// コンテンツに対する安全チェックを緩和し、エラーを防ぎます。
    ///
    /// - Parameter safetyOverride: 安全チェックを緩和するかどうか（デフォルト: true）
    /// - Throws: モデルが利用できない場合、LLMError.modelUnavailable をスロー
    func initializeSession(safetyOverride: Bool = true) throws {
        session = try makeNewSession(safetyOverride: safetyOverride)
    }
    
    /// ユーザーメッセージに対する応答を取得
    ///
    /// このメソッドが Apple の LLM とのメインインターフェースです:
    /// 1. セッションが初期化されていなければ初期化
    /// 2. session.respond(to:) を呼び出してモデルからの応答を取得
    /// 3. セッションは会話履歴を自動的に管理するため、文脈を理解した応答が得られます
    /// 4. 応答時間とトークン数を計測してメタデータとして返します
    ///
    /// - Parameter userMessage: ユーザーからのメッセージテキスト
    /// - Returns: 応答テキストとメタデータを含むLLMResponse
    /// - Throws: セッションエラーまたは応答エラー
    func sendMessage(_ userMessage: String) async throws -> LLMResponse {
        // セッションが存在しない場合は初期化（safetyOverride を有効化）
        if session == nil {
            try initializeSession(safetyOverride: true)
        }

        guard let session = session else {
            throw LLMError.sessionNotInitialized
        }
        
        // 送信時刻を記録
        let startTime = Date()
        
        do {
            // 【ここが重要】Apple の LLM にメッセージを送信し、応答を取得
            // session.respond(to:) は非同期処理で、await を使って完了を待ちます
            // セッション内で会話履歴が保持されるため、マルチターン対話が可能です
            let response: LanguageModelSession.Response<String> = try await session.respond(to: userMessage)
            let responseText = response.content
            
            // 応答受信時刻を記録
            let endTime = Date()
            let responseTime = endTime.timeIntervalSince(startTime)
            
            // トークン数を推定（文字数ベース）
            // 注: Foundation Models API がトークン数を返さない場合の概算
            // 英語: 約4文字/トークン、日本語: 約2文字/トークン
            // ここでは平均的な値として3文字/トークンで概算
            let estimatedTokens = max(1, responseText.count / 3)
            
            // 1秒あたりのトークン生成速度を計算
            let tokensPerSecond = responseTime > 0 ? Double(estimatedTokens) / responseTime : 0
            
            return LLMResponse(
                text: responseText,
                responseTime: responseTime,
                outputTokens: estimatedTokens,
                tokensPerSecond: tokensPerSecond
            )
        } catch {
            if isUnsafeContentError(error) {
                resetSession()
            }
            throw LLMError.responseError(error.localizedDescription)
        }
    }
    
    /// セッションをリセット（会話履歴をクリア）
    ///
    /// 新しい会話を始めたい場合に呼び出します。
    /// セッションを破棄して再初期化することで、会話履歴がクリアされます。
    /// safetyOverride を有効にして初期化します。
    func resetSession() {
        do {
            session = try makeNewSession(safetyOverride: true)
        } catch {
            session = nil
        }
    }

    /// 新しいセッションを安全に生成
    ///
    /// - Parameter safetyOverride: 安全チェックを緩和するかどうか
    /// - Returns: 初期化された LanguageModelSession
    private func makeNewSession(safetyOverride: Bool) throws -> LanguageModelSession {
        guard checkAvailability() else {
            throw LLMError.modelUnavailable
        }

        let model = SystemLanguageModel.default
        return try model.makeSession(safetyOverride: safetyOverride)
    }

    /// unsafe コンテンツ関連のエラーか判定
    /// - Parameter error: 捕捉したエラー
    /// - Returns: unsafe を含む場合は true
    private func isUnsafeContentError(_ error: Error) -> Bool {
        error.localizedDescription
            .lowercased()
            .contains(unsafeKeyword)
    }
}

/// LLM関連のエラー定義
///
/// Foundation Models 使用時に発生する可能性のあるエラーを定義します。
/// LocalizedError に準拠することで、ユーザーフレンドリーなエラーメッセージを提供できます。
enum LLMError: LocalizedError {
    /// モデルが利用できない（デバイス非対応、OS バージョン不足など）
    case modelUnavailable
    /// セッションの初期化に失敗
    case sessionNotInitialized
    /// 応答取得中のエラー
    case responseError(String)
    
    /// ユーザーに表示するエラーメッセージ
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

