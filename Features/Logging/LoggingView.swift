import SwiftUI

struct LoggingView: View {
    @EnvironmentObject private var app: AppState
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BubblesCanvas()
            VStack {
                Spacer(minLength: 16)
                if case let .running(since) = app.state {
                    Text(elapsedString(from: since, to: now))
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .padding(.bottom, 24)
                        .accessibilityLabel("Elapsed time")
                } else {
                    Spacer().frame(height: 60)
                }
                StartStopButton()
                    .frame(width: 220, height: 220)
                    .padding(.vertical, 32)
                Spacer()
                DailyStripeView()
                    .frame(height: 20)
                    .padding(.bottom, 24)
            }
            .padding()
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onReceive(timer) { value in
            now = value
        }
        .sheet(isPresented: $app.isPromptPresented) {
            NamePromptSheet()
                .environmentObject(app)
        }
        .onAppear {
            app.resumeIfNeeded()
        }
    }

    private func elapsedString(from start: Date, to end: Date) -> String {
        let elapsed = Int(end.timeIntervalSince(start))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct LoggingView_Previews: PreviewProvider {
    static var previews: some View {
        LoggingView()
            .environmentObject(AppState(store: Store()))
    }
}
