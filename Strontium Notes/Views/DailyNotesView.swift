//
//  DailyNotesView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct DailyNotesView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var selectedDate = Date()
    @State private var showingCalendar = false
    
    private var dailyNotes: [Note] {
        appViewModel.mockNotes.filter { note in
            isDailyNote(note)
        }.sorted { $0.createdDate > $1.createdDate }
    }
    
    private var todayNote: Note? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyNotes.first { note in
            Calendar.current.isDate(note.createdDate, inSameDayAs: today)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Daily Notes")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    // Calendar toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCalendar.toggle()
                        }
                        HapticManager.shared.lightImpact()
                    } label: {
                        Image(systemName: showingCalendar ? "list.bullet" : "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(.accent)
                    }
                    .buttonStyle(GentleButtonStyle())
                }
                
                // Today's note quick access
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryText)
                        
                        Text(Date(), style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    if let todayNote = todayNote {
                        Button {
                            appViewModel.selectedNote = todayNote
                            HapticManager.shared.mediumImpact()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                Text("Open")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accent.opacity(0.1))
                            )
                        }
                        .buttonStyle(GentleButtonStyle())
                    } else {
                        Button {
                            createTodayNote()
                            HapticManager.shared.mediumImpact()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12))
                                Text("Create")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accent)
                            )
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.tertiaryBackground)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()
            
            // Content
            if showingCalendar {
                calendarView
            } else {
                dailyNotesListView
            }
        }
        .background(Color.primaryBackground)
    }
    
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Calendar header
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .foregroundColor(.accent)
                }
                .buttonStyle(GentleButtonStyle())
                
                Spacer()
                
                Text(selectedDate, format: .dateTime.month(.wide).year())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.accent)
                }
                .buttonStyle(GentleButtonStyle())
            }
            .padding(.horizontal, 20)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.tertiaryText)
                        .frame(height: 32)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        hasNote: hasNoteForDate(date),
                        isToday: Calendar.current.isDateInToday(date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month)
                    ) {
                        if hasNoteForDate(date) {
                            if let note = getNoteForDate(date) {
                                appViewModel.selectedNote = note
                            }
                        } else {
                            createNoteForDate(date)
                        }
                        HapticManager.shared.mediumImpact()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private var dailyNotesListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(dailyNotes) { note in
                    DailyNoteRowView(
                        note: note,
                        appViewModel: appViewModel
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
                
                if dailyNotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.tertiaryText)
                        
                        Text("No daily notes yet")
                            .font(.system(size: 16))
                            .foregroundColor(.secondaryText)
                        
                        Text("Create your first daily note to get started")
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)
                        
                        Button {
                            createTodayNote()
                        } label: {
                            Text("Create Today's Note")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accent)
                                )
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let startOfCalendar = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let date = calendar.date(byAdding: .day, value: i, to: startOfCalendar) {
                days.append(date)
            }
        }
        return days
    }
    
    private func isDailyNote(_ note: Note) -> Bool {
        // Check if note title matches daily note pattern (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: note.title) != nil
    }
    
    private func hasNoteForDate(_ date: Date) -> Bool {
        return getNoteForDate(date) != nil
    }
    
    private func getNoteForDate(_ date: Date) -> Note? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return appViewModel.mockNotes.first { $0.title == dateString }
    }
    
    private func createTodayNote() {
        createNoteForDate(Date())
    }
    
    private func createNoteForDate(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateStyle = .full
        let fullDateString = fullDateFormatter.string(from: date)
        
        let newNote = Note(
            filePath: "\(dateString).md",
            title: dateString,
            content: "# \(fullDateString)\n\n## Today's Goals\n- \n\n## Notes\n\n\n## Reflection\n\n"
        )
        
        appViewModel.mockNotes.append(newNote)
        appViewModel.selectedNote = newNote
    }
}

struct CalendarDayView: View {
    let date: Date
    let hasNote: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                    .foregroundColor(
                        isToday ? .white :
                        isCurrentMonth ? .primaryText : .tertiaryText
                    )
                
                if hasNote {
                    Circle()
                        .fill(Color.accent)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isToday ? Color.accent :
                        (isHovered ? Color.tertiaryBackground : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct DailyNoteRowView: View {
    let note: Note
    @ObservedObject var appViewModel: AppViewModel
    
    @State private var isHovered = false
    
    private var noteDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: note.title)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(alignment: .leading, spacing: 2) {
                if let date = noteDate {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accent)
                    
                    Text(date, format: .dateTime.month().day())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryText)
                } else {
                    Text(note.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryText)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                // Note preview
                Text(note.content.prefix(100))
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                
                // Metadata
                HStack(spacing: 8) {
                    Text("\(note.wordCount) words")
                        .font(.system(size: 10))
                        .foregroundColor(.tertiaryText)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.tertiaryText)
                    
                    Text(note.modifiedDate, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.tertiaryText)
                }
            }
            
            Spacer()
            
            if isHovered {
                Button {
                    appViewModel.selectedNote = note
                    HapticManager.shared.mediumImpact()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.accent)
                }
                .buttonStyle(GentleButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.tertiaryBackground : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            appViewModel.selectedNote?.id == note.id ? Color.accent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appViewModel.selectedNote = note
            HapticManager.shared.selectionChanged()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    DailyNotesView(appViewModel: AppViewModel())
}