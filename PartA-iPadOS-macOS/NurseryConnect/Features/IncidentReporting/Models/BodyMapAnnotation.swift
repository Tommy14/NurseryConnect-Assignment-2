//
//  BodyMapAnnotation.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 6 April 2026
//  Description: Codable model for injury marker coordinates stored as JSON in Core Data.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 060426     Tommy1914   Created the file with normalised coordinates and body side metadata.
// -----------------------------------------------------------------

import CoreGraphics
import Foundation

/// - Description: Which silhouette is active on the body map UI.
enum BodyMapSide: String, Codable, CaseIterable, Identifiable {
    case front
    case back

    var id: String { rawValue }
}

/// - Description: Single tap marker stored in `Incident.bodyMapAnnotations` as JSON bytes.
struct BodyMapAnnotation: Codable, Hashable, Identifiable {
    /// - Description: Stable identity for SwiftUI lists; persisted for round-trips when encoded.
    var id: UUID
    var side: BodyMapSide
    var normalizedX: Double
    var normalizedY: Double

    init(id: UUID = UUID(), side: BodyMapSide, normalizedX: Double, normalizedY: Double) {
        self.id = id
        self.side = side
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
    }

    private enum CodingKeys: String, CodingKey {
        case id, side, normalizedX, normalizedY
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        side = try c.decode(BodyMapSide.self, forKey: .side)
        normalizedX = try c.decode(Double.self, forKey: .normalizedX)
        normalizedY = try c.decode(Double.self, forKey: .normalizedY)
    }
}

/// - Description: Encodes and decodes annotation arrays for Core Data `Data` storage.
enum BodyMapCodec {
    /// - Description: Encodes an array of markers to JSON data for persistence.
    /// - Parameters:
    ///   - annotations: Tap markers captured on the body map.
    /// - Returns: JSON `Data` suitable for Core Data, or `nil` when encoding fails.
    static func encode(_ annotations: [BodyMapAnnotation]) -> Data? {
        // EYFS: Structured injury mapping supports accurate handovers to medical professionals.
        let encoder = JSONEncoder()
        return try? encoder.encode(annotations)
    }

    /// - Description: Decodes previously stored JSON bytes into Swift models.
    /// - Parameters:
    ///   - data: Persisted payload from Core Data.
    /// - Returns: Decoded markers, or an empty array when data is missing or invalid.
    static func decode(_ data: Data?) -> [BodyMapAnnotation] {
        guard let data else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([BodyMapAnnotation].self, from: data)) ?? []
    }
}
