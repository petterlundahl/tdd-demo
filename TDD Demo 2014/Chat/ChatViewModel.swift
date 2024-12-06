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
    case completed
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
    state = .active(.loading, [])
    
    do {
      let response = try await service.loadMessages(pageNumber: 0)
      if response.messages.isEmpty {
        state = .noContent
      } else {
        let messages = response.messages.map { message in
          Message(id: message.id, text: message.text, sender: .other(message.sender ?? ""), state: .sent("08:00"))
        }
        if response.moreExists {
          state = .active(.canLoadMore, [ViewState.MessageGroup(header: "Today", messages: messages)])
        } else {
          state = .active(.completed, [ViewState.MessageGroup(header: "Today", messages: messages)])
        }
      }
    } catch {
      state = .active(.error("Something went wrong"), [])
    }
  }
  
  func sendMessage() {
  }
  
  func retry(message: Message) {
  }
}
