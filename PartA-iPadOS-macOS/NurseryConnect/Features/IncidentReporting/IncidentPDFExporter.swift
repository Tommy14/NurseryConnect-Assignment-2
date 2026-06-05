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
// 100426     Tommy1914   Sectioned layout, wrapped text, body-map images + markers, multi-page.
// 100426     Tommy1914   Futuristic dossier styling: gradient hero, panels, accent rails, map chrome.
// -----------------------------------------------------------------

import CoreData
import UIKit

/// - Description: Builds a minimal PDF suitable for external safeguarding workflows.
enum IncidentPDFExporter {
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 40
    private static var contentWidth: CGFloat { pageSize.width - margin * 2 }
    private static let panelInset: CGFloat = 14
    private static let heroHeight: CGFloat = 118

    /// Brand-forward palette (falls back if asset colours unavailable in PDF context).
    private enum Theme {
        static let primary = UIColor(named: "BrandPrimary") ?? UIColor(red: 0.18, green: 0.45, blue: 0.82, alpha: 1)
        static let cyanGlow = UIColor(red: 0.25, green: 0.78, blue: 0.92, alpha: 1)
        static let panelFill = UIColor(red: 0.95, green: 0.97, blue: 1, alpha: 1)
        static let panelStroke = UIColor(red: 0.72, green: 0.84, blue: 0.96, alpha: 1)
        static let railDeep = UIColor(red: 0.12, green: 0.4, blue: 0.75, alpha: 1)
        static let textOnHero = UIColor.white
        static let tagline = UIColor.white.withAlphaComponent(0.88)
    }

    /// - Description: Renders incident fields into PDF data for sharing or archiving.
    static func pdfData(for incident: Incident, childName: String) -> Data? {
        let annotations = BodyMapCodec.decode(incident.bodyMapAnnotations)
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        var isFirstPage = true

        let data = renderer.pdfData { context in
            var cursor = margin
            context.beginPage()

            func ensureSpace(_ extra: CGFloat) {
                let bottomLimit = pageSize.height - margin - 28
                if cursor + extra > bottomLimit {
                    context.beginPage()
                    isFirstPage = false
                    drawContinuationHeader(context: context, cursor: &cursor)
                }
            }

            func drawSectionHeader(_ title: String) {
                ensureSpace(44)
                let cg = context.cgContext
                let railW: CGFloat = 4
                let railRect = CGRect(x: margin, y: cursor + 2, width: railW, height: 18)
                let railColors = [Theme.railDeep.cgColor, Theme.cyanGlow.cgColor]
                if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: railColors as CFArray, locations: [0, 1]) {
                    cg.saveGState()
                    cg.clip(to: railRect)
                    cg.drawLinearGradient(grad, start: CGPoint(x: margin, y: cursor), end: CGPoint(x: margin, y: cursor + 22), options: [])
                    cg.restoreGState()
                }
                let font = UIFont.systemFont(ofSize: 13, weight: .heavy)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: Theme.primary,
                    .kern: 1.4
                ]
                let str = NSAttributedString(string: title.uppercased(), attributes: attrs)
                str.draw(at: CGPoint(x: margin + railW + 10, y: cursor))
                cursor += 24
                let lineY = cursor - 2
                // Horizontal linear gradients with identical start/end Y fill the *entire page height*
                // perpendicular to the vector unless clipped. Clip to a hairline band.
                let underlineW = pageSize.width - margin - (margin + railW + 10)
                let underlineBand = CGRect(x: margin + railW + 10, y: lineY - 1, width: underlineW, height: 2.5)
                cg.saveGState()
                cg.clip(to: underlineBand)
                let fade = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [Theme.cyanGlow.withAlphaComponent(0.45).cgColor, Theme.primary.withAlphaComponent(0.2).cgColor] as CFArray,
                    locations: [0, 1]
                )!
                cg.drawLinearGradient(
                    fade,
                    start: CGPoint(x: underlineBand.minX, y: lineY),
                    end: CGPoint(x: underlineBand.maxX, y: lineY),
                    options: []
                )
                cg.restoreGState()
                cursor += 12
            }

            func wrappedHeight(_ text: String, font: UIFont, inset: CGFloat) -> CGFloat {
                let w = contentWidth - inset * 2
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.darkText,
                    .paragraphStyle: paragraph
                ]
                let str = NSAttributedString(string: text, attributes: attrs)
                return ceil(str.boundingRect(
                    with: CGSize(width: w, height: 10_000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)
            }

            func keyValueBlockHeight(label: String, value: String, inset: CGFloat) -> CGFloat {
                let labelFont = UIFont.systemFont(ofSize: 10, weight: .bold)
                let valueFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: Theme.primary.withAlphaComponent(0.75)
                ]
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: valueFont,
                    .foregroundColor: UIColor.darkText
                ]
                let block = NSMutableAttributedString()
                block.append(NSAttributedString(string: "\(label.uppercased())\n", attributes: labelAttrs))
                let display = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value
                block.append(NSAttributedString(string: display, attributes: valueAttrs))
                let w = contentWidth - inset * 2
                let h = ceil(block.boundingRect(
                    with: CGSize(width: w, height: 10_000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)
                return h + 10
            }

            func drawWrapped(_ text: String, font: UIFont, color: UIColor = .darkText, inset: CGFloat = 0, skipEnsure: Bool = false) {
                let w = contentWidth - inset * 2
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let str = NSAttributedString(string: text, attributes: attrs)
                let h = ceil(str.boundingRect(
                    with: CGSize(width: w, height: 10_000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)
                if !skipEnsure { ensureSpace(h + 10) }
                str.draw(
                    with: CGRect(x: margin + inset, y: cursor, width: w, height: h),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                cursor += h + 8
            }

            func drawKeyValue(label: String, value: String, inset: CGFloat = 0, skipEnsure: Bool = false) {
                let labelFont = UIFont.systemFont(ofSize: 10, weight: .bold)
                let valueFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: Theme.primary.withAlphaComponent(0.75)
                ]
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: valueFont,
                    .foregroundColor: UIColor.darkText
                ]
                let block = NSMutableAttributedString()
                block.append(NSAttributedString(string: "\(label.uppercased())\n", attributes: labelAttrs))
                let display = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value
                block.append(NSAttributedString(string: display, attributes: valueAttrs))
                let w = contentWidth - inset * 2
                let h = ceil(block.boundingRect(
                    with: CGSize(width: w, height: 10_000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)
                if !skipEnsure { ensureSpace(h + 12) }
                block.draw(
                    with: CGRect(x: margin + inset, y: cursor, width: w, height: h),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                cursor += h + 10
            }

            // — Hero (page 1 only) —
            if isFirstPage {
                drawHeroBanner(
                    context: context,
                    incident: incident,
                    nurseryLine: AppConstants.nurseryDisplayName
                )
                cursor = heroHeight + 24
            }

            // — Summary in panel (background first) —
            drawSectionHeader("Field summary")
            let dateString: String? = {
                guard let ts = incident.timestamp else { return nil }
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: ts)
            }()
            var summaryH = panelInset
            summaryH += keyValueBlockHeight(label: "Child", value: childName.trimmingCharacters(in: .whitespaces), inset: panelInset)
            if let ds = dateString {
                summaryH += keyValueBlockHeight(label: "Recorded at", value: ds, inset: panelInset)
            }
            summaryH += keyValueBlockHeight(label: "Category", value: IncidentCategory.fromPersistence(incident.category ?? "").title, inset: panelInset)
            summaryH += keyValueBlockHeight(label: "Severity", value: IncidentSeverity.fromPersistence(incident.severity ?? "").title, inset: panelInset)
            summaryH += keyValueBlockHeight(label: "Status", value: IncidentStatus.fromPersistence(incident.status ?? "").title, inset: panelInset)
            summaryH += keyValueBlockHeight(label: "Location", value: incident.location ?? "", inset: panelInset)
            summaryH += panelInset
            ensureSpace(summaryH + 8)
            let summaryPanelTop = cursor
            drawPanelChrome(
                context: context,
                frame: CGRect(x: margin - 6, y: summaryPanelTop, width: contentWidth + 12, height: summaryH)
            )
            cursor = summaryPanelTop + panelInset
            drawKeyValue(label: "Child", value: childName.trimmingCharacters(in: .whitespaces), inset: panelInset, skipEnsure: true)
            if let ds = dateString {
                drawKeyValue(label: "Recorded at", value: ds, inset: panelInset, skipEnsure: true)
            }
            drawKeyValue(label: "Category", value: IncidentCategory.fromPersistence(incident.category ?? "").title, inset: panelInset, skipEnsure: true)
            drawKeyValue(label: "Severity", value: IncidentSeverity.fromPersistence(incident.severity ?? "").title, inset: panelInset, skipEnsure: true)
            drawKeyValue(label: "Status", value: IncidentStatus.fromPersistence(incident.status ?? "").title, inset: panelInset, skipEnsure: true)
            drawKeyValue(label: "Location", value: incident.location ?? "", inset: panelInset, skipEnsure: true)
            cursor = summaryPanelTop + summaryH + 12

            // — Narrative in panel —
            drawSectionHeader("Narrative log")
            let narrativeLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .heavy),
                .foregroundColor: Theme.primary.withAlphaComponent(0.8),
                .kern: 0.8
            ]
            func narrBlockHeight(_ heading: String, _ body: String) -> CGFloat {
                let text = body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : body
                return 16 + wrappedHeight(text, font: UIFont.systemFont(ofSize: 12, weight: .regular), inset: panelInset) + 8
            }
            var narH = panelInset
            narH += narrBlockHeight("Description", incident.incidentDescription ?? "")
            narH += narrBlockHeight("Immediate action", incident.immediateActionTaken ?? "")
            narH += narrBlockHeight("Witnesses", incident.witnesses ?? "")
            narH += panelInset - 8
            ensureSpace(narH + 8)
            let narPanelTop = cursor
            drawPanelChrome(
                context: context,
                frame: CGRect(x: margin - 6, y: narPanelTop, width: contentWidth + 12, height: narH)
            )
            cursor = narPanelTop + panelInset
            func drawNarrBlock(_ heading: String, _ body: String) {
                ("\(heading.uppercased())" as NSString).draw(
                    at: CGPoint(x: margin + panelInset, y: cursor),
                    withAttributes: narrativeLabelAttrs
                )
                cursor += 16
                let text = body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : body
                drawWrapped(text, font: UIFont.systemFont(ofSize: 12, weight: .regular), inset: panelInset, skipEnsure: true)
            }
            drawNarrBlock("Description", incident.incidentDescription ?? "")
            drawNarrBlock("Immediate action", incident.immediateActionTaken ?? "")
            drawNarrBlock("Witnesses", incident.witnesses ?? "")
            cursor = narPanelTop + narH + 12

            // — Body map —
            drawSectionHeader("Bio-scan · injury plot")
            let mapCaptionFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let frontMarkers = annotations.filter { $0.side == .front }
            let backMarkers = annotations.filter { $0.side == .back }

            if UIImage(named: "BodyMapFront") != nil {
                drawMapChip(context: context, label: "ANTERIOR", atY: cursor)
                cursor += 22
                let mapHeight: CGFloat = 200
                ensureSpace(mapHeight + 48)
                let mapFrame = CGRect(x: margin, y: cursor, width: contentWidth, height: mapHeight)
                drawBodyMapImageFuturistic(
                    context: context,
                    imageName: "BodyMapFront",
                    markers: frontMarkers,
                    in: mapFrame
                )
                cursor += mapHeight + 10
                let cap = frontMarkers.isEmpty
                    ? "No telemetry on anterior view."
                    : "\(frontMarkers.count) localised point(s) · anterior"
                (cap as NSString).draw(
                    at: CGPoint(x: margin + panelInset, y: cursor),
                    withAttributes: [.font: mapCaptionFont, .foregroundColor: Theme.primary.withAlphaComponent(0.75)]
                )
                cursor += 26
            }

            if UIImage(named: "BodyMapBack") != nil {
                ensureSpace(260)
                drawMapChip(context: context, label: "POSTERIOR", atY: cursor)
                cursor += 22
                let mapHeight: CGFloat = 200
                ensureSpace(mapHeight + 48)
                let mapFrame = CGRect(x: margin, y: cursor, width: contentWidth, height: mapHeight)
                drawBodyMapImageFuturistic(
                    context: context,
                    imageName: "BodyMapBack",
                    markers: backMarkers,
                    in: mapFrame
                )
                cursor += mapHeight + 10
                let cap = backMarkers.isEmpty
                    ? "No telemetry on posterior view."
                    : "\(backMarkers.count) localised point(s) · posterior"
                (cap as NSString).draw(
                    at: CGPoint(x: margin + panelInset, y: cursor),
                    withAttributes: [.font: mapCaptionFont, .foregroundColor: Theme.primary.withAlphaComponent(0.75)]
                )
                cursor += 22
            }

            if UIImage(named: "BodyMapFront") == nil && UIImage(named: "BodyMapBack") == nil {
                drawWrapped(
                    "Body map raster assets unavailable in this build.",
                    font: mapCaptionFont,
                    color: .secondaryLabel
                )
            }

            // — Compliance —
            drawSectionHeader("Compliance")
            let riddor = incident.riddorRequired ? "YES" : "NO"
            let compH = panelInset + keyValueBlockHeight(label: "RIDDOR flagged", value: riddor, inset: panelInset) + panelInset - 10
            ensureSpace(compH + 24)
            let compPanelTop = cursor
            if incident.riddorRequired {
                drawRiddorPulse(
                    context: context,
                    frame: CGRect(x: margin - 6, y: compPanelTop, width: contentWidth + 12, height: compH)
                )
            } else {
                drawPanelChrome(
                    context: context,
                    frame: CGRect(x: margin - 6, y: compPanelTop, width: contentWidth + 12, height: compH)
                )
            }
            cursor = compPanelTop + panelInset
            drawKeyValue(label: "RIDDOR flagged", value: riddor, inset: panelInset, skipEnsure: true)
            cursor = compPanelTop + compH + 12

            ensureSpace(32)
            drawFuturisticFooter(context: context, cursor: cursor)
        }
        return data
    }

    // MARK: - Chrome & hero

    private static func drawHeroBanner(
        context: UIGraphicsPDFRendererContext,
        incident: Incident,
        nurseryLine: String
    ) {
        let cg = context.cgContext
        let w = pageSize.width
        let h = heroHeight
        let colors = [
            UIColor(red: 0.06, green: 0.22, blue: 0.48, alpha: 1).cgColor,
            UIColor(red: 0.12, green: 0.42, blue: 0.78, alpha: 1).cgColor,
            UIColor(red: 0.18, green: 0.55, blue: 0.88, alpha: 1).cgColor
        ]
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.5, 1]) {
            cg.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w, y: h), options: [])
        }
        // Scan-line hint
        cg.saveGState()
        cg.setStrokeColor(UIColor.white.withAlphaComponent(0.06).cgColor)
        cg.setLineWidth(0.5)
        var ly: CGFloat = 8
        while ly < h {
            cg.move(to: CGPoint(x: 0, y: ly))
            cg.addLine(to: CGPoint(x: w, y: ly))
            ly += 14
        }
        cg.strokePath()
        cg.restoreGState()

        let title = "Incident dossier" as NSString
        title.draw(
            at: CGPoint(x: margin, y: 28),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 26, weight: .heavy),
                .foregroundColor: Theme.textOnHero,
                .kern: 0.5
            ]
        )
        let tag = "Safeguarding snapshot · encrypted export" as NSString
        tag.draw(
            at: CGPoint(x: margin, y: 62),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: Theme.tagline,
                .kern: 1.2
            ]
        )
        (nurseryLine as NSString).draw(
            at: CGPoint(x: margin, y: 82),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: Theme.tagline
            ]
        )
        if let id = incident.id {
            let ref = "REF  \(id.uuidString.uppercased())" as NSString
            ref.draw(
                at: CGPoint(x: margin, y: 98),
                withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: Theme.tagline
                ]
            )
        }
    }

    private static func drawContinuationHeader(context: UIGraphicsPDFRendererContext, cursor: inout CGFloat) {
        let cg = context.cgContext
        cg.setFillColor(Theme.panelFill.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: pageSize.width, height: 36))
        let t = "NurseryConnect · incident record (cont.)" as NSString
        t.draw(
            at: CGPoint(x: margin, y: 12),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: Theme.primary.withAlphaComponent(0.85),
                .kern: 0.6
            ]
        )
        cursor = 48
    }

    private static func drawPanelChrome(context: UIGraphicsPDFRendererContext, frame: CGRect) {
        let cg = context.cgContext
        cg.saveGState()
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 12).cgPath
        cg.addPath(path)
        cg.setFillColor(Theme.panelFill.cgColor)
        cg.fillPath()
        cg.addPath(path)
        cg.setStrokeColor(Theme.panelStroke.cgColor)
        cg.setLineWidth(1)
        cg.strokePath()
        cg.restoreGState()
    }

    private static func drawRiddorPulse(context: UIGraphicsPDFRendererContext, frame: CGRect) {
        let cg = context.cgContext
        cg.saveGState()
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 12).cgPath
        cg.addPath(path)
        cg.clip()
        let warm = [
            UIColor(red: 1, green: 0.92, blue: 0.88, alpha: 1).cgColor,
            UIColor(red: 1, green: 0.96, blue: 0.93, alpha: 1).cgColor
        ]
        if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: warm as CFArray, locations: [0, 1]) {
            cg.drawLinearGradient(g, start: CGPoint(x: frame.minX, y: frame.minY), end: CGPoint(x: frame.maxX, y: frame.maxY), options: [])
        }
        cg.restoreGState()
        cg.addPath(path)
        cg.setStrokeColor(UIColor.systemOrange.withAlphaComponent(0.55).cgColor)
        cg.setLineWidth(1.5)
        cg.strokePath()
    }

    private static func drawMapChip(context: UIGraphicsPDFRendererContext, label: String, atY: CGFloat) {
        let cg = context.cgContext
        let text = label as NSString
        let size = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .heavy)])
        let chipW = size.width + 20
        let chipH: CGFloat = 22
        let rect = CGRect(x: margin, y: atY, width: chipW, height: chipH)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6).cgPath
        cg.saveGState()
        cg.addPath(path)
        cg.setFillColor(Theme.primary.withAlphaComponent(0.12).cgColor)
        cg.fillPath()
        cg.addPath(path)
        cg.setStrokeColor(Theme.cyanGlow.withAlphaComponent(0.5).cgColor)
        cg.setLineWidth(0.75)
        cg.strokePath()
        cg.restoreGState()
        text.draw(
            at: CGPoint(x: margin + 10, y: atY + 4),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .heavy),
                .foregroundColor: Theme.primary,
                .kern: 1
            ]
        )
    }

    private static func drawFuturisticFooter(context: UIGraphicsPDFRendererContext, cursor: CGFloat) {
        let cg = context.cgContext
        let y = cursor
        cg.saveGState()
        let glowBand = CGRect(x: margin, y: y, width: pageSize.width - margin * 2, height: 14)
        cg.clip(to: glowBand)
        if let g = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [Theme.cyanGlow.withAlphaComponent(0.22).cgColor, UIColor.clear.cgColor] as CFArray,
            locations: [0, 1]
        ) {
            cg.drawLinearGradient(
                g,
                start: CGPoint(x: margin, y: y),
                end: CGPoint(x: pageSize.width - margin, y: y),
                options: []
            )
        }
        cg.restoreGState()
        let footer = "NURSERYCONNECT  ·  \(AppConstants.nurseryDisplayName)" as NSString
        footer.draw(
            at: CGPoint(x: margin, y: y + 6),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 8, weight: .semibold),
                .foregroundColor: UIColor.tertiaryLabel,
                .kern: 1
            ]
        )
    }

    /// Draws asset image aspect-filled into `rect`, then styled markers.
    private static func drawBodyMapImageFuturistic(
        context: UIGraphicsPDFRendererContext,
        imageName: String,
        markers: [BodyMapAnnotation],
        in rect: CGRect
    ) {
        guard let image = UIImage(named: imageName) else { return }
        let cg = context.cgContext

        // Outer glow frame
        cg.saveGState()
        let outer = rect.insetBy(dx: -2, dy: -2)
        let outerPath = UIBezierPath(roundedRect: outer, cornerRadius: 14).cgPath
        cg.addPath(outerPath)
        cg.setStrokeColor(Theme.cyanGlow.withAlphaComponent(0.45).cgColor)
        cg.setLineWidth(2)
        cg.strokePath()
        cg.restoreGState()

        cg.saveGState()
        let innerPath = UIBezierPath(roundedRect: rect, cornerRadius: 12).cgPath
        cg.addPath(innerPath)
        cg.clip()
        if let g = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [Theme.panelFill.cgColor, UIColor.white.cgColor] as CFArray,
            locations: [0, 1]
        ) {
            cg.drawLinearGradient(
                g,
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY),
                options: []
            )
        }
        let imgSize = image.size
        let scale = max(rect.width / imgSize.width, rect.height / imgSize.height)
        let drawW = imgSize.width * scale
        let drawH = imgSize.height * scale
        let drawRect = CGRect(
            x: rect.midX - drawW / 2,
            y: rect.midY - drawH / 2,
            width: drawW,
            height: drawH
        )
        image.draw(in: drawRect)
        cg.restoreGState()

        for m in markers {
            let cx = rect.minX + CGFloat(m.normalizedX) * rect.width
            let cy = rect.minY + CGFloat(m.normalizedY) * rect.height
            let rOuter: CGFloat = 9
            let rMid: CGFloat = 6
            let rInner: CGFloat = 4
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: cx - rOuter / 2, y: cy - rOuter / 2, width: rOuter, height: rOuter))
            cg.setFillColor(Theme.primary.withAlphaComponent(0.35).cgColor)
            cg.fillEllipse(in: CGRect(x: cx - rMid / 2, y: cy - rMid / 2, width: rMid, height: rMid))
            cg.setFillColor(UIColor.systemRed.cgColor)
            cg.fillEllipse(in: CGRect(x: cx - rInner / 2, y: cy - rInner / 2, width: rInner, height: rInner))
        }

        cg.setStrokeColor(Theme.panelStroke.cgColor)
        cg.setLineWidth(1)
        cg.addPath(UIBezierPath(roundedRect: rect, cornerRadius: 12).cgPath)
        cg.strokePath()
    }
}
