import SwiftUI

struct DailyStripeView: View {
    @EnvironmentObject private var app: AppState
    private let tileHeight: CGFloat = 16

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(app.dayBuckets) { bucket in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(bucket.tileSlices) { slice in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color(hex: slice.colorHex) ?? .gray)
                                    .frame(width: max(6, CGFloat(slice.seconds) / 60.0 * 6), height: tileHeight)
                                    .accessibilityLabel("\(slice.activityName) \(slice.seconds / 60)분")
                            }
                        }
                        Text(bucket.id)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color(.systemGray6).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct DailyStripeView_Previews: PreviewProvider {
    static var previews: some View {
        DailyStripeView()
            .environmentObject(AppState(store: Store()))
            .frame(height: 40)
    }
}
