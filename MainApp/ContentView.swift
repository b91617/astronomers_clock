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
    
    @State private var selectedStyle: Int = 1
    
    @State private var selectedDate = Date()
    
    // String states are used for the text fields for typing comfortably without the numbers jumping around until hitting Enter.
    @State private var jdString:  String = ""
    @State private var mjdString: String = ""
    
    // Timer to update "Now" if needed, or just for reference
    let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()
    
    
    // DATE PICKER //
    var datePickerBinding: Binding<Date> {
        Binding(
            get: { self.selectedDate },
            set: {
                newValue in
                
                // Create a calendar (use current or gregorian)
                let calendar = Calendar.current
                
                // Strip the seconds and nanoseconds
                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: newValue
                )
                let cleanDate = calendar.date(from: components) ?? newValue
                
                // Save the clean date (triggering the .onChange sync automatically)
                self.selectedDate = cleanDate
            }
        )
    }

    // BODY //
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
            
            // MARK: Calendar Date Section
            GroupBox(label: Label("Calendar Date", systemImage: "calendar")) {
                HStack(spacing: 15) {
                    DatePicker("", selection: datePickerBinding, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.stepperField)
                        .environment(\.timeZone, TimeZone(secondsFromGMT: Int(timeZoneOffset * 3600))!)
                        .environment(\.locale, Locale(identifier: "en-CA"))
                        .onChange(of: selectedDate) {
                            newDate in
                            dateToJDs(from: newDate)
                        }
                    
                    HStack(spacing: 3) {
                        Text("UTC")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        
                        TextField("offset", text: $tzInputString)
                            .frame(width: 50)
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
                    
                    Spacer()
                    Divider()
                    Spacer()
                    
                    HStack(spacing: 0) {
                        Text("Format:")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $selectedStyle) {
                            Text("Date Picker").tag(1)
                            Text("Strings").tag(2)
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(20)
            
            // MARK: JD Section
            GroupBox(label: Label("Julian Date (JD)", systemImage: "number.square")) {
                HStack {
                    TextField("Enter JD", text: $jdString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .default))
                        .onSubmit {
                            // Convert String -> Double -> Date
                            if let jdValue = Double(jdString) {
                                let newDate = jdToDate(jdValue)
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
            
            // MARK: MJD Section
            GroupBox(label: Label("Modified Julian Date (MJD)", systemImage: "number.square")) {
                HStack {
                    TextField("Enter MJD", text: $mjdString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .default))
                        .onSubmit {
                            // Convert MJD String -> Double -> Date
                            if let mjdValue = Double(mjdString) {
                                let jdValue = mjdValue + 2400000.5
                                let newDate = jdToDate(jdValue)
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
        .frame(minWidth: 400, minHeight: 410)
        .onAppear {
            // initial setting
            updateAll(fromDate: Date())
        }
    }
    
    // MARK: - Logic Functions
    
    // Update Calender Date by time zone change
    func updateTimeZone(fromString input: String) {
        // Handle "6:30" format
        if input.contains(":") {
            let parts = input.split(separator: ":").map { Double($0) ?? 0 }
            if parts.count == 2 {
                let hours = parts[0]
                // Add or subtract minutes based on sign of hours
                let minutes = (hours >= 0) ? (parts[1] / 60.0) : -(parts[1] / 60.0)
                timeZoneOffset = hours + minutes
            }
        }
        // Handle standard "6.5" double format
        else if let doubleValue = Double(input) {
            timeZoneOffset = doubleValue
        }
        
        let sign = timeZoneOffset > 0 ? "+" : ""
            tzInputString = "\(sign)\(String(format: "%g", timeZoneOffset))"
    }
    
    
    // Updates the Date object AND the text strings simultaneously
    func updateAll(fromDate date: Date) {
        selectedDate = date
        dateToJDs(from: date)
    }
    
    
    // Convert: Date -> JD/MJD
    func dateToJDs(from date: Date) {
        let jd:  Double = (date.timeIntervalSince1970 / 86400.0) + 2440587.5
        let mjd: Double = jd - 2400000.5
        
        jdString  = String(format: "%.6f", jd)
        mjdString = String(format: "%.6f", mjd)
    }
    
    
    // Convert: JD -> Date
    func jdToDate(_ jd: Double) -> Date {
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
