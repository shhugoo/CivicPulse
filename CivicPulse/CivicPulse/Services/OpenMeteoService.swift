import Foundation
import MapKit

struct CurrentWeather: Decodable {
    let time: String
    let temperature: Double
    let apparentTemperature: Double
    let relativeHumidity: Int
    let precipitation: Double
    let weatherCode: Int
    let windSpeed: Double
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity = "relative_humidity_2m"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case isDay = "is_day"
    }

    var condition: String {
        switch weatherCode {
        case 0: return "Despejado"
        case 1, 2: return "Poco nuboso"
        case 3: return "Cubierto"
        case 45, 48: return "Niebla"
        case 51...57: return "Llovizna"
        case 61...67: return "Lluvia"
        case 71...77, 85, 86: return "Nieve"
        case 80...82: return "Chubascos"
        case 95...99: return "Tormenta"
        default: return "Condiciones variables"
        }
    }

    var symbol: String {
        switch weatherCode {
        case 0: return isDay == 1 ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay == 1 ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }

    var localTime: String {
        String(time.split(separator: "T").last ?? "")
    }
}

enum OpenMeteoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "No se pudo crear la consulta del tiempo."
        case .invalidResponse: return "Los datos del tiempo no se pudieron interpretar."
        case .serviceUnavailable: return "Open-Meteo no está disponible en este momento."
        }
    }
}

struct OpenMeteoService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func currentWeather(at coordinate: CLLocationCoordinate2D) async throws -> CurrentWeather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components?.url else { throw OpenMeteoError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw OpenMeteoError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else { throw OpenMeteoError.serviceUnavailable }

        do {
            return try JSONDecoder().decode(WeatherResponse.self, from: data).current
        } catch {
            throw OpenMeteoError.invalidResponse
        }
    }
}

private struct WeatherResponse: Decodable {
    let current: CurrentWeather
}
