//
//  ChatView.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-04.
//

import SwiftUI

struct ChatView<ViewModel: ChatViewModel>: View {
  @ObservedObject private var viewModel: ViewModel
  
  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    VStack {
      switch viewModel.state {
      case .idle:
        Color.clear.onAppear { Task { await viewModel.loadNext() } }
      case .noContent:
        Text("This chat is empty! Write the first message")
        Spacer()
      case .active(let loadingState, let groups):
        LoadingView(state: loadingState) { Task { await viewModel.loadNext() } }
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(groups, id: \.header) { group in
              Text(group.header)
              ForEach(group.messages) { message in
                ChatMessageView(message: message) {
                  Task { await viewModel.sendMessage() }
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
        .frame(minHeight: CGFloat(40))
        .lineLimit(0)
      Button(action: { Task { await viewModel.sendMessage() }}) {
        Text("Send")
      }
    }
    .frame(minHeight: CGFloat(50))
    .padding()
  }
}

private struct LoadingView: View {
  let state: ViewState.LoadingState
  let reload: () -> Void
  
  var body: some View {
    switch state {
    case .canLoadMore:
      Button("Load more") {
        reload()
      }
    case .loading:
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(1.5)
    case .error(let message):
      VStack {
        Text(message)
        Button("Retry") {
          reload()
        }
      }
    case .loadedEverything:
      EmptyView()
    }
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


#Preview("Loading first batch") {
  ChatView(viewModel: ChatPreviewModel(state: .active(.loading, [])))
}

#Preview("Can load more") {
  ChatView(viewModel: ChatPreviewModel(state: .active(.canLoadMore, [
    .init(header: "24 december", messages: [
      Message(text: "Merry Christmas!", sender: .other("Alice"), state: .sent("14:45"))
      ])
  ])))
}

#Preview("Failed to load more") {
  ChatView(viewModel: ChatPreviewModel(state: .active(.error("Failed to load older messages"), [
    .init(header: "24 december", messages: [
      Message(text: "Merry Christmas!", sender: .other("Alice"), state: .sent("14:45"))
      ])
  ])))
}

#Preview("Loading more") {
  ChatView(viewModel: ChatPreviewModel(state: .active(.loading, [
    .init(header: "24 december", messages: [
      Message(text: "Merry Christmas!", sender: .other("Alice"), state: .sent("14:45"))
      ])
  ])))
}

#Preview("No messages exist") {
  ChatView(viewModel: ChatPreviewModel(state: .noContent))
}

#Preview("Loaded 5 Messages") {
  let state = ViewState.active(.loadedEverything, [
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
  ChatView(viewModel: ChatPreviewModel(state: state))
}

#Preview("Messages being sent, and failed to send") {
  let state = ViewState.active(.loadedEverything, [
    .init(header: "Today", messages: [
      Message(text: "Hello guys! Do you want to do something fun today like maybe visit an owl sanctuary?", sender: .you, state: .failedToSend),
      Message(text: "We can bring snacks and beverages", sender: .you, state: .sending)
    ])
  ])
  ChatView(viewModel: ChatPreviewModel(state: state, typing: "And then maybe we can do something else like going to a movie"))
}
