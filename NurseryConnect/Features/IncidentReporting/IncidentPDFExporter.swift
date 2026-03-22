//
//  IncidentPDFExporter.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 8 April 2026
//  Description: Renders a statutory-friendly PDF snapshot of an incident record.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 080426     Tommy1914   Created the file with UIGraphicsPDFRenderer output.
// -----------------------------------------------------------------

import CoreData
import UIKit

/// - Description: Builds a minimal PDF suitable for external safeguarding workflows.
enum IncidentPDFExporter {
    /// - Description: Renders incident fields into PDF data for sharing or archiving.
    /// - Parameters:
    ///   - incident: Persisted incident entity.
    ///   - childName: Resolved child display name for the header.
    /// - Returns: PDF `Data`, or `nil` when rendering fails.
    static func pdfData(for incident: Incident, childName: String) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            context.beginPage()
            let title = "Incident report — \(AppConstants.nurseryDisplayName)"
            let bodyFont = UIFont.preferredFont(forTextStyle: .body)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .title2)
            ]
            title.draw(at: CGPoint(x: 32, y: 32), withAttributes: titleAttributes)

            var cursor: CGFloat = 80
            func drawLine(_ text: String) {
                let attributes: [NSAttributedString.Key: Any] = [.font: bodyFont]
                text.draw(at: CGPoint(x: 32, y: cursor), withAttributes: attributes)
                cursor += 22
            }

            // EYFS: PDF captures immutable timestamp text for external disclosure packs.
            drawLine("Child: \(childName)")
            if let ts = incident.timestamp {
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                drawLine("Recorded at: \(formatter.string(from: ts))")
            }
            drawLine("Category: \(IncidentCategory.fromPersistence(incident.category ?? "").title)")
            drawLine("Severity: \(IncidentSeverity.fromPersistence(incident.severity ?? "").title)")
            drawLine("Status: \(IncidentStatus.fromPersistence(incident.status ?? "").title)")
            drawLine("Location: \(incident.location ?? "")")
            drawLine("Description:")
            drawLine(incident.incidentDescription ?? "")
            drawLine("Immediate action:")
            drawLine(incident.immediateActionTaken ?? "")
            drawLine("Witnesses: \(incident.witnesses ?? "")")
            drawLine("RIDDOR flagged: \(incident.riddorRequired ? "Yes" : "No")")
        }
        return data
    }
}
