//
//  Message.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-04.
//
import Foundation

struct Message: Identifiable, Equatable {
  enum State: Equatable {
    case sending
    case sent(String)
    case failedToSend
  }
  
  enum Sender: Equatable {
    case you
    case other(String)
  }
  
  let id = UUID()
  let text: String
  let sender: Sender
  let state: State
  
  init(text: String, sender: Sender, state: State) {
    self.text = text
    self.sender = sender
    self.state = state
  }
}
