//
//  ChatViewModelTests.swift
//  TDD Demo 2014Tests
//
//  Created by Petter Lundahl on 2024-12-02.
//

import Testing
@testable import TDD_Demo_2014
import Foundation

fileprivate typealias SUT = ChatViewModelLive

struct ChatViewModelTests {
  
  private let service: MockService
  private let sut: SUT
  
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
      currentDate: .makeDate("2025-01-05 09:00"),
      currentTimeZone: TimeZone.gmt
    )
  }
  
  @Test("When no messages exist, Then state is noContent") func testNoContent() async throws {
    // Given
    service.responseStub = .init(moreExists: false, messages: [])
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(sut.state == .noContent)
  }
  
  @Test("When one page of messages exist, Then state is active with loading completed") func testLoadFirstAndOnlyPage() async throws {
    // Given
    service.responseStub = .init(moreExists: false, messages: [simpleMessage])
    
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
    service.responseStub = .init(moreExists: true, messages: [simpleMessage])
    
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
    service.responseStub = .init(moreExists: false, messages: [simpleMessage])
    var observedStates: [ViewState] = []
    let sink = sut.$state.sink { observedStates.append($0) }
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(observedStates == [
      .idle,
      .active(.loading, []),
      .active(.completed, [.init(header: "Today", messages: [
        .init(id: "1", text: "Hello!", sender: .other("Alice"), state: .sent("08:30"))
      ])])
    ])
    
    sink.cancel()
  }
  
  @Test("When loading fails, Then state is error") func testLoadError() async throws {
    // Given
    service.loadError = URLError(.timedOut)
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(sut.state == .active(.error("Something went wrong"), []))
  }
  
  @Test("Messages can be grouped by date, with correct time of day and sender") func testLoadMany() async throws {
    // Given
    service.responseStub = .init(moreExists: false, messages: [
      .init(id: "1", text: "Merry Christmas!", dateTime: "2024-12-24T14:45:17Z", sender: "Alice"),
      .init(id: "2", text: "You too!", dateTime: "2024-12-24T14:58:19Z", sender: nil),
      .init(id: "3", text: "Happy new year!", dateTime: "2024-12-31T23:58:07Z", sender: "Bob"),
      .init(id: "4", text: "Hello guys!", dateTime: "2025-01-05T07:15:19Z", sender: nil),
      .init(id: "5", text: "Hey Friend!", dateTime: "2025-01-05T07:16:19Z", sender: "Alice"),
    ])
    
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
  
}

extension Date {
  static func makeDate(_ dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    return dateFormatter.date(from: dateString)!
  }
}

private final class MockService: ChatServicing {
  var loadError: Error?
  var responseStub: MessagesResponse?
  
  func loadMessages(pageNumber: Int) async throws -> MessagesResponse {
    if let loadError { throw loadError }
    if let responseStub { return responseStub }
    Issue.record("Response was not stubbed")
    throw URLError(.timedOut)
  }
  
  func sendMessage(text: String) async throws {
    
  }
}
