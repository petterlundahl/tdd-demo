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
        LazyVStack(spacing: 8) {
          ForEach(groups, id: \.header) { group in
            Text(group.header)
            ForEach(group.messages) { message in
              ChatMessageView(message: message)
            }
          }
        }
        .padding()
      }
    }
  }
}

private struct ChatMessageView: View {
  let message: Message
  
  init(message: Message) {
    self.message = message
  }
  
  var body: some View {
    HStack {
      Spacer()
      Text(message.text)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray)
    )
    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
    .font(.title)
  }
}


#Preview("Loading") {
  ChatView(viewModel: .mocked(state: .loading))
}

#Preview("Loaded 5 Messages") {
  let state = ChatViewModel.ViewState.loaded([
    .init(header: "24 december", messages: [
      Message(text: "Merry Christmas!", sender: .other("Alice"), state: .sent, time: "14:45"),
      Message(text: "And to you as well!", sender: .you, state: .sent, time: "14:58"),
    ]),
    .init(header: "31 december", messages: [
      Message(text: "Happy new year!", sender: .other("Alice"), state: .sent, time: "23:58")
    ])
  ])
  ChatView(viewModel: .mocked(state: state))
}
