//
//  ChatView.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-04.
//

import SwiftUI

struct ChatView: View {
  @ObservedObject private var viewModel: ChatViewModel
  
  init(viewModel: ChatViewModel) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    VStack {
      switch viewModel.state {
      case .idle:
        Color.clear.onAppear { viewModel.load() }
      case .loading:
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(2)
          Spacer()
        }
      case .noContent:
        Text("You don't have any  yet!")
      case .error:
        Text("Something went wrong. Please try again later!")
      case .loaded(let groups):
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(groups, id: \.header) { group in
              Text(group.header)
              ForEach(group.messages) { message in
                ChatMessageView(message: message) {
                  viewModel.sendMessage()
                }
              }
            }
          }
          .padding()
        }
      }
    }
    HStack {
      TextField("Message...", text: $viewModel.typingMessage)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .frame(minHeight: CGFloat(30))
      Button(action: { viewModel.sendMessage() }) {
        Text("Send")
      }
    }
    .frame(minHeight: CGFloat(50))
    .padding()
  }
}

private struct ChatMessageView: View {
  let message: Message
  let time: String?
  let retrySend: () -> Void
  
  init(message: Message, retrySend: @escaping () -> Void) {
    self.message = message
    if case .sent(let time) = message.state {
      self.time = time
    } else {
      time = nil
    }
    self.retrySend = retrySend
  }
  
  var body: some View {
    HStack(spacing: 16) {
      switch message.sender {
      case .you:
        Spacer()
        MessageContentView(text: message.text, time: time)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(message.state == .failedToSend ? Color.pink : Color.blue)
          )
          .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
          .font(.title2)
          .foregroundStyle(.white)
        if message.state == .sending {
          ProgressView()
        } else if message.state == .failedToSend {
          Button(action: {
            retrySend()
          }) {
              Image(systemName: "arrow.clockwise")
              .scaleEffect(2)
              .foregroundColor(.black)
          }
        }
      case .other(let sender):
        Image(systemName: "person.circle.fill")
          .scaleEffect(1.5)
        MessageContentView(text: message.text, sender: sender, time: time)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color(UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)))
          )
          .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
        Spacer()
      }
    }
  }
}

private struct MessageContentView: View {
  private let text: String
  private let sender: String?
  private let time: String?
  
  init(text: String, sender: String? = nil, time: String? = nil) {
    self.text = text
    self.sender = sender
    self.time = time
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      if let sender {
        Text(sender)
          .font(.subheadline).bold()
      }
      Text(text)
        .font(.title2)
      if let time {
        Text(time)
          .font(.footnote)
      }
    }
    .padding()
  }
}


#Preview("Loading") {
  ChatView(viewModel: .mocked(state: .loading))
}

#Preview("Loaded 5 Messages") {
  let state = ChatViewModel.ViewState.loaded([
    .init(header: "24 december", messages: [
      Message(text: "Merry Christmas!", sender: .other("Alice"), state: .sent("14:45")),
      Message(text: "And to you as well!", sender: .you, state: .sent("14:58")),
    ]),
    .init(header: "31 december", messages: [
      Message(text: "Happy new year!", sender: .other("Bob"), state: .sent("23:58"))
    ]),
    .init(header: "Today", messages: [
      Message(text: "Hello guys! Do you want to do something fun today like maybe visit an owl sanctuary?", sender: .you, state: .sent("07:15")),
      Message(text: "For sure! That sounds like an excellent idea!", sender: .other("Alice"), state: .sent("07:16"))
    ])
  ])
  ChatView(viewModel: .mocked(state: state))
}

#Preview("Messages being sent, and failed to send") {
  let state = ChatViewModel.ViewState.loaded([
    .init(header: "Today", messages: [
      Message(text: "Hello guys! Do you want to do something fun today like maybe visit an owl sanctuary?", sender: .you, state: .failedToSend),
      Message(text: "We can bring snacks and beverages", sender: .you, state: .sending)
    ])
  ])
  ChatView(viewModel: .mocked(state: state))
}
