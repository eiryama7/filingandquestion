//
//  ChatMessage.swift
//  filingandquestion
//
//  チャットメッセージのデータモデル
//

import Foundation

/// チャットメッセージの役割（ユーザーまたはアシスタント）
enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

/// チャットメッセージのデータ構造
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let text: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
