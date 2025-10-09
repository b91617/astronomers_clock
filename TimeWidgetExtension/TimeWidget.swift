//
//  TimeWidgetExtension.swift
//  TimeWidgetExtension
//
//  Created by Justin Cheng on 2025/10/9.
//

import WidgetKit
import SwiftUI


// MARK: - Widget Provider
struct TimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeEntry {
        TimeEntry(
            date: Date(),
            currentTime: formatCurrentTime(Date()),
            julianDate: calculateJulianDate(Date())
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimeEntry) -> ()) {
        let entry = TimeEntry(
            date: Date(),
            currentTime: formatCurrentTime(Date()),
            julianDate: calculateJulianDate(Date())
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TimeEntry] = []
        let currentDate = Date()
        
        // Get the start of the next minute
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        guard var nextMinute = calendar.date(from: components) else {
            completion(Timeline(entries: [], policy: .atEnd))
            return
        }
        
        // If we're past the second 0, move to next minute
        let currentSecond = calendar.component(.second, from: currentDate)
        if currentSecond > 0 {
            nextMinute = calendar.date(byAdding: .minute, value: 1, to: nextMinute)!
        }
        
        // Generate entries for the next 60 minutes, each exactly on the minute mark
        for minuteOffset in 0..<60 {
            let entryDate = calendar.date(
                byAdding: .minute,
                value: minuteOffset,
                to: nextMinute
            )!
            let entry = TimeEntry(
                date: entryDate,
                currentTime: formatCurrentTime(entryDate),
                julianDate: calculateJulianDate(entryDate)
            )
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}


// MARK: - Widget Configuration
struct TimeWidget: Widget {
    let kind: String = "TimeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeProvider()) { entry in
            TimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time & Julian Date")
        .description("Shows current time and Julian Date")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


// MARK: - App Entry Point (for widget bundle)
@main
struct TimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeWidget()
    }
}
