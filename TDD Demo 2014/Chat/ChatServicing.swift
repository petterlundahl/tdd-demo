//
//  ChatServicing.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-05.
//
import Foundation

struct MessagesResponse: Decodable {
  let moreExists: Bool
  let messages: [Message]
  
  struct Message: Decodable {
    let id: String
    let text: String
    /// ISO 8601 Date Format YYYY-MM-DDTHH:mm:ssZ
    let dateTime: String
    /// `nil` if from current user
    let sender: String?
  }
}

protocol ChatServicing {
  func loadMessages(pageNumber: Int) async throws -> MessagesResponse
  func sendMessage(text: String) async throws
}
