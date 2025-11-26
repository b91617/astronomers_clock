//
//  WidgetContent.swift
//  Astronomer's Clock
//
//  Created by Justin Cheng on 2025/11/25.
//

import WidgetKit
import SwiftUI


// MARK: - Widget Entry
struct TimeEntry: TimelineEntry {
    let date: Date
    let currentTime: String
    let julianDate: Double
}


// MARK: - Helper Functions
func UTCDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}

func UTCTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

func formatCurrentTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy/MM/dd HH:mm 'UTC'"
    return formatter.string(from: date)
}

func calculateJulianDate(_ date: Date) -> Double {
    // Convert to Julian Date
    // JD = (Unix timestamp / 86400) + 2440587.5
    let unixTimestamp = date.timeIntervalSince1970
    let julianDate = (unixTimestamp / 86400.0) + 2440587.5
    return julianDate
}


// MARK: - Widget View
struct TimeWidgetEntryView: View {
    var entry: TimeEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if family == .systemSmall{
                // Current UTC Time
                Text(UTCDate(entry.date))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                Text(UTCTime(entry.date))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, -7)
                    .baselineOffset(5)
                
                // Julian Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("JD")
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.3f", entry.julianDate))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                
                // Modified Julian Date
                if entry.julianDate > 0 {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MJD")
                            .font(.caption2)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.5f", entry.julianDate - 2400000.5))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                }
                
            } else {
                // Current UTC Time
                Text(entry.currentTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
                    .baselineOffset(5)

                // Julian Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("Julian Date (JD)")
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.5f", entry.julianDate))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                
                // Modified Julian Date
                if entry.julianDate > 0 {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modified Julian Date (MJD)")
                            .font(.caption2)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.5f", entry.julianDate - 2400000.5))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
    }
}


// MARK: - Preview
struct TimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimeWidgetEntryView(entry: TimeEntry(
                date: Date(),
                currentTime: formatCurrentTime(Date()),
                julianDate: calculateJulianDate(Date())
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            .frame(width: 170, height: 170)
            
            TimeWidgetEntryView(entry: TimeEntry(
                date: Date(),
                currentTime: formatCurrentTime(Date()),
                julianDate: calculateJulianDate(Date())
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .frame(width: 364, height: 170)
        }
    }
}
