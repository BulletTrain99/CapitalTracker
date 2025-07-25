import Foundation

struct CapitalEntry: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    
    init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
    
    func formattedAmount(currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = currency.symbol
        formatter.minimumFractionDigits = currency == .jpy ? 0 : 2
        formatter.maximumFractionDigits = currency == .jpy ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)0.00"
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension CapitalEntry: Comparable {
    static func < (lhs: CapitalEntry, rhs: CapitalEntry) -> Bool {
        lhs.date < rhs.date
    }
}