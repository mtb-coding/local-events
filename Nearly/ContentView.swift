import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(
                    onContinue: { hasCompletedOnboarding = true },
                    onRequestLocation: { locationManager.requestPermission() }
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(LocationManager())
        .environment(DiscoverViewModel(eventService: MockEventService()))
}
