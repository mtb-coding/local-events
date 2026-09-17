import SwiftUI

struct CategoryChipView: View {
    let category: EventCategory
    var isSelected: Bool = false
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.systemImage)
            Text(category.rawValue)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .font(compact ? .caption : .subheadline)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 7)
        .background(
            Capsule()
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
        )
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        .overlay(
            Capsule()
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    HStack {
        CategoryChipView(category: .music, isSelected: true)
        CategoryChipView(category: .food, compact: true)
    }
    .padding()
}
