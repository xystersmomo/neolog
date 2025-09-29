import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    enum LogState: Equatable {
        case idle
        case running(since: Date)
        case prompting
    }

    @Published private(set) var state: LogState = .idle
    @Published var promptText: String = ""
    @Published var isPromptPresented: Bool = false

    @Published private(set) var availableActivities: [Activity] = []
    @Published private(set) var runningSession: Session?
    @Published private(set) var dayBuckets: [DayBucket] = []

    private var store: Store
    private var cancellables = Set<AnyCancellable>()

    init(store: Store) {
        self.store = store
        bindStore()
        resumeIfNeeded()
    }

    func startLogging(activityName: String?) {
        guard runningSession == nil else { return }
        store.startSession(named: activityName)
        runningSession = store.runningSession
        if let start = store.runningSession?.start {
            state = .running(since: start)
        } else {
            state = .running(since: Date())
        }
        isPromptPresented = false
        promptText = ""
    }

    func stopLogging() {
        guard runningSession != nil else { return }
        store.stopSession()
        runningSession = store.runningSession
        state = .prompting
        promptText = runningSession?.activityName ?? ""
        isPromptPresented = true
    }

    func resumeIfNeeded() {
        guard let running = store.runningSession else { return }
        runningSession = running
        if running.end != nil {
            state = .prompting
            promptText = running.activityName
            isPromptPresented = true
        } else {
            state = .running(since: running.start)
        }
    }

    func confirmActivityName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.finalizeSession(activityName: trimmed)
        runningSession = store.runningSession
        isPromptPresented = false
        state = .idle
        promptText = ""
    }

    func selectExistingActivity(_ activity: Activity) {
        promptText = activity.name
        confirmActivityName(activity.name)
    }

    func totalSeconds(for activityName: String) -> Int {
        store.totalSeconds(for: activityName)
    }

    private func bindStore() {
        store.$activities
            .receive(on: DispatchQueue.main)
            .map { $0.sortedByRecent() }
            .assign(to: &$availableActivities)

        store.$runningSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                self.runningSession = session
                if let session {
                    if session.end != nil {
                        if self.state != .prompting {
                            self.state = .prompting
                            self.promptText = session.activityName
                            self.isPromptPresented = true
                        }
                        // Keep prompting state while awaiting confirmation.
                        return
                    }
                    if self.state != .prompting {
                        self.state = .running(since: session.start)
                    }
                } else if self.state != .prompting {
                    self.state = .idle
                }
            }
            .store(in: &cancellables)

        store.$dayBuckets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buckets in
                self?.dayBuckets = buckets
            }
            .store(in: &cancellables)
    }
}
