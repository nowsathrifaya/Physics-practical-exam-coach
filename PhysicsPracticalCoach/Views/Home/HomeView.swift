//
//  HomeView.swift
//  PhysicsPracticalCoach
//
//  Replaces `HomeFragment` / `fragment_home.xml`. Redesigned so a student
//  landing on Home immediately knows where to start: one clear "Continue"
//  card, a Today's Progress snapshot, four big feature cards (Virtual Lab,
//  Apparatus Trainer, Graph Coach, ACE Practice), a Quick Practice row for
//  a fast drill, two dedicated exam-prep cards (Last Minute Revision and
//  Answering Techniques), and a Daily Practical Challenge banner.
//

import SwiftUI

/// Destination for the Quick Practice row, which re-rolls a fresh random
/// target each tap (a random experiment, a random apparatus reading, or a
/// short quiz of random ACE questions).
enum RandomPracticeDestination: Hashable {
    case apparatus(ApparatusType)
    case simulation(SimulationType)
    case quickQuiz(Int)
}

struct HomeView: View {
    @Bindable var homeViewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var randomDestination: RandomPracticeDestination?

    private var profile: CurriculumProfile { CurriculumProfiles.forCurriculum(homeViewModel.curriculum) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                ExamCountdownCard()

                ContinueLearningCard(homeViewModel: homeViewModel, profile: profile)

                TodayProgressCard(progress: homeViewModel.todayProgress, streakDays: homeViewModel.userStats.streakDays)

                NavigationLink {
                    if let resumed = LastStudiedNoteStore.resolve(curriculum: homeViewModel.curriculum) {
                        StudyNoteCategoryDetailView(category: resumed.category, curriculum: homeViewModel.curriculum, resumeAtIndex: resumed.pageIndex)
                    } else {
                        StudyNotesListView(curriculum: homeViewModel.curriculum)
                    }
                } label: {
                    LearnHeroCard(resumed: LastStudiedNoteStore.resolve(curriculum: homeViewModel.curriculum))
                }

                sectionHeader("Start here")
                featureGrid

                sectionHeader("Quick Practice")
                quickPracticeRow

                sectionHeader("Exam Prep")
                revisionRow

                if let challenge = homeViewModel.dailyChallenge {
                    DailyChallengeBanner(
                        simulation: challenge,
                        isCompletedToday: UserStatsCalculator.hasCompletedToday(
                            homeViewModel.attempts, target: challenge.label
                        ),
                        curriculum: homeViewModel.curriculum
                    )
                }

                curriculumSummary
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { homeViewModel.refreshStats() }
        .navigationDestination(item: $randomDestination) { destination in
            switch destination {
            case .apparatus(let type):
                ApparatusPracticeContainerView(apparatusType: type, curriculum: homeViewModel.curriculum)
            case .simulation(let type):
                SimulationDestinationView(type: type, curriculum: homeViewModel.curriculum)
            case .quickQuiz(let count):
                AcePracticeSessionView(
                    repository: AttemptRepository(modelContext: modelContext),
                    curriculum: homeViewModel.curriculum, filterTopic: nil, filterSkill: nil,
                    isMockExam: false, mockExamMinutes: profile.durationMinutes,
                    questionLimit: count, sessionTitle: "Quick Quiz"
                )
            }
        }
    }

    private var header: some View {
        NavigationLink {
            CurriculumPickerView(homeViewModel: homeViewModel, isOnboarding: false)
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.homeHeadlineLine1)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text(profile.homeHeadlineLine2)
                        Text("\u{00B7} Change")
                            .foregroundStyle(Color.accentColor)
                    }
                    .font(.title3)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .padding(.top, 2)
    }

    // MARK: - Feature grid (the four primary practice modes)

    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            NavigationLink {
                SimulationListView(profile: profile)
            } label: {
                FeatureCard(title: "Virtual Lab", subtitle: "Build & perform experiments", systemImage: "flask.fill", tint: .teal)
            }
            NavigationLink {
                ApparatusListView(profile: profile)
            } label: {
                FeatureCard(title: "Apparatus Trainer", subtitle: "Learn & test every apparatus", systemImage: "ruler.fill", tint: .green)
            }
            NavigationLink {
                GraphCoachListView(profile: profile)
            } label: {
                FeatureCard(title: "Graph Coach", subtitle: "Draw perfect graphs", systemImage: "chart.xyaxis.line", tint: .purple)
            }
            NavigationLink {
                AceListView(curriculum: homeViewModel.curriculum)
            } label: {
                FeatureCard(title: "ACE Practice", subtitle: "Answer, compare & evaluate", systemImage: "checkmark.seal.fill", tint: .orange)
            }
        }
    }

    // MARK: - Quick Practice (fast, re-rollable drills)

    private var quickPracticeRow: some View {
        VStack(spacing: 10) {
            Button {
                if let type = profile.simulations.randomElement() {
                    randomDestination = .simulation(type)
                }
            } label: {
                QuickPracticeCard(title: "Random Experiment", subtitle: "Practice any experiment", systemImage: "die.face.5.fill", tint: .blue)
            }
            .buttonStyle(.plain)
            .disabled(profile.simulations.isEmpty)

            Button {
                randomDestination = .quickQuiz(Int.random(in: 5...10))
            } label: {
                QuickPracticeCard(title: "Quick Quiz", subtitle: "5\u{2013}10 questions to test yourself", systemImage: "bolt.fill", tint: .yellow)
            }
            .buttonStyle(.plain)

            Button {
                if let type = profile.apparatus.randomElement() {
                    randomDestination = .apparatus(type)
                }
            } label: {
                QuickPracticeCard(title: "Random Apparatus", subtitle: "Identify & learn apparatus", systemImage: "flask", tint: .orange)
            }
            .buttonStyle(.plain)
            .disabled(profile.apparatus.isEmpty)
        }
    }

    // MARK: - Exam prep (Last Minute Revision + Answering Techniques)

    private var revisionRow: some View {
        VStack(spacing: 12) {
            NavigationLink {
                LastMinuteRevisionView()
            } label: {
                RevisionCard(
                    title: "Last Minute Revision", systemImage: "book.fill", tint: .blue,
                    description: "Key formulas, important points & high yield notes"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                AnsweringTechniquesListView(curriculum: homeViewModel.curriculum)
            } label: {
                RevisionCard(
                    title: "Answering Techniques", systemImage: "pencil.and.list.clipboard", tint: .green,
                    description: "Precision, common errors & how to write the answer, per apparatus"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var curriculumSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(profile.examBoard) \u{00B7} \(profile.paperName)")
                .font(.headline)
            Text(profile.markingScheme)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(profile.toleranceNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Continue Learning card

private struct ContinueLearningCard: View {
    let homeViewModel: HomeViewModel
    let profile: CurriculumProfile
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let target = ContinueLearningResolver.resolve(homeViewModel.userStats.lastAttempt)
        let label = ContinueLearningResolver.label(homeViewModel.userStats.lastAttempt)

        Group {
            switch target {
            case .apparatus(let type):
                NavigationLink {
                    ApparatusPracticeView(
                        apparatusType: type, curriculum: homeViewModel.curriculum,
                        repository: AttemptRepository(modelContext: modelContext),
                        onSaved: { homeViewModel.refreshStats() }
                    )
                } label: {
                    ContinueCardBody(title: "Continue: \(label)", systemImage: "arrow.forward.circle.fill")
                }
            case .graph(let type):
                NavigationLink {
                    GraphCoachPracticeView(
                        graphType: type, curriculum: homeViewModel.curriculum,
                        repository: AttemptRepository(modelContext: modelContext),
                        onSaved: { homeViewModel.refreshStats() }
                    )
                } label: {
                    ContinueCardBody(title: "Continue: \(label)", systemImage: "arrow.forward.circle.fill")
                }
            case .acePractice:
                NavigationLink {
                    AceListView(curriculum: homeViewModel.curriculum)
                } label: {
                    ContinueCardBody(title: "Continue ACE practice", systemImage: "arrow.forward.circle.fill")
                }
            case .simulationLab(let type):
                NavigationLink {
                    SimulationDestinationView(type: type, curriculum: homeViewModel.curriculum)
                } label: {
                    ContinueCardBody(title: "Continue: \(label)", systemImage: "arrow.forward.circle.fill")
                }
            case .none:
                NavigationLink {
                    ApparatusListView(profile: profile)
                } label: {
                    ContinueCardBody(title: label, systemImage: "sparkles")
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ContinueCardBody: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text("Tap to jump back in").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .foregroundStyle(.white)
    }
}

// MARK: - Today's Progress card

private struct TodayProgressCard: View {
    let progress: TodayProgress
    let streakDays: Int

    private static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress").font(.headline)

            HStack(alignment: .center, spacing: 16) {
                DailyGoalRing(percent: progress.dailyGoalPercent)

                VStack(spacing: 10) {
                    statRow(value: "\(progress.experimentsToday)", label: "Experiments", systemImage: "flask.fill", tint: .teal)
                    statRow(value: "\(progress.apparatusToday)", label: "Apparatus", systemImage: "ruler.fill", tint: .green)
                    statRow(value: "\(progress.xpToday)", label: "XP Earned", systemImage: "star.fill", tint: .yellow)
                }
                .frame(maxWidth: .infinity)

                streakBlock
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statRow(value: String, label: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).foregroundStyle(tint).font(.caption)
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private var streakBlock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(streakDays)").font(.title3.bold())
            }
            Text("Day Streak").font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text(Self.weekdayLetters[index]).font(.system(size: 9)).foregroundStyle(.secondary)
                        Image(systemName: progress.weekActivity[index] ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13))
                            .foregroundStyle(progress.weekActivity[index] ? .green : Color(.tertiaryLabel))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DailyGoalRing: View {
    let percent: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(percent, 0), 100)) / 100)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(percent)%").font(.headline.bold())
                Text("Daily\nGoal").font(.system(size: 9)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .frame(width: 76, height: 76)
    }
}

// MARK: - Daily Practical Challenge banner

private struct DailyChallengeBanner: View {
    let simulation: SimulationType
    let isCompletedToday: Bool
    let curriculum: Curriculum

    var body: some View {
        NavigationLink {
            SimulationDestinationView(type: simulation, curriculum: curriculum)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily Practical Challenge").font(.subheadline.weight(.semibold))
                    Text(simulation.descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 12) {
                        Label("+20 XP", systemImage: "star.fill").foregroundStyle(.yellow)
                        Label("+1 Badge", systemImage: "shield.fill").foregroundStyle(.green)
                    }
                    .font(.caption2.weight(.semibold))
                }

                Spacer(minLength: 8)

                if isCompletedToday {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Text("Start Now")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.orange, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared card components

/// Full-width, larger-than-grid treatment for the Learn tab — deliberately
/// not just a fifth tile squeezed into `featureGrid`, since a hero feature
/// should read as more prominent than the other four, not equal to them.
/// Shows "Continue reading: <note title>" and resumes at that exact page
/// when the student has read something before, falling back to a generic
/// invitation into the Study Notes list otherwise.
private struct LearnHeroCard: View {
    let resumed: (category: StudyNoteCategory, pageIndex: Int, note: StudyNote)?

    private var title: String { resumed == nil ? "Learn" : "Continue reading" }
    private var subtitle: String {
        guard let resumed else { return "Study notes & concept walkthroughs for every topic" }
        return "\(resumed.note.title) · \(resumed.category.label)"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title3.bold()).foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.blue.opacity(0.25), lineWidth: 1.5)
        )
    }
}

/// Shows "X days to go" once the student has set an exam date, or a CTA
/// to set one if they haven't. Self-contained — reads/writes
/// `ExamDateStore` directly and presents its own sheet to set the date,
/// so it works from Home without needing to hop to Settings (which has
/// the same control too, for anyone who prefers to set it there instead).
private struct ExamCountdownCard: View {
    @State private var examDate: Date?
    @State private var showingPicker = false
    @State private var draftDate: Date = Date()

    private var daysRemaining: Int? { ExamDateStore.daysRemaining() }

    var body: some View {
        Button {
            draftDate = examDate ?? Date()
            showingPicker = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    if let days = daysRemaining {
                        Text(countdownHeadline(for: days)).font(.title3.bold()).foregroundStyle(.primary)
                        Text("until your Physics Practical exam").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Set your exam date").font(.title3.bold()).foregroundStyle(.primary)
                        Text("See how many days you have left to prepare").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.orange.opacity(0.25), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .onAppear { examDate = ExamDateStore.get() }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker("Exam date", selection: $draftDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)

                    if examDate != nil {
                        Button("Clear exam date", role: .destructive) {
                            ExamDateStore.set(nil)
                            examDate = nil
                            showingPicker = false
                        }
                    }
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("Exam Countdown")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingPicker = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            ExamDateStore.set(draftDate)
                            examDate = draftDate
                            showingPicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func countdownHeadline(for days: Int) -> String {
        if days < 0 { return "Exam date has passed" }
        if days == 0 { return "Exam is today — good luck!" }
        if days == 1 { return "1 day to go" }
        return "\(days) days to go"
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            Spacer(minLength: 0)
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(tint, in: Circle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 140)
        .padding(16)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct QuickPracticeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct RevisionCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text("Open")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(tint, in: Capsule())
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
