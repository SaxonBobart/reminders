import SQLiteData
import SwiftUI

struct ListEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.defaultDatabase) private var database
    let existing: ReminderList?

    @State private var title = ""
    @State private var colorHex = ReminderList.defaultColorHex
    @State private var symbolName = ReminderList.defaultSymbolName

    private static let presetColors = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE",
        "#30B0C7", "#4A99EF", "#5856D6", "#AF52DE", "#FF2D55",
        "#A2845E", "#8E8E93"
    ]

    private static let presetSymbols = [
        "list.bullet", "star.fill", "house.fill", "briefcase.fill",
        "cart.fill", "gift.fill", "book.fill", "heart.fill",
        "airplane", "car.fill", "fork.knife", "dumbbell.fill",
        "gamecontroller.fill", "graduationcap.fill", "person.crop.circle",
        "folder.fill", "tag.fill", "pencil", "camera.fill", "music.note"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Title", text: $title)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().strokeBorder(
                                        colorHex == hex ? Color.primary : .clear,
                                        lineWidth: 2
                                    )
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(Self.presetSymbols, id: \.self) { sym in
                            Image(systemName: sym)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle().fill(
                                        symbolName == sym
                                            ? Color.accentColor.opacity(0.2)
                                            : Color.secondary.opacity(0.1)
                                    )
                                )
                                .onTapGesture { symbolName = sym }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(existing == nil ? "New List" : "Edit List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let existing {
                    title = existing.title
                    colorHex = existing.colorHex
                    symbolName = existing.symbolName
                }
            }
        }
    }

    private func save() async {
        let repo = ReminderListRepository(database: database)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if var existing {
            existing.title = trimmedTitle
            existing.colorHex = colorHex
            existing.symbolName = symbolName
            try? await repo.update(existing)
        } else {
            _ = try? await repo.create(title: trimmedTitle, colorHex: colorHex, symbolName: symbolName)
        }
        dismiss()
    }
}
