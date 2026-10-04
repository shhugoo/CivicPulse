import Foundation
import MapKit

struct OpenRouteAlternative: Identifiable {
    let id: String
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let durationSeconds: Double
    let instructions: [String]

    var durationMinutes: Int { Int((durationSeconds / 60).rounded(.up)) }
    var distanceKilometers: Double { distanceMeters / 1_000 }
}

enum OpenRouteServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case noRoutes
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Falta la clave de OpenRouteService. Añade ORS_API_KEY a Secrets.xcconfig y vuelve a compilar."
        case .invalidResponse:
            return "OpenRouteService devolvió una respuesta que la app no pudo interpretar."
        case .noRoutes:
            return "OpenRouteService no encontró rutas para este incidente."
        case let .httpError(status, detail):
            return "OpenRouteService respondió con error (\(status)): \(detail)"
        }
    }
}

struct OpenRouteService {
    private let session: URLSession
    private let apiKey: String
    private let baseURL = URL(string: "https://api.heigit.org/openrouteservice/v2/directions")!

    init(session: URLSession = .shared, apiKey: String? = nil) {
        self.session = session
        self.apiKey = apiKey ?? (Bundle.main.object(forInfoDictionaryKey: "ORS_API_KEY") as? String ?? "")
    }

    func calculateDrivingRoutes(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        alternativeCount: Int = 3
    ) async throws -> [OpenRouteAlternative] {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.hasPrefix("$(") else { throw OpenRouteServiceError.missingAPIKey }

        let endpoint = baseURL
            .appendingPathComponent("driving-car")
            .appendingPathComponent("geojson")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/geo+json, application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 25

        let body = DirectionsRequest(
            coordinates: [
                [origin.longitude, origin.latitude],
                [destination.longitude, destination.latitude]
            ],
            alternativeRoutes: AlternativeRoutes(targetCount: min(max(alternativeCount, 1), 3)),
            instructions: true,
            units: "m"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw OpenRouteServiceError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else {
            let detail = (try? JSONDecoder().decode(ServiceErrorResponse.self, from: data).error.message)
                ?? String(data: data, encoding: .utf8)
                ?? "Error sin descripción"
            throw OpenRouteServiceError.httpError(response.statusCode, detail)
        }

        let decoded: DirectionsResponse
        do {
            decoded = try JSONDecoder().decode(DirectionsResponse.self, from: data)
        } catch {
            throw OpenRouteServiceError.invalidResponse
        }

        let routes = decoded.features.enumerated().compactMap { index, feature -> OpenRouteAlternative? in
            let coordinates = feature.geometry.coordinates.compactMap { pair -> CLLocationCoordinate2D? in
                guard pair.count >= 2 else { return nil }
                return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
            }
            guard coordinates.count >= 2 else { return nil }
            let instructions = feature.properties.segments?.flatMap { $0.steps ?? [] }.map(\.instruction) ?? []
            return OpenRouteAlternative(
                id: "ors-\(index)",
                name: index == 0 ? "Ruta recomendada" : "Alternativa \(index)",
                coordinates: coordinates,
                distanceMeters: feature.properties.summary.distance,
                durationSeconds: feature.properties.summary.duration,
                instructions: instructions.isEmpty ? ["Continúa hacia el incidente."] : instructions
            )
        }
        guard !routes.isEmpty else { throw OpenRouteServiceError.noRoutes }
        return routes
    }
}

private struct DirectionsRequest: Encodable {
    let coordinates: [[Double]]
    let alternativeRoutes: AlternativeRoutes
    let instructions: Bool
    let units: String

    enum CodingKeys: String, CodingKey {
        case coordinates
        case alternativeRoutes = "alternative_routes"
        case instructions
        case units
    }
}

private struct AlternativeRoutes: Encodable {
    let targetCount: Int
    let weightFactor = 1.6
    let shareFactor = 0.6

    enum CodingKeys: String, CodingKey {
        case targetCount = "target_count"
        case weightFactor = "weight_factor"
        case shareFactor = "share_factor"
    }
}

private struct DirectionsResponse: Decodable {
    let features: [Feature]

    struct Feature: Decodable {
        let geometry: Geometry
        let properties: Properties
    }

    struct Geometry: Decodable {
        let coordinates: [[Double]]
    }

    struct Properties: Decodable {
        let summary: Summary
        let segments: [Segment]?
    }

    struct Summary: Decodable {
        let distance: Double
        let duration: Double
    }

    struct Segment: Decodable {
        let steps: [Step]?
    }

    struct Step: Decodable {
        let instruction: String
    }
}

private struct ServiceErrorResponse: Decodable {
    let error: ServiceError

    struct ServiceError: Decodable {
        let message: String
    }
}
