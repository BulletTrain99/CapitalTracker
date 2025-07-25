import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var targetAmountInput = ""
    @State private var selectedTargetDate = Date()
    @State private var hasInitialized = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Current target display
                HStack {
                    Text("Current Target:")
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(dataManager.formattedTargetAmount)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Text("by \(dataManager.formattedTargetDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                Divider()
                
                // Currency selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currency")
                        .font(.headline)
                    
                    Picker("Currency", selection: $dataManager.selectedCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.name)
                            }.tag(currency)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: dataManager.selectedCurrency) { newCurrency in
                        dataManager.updateCurrency(newCurrency)
                    }
                }
                
                Divider()
                
                // Target amount input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Amount")
                        .font(.headline)
                    
                    HStack {
                        Text(dataManager.selectedCurrency.symbol)
                            .font(.title2)
                        TextField("Enter target amount", text: $targetAmountInput)
                            .textFieldStyle(.roundedBorder)
                            .onReceive(targetAmountInput.publisher.collect()) { newValue in
                                let filtered = String(newValue).filter { "0123456789.,".contains($0) }
                                let formatted = filtered.replacingOccurrences(of: ",", with: ".")
                                
                                let components = formatted.components(separatedBy: ".")
                                if components.count > 2 {
                                    targetAmountInput = String(targetAmountInput.dropLast())
                                } else if components.count == 2 && components[1].count > 2 {
                                    targetAmountInput = String(targetAmountInput.dropLast())
                                } else {
                                    targetAmountInput = formatted
                                }
                            }
                    }
                }
                
                // Target date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Date")
                        .font(.headline)
                    
                    DatePicker("Select target date", selection: $selectedTargetDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                // Save button
                Button(action: saveTarget) {
                    Text("Update Target")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(targetAmountInput.isEmpty)
                
                Spacer()
                
                // Progress info
                if !dataManager.entries.isEmpty {
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
                        
                        ProgressView(value: min(progress, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: progress >= 1.0 ? .green : .orange))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .onAppear {
            if !hasInitialized {
                targetAmountInput = String(format: "%.2f", dataManager.targetAmount)
                selectedTargetDate = dataManager.targetDate
                hasInitialized = true
            }
        }
    }
    
    private func saveTarget() {
        guard let amount = Double(targetAmountInput), amount > 0 else { return }
        
        dataManager.updateTarget(amount: amount, date: selectedTargetDate)
    }
}