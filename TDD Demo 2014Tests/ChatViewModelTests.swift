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
  
  init() {
    
  }
  
  @Test("When no messages exist, Then state is noContent") func testNoContent() async throws {
    // Given
    let service = MockService()
    service.responseStub = .init(moreExists: false, messages: [])
    let sut = SUT(service: service)
    
    // When
    await sut.loadNext()
    
    // Then
    #expect(sut.state == .noContent)
  }
  
  @Test("When one page of messages exist, Then state is active with loading completed") func testLoadOnePage() async throws {
    // Given
    let service = MockService()
    service.responseStub = .init(moreExists: false, messages: [
      .init(id: "1", text: "Hello!", time: makeDate("2024-12-05 08:00"), sender: "Alice")
    ])
    let sut = SUT(service: service, currentDate: makeDate("2024-12-05 12:00"))
    
    // When
    await sut.loadNext()
    
    // Then
    switch sut.state {
    case .active(let loadingState, _):
      #expect(loadingState == .completed)
    default: Issue.record("Unexpected state")
    }
  }
  
  func makeDate(_ dateString: String) -> Date {
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
