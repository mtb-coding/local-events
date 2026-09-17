import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void
    let onRequestLocation: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text("Welcome to Nearly")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Discover nearby local events and save your favorites. Nearly uses your location to sort what’s close to you.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "location.fill", title: "Find what’s near", detail: "See events around your neighborhood.")
                featureRow(icon: "bookmark.fill", title: "Save favorites", detail: "Bookmark events to revisit anytime.")
                featureRow(icon: "map.fill", title: "See it on the map", detail: "Open details with a MapKit pin.")
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onRequestLocation()
                    onContinue()
                } label: {
                    Text("Continue with Location")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Maybe later") {
                    onContinue()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView(onContinue: {}, onRequestLocation: {})
}
