import MapKit

struct CityMapData {
    let cityName: String
    let center: CLLocationCoordinate2D
    let incidents: [CivicIncident]
    let trafficHotspots: [SimulatedTrafficHotspot]
    let closureCoordinate: CLLocationCoordinate2D

    static let salamanca = CityMapData(
        cityName: "Salamanca",
        center: CLLocationCoordinate2D(latitude: 40.9640, longitude: -5.6670),
        incidents: CivicIncident.salamanca,
        trafficHotspots: SimulatedTrafficHotspot.salamanca,
        closureCoordinate: CLLocationCoordinate2D(latitude: 40.9611, longitude: -5.6624)
    )

    static func centered(city: String, at center: CLLocationCoordinate2D) -> CityMapData {
        guard city.caseInsensitiveCompare("Salamanca") != .orderedSame else { return .salamanca }

        let reference = salamanca.center
        let latitudeOffset = center.latitude - reference.latitude
        let longitudeOffset = center.longitude - reference.longitude

        let addresses = [
            "Plaza Mayor, \(city)",
            "Calle Mayor, 12, \(city)",
            "Avenida de la Estación, \(city)",
            "Calle del Mercado, \(city)",
            "Entorno del hospital, \(city)"
        ]

        let cityIncidents = CivicIncident.salamanca.enumerated().map { index, source in
            CivicIncident(
                id: source.id,
                address: addresses[index],
                priority: source.priority,
                description: source.description,
                service: source.service,
                coordinate: shifted(source.coordinate, latitude: latitudeOffset, longitude: longitudeOffset),
                vehicleRoute: source.vehicleRoute.map { shifted($0, latitude: latitudeOffset, longitude: longitudeOffset) },
                routes: source.routes.map { option in
                    var directions = option.directions
                    let destination = shifted(source.coordinate, latitude: latitudeOffset, longitude: longitudeOffset)
                    if !directions.isEmpty {
                        directions[directions.count - 1] = "El incidente está en \(destination.latitude.formatted(.number.precision(.fractionLength(3)))), \(destination.longitude.formatted(.number.precision(.fractionLength(3))))."
                    }
                    return IncidentRouteOption(
                        id: option.id,
                        name: option.name,
                        coordinates: option.coordinates.map { shifted($0, latitude: latitudeOffset, longitude: longitudeOffset) },
                        trafficHotspotIDs: option.trafficHotspotIDs,
                        baseMinutes: option.baseMinutes,
                        distanceKilometers: option.distanceKilometers,
                        directions: directions
                    )
                },
                disturbances: source.disturbances
            )
        }

        let streetNames = [
            "Centro urbano · \(city)",
            "Avenida principal · \(city)",
            "Zona oeste · \(city)",
            "Acceso al hospital · \(city)"
        ]
        let cityHotspots = SimulatedTrafficHotspot.salamanca.enumerated().map { index, hotspot in
            SimulatedTrafficHotspot(
                id: hotspot.id,
                street: streetNames[index],
                coordinate: shifted(hotspot.coordinate, latitude: latitudeOffset, longitude: longitudeOffset),
                radiusMeters: hotspot.radiusMeters,
                cycle: hotspot.cycle
            )
        }

        return CityMapData(
            cityName: city,
            center: center,
            incidents: cityIncidents,
            trafficHotspots: cityHotspots,
            closureCoordinate: shifted(salamanca.closureCoordinate, latitude: latitudeOffset, longitude: longitudeOffset)
        )
    }

    private static func shifted(
        _ coordinate: CLLocationCoordinate2D,
        latitude latitudeOffset: CLLocationDegrees,
        longitude longitudeOffset: CLLocationDegrees
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude + latitudeOffset,
            longitude: coordinate.longitude + longitudeOffset
        )
    }
}
