//
//  ChatViewModel.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-04.
//
import SwiftUI
import Foundation

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
  private let currentTimeZone: TimeZone
  
  init(
    service: ChatServicing,
    currentDate: Date = Date.now,
    currentTimeZone: TimeZone = TimeZone.current
  ) {
    self.service = service
    self.currentDate = currentDate
    self.currentTimeZone = currentTimeZone
  }
  
  func loadNext() async {
    state = .active(.loading, [])
    
    do {
      let response = try await service.loadMessages(pageNumber: 0)
      if response.messages.isEmpty {
        state = .noContent
      } else {
        var currentGroups = currentMessageGroups
        let messageAndDays = response.messages.map { message in messageAndDay(from: message) }
        
        for (message, day) in messageAndDays {
          let matchingGroup = currentGroups.first { $0.header == day } ?? ViewState.MessageGroup(header: day, messages: [])
          var copy = matchingGroup.messages
          copy.append(message)
          currentGroups.removeAll { $0.header == day }
          currentGroups.append(ViewState.MessageGroup(header: day, messages: copy))
        }
        
        if response.moreExists {
          state = .active(.canLoadMore, currentGroups)
        } else {
          state = .active(.completed, currentGroups)
        }
      }
    } catch {
      state = .active(.error("Something went wrong"), [])
    }
  }
  
  private var currentMessageGroups: [ViewState.MessageGroup] {
    return switch state {
    case .active(_, let groups): groups
    default: []
    }
  }
  
  private func messageAndDay(from message: MessagesResponse.Message) -> (Message, String) {
    let (day, time) = dateComponents(from: message.dateTime)
    let sender: Message.Sender = (message.sender != nil) ? .other(message.sender!) : .you
    let result = Message(id: message.id, text: message.text, sender: sender, state: .sent(time))
    return (result, day)
  }
  
  private func dateComponents(from iso8601String: String) -> (String, String) {
    let isoFormatter = ISO8601DateFormatter()
    let displayDateFormatter = DateFormatter()
    let displayTimeFormatter = DateFormatter()
    
    // Define date and time output formats
    displayDateFormatter.dateFormat = "d MMMM" // E.g., "24 December"
    displayDateFormatter.timeZone = currentTimeZone
    
    displayTimeFormatter.dateFormat = "HH:mm" // E.g., "14:30"
    displayTimeFormatter.timeZone = currentTimeZone
    
    // Parse the ISO 8601 date string
    guard let date = isoFormatter.date(from: iso8601String) else {
      fatalError()
    }
    // Format the date and time
    var formattedDate = displayDateFormatter.string(from: date)
    let formattedTime = displayTimeFormatter.string(from: date)
    
    if (displayDateFormatter.string(from: currentDate) ?? "") == formattedDate {
      formattedDate = "Today"
    }
    
    return (formattedDate, formattedTime)
  }
  
  func sendMessage() {
  }
  
  func retry(message: Message) {
  }
}
