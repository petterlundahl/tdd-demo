//
//  ChatViewModel.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-04.
//
import SwiftUI

final class ChatViewModel: ObservableObject {
  
  enum ViewState: Equatable {
    case idle
    case loading
    case noContent
    case error
    case loaded([MessageGroup])
    
    struct MessageGroup: Equatable {
      let header: String
      let messages: [Message]
    }
  }
  
  @Published private(set) var state: ViewState = .idle
  @Published var typingMessage: String = ""
  
  func load() {
    //
  }
  
  func sendMessage() {
    typingMessage = ""
  }
}

extension ChatViewModel {
  static func mocked(state: ViewState) -> ChatViewModel {
    let vm = ChatViewModel()
    vm.state = state
    return vm
  }
}
