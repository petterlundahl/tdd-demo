//
//  ContentView.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-02.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    ChatView(viewModel: ChatViewModelLive(service: DemoService()))
  }
}

#Preview {
    ContentView()
}

final class DemoService: ChatServicing {
  private var msgCount = 100
  private var failSend = true
  
  private let messages: [MessagesResponse.Message] = [
    .init(id: "1", text: "Hey, how's it going?", dateTime: "2024-06-15T09:00:00Z", sender: "Alice"),
    .init(id: "2", text: "Not bad, just working. You?", dateTime: "2024-06-15T09:05:00Z", sender: "Bob"),
    .init(id: "3", text: "Same here, just finishing up some tasks.", dateTime: "2024-06-15T09:06:00Z", sender: nil),
    .init(id: "4", text: "Want to grab lunch later?", dateTime: "2024-06-15T09:10:00Z", sender: "Alice"),
    .init(id: "5", text: "Sure! What time?", dateTime: "2024-06-15T09:11:00Z", sender: "Bob"),
    .init(id: "6", text: "How about 1 PM?", dateTime: "2024-06-15T09:12:00Z", sender: nil),
    .init(id: "7", text: "Sounds good. Where?", dateTime: "2024-06-15T09:15:00Z", sender: "Alice"),
    .init(id: "8", text: "Let's meet at the park.", dateTime: "2024-06-15T09:16:00Z", sender: "Bob"),
    .init(id: "9", text: "Perfect, see you then.", dateTime: "2024-06-15T09:17:00Z", sender: nil),
    .init(id: "10", text: "Can't wait!", dateTime: "2024-06-15T09:18:00Z", sender: "Alice"),
    .init(id: "11", text: "How have you been lately?", dateTime: "2024-06-20T10:00:00Z", sender: "Bob"),
    .init(id: "12", text: "I've been great, thanks for asking.", dateTime: "2024-06-20T10:05:00Z", sender: nil),
    .init(id: "13", text: "I saw a new movie last night.", dateTime: "2024-06-20T10:10:00Z", sender: "Alice"),
    .init(id: "14", text: "Oh really? What movie?", dateTime: "2024-06-20T10:12:00Z", sender: "Bob"),
    .init(id: "15", text: "It was a sci-fi thriller, pretty cool.", dateTime: "2024-06-20T10:15:00Z", sender: nil),
    .init(id: "16", text: "Nice! I need to watch it.", dateTime: "2024-06-20T10:20:00Z", sender: "Alice"),
    .init(id: "17", text: "What else have you been up to?", dateTime: "2024-06-25T11:00:00Z", sender: "Bob"),
    .init(id: "18", text: "Just relaxing. Taking a break from work.", dateTime: "2024-06-25T11:05:00Z", sender: nil),
    .init(id: "19", text: "That's good to hear!", dateTime: "2024-06-25T11:10:00Z", sender: "Alice"),
    .init(id: "20", text: "What about you, anything exciting?", dateTime: "2024-06-25T11:12:00Z", sender: "Bob"),
    .init(id: "21", text: "Well, I started a new project at work.", dateTime: "2024-06-25T11:15:00Z", sender: nil),
    .init(id: "22", text: "That's awesome! What kind of project?", dateTime: "2024-06-25T11:20:00Z", sender: "Alice"),
    .init(id: "23", text: "It's a software development project, quite challenging.", dateTime: "2024-06-25T11:22:00Z", sender: nil),
    .init(id: "24", text: "Sounds interesting, good luck with that!", dateTime: "2024-06-25T11:25:00Z", sender: "Bob"),
    .init(id: "25", text: "Thanks! How’s your work going?", dateTime: "2024-06-30T12:00:00Z", sender: nil),
    .init(id: "26", text: "Busy as usual, but manageable.", dateTime: "2024-06-30T12:05:00Z", sender: "Alice"),
    .init(id: "27", text: "Anything fun planned for the weekend?", dateTime: "2024-06-30T12:10:00Z", sender: "Bob"),
    .init(id: "28", text: "Thinking about going hiking.", dateTime: "2024-06-30T12:15:00Z", sender: nil),
    .init(id: "29", text: "That sounds like fun! Where?", dateTime: "2024-07-05T13:00:00Z", sender: "Alice"),
    .init(id: "30", text: "Up in the mountains, should be a nice view.", dateTime: "2024-07-05T13:05:00Z", sender: "Bob")
]
  
  func loadMessages(pageNumber: Int) async throws -> MessagesResponse {
    try await Task.sleep(for: .seconds(1))
    
    let totalMessages = messages.count
    
    // Calculate the range of messages for the given page
    let endIndex = max(0, totalMessages - ((pageNumber - 1) * 5))
    let startIndex = max(0, endIndex - 5)
    
    // Return the slice of messages for this page
    let result = Array(messages[startIndex..<endIndex])
    
    return MessagesResponse(moreExists: startIndex > 0, messages: result)
  }
  
  func sendMessage(text: String) async throws -> String {
    msgCount += 1
    try await Task.sleep(for: .seconds(2))
    failSend = !failSend
    if failSend {
      throw URLError(.timedOut)
    }
    return String(msgCount)
  }
}
