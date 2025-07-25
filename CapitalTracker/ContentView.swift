import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager: DataManager
    @State private var inputAmount = ""
    @State private var selectedDate = Date()
    @State private var showChart = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Capital Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                }
                Button(action: { showChart.toggle() }) {
                    Image(systemName: showChart ? "text.below.photo" : "chart.xyaxis.line")
                }
            }
            .padding(.horizontal)
            
            if showSettings {
                SettingsView(dataManager: dataManager)
            } else if showChart {
                ChartView(dataManager: dataManager)
            } else {
                inputView
            }
        }
        .padding()
        .frame(width: 600, height: 400)
    }
    
    private var inputView: some View {
        VStack(spacing: 16) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
            
            HStack {
                Text(dataManager.selectedCurrency.symbol)
                    .font(.title2)
                TextField("Enter capital amount", text: $inputAmount)
                    .textFieldStyle(.roundedBorder)
                    .onReceive(inputAmount.publisher.collect()) { newValue in
                        let filtered = String(newValue).filter { "0123456789.,".contains($0) }
                        let formatted = filtered.replacingOccurrences(of: ",", with: ".")
                        
                        let components = formatted.components(separatedBy: ".")
                        if components.count > 2 {
                            inputAmount = String(inputAmount.dropLast())
                        } else if components.count == 2 && components[1].count > 2 {
                            inputAmount = String(inputAmount.dropLast())
                        } else {
                            inputAmount = formatted
                        }
                    }
            }
            
            if let existingEntry = dataManager.getEntryForDate(selectedDate) {
                Text("Current entry: \(existingEntry.formattedAmount(currency: dataManager.selectedCurrency))")
                    .foregroundColor(.secondary)
            }
            
            Button(action: addEntry) {
                Text(dataManager.getEntryForDate(selectedDate) != nil ? "Update Entry" : "Add Entry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputAmount.isEmpty)
            
            // Target info
            HStack {
                Text("Target: \(dataManager.formattedTargetAmount)")
                    .font(.caption)
                    .foregroundColor(.orange)
                Spacer()
                Text("by \(dataManager.formattedTargetDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            Spacer()
            
            if !dataManager.entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Entries")
                        .font(.headline)
                    
                    ForEach(dataManager.entries.suffix(5).reversed(), id: \.id) { entry in
                        HStack {
                            Text(entry.dateString)
                            Spacer()
                            Text(entry.formattedAmount(currency: dataManager.selectedCurrency))
                                .fontWeight(.semibold)
                            
                            if let previousEntry = dataManager.getPreviousEntry(before: entry.date) {
                                let change = entry.amount - previousEntry.amount
                                let changeColor: Color = change >= 0 ? .green : .red
                                let changeSymbol = change >= 0 ? "+" : ""
                                
                                Text("\(changeSymbol)\(String(format: "%.2f", change))\(dataManager.selectedCurrency.symbol)")
                                    .foregroundColor(changeColor)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top)
            }
        }
    }
    
    private func addEntry() {
        guard let amount = Double(inputAmount) else { return }
        
        let entry = CapitalEntry(date: selectedDate, amount: amount)
        dataManager.addEntry(entry)
        
        inputAmount = ""
        selectedDate = Date()
    }
}