import SwiftUI

struct DrinkCard: View {
    let drink: DrinkSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: drink.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "wineglass")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                case .empty:
                    ProgressView()
                @unknown default:
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(drink.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
    }
}
