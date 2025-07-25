import SwiftUI

struct ContentView: View {
    @ObservedObject var dataManager: DataManager
    @State private var inputAmount = ""
    @State private var selectedDate = Date()
    @State private var showChart = false
    @State private var showSettings = false
    @State private var hoveredEntryId: UUID? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Capital Tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                if !showSettings {
                    Button(action: { 
                        showChart.toggle()
                    }) {
                        Image(systemName: showChart ? "chart.xyaxis.line.fill" : "chart.xyaxis.line")
                    }
                    Button(action: { 
                        showSettings.toggle()
                        showChart = false
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .padding(.horizontal)
            
            if showSettings {
                SettingsView(dataManager: dataManager) {
                    showSettings = false
                }
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
        ScrollView {
            VStack(spacing: 16) {
                dateAndAmountSection
                targetInfoSection
                progressSection
                Spacer()
                recentEntriesSection
            }
            .padding(.horizontal)
        }
    }
    
    private var dateAndAmountSection: some View {
        VStack(spacing: 16) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
            
            amountInputSection
            
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
        }
    }
    
    private var amountInputSection: some View {
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
    }
    
    private var targetInfoSection: some View {
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
    }
    
    private var progressSection: some View {
        Group {
            if !dataManager.entries.isEmpty && dataManager.targetAmount > 0 {
                let currentAmount = dataManager.entries.last?.amount ?? 0
                let progress = currentAmount / dataManager.targetAmount
                let remaining = dataManager.targetAmount - currentAmount
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress")
                        .font(.headline)
                    
                    HStack {
                        Text("Current:")
                        Spacer()
                        Text(dataManager.formatAmount(currentAmount))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Remaining:")
                        Spacer()
                        Text(dataManager.formatAmount(remaining))
                            .fontWeight(.semibold)
                            .foregroundColor(remaining > 0 ? .red : .green)
                    }
                    
                    HStack {
                        Text("Progress:")
                        Spacer()
                        Text("\(String(format: "%.1f", progress * 100))%")
                            .fontWeight(.semibold)
                            .foregroundColor(progress >= 1.0 ? .green : .orange)
                    }
                    
                    SwiftUI.ProgressView(value: min(progress, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: progress >= 1.0 ? .green : .orange))
                        .scaleEffect(x: 1, y: 1.5)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var recentEntriesSection: some View {
        Group {
            if !dataManager.entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Entries")
                        .font(.headline)
                    
                    ForEach(dataManager.entries.suffix(5).reversed(), id: \.id) { entry in
                        entryRow(for: entry)
                    }
                }
                .padding(.top)
            }
        }
    }
    
    private func entryRow(for entry: CapitalEntry) -> some View {
        HStack {
            Text(entry.dateString)
            Spacer()
            Text(entry.formattedAmount(currency: dataManager.selectedCurrency))
                .fontWeight(.semibold)
            
            entryChangeText(for: entry)
            
            if hoveredEntryId == entry.id {
                Button(action: {
                    dataManager.removeEntry(entry)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(hoveredEntryId == entry.id ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredEntryId = isHovering ? entry.id : nil
            }
        }
    }
    
    private func entryChangeText(for entry: CapitalEntry) -> some View {
        Group {
            if let previousEntry = dataManager.getPreviousEntry(before: entry.date) {
                let change = entry.amount - previousEntry.amount
                let changeColor: Color = change >= 0 ? .green : .red
                let changeSymbol = change >= 0 ? "+" : ""
                
                Text("\(changeSymbol)\(String(format: "%.2f", change))\(dataManager.selectedCurrency.symbol)")
                    .foregroundColor(changeColor)
                    .font(.caption)
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
