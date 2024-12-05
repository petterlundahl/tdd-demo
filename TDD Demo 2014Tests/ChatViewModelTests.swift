//
//  ChatViewModelTests.swift
//  TDD Demo 2014Tests
//
//  Created by Petter Lundahl on 2024-12-02.
//

import Testing
@testable import TDD_Demo_2014

fileprivate typealias SUT = ChatViewModelLive

struct TDD_Demo_2014Tests {
  
  init() {
    
  }
  
  @Test("When no messages exist, Then state is noContent") func example() async throws {
    // Given
    let service = MockService()
    let sut = SUT(service: service)
    var observedStates: [ViewState] = []
    let sink = sut.$state.sink { observedStates.append($0) }
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(observedStates == [
      .idle,
      .active(.loading, []),
      .noContent
    ])
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
