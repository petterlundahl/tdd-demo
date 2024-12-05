//
//  ChatPreviewModel.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-05.
//
import SwiftUI

final class ChatPreviewModel: ChatViewModel {
  @Published private(set) var state: ViewState
  @Published var typingMessage: String = ""
  
  init(state: ViewState, typing: String = "") {
    self.state = state
    self.typingMessage = typing
  }
  
  func loadNext() {}
  
  func sendMessage() {}
  
  func retry(message: Message) {}
}
