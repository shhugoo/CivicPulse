import SwiftUI

struct SimulationLoadingView: View {
    let cityName: String
    let onComplete: () -> Void

    @State private var animatePulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.31, green: 0.91, blue: 0.94), Color(red: 0.19, green: 0.78, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 27) {
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(.black.opacity(0.13), lineWidth: 1.5)
                            .frame(width: 112, height: 112)
                            .scaleEffect(animatePulse ? 1.25 + CGFloat(index) * 0.42 : 0.55)
                            .opacity(animatePulse ? 0 : 0.65 - Double(index) * 0.12)
                            .animation(
                                .easeOut(duration: 2.1)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.48),
                                value: animatePulse
                            )
                    }

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 37, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 92, height: 92)
                        .background(.white.opacity(0.58), in: Circle())
                        .scaleEffect(animatePulse ? 1.06 : 0.94)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animatePulse)
                }
                .frame(height: 190)

                VStack(spacing: 9) {
                    Text("simulando datos...")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .tracking(-0.6)
                        .foregroundStyle(.black)
                    Text("Actualizando tráfico e incidentes en \(cityName)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.62))
                        .multilineTextAlignment(.center)
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(1.15)
                        .padding(.top, 7)
                }
            }
            .padding(.horizontal, 30)
        }
        .preferredColorScheme(.light)
        .onAppear { animatePulse = true }
        .task {
            do { try await Task.sleep(for: .seconds(2.8)) } catch { return }
            guard !Task.isCancelled else { return }
            onComplete()
        }
    }
}
