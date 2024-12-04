//
//  NoteListView.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-02.
//

import SwiftUI

struct Note: Identifiable {
  enum Priority {
    case low
    case medium
    case high
  }
  
  let id = UUID()
  let text: String
  let priority: Priority
  let completed: Bool
  
  init(text: String, priority: Priority, completed: Bool = false) {
    self.text = text
    self.priority = priority
    self.completed = completed
  }
}

enum ViewState {
  case idle
  case loading
  case noContent
  case error
  case loaded([Note])
}

protocol NoteListStateProviding: ObservableObject {
  var state: ViewState { get }
  func load()
  func toggleCompletion(of: Note)
}

final class NoteListViewModel: NoteListStateProviding {
  func load() {
    //
  }
  
  func toggleCompletion(of: Note) {
    //
  }
  
  @Published private(set) var state: ViewState = .idle
}

struct NoteListView<ViewModel: NoteListStateProviding>: View {
  @ObservedObject private var viewModel: ViewModel
  
  init(viewModel: ViewModel) {
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
      Text("You don't have any TODOs yet!")
    case .error:
      Text("Something went wrong. Please try again later!")
    case .loaded(let notes):
      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(notes) { note in
            HStack {
              /*@START_MENU_TOKEN@*/Text(note.text)/*@END_MENU_TOKEN@*/
              Spacer()
              Button {
                viewModel.toggleCompletion(of: note)
              } label: {
                Image(systemName: note.completed ? "checkmark.circle.fill" : "circle")
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(color(forPriority: note.priority))
            )
            .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
            .font(.title)
          }
        }
        .padding()
      }
    }
  }
  
  private func color(forPriority priority: Note.Priority) -> Color {
    switch priority {
    case .low: .yellow
    case .medium: .accentColor
    case .high: .red
    }
  }
}

final class MockViewModel: NoteListStateProviding {
  
  @Published private(set) var state: ViewState
  init(state: ViewState) {
    self.state = state
  }
  
  func load() {
    // No action
  }
  
  func toggleCompletion(of note: Note) {
    
  }
}

#Preview("Loading") {
  NoteListView(viewModel: MockViewModel(state: .loading))
}

#Preview("Loaded 3 Notes") {
  NoteListView(viewModel: MockViewModel(state: .loaded([
    .init(text: "Call the police", priority: .high),
    .init(text: "Take out the trash", priority: .medium),
    .init(text: "Plan for retirement", priority: .low),
    .init(text: "Prepare for Y2K", priority: .high, completed: true)
  ])))
}
