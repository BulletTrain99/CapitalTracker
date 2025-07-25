import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @State private var targetAmountInput = ""
    @State private var selectedTargetDate = Date()
    @State private var hasInitialized = false
    @State private var showResetConfirmation = false
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Invisible spacer to center the title
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .opacity(0)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                Divider()
                
                // Currency selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("Currency")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Amount")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
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
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Date")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
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
                
                // Reset button at the bottom
                Divider()
                    .padding(.top, 20)
                
                VStack(spacing: 12) {
                    Text("Danger Zone")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        Text("Reset All Data")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.top, 16)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .alert("Reset All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                dataManager.resetAllData()
            }
        } message: {
            Text("This will permanently delete all your capital entries, reset your target goal, and restore default settings. This action cannot be undone.")
        }
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