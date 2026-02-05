import SwiftUI
import SwiftData

struct HabitManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.startDate, order: .reverse) private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var showingAddHabit = false
    @State private var habitToEdit: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var habitToDelete: Habit?
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    emptyStateView
                } else {
                    activeHabitsSection
                    
                    if habits.contains(where: { !$0.isActive }) {
                        inactiveHabitsSection
                    }
                    
                    summarySection
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabit = true
                        HapticManager.shared.buttonTap()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddEditHabitView(habit: nil)
            }
            .sheet(item: $habitToEdit) { habit in
                AddEditHabitView(habit: habit)
            }
            .confirmationDialog(
                "Delete habit",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        deleteHabit(habit)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this habit? All related data will be lost.")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        Section {
            VStack(spacing: 20) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green.opacity(0.5))
                
                Text("No habits yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start tracking a habit you want to quit and watch your savings grow!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    showingAddHabit = true
                } label: {
                    Label("Add your first habit", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Active Habits Section
    
    private var activeHabitsSection: some View {
        Section {
            ForEach(habits.filter { $0.isActive }) { habit in
                HabitListRow(habit: habit, settings: userSettings)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        habitToEdit = habit
                        HapticManager.shared.selection()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            habitToDelete = habit
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            habit.isActive = false
                            HapticManager.shared.warning()
                        } label: {
                            Label("Pause", systemImage: "pause.circle")
                        }
                        .tint(.orange)
                    }
            }
        } header: {
            Text("Active habits")
        } footer: {
            Text("Tap to edit, swipe to pause or delete")
        }
    }
    
    // MARK: - Inactive Habits Section
    
    private var inactiveHabitsSection: some View {
        Section {
            ForEach(habits.filter { !$0.isActive }) { habit in
                HabitListRow(habit: habit, settings: userSettings, isInactive: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        habitToEdit = habit
                        HapticManager.shared.selection()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            habitToDelete = habit
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            habit.isActive = true
                            HapticManager.shared.success()
                        } label: {
                            Label("Resume", systemImage: "play.circle")
                        }
                        .tint(.green)
                    }
            }
        } header: {
            Text("Paused")
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Daily savings")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(userSettings.formatCurrency(habits.filter { $0.isActive }.reduce(0) { $0 + $1.dailyCost }))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Yearly savings")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(userSettings.formatCurrency(habits.filter { $0.isActive }.reduce(0) { $0 + $1.yearlyCost }))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Total saved")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(userSettings.formatCurrency(habits.reduce(0) { $0 + $1.totalSaved }))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Summary")
        }
    }
    
    // MARK: - Actions
    
    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        HapticManager.shared.error()
    }
}

// MARK: - Habit List Row

struct HabitListRow: View {
    let habit: Habit
    let settings: UserSettings
    var isInactive: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: habit.iconName)
                .font(.title2)
                .foregroundColor(isInactive ? .gray : Color(hex: habit.colorHex))
                .frame(width: 44, height: 44)
                .background(
                    (isInactive ? Color.gray : Color(hex: habit.colorHex))
                        .opacity(0.15)
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(isInactive ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Label(habit.frequency.displayName, systemImage: "clock")
                    Text("•")
                    Text(settings.formatCurrency(habit.costPerUnit) + "/unit")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(settings.formatCurrency(habit.totalSaved))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isInactive ? .secondary : .green)
                
                Text("\(habit.currentStreak) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(isInactive ? 0.7 : 1)
    }
}

#Preview {
    HabitManagerView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
