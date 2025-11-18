//
//  ChatMessage.swift
//  filingandquestion
//
//  チャットメッセージのデータモデル
//  ユーザーと AI アシスタントのメッセージを表現します
//

import Foundation

/// チャットメッセージの役割（ユーザーまたはアシスタント）
///
/// - user: ユーザーからのメッセージ
/// - assistant: AI アシスタントからの応答メッセージ
enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

/// チャットメッセージのデータ構造
///
/// このstructは以下のプロトコルに準拠しています:
/// - Identifiable: SwiftUI の ForEach で使用するため
/// - Codable: 将来的な永続化（保存/読み込み）のため
struct ChatMessage: Identifiable, Codable {
    /// メッセージの一意識別子（SwiftUI のリスト表示に必要）
    let id: UUID
    
    /// メッセージの送信者（ユーザー or アシスタント）
    let role: MessageRole
    
    /// メッセージの本文
    let text: String
    
    /// メッセージが作成された時刻
    let timestamp: Date
    
    /// イニシャライザ
    /// - Parameters:
    ///   - id: メッセージID（デフォルトで新規UUID生成）
    ///   - role: メッセージの役割
    ///   - text: メッセージテキスト
    ///   - timestamp: タイムスタンプ（デフォルトで現在時刻）
    init(id: UUID = UUID(), role: MessageRole, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
