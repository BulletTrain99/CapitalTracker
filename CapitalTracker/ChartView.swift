import SwiftUI

struct ChartView: View {
    @ObservedObject var dataManager: DataManager
    @State private var showMovingAverages = true
    @State private var selectedPeriod: MovingAveragePeriod = .sevenDay
    
    enum MovingAveragePeriod: String, CaseIterable {
        case sevenDay = "7-day"
        case thirtyDay = "30-day"
        
        var days: Int {
            switch self {
            case .sevenDay: return 7
            case .thirtyDay: return 30
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Toggle("Moving Averages", isOn: $showMovingAverages)
                
                if showMovingAverages {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(MovingAveragePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            if dataManager.entries.isEmpty {
                VStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No data to display")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Add your first capital entry to see the chart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SimpleChartView(dataManager: dataManager, showMovingAverages: showMovingAverages, period: selectedPeriod.days)
                    .frame(height: 280)
                    .padding()
                
                HStack(spacing: 20) {
                    Label("Positive Values", systemImage: "circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Label("Negative Values", systemImage: "circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    if showMovingAverages {
                        Label("\(selectedPeriod.rawValue) MA", systemImage: "line.diagonal")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    Label("Trend", systemImage: "line.diagonal")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Label("Target Goal", systemImage: "line.horizontal.3")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SimpleChartView: View {
    let dataManager: DataManager
    let showMovingAverages: Bool
    let period: Int
    
    var body: some View {
        GeometryReader { geometry in
            let entries = dataManager.entries
            let maxAmount = entries.map(\.amount).max() ?? 0
            let minAmount = entries.map(\.amount).min() ?? 0
            let range = max(maxAmount - minAmount, 1000)
            let adjustedMax = maxAmount + range * 0.1
            let adjustedMin = minAmount - range * 0.1
            
            ZStack {
                // Background grid
                Path { path in
                    for i in 0...4 {
                        let y = geometry.size.height * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                
                // Target goal line
                let targetAmount = dataManager.targetAmount
                if adjustedMin <= targetAmount && adjustedMax >= targetAmount {
                    let goalY = geometry.size.height * (1 - (targetAmount - adjustedMin) / (adjustedMax - adjustedMin))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: goalY))
                    }
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    
                    Text(dataManager.formattedTargetAmount)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .position(x: geometry.size.width - 40, y: goalY - 10)
                }
                
                // Data points and connecting lines
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(entries.count - 1, 1))
                    let y = geometry.size.height * (1 - (entry.amount - adjustedMin) / (adjustedMax - adjustedMin))
                    
                    let previousEntry = index > 0 ? entries[index - 1] : nil
                    
                    // Point color: green if positive capital, red if negative
                    let pointColor = entry.amount >= 0 ? Color.green : Color.red
                    
                    // Line color: green if capital increased, red if decreased
                    let changeColor = if let previousEntry = previousEntry {
                        entry.amount >= previousEntry.amount ? Color.green : Color.red
                    } else {
                        Color.gray // First point has no previous point to compare
                    }
                    
                    // Connecting line to previous point
                    if let previousEntry = previousEntry {
                        let prevX = geometry.size.width * CGFloat(index - 1) / CGFloat(max(entries.count - 1, 1))
                        let prevY = geometry.size.height * (1 - (previousEntry.amount - adjustedMin) / (adjustedMax - adjustedMin))
                        
                        Path { path in
                            path.move(to: CGPoint(x: prevX, y: prevY))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        .stroke(changeColor, lineWidth: 2)
                    }
                    
                    // Data point
                    Circle()
                        .fill(pointColor)
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                                .frame(width: 10, height: 10)
                                .position(x: x, y: y)
                        )
                }
                
                // Moving average line
                if showMovingAverages {
                    Path { path in
                        var firstPoint = true
                        for (index, entry) in entries.enumerated() {
                            if let movingAvg = dataManager.getMovingAverage(for: entry, days: period) {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(max(entries.count - 1, 1))
                                let y = geometry.size.height * (1 - (movingAvg - adjustedMin) / (adjustedMax - adjustedMin))
                                
                                if firstPoint {
                                    path.move(to: CGPoint(x: x, y: y))
                                    firstPoint = false
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
                
                // Trendline
                if let trendline = dataManager.getTrendline(), entries.count >= 2 {
                    let firstY = geometry.size.height * (1 - (trendline.intercept - adjustedMin) / (adjustedMax - adjustedMin))
                    let lastX = geometry.size.width
                    let lastTrendValue = trendline.intercept + trendline.slope * Double(entries.count - 1)
                    let lastY = geometry.size.height * (1 - (lastTrendValue - adjustedMin) / (adjustedMax - adjustedMin))
                    
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: firstY))
                        path.addLine(to: CGPoint(x: lastX, y: lastY))
                    }
                    .stroke(Color.purple, lineWidth: 1.5)
                }
            }
            
            // Y-axis labels
            VStack {
                ForEach(0..<5) { i in
                    let value = adjustedMax - (adjustedMax - adjustedMin) * Double(i) / 4
                    Text("\(dataManager.selectedCurrency.symbol)\(Int(value))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if i < 4 { Spacer() }
                }
            }
            .frame(width: 40)
            .position(x: -20, y: geometry.size.height / 2)
        }
    }
}