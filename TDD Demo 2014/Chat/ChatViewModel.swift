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
    case noContent
    case active(LoadingState, [MessageGroup])
    
    struct MessageGroup: Equatable {
      let header: String
      let messages: [Message]
    }
    
    enum LoadingState: Equatable {
      case canLoadMore
      case loading
      case error(String)
      case loadedEverything
    }
  }
  
  @Published private(set) var state: ViewState = .idle
  @Published var typingMessage: String = ""
  
  func loadNext() {
    //
  }
  
  func sendMessage() {
    typingMessage = ""
  }
  
  func retry(message: Message) {
    //message.state = .sent("Now")
  }
}

extension ChatViewModel {
  static func mocked(state: ViewState, typing: String = "") -> ChatViewModel {
    let vm = ChatViewModel()
    vm.state = state
    vm.typingMessage = typing
    return vm
  }
}
