//
//  ChatDateFormatter.swift
//  TDD Demo 2014
//
//  Created by Petter Lundahl on 2024-12-12.
//
import Foundation

struct ChatDateFormatter {
  
  struct DateComponents {
    let day: String
    let timeOfDay: String
  }
  
  private let isoFormatter = ISO8601DateFormatter()
  private let dayFormatter = DateFormatter()
  private let timeOfDayFormatter = DateFormatter()
  private let currentDate: () -> Date
  
  init(
    currentDate: @escaping () -> Date = { Date.now },
    currentTimeZone: TimeZone = TimeZone.current
  ) {
    self.currentDate = currentDate
    dayFormatter.timeZone = currentTimeZone
    timeOfDayFormatter.timeZone = currentTimeZone
    // E.g., "24 December"
    dayFormatter.dateFormat = "d MMMM"
    timeOfDayFormatter.dateFormat = "HH:mm"
  }
  
  func dateComponents(from iso8601String: String) -> DateComponents {
    guard let date = isoFormatter.date(from: iso8601String) else {
      fatalError("Invalid date \(iso8601String)")
    }
    var day = dayFormatter.string(from: date)
    let timeOfDay = timeOfDayFormatter.string(from: date)
    let todayDate = dayFormatter.string(from: currentDate()) ?? ""
    
    if todayDate == day {
      day = "Today"
    }
    
    return DateComponents(day: day, timeOfDay: timeOfDay)
  }
  
  func timeOfDayNow() -> String {
    dayFormatter.string(from: currentDate()) ?? "?"
  }
}
