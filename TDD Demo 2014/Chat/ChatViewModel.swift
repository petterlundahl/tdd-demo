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

@MainActor
final class ChatViewModelLive: ChatViewModel {
  
  
  
  @Published private(set) var state: ViewState = .idle
  @Published var typingMessage: String = ""
  
  private let service: ChatServicing
  private let currentDate: Date
  private let currentTimeZone: TimeZone
  private var nextPageNumber = 1
  
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
      let response = try await service.loadMessages(pageNumber: nextPageNumber)
      nextPageNumber += 1
      if response.messages.isEmpty {
        state = .noContent
      } else {
        var messageAndDays = response.messages.map { message in messageAndDay(from: message) }
        
        var currentGroups = currentMessageGroups
        if let oldestExistingGroup = currentGroups.first {
          let newMessagesToAdd = messageAndDays.filter { (message, day) in oldestExistingGroup.header == day }
            .map { message, _ in message }
          var copy = oldestExistingGroup.messages
          copy.insert(contentsOf: newMessagesToAdd, at: 0)
          currentGroups.removeFirst()
          currentGroups.insert(ViewState.MessageGroup(header: oldestExistingGroup.header, messages: copy), at: 0)
          messageAndDays.removeFirst(newMessagesToAdd.count)
        }
        
        var currentDay: String = ""
        var messagesInCurrentDay: [Message] = []
        
        for (message, day) in messageAndDays {
          if day == currentDay {
            messagesInCurrentDay.append(message)
          } else {
            if !messagesInCurrentDay.isEmpty {
              currentGroups.append(ViewState.MessageGroup(header: currentDay, messages: messagesInCurrentDay))
            }
            currentDay = day
            messagesInCurrentDay = [message]
          }
        }
        if !messagesInCurrentDay.isEmpty {
          currentGroups.append(ViewState.MessageGroup(header: currentDay, messages: messagesInCurrentDay))
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
