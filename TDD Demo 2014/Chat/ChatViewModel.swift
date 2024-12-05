//
//  ChatViewModel.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-04.
//
import SwiftUI

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

protocol ChatViewModel: ObservableObject {
  var state: ViewState { get }
  var typingMessage: String { get set }
  func loadNext() async
  func sendMessage() async
  func retry(message: Message) async
}

final class ChatViewModelLive: ChatViewModel {
  
  @Published private(set) var state: ViewState = .idle
  @Published var typingMessage: String = ""
  
  private let service: ChatServicing
  private let currentDate: Date
  
  init(
    service: ChatServicing,
    currentDate: Date = Date.now
  ) {
    self.service = service
    self.currentDate = currentDate
  }
  
  func loadNext() async {
    
  }
  
  func sendMessage() {
  }
  
  func retry(message: Message) {
  }
}


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
