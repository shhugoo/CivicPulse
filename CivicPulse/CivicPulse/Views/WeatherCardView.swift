import SwiftUI

struct WeatherCardView: View {
    let cityName: String
    let weather: CurrentWeather?
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.67))
                Text("Tiempo en \(cityName)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                Spacer(minLength: 0)
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 34, height: 34)
                        .background(.black.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Actualizar el tiempo")
            }

            if let weather {
                HStack(alignment: .center, spacing: 13) {
                    Image(systemName: weather.symbol)
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 43))
                        .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.67))
                        .frame(width: 54)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weather.temperature.formatted(.number.precision(.fractionLength(0))))°C")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                        Text(weather.condition)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.65))
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    metric("Sensación", value: "\(weather.apparentTemperature.formatted(.number.precision(.fractionLength(0))))°C", symbol: "thermometer.medium")
                    metric("Humedad", value: "\(weather.relativeHumidity)%", symbol: "humidity.fill")
                    metric("Viento", value: "\(weather.windSpeed.formatted(.number.precision(.fractionLength(0)))) km/h", symbol: "wind")
                }

                HStack(spacing: 4) {
                    Label("Precipitación: \(weather.precipitation.formatted(.number.precision(.fractionLength(1)))) mm", systemImage: "drop.fill")
                    Spacer(minLength: 0)
                    Text("Datos: \(weather.localTime)")
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.55))
            } else if isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(.black)
                    Text("Consultando Open-Meteo…")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.65))
                }
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            } else {
                Text(errorMessage ?? "Esperando la ubicación de la ciudad…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.65))
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            }

            Text("Datos meteorológicos: Open-Meteo")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.5))
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func metric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
