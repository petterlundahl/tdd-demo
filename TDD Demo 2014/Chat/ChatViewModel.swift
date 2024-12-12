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

@MainActor
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
  private let dateFormatter: ChatDateFormatter
  private var nextPageNumber = 1
  
  init(
    service: ChatServicing,
    currentDate: @escaping () -> Date = { Date.now },
    currentTimeZone: TimeZone = TimeZone.current
  ) {
    self.service = service
    self.dateFormatter = ChatDateFormatter(
      currentDate: currentDate,
      currentTimeZone: currentTimeZone
    )
  }
  
  func loadNext() async {
    state = .active(.loading, currentMessageGroups)
    
    do {
      let response = try await service.loadMessages(pageNumber: nextPageNumber)
      nextPageNumber += 1
      if response.messages.isEmpty {
        state = .noContent
      } else {
        let messageGroups = createGroups(fromLoadedMessages: response.messages)
        
        if response.moreExists {
          state = .active(.canLoadMore, messageGroups)
        } else {
          state = .active(.completed, messageGroups)
        }
      }
    } catch {
      state = .active(.error("Something went wrong"), currentMessageGroups)
    }
  }
  
  private func createGroups(fromLoadedMessages messages: [MessagesResponse.Message]) -> [ViewState.MessageGroup] {
    var messageAndDays = messages.map { message in messageAndDay(from: message) }
    
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
    var newGroups: [ViewState.MessageGroup] = []
    
    for (message, day) in messageAndDays {
      if day == currentDay {
        messagesInCurrentDay.append(message)
      } else {
        if !messagesInCurrentDay.isEmpty {
          newGroups.append(ViewState.MessageGroup(header: currentDay, messages: messagesInCurrentDay))
        }
        currentDay = day
        messagesInCurrentDay = [message]
      }
    }
    if !messagesInCurrentDay.isEmpty {
      newGroups.append(ViewState.MessageGroup(header: currentDay, messages: messagesInCurrentDay))
    }
    
    currentGroups.insert(contentsOf: newGroups, at: 0)
    return currentGroups
  }
  
  private var currentMessageGroups: [ViewState.MessageGroup] {
    return switch state {
    case .active(_, let groups): groups
    default: []
    }
  }
  
  private func messageAndDay(from message: MessagesResponse.Message) -> (Message, String) {
    let dateComponents = dateFormatter.dateComponents(from: message.dateTime)
    let sender: Message.Sender = (message.sender != nil) ? .other(message.sender!) : .you
    let result = Message(id: message.id, text: message.text, sender: sender, state: .sent(dateComponents.timeOfDay))
    return (result, dateComponents.day)
  }
  
  func sendMessage() async {
    let messageText = typingMessage
    typingMessage = ""
    let pendingMessage = Message(id: "sending-1", text: messageText, sender: .you, state: .sending)
    appendReplacing(previousId: nil, newMessage: pendingMessage)
    do {
      let messageId = try await service.sendMessage(text: messageText)
      let message = Message(id: messageId, text: messageText, sender: .you, state: .sent("09:00"))
      appendReplacing(previousId: pendingMessage.id, newMessage: message)
    } catch {
      let message = Message(id: pendingMessage.id, text: messageText, sender: .you, state: .failedToSend)
      appendReplacing(previousId: pendingMessage.id, newMessage: message)
    }
  }
  
  private func appendReplacing(previousId: String?, newMessage: Message) {
    var currentGroups = currentMessageGroups
    if let mostRecentGroup = currentGroups.last {
      var messages = mostRecentGroup.messages
      if let previousId {
        messages.removeAll { $0.id == previousId }
      }
      messages.append(newMessage)
      currentGroups.removeLast()
      currentGroups.append(.init(header: mostRecentGroup.header, messages: messages))
      self.state = .active(.completed, currentGroups)
    } else {
      let group = ViewState.MessageGroup(header: "Today", messages: [newMessage])
      self.state = .active(.completed, [group])
    }
  }
  
  func retry(message: Message) async {
  }
}
