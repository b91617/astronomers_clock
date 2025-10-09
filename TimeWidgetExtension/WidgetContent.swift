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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Current UTC Time
            Text(entry.currentTime)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.semibold)
            
            Spacer().frame(height: 0)
            
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
        .padding()
    }
}


// MARK: - Preview
struct TimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        TimeWidgetEntryView(entry: TimeEntry(
            date: Date(),
            currentTime: formatCurrentTime(Date()),
            julianDate: calculateJulianDate(Date())
        ))
        // We comment out the widget context and just force a frame
//         .previewContext(WidgetPreviewContext(family: .systemSmall))
        .frame(width: 364, height: 170)
    }
}
