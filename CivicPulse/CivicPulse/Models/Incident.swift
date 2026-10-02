import MapKit
import SwiftUI

enum IncidentPriority: String {
    case medium = "Media"
    case high = "Alta"
    case veryHigh = "Muy Alta"

    var color: Color {
        switch self {
        case .medium: return Color(red: 0.83, green: 0.48, blue: 0.08)
        case .high: return Color(red: 0.78, green: 0.24, blue: 0.12)
        case .veryHigh: return Color(red: 0.65, green: 0.10, blue: 0.18)
        }
    }
}

enum EmergencyService: String {
    case police = "Policía"
    case ambulance = "Ambulancia"

    var symbol: String {
        switch self {
        case .police: return "car.side.fill"
        case .ambulance: return "cross.case.fill"
        }
    }
}

struct IncidentRouteOption: Identifiable {
    let id: String
    let name: String
    let coordinates: [CLLocationCoordinate2D]
    let trafficHotspotIDs: [String]
    let baseMinutes: Int
    let distanceKilometers: Double
    let directions: [String]
}

struct RouteDisturbance: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let delayMinutes: Int
    let blocked: Bool
    let affectedRouteIDs: [String]
}

struct PlannedRoute {
    let option: IncidentRouteOption
    let disturbances: [RouteDisturbance]
    let trafficDelayMinutes: Int

    var isBlocked: Bool {
        disturbances.contains(where: \.blocked)
    }

    var estimatedMinutes: Int {
        option.baseMinutes
            + trafficDelayMinutes
            + disturbances.filter { !$0.blocked }.reduce(0) { $0 + $1.delayMinutes }
    }
}

enum RoutePlanner {
    static func compareRoutes(
        for incident: CivicIncident,
        trafficStep: Int,
        hotspots: [SimulatedTrafficHotspot]
    ) -> [PlannedRoute] {
        incident.routes
            .map { route in
                let trafficDelay = route.trafficHotspotIDs.reduce(0) { total, hotspotID in
                    guard let hotspot = hotspots.first(where: { $0.id == hotspotID }) else {
                        return total
                    }
                    switch hotspot.condition(at: trafficStep) {
                    case .fluid: return total
                    case .moderate: return total + 2
                    case .dense: return total + 5
                    }
                }
                return PlannedRoute(
                    option: route,
                    disturbances: incident.disturbances.filter { $0.affectedRouteIDs.contains(route.id) },
                    trafficDelayMinutes: trafficDelay
                )
            }
            .sorted { first, second in
                if first.isBlocked != second.isBlocked { return !first.isBlocked }
                return first.estimatedMinutes < second.estimatedMinutes
            }
    }

    static func bestRoute(
        for incident: CivicIncident,
        trafficStep: Int,
        hotspots: [SimulatedTrafficHotspot]
    ) -> PlannedRoute? {
        compareRoutes(for: incident, trafficStep: trafficStep, hotspots: hotspots).first(where: { !$0.isBlocked })
    }
}

struct CivicIncident: Identifiable {
    let id: String
    let address: String
    let priority: IncidentPriority
    let description: String
    let service: EmergencyService
    let coordinate: CLLocationCoordinate2D
    let vehicleRoute: [CLLocationCoordinate2D]
    let routes: [IncidentRouteOption]
    let disturbances: [RouteDisturbance]

    static let salamanca: [CivicIncident] = [
        CivicIncident(
            id: "incident-01",
            address: "Calle Zamora, 43, Salamanca",
            priority: .high,
            description: "Persona herida tras una caída. Se solicita asistencia sanitaria.",
            service: .ambulance,
            coordinate: CLLocationCoordinate2D(latitude: 40.9662, longitude: -5.6634),
            vehicleRoute: route(to: CLLocationCoordinate2D(latitude: 40.9662, longitude: -5.6634), via: [
                CLLocationCoordinate2D(latitude: 40.9564, longitude: -5.6715),
                CLLocationCoordinate2D(latitude: 40.9613, longitude: -5.6682)
            ]),
            routes: [
                routeOption("direct", "Ruta directa", to: CLLocationCoordinate2D(latitude: 40.9662, longitude: -5.6634), via: [
                    CLLocationCoordinate2D(latitude: 40.9564, longitude: -5.6715), CLLocationCoordinate2D(latitude: 40.9613, longitude: -5.6682)
                ], hotspots: ["plaza-espana", "gran-via"], minutes: 7, distance: 3.1),
                routeOption("west", "Desvío oeste", to: CLLocationCoordinate2D(latitude: 40.9662, longitude: -5.6634), via: [
                    CLLocationCoordinate2D(latitude: 40.9578, longitude: -5.6790), CLLocationCoordinate2D(latitude: 40.9630, longitude: -5.6750)
                ], hotspots: ["carmelitas"], minutes: 9, distance: 4.0),
                routeOption("east", "Vía alternativa", to: CLLocationCoordinate2D(latitude: 40.9662, longitude: -5.6634), via: [
                    CLLocationCoordinate2D(latitude: 40.9572, longitude: -5.6645), CLLocationCoordinate2D(latitude: 40.9625, longitude: -5.6610)
                ], hotspots: ["canalejas"], minutes: 11, distance: 4.3)
            ],
            disturbances: demoDisturbances
        ),
        CivicIncident(
            id: "incident-02",
            address: "Avenida de Portugal, 86, Salamanca",
            priority: .medium,
            description: "Aviso por alteración del orden público. Se requiere una patrulla.",
            service: .police,
            coordinate: CLLocationCoordinate2D(latitude: 40.9681, longitude: -5.6713),
            vehicleRoute: route(to: CLLocationCoordinate2D(latitude: 40.9681, longitude: -5.6713), via: [
                CLLocationCoordinate2D(latitude: 40.9578, longitude: -5.6772),
                CLLocationCoordinate2D(latitude: 40.9634, longitude: -5.6750)
            ]),
            routes: [
                routeOption("direct", "Ruta directa", to: CLLocationCoordinate2D(latitude: 40.9681, longitude: -5.6713), via: [
                    CLLocationCoordinate2D(latitude: 40.9578, longitude: -5.6772), CLLocationCoordinate2D(latitude: 40.9634, longitude: -5.6750)
                ], hotspots: ["plaza-espana", "gran-via"], minutes: 6, distance: 2.8),
                routeOption("west", "Desvío oeste", to: CLLocationCoordinate2D(latitude: 40.9681, longitude: -5.6713), via: [
                    CLLocationCoordinate2D(latitude: 40.9586, longitude: -5.6802), CLLocationCoordinate2D(latitude: 40.9651, longitude: -5.6790)
                ], hotspots: ["carmelitas"], minutes: 8, distance: 3.9),
                routeOption("east", "Vía alternativa", to: CLLocationCoordinate2D(latitude: 40.9681, longitude: -5.6713), via: [
                    CLLocationCoordinate2D(latitude: 40.9580, longitude: -5.6681), CLLocationCoordinate2D(latitude: 40.9635, longitude: -5.6695)
                ], hotspots: ["canalejas"], minutes: 6, distance: 2.7)
            ],
            disturbances: demoDisturbances
        ),
        CivicIncident(
            id: "incident-03",
            address: "Paseo de Canalejas, 126, Salamanca",
            priority: .veryHigh,
            description: "Emergencia médica urgente. Se solicita una ambulancia con prioridad.",
            service: .ambulance,
            coordinate: CLLocationCoordinate2D(latitude: 40.9635, longitude: -5.6528),
            vehicleRoute: route(to: CLLocationCoordinate2D(latitude: 40.9635, longitude: -5.6528), via: [
                CLLocationCoordinate2D(latitude: 40.9555, longitude: -5.6661),
                CLLocationCoordinate2D(latitude: 40.9607, longitude: -5.6591)
            ]),
            routes: [
                routeOption("direct", "Ruta directa", to: CLLocationCoordinate2D(latitude: 40.9635, longitude: -5.6528), via: [
                    CLLocationCoordinate2D(latitude: 40.9555, longitude: -5.6661), CLLocationCoordinate2D(latitude: 40.9607, longitude: -5.6591)
                ], hotspots: ["plaza-espana", "gran-via"], minutes: 7, distance: 3.2),
                routeOption("west", "Desvío oeste", to: CLLocationCoordinate2D(latitude: 40.9635, longitude: -5.6528), via: [
                    CLLocationCoordinate2D(latitude: 40.9558, longitude: -5.6770), CLLocationCoordinate2D(latitude: 40.9605, longitude: -5.6690)
                ], hotspots: ["carmelitas"], minutes: 9, distance: 4.6),
                routeOption("east", "Vía alternativa", to: CLLocationCoordinate2D(latitude: 40.9635, longitude: -5.6528), via: [
                    CLLocationCoordinate2D(latitude: 40.9545, longitude: -5.6600), CLLocationCoordinate2D(latitude: 40.9598, longitude: -5.6558)
                ], hotspots: ["canalejas"], minutes: 10, distance: 4.1)
            ],
            disturbances: demoDisturbances
        ),
        CivicIncident(
            id: "incident-04",
            address: "Plaza de España, Salamanca",
            priority: .medium,
            description: "Colisión entre vehículos sin heridos graves. Se solicita una patrulla.",
            service: .police,
            coordinate: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635),
            vehicleRoute: route(to: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635), via: [
                CLLocationCoordinate2D(latitude: 40.9577, longitude: -5.6760),
                CLLocationCoordinate2D(latitude: 40.9628, longitude: -5.6702)
            ]),
            routes: [
                routeOption("direct", "Ruta directa", to: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635), via: [
                    CLLocationCoordinate2D(latitude: 40.9577, longitude: -5.6760), CLLocationCoordinate2D(latitude: 40.9628, longitude: -5.6702)
                ], hotspots: ["plaza-espana", "gran-via"], minutes: 6, distance: 2.6),
                routeOption("west", "Desvío oeste", to: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635), via: [
                    CLLocationCoordinate2D(latitude: 40.9570, longitude: -5.6801), CLLocationCoordinate2D(latitude: 40.9622, longitude: -5.6770)
                ], hotspots: ["carmelitas"], minutes: 9, distance: 3.8),
                routeOption("east", "Vía alternativa", to: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635), via: [
                    CLLocationCoordinate2D(latitude: 40.9584, longitude: -5.6639), CLLocationCoordinate2D(latitude: 40.9623, longitude: -5.6622)
                ], hotspots: ["canalejas"], minutes: 8, distance: 3.3)
            ],
            disturbances: demoDisturbances
        ),
        CivicIncident(
            id: "incident-05",
            address: "Calle de San Pablo, Salamanca",
            priority: .veryHigh,
            description: "Persona con una urgencia médica. Se dirige una ambulancia.",
            service: .ambulance,
            coordinate: CLLocationCoordinate2D(latitude: 40.9611, longitude: -5.6624),
            vehicleRoute: route(to: CLLocationCoordinate2D(latitude: 40.9611, longitude: -5.6624), via: [
                CLLocationCoordinate2D(latitude: 40.9558, longitude: -5.6712),
                CLLocationCoordinate2D(latitude: 40.9592, longitude: -5.6671)
            ]),
            routes: [
                routeOption("direct", "Ruta directa", to: CLLocationCoordinate2D(latitude: 40.9611, longitude: -5.6624), via: [
                    CLLocationCoordinate2D(latitude: 40.9558, longitude: -5.6712), CLLocationCoordinate2D(latitude: 40.9592, longitude: -5.6671)
                ], hotspots: ["plaza-espana", "gran-via"], minutes: 5, distance: 2.2),
                routeOption("west", "Desvío oeste", to: CLLocationCoordinate2D(latitude: 40.9611, longitude: -5.6624), via: [
                    CLLocationCoordinate2D(latitude: 40.9565, longitude: -5.6790), CLLocationCoordinate2D(latitude: 40.9605, longitude: -5.6730)
                ], hotspots: ["carmelitas"], minutes: 8, distance: 3.7),
                routeOption("east", "Vía alternativa", to: CLLocationCoordinate2D(latitude: 40.9611, longitude: -5.6624), via: [
                    CLLocationCoordinate2D(latitude: 40.9548, longitude: -5.6623), CLLocationCoordinate2D(latitude: 40.9585, longitude: -5.6608)
                ], hotspots: ["canalejas"], minutes: 7, distance: 3.1)
            ],
            disturbances: demoDisturbances
        )
    ]

    private static let demoDisturbances = [
        RouteDisturbance(
            id: "crash-jam",
            title: "Atasco por otro accidente",
            detail: "Retención en la vía principal. Se estima una demora de 4 minutos.",
            symbol: "car.rear.waves.up",
            delayMinutes: 4,
            blocked: false,
            affectedRouteIDs: ["direct", "west"]
        ),
        RouteDisturbance(
            id: "roadworks",
            title: "Calle cortada por obras",
            detail: "El tramo está cerrado y la ruta directa no puede utilizarse.",
            symbol: "cone.fill",
            delayMinutes: 0,
            blocked: true,
            affectedRouteIDs: ["direct"]
        ),
        RouteDisturbance(
            id: "signal-delay",
            title: "Semáforo con retención anormal",
            detail: "La espera prolongada añade unos 3 minutos.",
            symbol: "trafficlight.fill",
            delayMinutes: 3,
            blocked: false,
            affectedRouteIDs: ["direct", "east"]
        ),
        RouteDisturbance(
            id: "unit-in-zone",
            title: "Unidad entrando en zona congestionada",
            detail: "La ambulancia o patrulla avanza por una zona de circulación lenta.",
            symbol: "cross.case.fill",
            delayMinutes: 2,
            blocked: false,
            affectedRouteIDs: ["east"]
        )
    ]

    private static func route(to destination: CLLocationCoordinate2D, via: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        [CLLocationCoordinate2D(latitude: 40.9509, longitude: -5.6747)] + via + [destination]
    }

    private static func routeOption(
        _ id: String,
        _ name: String,
        to destination: CLLocationCoordinate2D,
        via: [CLLocationCoordinate2D],
        hotspots: [String],
        minutes: Int,
        distance: Double
    ) -> IncidentRouteOption {
        IncidentRouteOption(
            id: id,
            name: name,
            coordinates: route(to: destination, via: via),
            trafficHotspotIDs: hotspots,
            baseMinutes: minutes,
            distanceKilometers: distance,
            directions: [
                "Sal desde el centro de respuesta por la ruta seleccionada.",
                "Sigue por \(name.lowercased()) y mantente en el itinerario recomendado.",
                "El incidente está en \(destination.latitude.formatted(.number.precision(.fractionLength(3)))), \(destination.longitude.formatted(.number.precision(.fractionLength(3))))."
            ]
        )
    }
}
