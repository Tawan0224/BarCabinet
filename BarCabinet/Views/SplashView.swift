import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            logo
                .frame(width: 140, height: 140)
                .scaleEffect(scale)
                .opacity(opacity)

            VStack(spacing: 8) {
                Text("Bar Cabinet")
                    .font(.title.bold())
                Text("Find drinks you can make right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacity)

            Spacer()

            VStack(spacing: 10) {
                ProgressView(value: progress)
                    .tint(Color.accentColor)
                    .frame(maxWidth: 220)
                Text("Getting things ready…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacity)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1
                opacity = 1
            }
            withAnimation(.easeInOut(duration: 2.4)) {
                progress = 1
            }
        }
    }

    @ViewBuilder
    private var logo: some View {
        if UIImage(named: "AppLogo") != nil {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "wineglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color.accentColor)
                .padding(24)
        }
    }
}

#Preview {
    SplashView()
}
