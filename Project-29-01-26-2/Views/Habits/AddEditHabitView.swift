import SwiftUI
import SwiftData

struct AddEditHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    
    let habit: Habit?
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    @State private var name: String = ""
    @State private var iconName: String = "flame.fill"
    @State private var costPerUnit: String = ""
    @State private var unitsPerPeriod: String = "1"
    @State private var frequency: HabitFrequency = .daily
    @State private var startDate: Date = Date()
    @State private var colorHex: String = "#FF6B6B"
    
    @State private var showingIconPicker = false
    @State private var showingPresets = false
    
    private var isEditing: Bool {
        habit != nil
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(costPerUnit) != nil &&
        Double(costPerUnit)! > 0 &&
        Double(unitsPerPeriod) != nil &&
        Double(unitsPerPeriod)! > 0
    }
    
    private var availableIcons: [String] {
        [
            "flame.fill", "smoke.fill", "wineglass.fill", "cup.and.saucer.fill",
            "fork.knife", "cart.fill", "dice.fill", "gamecontroller.fill",
            "tv.fill", "iphone", "creditcard.fill", "bag.fill",
            "pills.fill", "heart.slash.fill", "bolt.fill", "waterbottle.fill",
            "moon.fill", "bed.double.fill", "figure.walk", "car.fill"
        ]
    }
    
    private var availableColors: [String] {
        [
            "#FF6B6B", "#E74C3C", "#9B59B6", "#8E44AD",
            "#3498DB", "#2980B9", "#1ABC9C", "#16A085",
            "#2ECC71", "#27AE60", "#F39C12", "#F1C40F",
            "#E67E22", "#D35400", "#E91E63", "#795548"
        ]
    }
    
    init(habit: Habit?) {
        self.habit = habit
        
        if let habit = habit {
            _name = State(initialValue: habit.name)
            _iconName = State(initialValue: habit.iconName)
            _costPerUnit = State(initialValue: String(format: "%.2f", habit.costPerUnit))
            _unitsPerPeriod = State(initialValue: String(format: "%.0f", habit.unitsPerPeriod))
            _frequency = State(initialValue: habit.frequency)
            _startDate = State(initialValue: habit.startDate)
            _colorHex = State(initialValue: habit.colorHex)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick Presets (only for new habits)
                if !isEditing {
                    Section {
                        Button {
                            showingPresets = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("Choose from templates")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Basic Info
                Section {
                    HStack {
                        Button {
                            showingIconPicker = true
                        } label: {
                            Image(systemName: iconName)
                                .font(.title)
                                .foregroundColor(Color(hex: colorHex))
                                .frame(width: 50, height: 50)
                                .background(Color(hex: colorHex).opacity(0.15))
                                .clipShape(Circle())
                        }
                        
                        TextField("Habit name", text: $name)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Habit details")
                }
                
                // Cost Details
                Section {
                    HStack {
                        Text("Cost per unit")
                        Spacer()
                        TextField("0.00", text: $costPerUnit)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Units per period")
                        Spacer()
                        TextField("1", text: $unitsPerPeriod)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                } header: {
                    Text("Cost and frequency")
                } footer: {
                    if let cost = Double(costPerUnit), let units = Double(unitsPerPeriod), cost > 0, units > 0 {
                        let dailyCost = (cost * units) / frequency.daysMultiplier
                        Text("Approx. \(userSettings.formatCurrency(dailyCost))/day or \(userSettings.formatCurrency(dailyCost * 365))/year")
                    }
                }
                
                // Start Date
                Section {
                    DatePicker("Quit date", selection: $startDate, in: ...Date(), displayedComponents: .date)
                } header: {
                    Text("When did you quit?")
                }
                
                // Color Picker
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorHex == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    colorHex = color
                                    HapticManager.shared.selection()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                }
                
                // Danger Zone for existing habits
                if isEditing {
                    Section {
                    HStack {
                        Text("Total saved")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(userSettings.formatCurrency(habit?.totalSaved ?? 0))
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                        
                        HStack {
                            Text("Current streak")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(habit?.currentStreak ?? 0) days")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Relapses")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(habit?.relapseCount ?? 0)")
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text("Statistics")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit" : "New habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $iconName)
            }
            .sheet(isPresented: $showingPresets) {
                PresetPickerView { preset in
                    name = preset.name
                    iconName = preset.icon
                    costPerUnit = String(format: "%.2f", preset.avgCost)
                    frequency = preset.frequency
                    colorHex = preset.color
                }
            }
        }
    }
    
    private func saveHabit() {
        guard let costValue = Double(costPerUnit),
              let unitsValue = Double(unitsPerPeriod) else { return }
        
        if let habit = habit {
            // Update existing
            habit.name = name.trimmingCharacters(in: .whitespaces)
            habit.iconName = iconName
            habit.costPerUnit = costValue
            habit.unitsPerPeriod = unitsValue
            habit.frequency = frequency
            habit.startDate = startDate
            habit.colorHex = colorHex
        } else {
            // Create new
            let newHabit = Habit(
                name: name.trimmingCharacters(in: .whitespaces),
                iconName: iconName,
                costPerUnit: costValue,
                unitsPerPeriod: unitsValue,
                frequency: frequency,
                startDate: startDate,
                colorHex: colorHex
            )
            modelContext.insert(newHabit)
        }
        
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Icon Picker

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    
    private let icons: [String] = [
        // Substances
        "flame.fill", "smoke.fill", "wineglass.fill", "cup.and.saucer.fill",
        "pills.fill", "cross.vial.fill", "syringe.fill", "leaf.fill",
        
        // Food & Drink
        "fork.knife", "takeoutbag.and.cup.and.straw.fill", "birthday.cake.fill", "carrot.fill",
        "waterbottle.fill", "mug.fill", "popcorn.fill",
        
        // Shopping & Money
        "cart.fill", "bag.fill", "creditcard.fill", "banknote.fill",
        "giftcard.fill", "tag.fill",
        
        // Entertainment
        "gamecontroller.fill", "tv.fill", "iphone", "laptopcomputer",
        "headphones", "dice.fill", "suit.spade.fill", "suit.heart.fill",
        
        // Lifestyle
        "bed.double.fill", "moon.fill", "sun.max.fill", "bolt.fill",
        "figure.walk", "figure.run", "heart.slash.fill", "brain.head.profile",
        
        // Transport
        "car.fill", "fuelpump.fill", "airplane", "bicycle"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            HapticManager.shared.selection()
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title)
                                .frame(width: 50, height: 50)
                                .background(
                                    selectedIcon == icon ?
                                    Color.blue.opacity(0.2) :
                                    Color(UIColor.secondarySystemBackground)
                                )
                                .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preset Picker

struct PresetPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    let onSelect: ((name: String, icon: String, avgCost: Double, frequency: HabitFrequency, color: String)) -> Void
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Habit.presets, id: \.name) { preset in
                    Button {
                        onSelect(preset)
                        HapticManager.shared.selection()
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: preset.icon)
                                .font(.title2)
                                .foregroundColor(Color(hex: preset.color))
                                .frame(width: 44, height: 44)
                                .background(Color(hex: preset.color).opacity(0.15))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("\(preset.frequency.displayName) • ~\(userSettings.formatCurrency(preset.avgCost))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddEditHabitView(habit: nil)
        .modelContainer(for: [Habit.self], inMemory: true)
}
