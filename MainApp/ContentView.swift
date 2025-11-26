//
//  ContentView.swift
//  Astronomer's Clock
//
//  Created by Justin Cheng on 2025/10/9.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var timeZoneOffset: Double = 0.0
    @State private var tzInputString: String = "0"
    
    @State private var selectedDate = Date()
    
    // We use String states for the text fields so the user can type
    // comfortably without the numbers jumping around until they hit Enter.
    @State private var jdString: String = ""
    @State private var mjdString: String = ""
    
    // Timer to update "Now" if needed, or just for reference
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var datePickerBinding: Binding<Date> {
        Binding(
            get: { self.selectedDate },
            set: { newValue in
                // 1. Create a calendar (use current or gregorian)
                let calendar = Calendar.current
                
                // 2. Strip the seconds/nanoseconds by only keeping minute & up
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: newValue)
                let cleanDate = calendar.date(from: components) ?? newValue
                
                // 3. Save the "clean" date (triggering the .onChange sync automatically)
                self.selectedDate = cleanDate
            }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Header
            HStack {
                Image(systemName: "clock")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Julian Dates Converter")
                    .font(.headline)
                Spacer()
                Button("Set to Now") {
                    updateAll(fromDate: Date())
                }
            }
            
            Divider()
            
            // MARK: - 1. Calendar Date Section
            GroupBox(label: Label("Calendar Date", systemImage: "calendar")) {
                HStack(spacing: 15) {
                    DatePicker("", selection: datePickerBinding, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.stepperField)
                            .environment(\.timeZone, TimeZone(secondsFromGMT: Int(timeZoneOffset * 3600))!)
                            .onChange(of: selectedDate) { newDate in
                                syncTextFields(from: newDate)
                            }
                    
                    HStack(spacing: 3) {
                        Text("UTC")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        
                        TextField("Offset", text: $tzInputString)
                            .frame(width: 65)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .onSubmit {
                                updateTimeZone(fromString: tzInputString)
                            }
                        
                        Stepper("", value: $timeZoneOffset, in: -12...14, step: 1)
                            .labelsHidden()
                            .onChange(of: timeZoneOffset) { newValue in
                                let sign = newValue > 0 ? "+" : ""
                                tzInputString = "\(sign)\(String(format: "%g", newValue))"
                            }
                        }
                    }
                }
                .padding(10)
            
            // MARK: - 2. Julian Date (JD) Section
            GroupBox(label: Label("Julian Date (JD)", systemImage: "123.rectangle")) {
                HStack {
                    TextField("Enter JD", text: $jdString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit {
                            // Convert String -> Double -> Date
                            if let jdValue = Double(jdString) {
                                let newDate = dateFromJD(jdValue)
                                updateAll(fromDate: newDate)
                            }
                        }
                    
                    Button(action: { copyToClipboard(jdString) }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help("Copy JD")
                }
                .padding(10)
            }
            
            // MARK: - 3. Modified Julian Date (MJD) Section
            GroupBox(label: Label("Modified Julian Date (MJD)", systemImage: "number.square")) {
                HStack {
                    TextField("Enter MJD", text: $mjdString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit {
                            // Convert MJD String -> Double -> Date
                            if let mjdValue = Double(mjdString) {
                                let jdValue = mjdValue + 2400000.5
                                let newDate = dateFromJD(jdValue)
                                updateAll(fromDate: newDate)
                            }
                        }
                    
                    Button(action: { copyToClipboard(mjdString) }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help("Copy MJD")
                }
                .padding(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400) // Set a good default window size for Mac
        .onAppear {
            // When initialize the app
            updateAll(fromDate: Date())
        }
    }
    
    // MARK: - Logic Functions
    
    func updateTimeZone(fromString input: String) {
        // Case 1: Handle "6:30" format
        if input.contains(":") {
            let parts = input.split(separator: ":").map { Double($0) ?? 0 }
            if parts.count == 2 {
                let hours = parts[0]
                // Add or subtract minutes based on sign of hours
                let minutes = (hours >= 0) ? (parts[1] / 60.0) : -(parts[1] / 60.0)
                timeZoneOffset = hours + minutes
            }
        }
        // Case 2: Handle standard "6.5" double format
        else if let doubleValue = Double(input) {
            timeZoneOffset = doubleValue
        }
        
        let sign = timeZoneOffset > 0 ? "+" : ""
            tzInputString = "\(sign)\(String(format: "%g", timeZoneOffset))"
    }
    
    // Updates the Date object AND the text strings simultaneously
    func updateAll(fromDate date: Date) {
        selectedDate = date
        syncTextFields(from: date)
    }
    
    // Calculates JD/MJD strings from a Date
    func syncTextFields(from date: Date) {
        let jd = jdFromDate(date)
        let mjd = jd - 2400000.5
        
        jdString = String(format: "%.6f", jd)
        mjdString = String(format: "%.6f", mjd)
    }
    
    // Calculation: Date -> JD
    func jdFromDate(_ date: Date) -> Double {
        return (date.timeIntervalSince1970 / 86400.0) + 2440587.5
    }
    
    // Calculation: JD -> Date
    func dateFromJD(_ jd: Double) -> Date {
        let unixTime = (jd - 2440587.5) * 86400.0
        return Date(timeIntervalSince1970: unixTime)
    }
    
    // Copy helper for macOS
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    ContentView()
}
