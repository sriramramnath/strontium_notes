//
//  StatisticsView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedMetric: StatisticMetric = .notes
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Statistics")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                // Quick stats cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCardView(
                        title: "Total Notes",
                        value: "\(appViewModel.mockNotes.count)",
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    StatCardView(
                        title: "Total Words",
                        value: "\(totalWords)",
                        icon: "textformat.123",
                        color: .green
                    )
                    
                    StatCardView(
                        title: "Total Tags",
                        value: "\(appViewModel.allTags.count)",
                        icon: "tag",
                        color: .orange
                    )
                    
                    StatCardView(
                        title: "Avg Words/Note",
                        value: "\(averageWordsPerNote)",
                        icon: "chart.bar",
                        color: .purple
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Activity chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Activity Over Time")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Picker("Metric", selection: $selectedMetric) {
                                ForEach(StatisticMetric.allCases, id: \.self) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Chart placeholder (would use Swift Charts in real implementation)
                        ActivityChartView(
                            data: getActivityData(),
                            metric: selectedMetric,
                            timeRange: selectedTimeRange
                        )
                        .frame(height: 200)
                    }
                    .padding(.horizontal, 20)
                    
                    // Top tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most Used Tags")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(topTags.prefix(10), id: \.tag) { tagData in
                                TagStatRowView(
                                    tag: tagData.tag,
                                    count: tagData.count,
                                    percentage: Double(tagData.count) / Double(appViewModel.mockNotes.count)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Note length distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Note Length Distribution")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(noteLengthCategories, id: \.category) { data in
                                LengthCategoryRowView(
                                    category: data.category,
                                    count: data.count,
                                    percentage: Double(data.count) / Double(appViewModel.mockNotes.count)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Most active days
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most Active Days")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(mostActiveDays.prefix(7), id: \.day) { dayData in
                                ActiveDayRowView(
                                    day: dayData.day,
                                    count: dayData.count
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Recent activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(recentNotes.prefix(10)) { note in
                                RecentActivityRowView(
                                    note: note,
                                    appViewModel: appViewModel
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .background(Color.primaryBackground)
    }
    
    // MARK: - Computed Properties
    
    private var totalWords: Int {
        appViewModel.mockNotes.reduce(0) { $0 + $1.wordCount }
    }
    
    private var averageWordsPerNote: Int {
        guard !appViewModel.mockNotes.isEmpty else { return 0 }
        return totalWords / appViewModel.mockNotes.count
    }
    
    private var topTags: [(tag: String, count: Int)] {
        let allTags = appViewModel.mockNotes.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
        
        return tagCounts.sorted { $0.value > $1.value }
            .map { (tag: $0.key, count: $0.value) }
    }
    
    private var noteLengthCategories: [(category: String, count: Int)] {
        let categories = [
            ("Short (0-100 words)", appViewModel.mockNotes.filter { $0.wordCount <= 100 }.count),
            ("Medium (101-500 words)", appViewModel.mockNotes.filter { $0.wordCount > 100 && $0.wordCount <= 500 }.count),
            ("Long (501-1000 words)", appViewModel.mockNotes.filter { $0.wordCount > 500 && $0.wordCount <= 1000 }.count),
            ("Very Long (1000+ words)", appViewModel.mockNotes.filter { $0.wordCount > 1000 }.count)
        ]
        
        return categories.map { (category: $0.0, count: $0.1) }
    }
    
    private var mostActiveDays: [(day: String, count: Int)] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        let dayGroups = Dictionary(grouping: appViewModel.mockNotes) { note in
            dayFormatter.string(from: note.createdDate)
        }
        
        return dayGroups.map { (day: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    private var recentNotes: [Note] {
        appViewModel.mockNotes.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    private func getActivityData() -> [ActivityDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        var dataPoints: [ActivityDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= now {
            let notesForDate = appViewModel.mockNotes.filter { note in
                calendar.isDate(note.createdDate, inSameDayAs: currentDate)
            }
            
            let value: Int
            switch selectedMetric {
            case .notes:
                value = notesForDate.count
            case .words:
                value = notesForDate.reduce(0) { $0 + $1.wordCount }
            case .characters:
                value = notesForDate.reduce(0) { $0 + $1.characterCount }
            }
            
            dataPoints.append(ActivityDataPoint(date: currentDate, value: value))
            currentDate = calendar.date(byAdding: DateComponents(day: 1), to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
}

// MARK: - Supporting Views

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryText)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.tertiaryBackground)
        )
    }
}

struct ActivityChartView: View {
    let data: [ActivityDataPoint]
    let metric: StatisticMetric
    let timeRange: TimeRange
    
    var body: some View {
        // Simplified chart representation
        VStack(spacing: 8) {
            HStack {
                ForEach(data.indices, id: \.self) { index in
                    let point = data[index]
                    let maxValue = data.map { $0.value }.max() ?? 1
                    let height = CGFloat(point.value) / CGFloat(maxValue) * 150
                    
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accent)
                            .frame(height: max(height, 2))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
            
            HStack {
                Text(data.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryText)
                
                Spacer()
                
                Text(data.last?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.tertiaryBackground)
        )
    }
}

struct TagStatRowView: View {
    let tag: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(tag)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accent)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tertiaryBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accent)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(width: 60, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct LengthCategoryRowView: View {
    let category: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Text(category)
                .font(.system(size: 14))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tertiaryBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(width: 60, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ActiveDayRowView: View {
    let day: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text(day)
                .font(.system(size: 14))
                .foregroundColor(.primaryText)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text("\(count) notes")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct RecentActivityRowView: View {
    let note: Note
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 12))
                .foregroundColor(.accent)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                
                Text("Modified \(note.modifiedDate, style: .relative)")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
            }
            
            Spacer()
            
            Text("\(note.wordCount) words")
                .font(.system(size: 11))
                .foregroundColor(.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appViewModel.selectedNote = note
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

enum StatisticMetric: String, CaseIterable {
    case notes = "Notes"
    case words = "Words"
    case characters = "Characters"
}

struct ActivityDataPoint {
    let date: Date
    let value: Int
}

#Preview {
    StatisticsView(appViewModel: AppViewModel())
}