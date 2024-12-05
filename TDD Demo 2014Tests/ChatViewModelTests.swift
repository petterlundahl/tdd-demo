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

struct TDD_Demo_2014Tests {
  
  private let service: MockService
  private let sut: SUT
  
  private let simpleMessage = MessagesResponse.Message(
    id: "1",
    text: "Hello!",
    time: .makeDate("2024-12-05 08:00"),
    sender: "Alice"
  )
  
  init() {
    service = MockService()
    sut = SUT(service: service, currentDate: .makeDate("2024-12-05 08:00"))
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
        .init(id: "1", text: "Hello!", sender: .other("Alice"), state: .sent("08:00"))
      ])])
    ])
    
    sink.cancel()
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
  var responseStub: MessagesResponse?
  
  func loadMessages(pageNumber: Int) async throws -> MessagesResponse {
    if let responseStub { return responseStub }
    Issue.record("Response was not stubbed")
    throw "Response was not stubbed"
  }
  
  func sendMessage(text: String) async throws {
    
  }
}

extension String: Error { }
