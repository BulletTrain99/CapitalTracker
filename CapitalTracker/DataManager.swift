import Foundation

enum Currency: String, CaseIterable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    
    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cad: return "C$"
        case .aud: return "A$"
        case .chf: return "CHF"
        }
    }
    
    var name: String {
        switch self {
        case .eur: return "Euro"
        case .usd: return "US Dollar"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        }
    }
}

class DataManager: ObservableObject {
    @Published var entries: [CapitalEntry] = []
    @Published var targetAmount: Double = 20000.0
    @Published var targetDate: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? Date()
    @Published var selectedCurrency: Currency = .eur
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "CapitalEntries"
    private let targetAmountKey = "TargetAmount"
    private let targetDateKey = "TargetDate"
    private let currencyKey = "SelectedCurrency"
    
    init() {
        loadEntries()
        loadTarget()
    }
    
    func addEntry(_ entry: CapitalEntry) {
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        
        entries.append(entry)
        entries.sort()
        saveEntries()
    }
    
    func getEntryForDate(_ date: Date) -> CapitalEntry? {
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getPreviousEntry(before date: Date) -> CapitalEntry? {
        return entries.filter { $0.date < date }.last
    }
    
    func getMovingAverage(for entry: CapitalEntry, days: Int) -> Double? {
        let entryIndex = entries.firstIndex(of: entry) ?? 0
        let startIndex = max(0, entryIndex - days + 1)
        let relevantEntries = Array(entries[startIndex...entryIndex])
        
        guard relevantEntries.count >= min(days, entryIndex + 1) else { return nil }
        
        let sum = relevantEntries.reduce(0) { $0 + $1.amount }
        return sum / Double(relevantEntries.count)
    }
    
    func getTrendline() -> (slope: Double, intercept: Double)? {
        guard entries.count >= 2 else { return nil }
        
        let n = Double(entries.count)
        let xValues = entries.enumerated().map { Double($0.offset) }
        let yValues = entries.map { $0.amount }
        
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).reduce(0) { $0 + ($1.0 * $1.1) }
        let sumXX = xValues.reduce(0) { $0 + ($1 * $1) }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        return (slope: slope, intercept: intercept)
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            userDefaults.set(data, forKey: entriesKey)
        }
    }
    
    func updateTarget(amount: Double, date: Date) {
        targetAmount = amount
        targetDate = date
        saveTarget()
    }
    
    func updateCurrency(_ currency: Currency) {
        selectedCurrency = currency
        saveCurrency()
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.rawValue
        formatter.currencySymbol = selectedCurrency.symbol
        formatter.minimumFractionDigits = selectedCurrency == .jpy ? 0 : 2
        formatter.maximumFractionDigits = selectedCurrency == .jpy ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(selectedCurrency.symbol)0.00"
    }
    
    var formattedTargetAmount: String {
        return formatAmount(targetAmount)
    }
    
    var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: targetDate)
    }
    
    private func saveTarget() {
        userDefaults.set(targetAmount, forKey: targetAmountKey)
        userDefaults.set(targetDate, forKey: targetDateKey)
    }
    
    private func saveCurrency() {
        userDefaults.set(selectedCurrency.rawValue, forKey: currencyKey)
    }
    
    private func loadTarget() {
        if userDefaults.object(forKey: targetAmountKey) != nil {
            targetAmount = userDefaults.double(forKey: targetAmountKey)
        }
        if let savedDate = userDefaults.object(forKey: targetDateKey) as? Date {
            targetDate = savedDate
        }
        if let savedCurrency = userDefaults.string(forKey: currencyKey),
           let currency = Currency(rawValue: savedCurrency) {
            selectedCurrency = currency
        }
    }
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: entriesKey),
           let decodedEntries = try? JSONDecoder().decode([CapitalEntry].self, from: data) {
            entries = decodedEntries.sorted()
        }
    }
}