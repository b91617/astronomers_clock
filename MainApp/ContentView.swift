//
//  ContentView.swift
//  Astronomer's Clock
//
//  Created by Justin Cheng on 2025/10/9.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedTool: Int = 0

    @State private var tzDouble:      Double = 0.0
    @State private var tzInputString: String = "0"
    
    @State private var selectedFormat: Int = 1
    @State private var selectedDate = Date()
    
    // String states are used for the text fields for typing comfortably without the numbers jumping around until hitting Enter.
    @State private var jdString:   String = ""
    @State private var mjdString:  String = ""
    @State private var dateString: String = ""
    
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
           HStack {
               Spacer()
               
               Picker("", selection: $selectedTool) {
                   Text("Date Converter").tag(0)
                   Text("Coordinate Conversion").tag(1)
                   Text("Distance & Magnitude Calculator").tag(2)
               }
               .pickerStyle(.segmented)
               
               Spacer()
           }
            
            // MARK: - Header
            HStack {
                Image(systemName: "clock")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Dates Converter")
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

                    if selectedFormat == 1 {
                        // DatePicker
                        DatePicker("", selection: datePickerBinding, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.stepperField)
                            .frame(minWidth: 150)
                            .environment(\.timeZone, TimeZone(secondsFromGMT: Int(tzDouble * 3600))!)
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
                                .font(selectedFormat == 1 ? .system(.body, design: .default) : .system(.body, design: .monospaced))
                                .onSubmit {
                                    updateTimeZone(fromString: tzInputString)
                                }
                            
                            Stepper("", value: $tzDouble, in: -12...14, step: 1)
                                .labelsHidden()
                                .onChange(of: tzDouble) {
                                    newValue in
                                    let sign = newValue > 0 ? "+" : ""

                                    tzInputString = "\(sign)\(String(format: "%g", newValue))"
                                    
                                    if selectedFormat == 2 {
                                        dateString = dateToISO8601(selectedDate)
                                    }
                                }
                        }
                    
                    } else if selectedFormat == 2 {
                        // ISO 8601 string
                        HStack {
                            TextField("YYYY-MM-DDThh:mm:ssZ", text: $dateString)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 150)
                                .onSubmit {
                                    if let parsed = iso8601ToDate(dateString) {
                                        updateAll(fromDate: parsed)
                                    }
                                }
                                .onChange(of: selectedDate) {
                                    newDate in
                                    dateString = dateToISO8601(newDate)
                                    dateToJDs(from: newDate)
                                }
                            
                            Button(action: { copyToClipboard(dateString) }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .help("Copy date string")
                        }
                    }
                    
                    Divider()
                        .frame(width: 20, height: 20)
                    
                    HStack(spacing: 0) {
                        Text("Format:")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $selectedFormat) {
                            Text("Date Picker").tag(1)
                            Text("Strings").tag(2)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedFormat) { _ in
                            dateString = dateToISO8601(selectedDate)
                        }
                    }
                }
                .padding(5)
            }
            
            
            // MARK: JD Section
            GroupBox(label: Label("Julian Date (JD)", systemImage: "number.square")) {
                HStack {
                    TextField("Enter JD", text: $jdString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
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
                .padding(5)
            }
            
            // MARK: MJD Section
            GroupBox(label: Label("Modified Julian Date (MJD)", systemImage: "number.square")) {
                HStack {
                    TextField("Enter MJD", text: $mjdString)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
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
                .padding(5)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            // initial setting
            updateAll(fromDate: Date())
        }
    }
    
    // MARK: - Logic Functions
    
    // Update Calender Date by time zone change
    func updateTimeZone(fromString input: String) {
        // Handle "H:MM" format
        if input.contains(":") {
            let parts = input.split(separator: ":").map { Double($0) ?? 0 }

            if parts.count == 2 {
                let hours = parts[0]
                // Add or subtract minutes based on sign of hours
                let minutes = (hours >= 0) ? (parts[1] / 60.0) : -(parts[1] / 60.0)
                tzDouble = hours + minutes
            }
        }
        // Handle standard double format
        else if let doubleValue = Double(input) {
            tzDouble = doubleValue
        }
        
        let sign = tzDouble > 0 ? "+" : ""
            tzInputString = "\(sign)\(String(format: "%g", tzDouble))"
    }
    
    
    // Updates the Date object, JDs, and the ISO8601 strings simultaneously
    func updateAll(fromDate date: Date) {
        selectedDate = date
        dateToJDs(from: date)
        dateString = dateToISO8601(date)
    }
    
    // CONVERTER FUNCTIONS //
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
    
    
    // Convert: Date -> ISO 8601
    func dateToISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: Int(tzDouble * 3600))

        return formatter.string(from: date)
    }
    
    
    // Convert: ISO 8601 string -> Date
    func iso8601ToDate(_ iso8601Sstring: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        
        formatter.formatOptions = [.withInternetDateTime]
        
        if let index = iso8601Sstring.lastIndex(where: { $0 == "+" || $0 == "-"}) {
            updateTimeZone(fromString: String(iso8601Sstring[index...]))
        }
        formatter.timeZone = TimeZone(secondsFromGMT: Int(tzDouble * 3600))
        
        return formatter.date(from: iso8601Sstring)
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
        .frame(width: 600, height: 400)
}

extension View {
    @ViewBuilder
    func liquidGlassIfAvailable() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}

