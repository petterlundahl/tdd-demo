//
//  ChatViewModelTests.swift
//  TDD Demo 2014Tests
//
//  Created by Petter Lundahl on 2024-12-02.
//

import Testing
@testable import TDD_Demo_2014
import Foundation
import Combine

fileprivate typealias SUT = ChatViewModelLive

@MainActor
struct ChatViewModelTests {
  
  final class Environment {
    var observedStates: [ViewState] = []
    var sink: Cancellable?
  }
  
  private let service: MockService
  private let sut: SUT
  private let environment: Environment
  
  private let simpleMessage = MessagesResponse.Message(
    id: "1",
    text: "Hello!",
    dateTime: "2025-01-05T08:30:00Z",
    sender: "Alice"
  )
  
  init() {
    service = MockService()
    sut = SUT(
      service: service,
      currentDate: { .makeDate("2025-01-05 09:00") },
      currentTimeZone: TimeZone.gmt
    )
    environment = Environment()
    environment.sink = sut.$state.sink { [weak environment] in environment?.observedStates.append($0) }
  }
  
  @Test("When no messages exist, Then state is noContent") func testNoContent() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: []))
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(sut.state == .noContent)
  }
  
  @Test("When one page of messages exist, Then state is active with loading completed") func testLoadFirstAndOnlyPage() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: [simpleMessage]))
    
    // When
    await sut.loadNext()
    
    // Then
    switch sut.state {
    case .active(let loadingState, _):
      #expect(loadingState == .completed)
    default: Issue.record("Unexpected state")
    }
  }
  
  @Test("When more than one page exists, Then state is active and more can be loaded after first load") func testLoadFirstOfManyPages() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: true, messages: [simpleMessage]))
    
    // When
    await sut.loadNext()
    
    // Then
    switch sut.state {
    case .active(let loadingState, _):
      #expect(loadingState == .canLoadMore)
    default: Issue.record("Unexpected state")
    }
  }
  
  @Test("State changes to loading before completed") func testStateChanges() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: [simpleMessage]))
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(environment.observedStates == [
      .idle,
      .active(.loading, []),
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "1", text: "Hello!", sender: .other("Alice"), state: .sent("08:30"))
      ])])
    ])
  }
  
  @Test("When loading fails, Then state is error") func testLoadError() async throws {
    // Given
      service.loadingResponse = .failWith(URLError(.timedOut))
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(sut.state == .active(.error("Something went wrong"), []))
  }
  
  @Test("Messages can be grouped by date, with correct time of day and sender") func testLoadMany() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: [
      .init(id: "1", text: "Merry Christmas!", dateTime: "2024-12-24T14:45:17Z", sender: "Alice"),
      .init(id: "2", text: "You too!", dateTime: "2024-12-24T14:58:19Z", sender: nil),
      .init(id: "3", text: "Happy new year!", dateTime: "2024-12-31T23:58:07Z", sender: "Bob"),
      .init(id: "4", text: "Hello guys!", dateTime: "2025-01-05T07:15:19Z", sender: nil),
      .init(id: "5", text: "Hey Friend!", dateTime: "2025-01-05T07:16:19Z", sender: "Alice"),
    ]))
    
    // When
    await sut.loadNext()
    
    // Then
    let expectedState = ViewState.active(.completed, [
      .init(header: "24 December", messages: [
        Message(id: "1", text: "Merry Christmas!", sender: .other("Alice"), state: .sent("14:45")),
        Message(id: "2", text: "You too!", sender: .you, state: .sent("14:58")),
      ]),
      .init(header: "31 December", messages: [
        Message(id: "3", text: "Happy new year!", sender: .other("Bob"), state: .sent("23:58"))
      ]),
      .init(header: "Today", messages: [
        Message(id: "4", text: "Hello guys!", sender: .you, state: .sent("07:15")),
        Message(id: "5", text: "Hey Friend!", sender: .other("Alice"), state: .sent("07:16"))
      ])
    ])
    #expect(sut.state == expectedState)
  }
  
  @Test("When loading more pages, then older messages are added to the list, and page number is incremented") func testLoadMorePages() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: true, messages: [
      .init(id: "4", text: "Hello guys!", dateTime: "2025-01-05T07:15:19Z", sender: nil),
      .init(id: "5", text: "Hey Friend!", dateTime: "2025-01-05T07:16:19Z", sender: "Alice")
    ]))
    
    // When
    await sut.loadNext()
    
    // Given
    service.loadingResponse = .ok(.init(moreExists: true, messages: [
      .init(id: "2", text: "You too!", dateTime: "2024-12-24T14:58:19Z", sender: nil),
      .init(id: "3", text: "Happy new year!", dateTime: "2024-12-31T23:58:07Z", sender: "Bob")
    ]))
    
    // When
    await sut.loadNext()
    
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: [
      .init(id: "1", text: "Merry Christmas!", dateTime: "2024-12-24T14:45:17Z", sender: "Alice")
    ]))
    
    // When
    await sut.loadNext()
    
    // Then
    let expectedState = ViewState.active(.completed, [
      .init(header: "24 December", messages: [
        Message(id: "1", text: "Merry Christmas!", sender: .other("Alice"), state: .sent("14:45")),
        Message(id: "2", text: "You too!", sender: .you, state: .sent("14:58")),
      ]),
      .init(header: "31 December", messages: [
        Message(id: "3", text: "Happy new year!", sender: .other("Bob"), state: .sent("23:58"))
      ]),
      .init(header: "Today", messages: [
        Message(id: "4", text: "Hello guys!", sender: .you, state: .sent("07:15")),
        Message(id: "5", text: "Hey Friend!", sender: .other("Alice"), state: .sent("07:16"))
      ])
    ])
    #expect(sut.state == expectedState)
    #expect(service.requestedPages == [1, 2, 3])
  }
  
  @Test("When loading the second page fails, previously loaded messages are not changed, and the state is error") func testLoadMorePagesWithErrors() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: true, messages: [
      .init(id: "5", text: "Hey Friend!", dateTime: "2025-01-05T07:16:19Z", sender: "Alice")
    ]))
    await sut.loadNext()
    service.loadingResponse = .failWith(URLError(.timedOut))
    
    // When
    await sut.loadNext()
    
    // Then
    let expectedState = ViewState.active(.error("Something went wrong"), [
      .init(header: "Today", messages: [
        Message(id: "5", text: "Hey Friend!", sender: .other("Alice"), state: .sent("07:16"))
      ])
    ])
    #expect(sut.state == expectedState)
  }
  
  @Test("When loading the next page fails, page number is not increased until after loading succeeds") func testLoadMorePagesWithErrorsCheckingPageNumber() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: true, messages: [
      .init(id: "2", text: "Latest Message", dateTime: "2025-01-05T07:16:19Z", sender: "Alice")
    ]))
    
    await sut.loadNext()
    
    service.loadingResponse = .failWith(URLError(.timedOut))
    
    // Trying to reload multiple times, with errors
    await sut.loadNext()
    await sut.loadNext()
    await sut.loadNext()
    
    service.loadingResponse = .ok(.init(moreExists: false, messages: [
      .init(id: "1", text: "Oldest Message", dateTime: "2025-01-05T07:15:19Z", sender: nil)
    ]))
    
    // When
    await sut.loadNext()
    
    // Then
    let expectedState = ViewState.active(.completed, [
      .init(header: "Today", messages: [
        Message(id: "1", text: "Oldest Message", sender: .you, state: .sent("07:15")),
        Message(id: "2", text: "Latest Message", sender: .other("Alice"), state: .sent("07:16"))
      ])
    ])
    #expect(sut.state == expectedState)
    #expect(service.requestedPages == [1, 2, 2, 2, 2])
  }
  
  @Test("When sending a message, Then typingMessage is cleared, And the message is sent") func testSendMessageSuccess() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: [simpleMessage]))
    service.sendingResponse = .ok("2")
    await sut.loadNext()
    
    // When
    sut.typingMessage = "Heeey!"
    await sut.sendMessage()
    
    // Then
    #expect(sut.typingMessage == "")
    #expect(service.sentMessageTexts == ["Heeey!"])
    #expect(sut.state == .active(.completed, [
      .init(header: "Today", messages: [
        .init(id: "1", text: "Hello!", sender: .other("Alice"), state: .sent("08:30")),
        .init(id: "2", text: "Heeey!", sender: .you, state: .sent("09:00"))
      ])
    ]))
  }
  
  @Test("When sending a message, Then it's state is sending before finally being sent") func testSendingMessage() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: []))
    service.sendingResponse = .ok("1")
    await sut.loadNext()
    
    // When
    sut.typingMessage = "Heeey!"
    await sut.sendMessage()
    
    // Then
    #expect(environment.observedStates == [
      .idle,
      .active(.loading, []),
      .noContent,
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "sending-1", text: "Heeey!", sender: .you, state: .sending)
      ])]),
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "1", text: "Heeey!", sender: .you, state: .sent("09:00"))
      ])])
    ])
  }
  
  @Test("When sending a message fails, Then it's state is failed") func testSendingMessageFailed() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: []))
    service.sendingResponse = .failWith(URLError(.networkConnectionLost))
    await sut.loadNext()
    
    // When
    sut.typingMessage = "Heeey!"
    await sut.sendMessage()
    
    // Then
    #expect(sut.state == .active(.completed, [
      .init(header: "Today", messages: [
        .init(id: "sending-1", text: "Heeey!", sender: .you, state: .failedToSend)
      ])
    ]))
  }
  
  @Test("When sending multiple messages, the temporary message IDs are generated uniquely") func testSendingMessageFailedWithUniqueID() async throws {
    // Given
    service.loadingResponse = .ok(.init(moreExists: false, messages: []))
    service.sendingResponse = .ok("1")
    await sut.loadNext()
    
    // When
    sut.typingMessage = "First"
    await sut.sendMessage()
    service.sendingResponse = .ok("2")
    sut.typingMessage = "Second"
    // Reset the previously collected states:
    environment.observedStates.removeAll()
    await sut.sendMessage()
    
    // Then
    
    #expect(environment.observedStates == [
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "1", text: "First", sender: .you, state: .sent("09:00")),
        .init(id: "sending-2", text: "Second", sender: .you, state: .sending)
      ])]),
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "1", text: "First", sender: .you, state: .sent("09:00")),
        .init(id: "2", text: "Second", sender: .you, state: .sent("09:00"))
      ])])
    ])
  }
  
  @Test("When retrying to send a failed message, Then it can be sent") func testResendingFailedMessage() async throws {
    // Given that the message fails to send
    service.loadingResponse = .ok(.init(moreExists: false, messages: []))
    service.sendingResponse = .failWith(URLError(.timedOut))
    await sut.loadNext()
    sut.typingMessage = "Failing message"
    await sut.sendMessage()
    
    guard let failedMessage = findNewestMessageInLatestState() else {
      return
    }
    
    // Reset the previously collected states:
    environment.observedStates.removeAll()
    service.sendingResponse = .ok("1")
    
    // When we retry the failing message
    await sut.retry(message: failedMessage)
    
    // Then the message should first be sending, then sent
    #expect(environment.observedStates == [
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "sending-1", text: "Failing message", sender: .you, state: .sending)
      ])]),
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "1", text: "Failing message", sender: .you, state: .sent("09:00"))
      ])])
    ])
    #expect(service.sentMessageTexts == ["Failing message", "Failing message"])
  }
  
  private func findNewestMessageInLatestState() -> Message? {
    guard let lastState = environment.observedStates.last else {
      Issue.record("Expected at least one state to be observed. 0 found")
      return nil
    }
    
    switch lastState {
    case .active(_, let messageGroups):
      guard let message = messageGroups.first?.messages.first else {
        Issue.record("Expected one message to be published in state")
        return nil
      }
      return message
    default: Issue.record("Unexpected state: \(lastState)")
    }
    return nil
  }
  
  // TODO:
  // Use the current time when sending a Message
  // Messages over a year old should include year in header
  // When sending the first message Today, the Today group should be added
  // When sending a message, the loading state should be unchanged
  // When text is empty, nothing should be sent
}

extension Date {
  static func makeDate(_ dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    return dateFormatter.date(from: dateString)!
  }
}

private final class MockService: ChatServicing {
  
  enum LoadResponse {
    case ok(MessagesResponse)
    case failWith(Error)
  }
  
  enum SendResponse {
    case ok(String)
    case failWith(Error)
  }
  
  var loadingResponse: LoadResponse = .failWith(URLError(.timedOut))
  var sendingResponse: SendResponse = .failWith(URLError(.timedOut))
  
  var requestedPages: [Int] = []
  var sentMessageTexts: [String] = []
  
  func loadMessages(pageNumber: Int) async throws -> MessagesResponse {
    requestedPages.append(pageNumber)
    switch loadingResponse {
    case .ok(let messagesResponse): return messagesResponse
    case .failWith(let error): throw error
    }
  }
  
  func sendMessage(text: String) async throws -> String {
    sentMessageTexts.append(text)
    switch sendingResponse {
    case .ok(let messagesId): return messagesId
    case .failWith(let error): throw error
    }
  }
}
