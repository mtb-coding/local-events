import SwiftUI
import CoreLocation

struct EventRowView: View {
    let event: Event
    let userLocation: CLLocation?
    var isSaved: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: event.imageSystemName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    if isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }

                Text(Self.dateFormatter.string(from: event.startDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(event.venueName) · \(event.neighborhood)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    CategoryChipView(category: event.category, compact: true)
                    Text(event.formattedDistance(from: userLocation))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
