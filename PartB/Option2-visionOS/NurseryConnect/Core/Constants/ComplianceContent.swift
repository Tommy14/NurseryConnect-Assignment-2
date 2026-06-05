//
//  ComplianceContent.swift
//  NurseryConnect
//
//  Feature: Core
//  Role: Keyworker
//  Created: 22 April 2026
//  Description: Canonical UK (England) compliance copy used across legal and contextual UI.
//

import Foundation

enum ComplianceContent {
    static let legalScreenTitle = "Legal & Compliance"
    static let legalScreenDisclaimer = "This guidance explains how NurseryConnect supports compliance workflows in UK (England) nursery practice. It is informational support and not legal advice."

    static let frameworks: [String] = [
        "EYFS (Early Years Foundation Stage) safeguarding and record-keeping expectations.",
        "Ofsted-aligned incident escalation and inspection-ready record workflows.",
        "RIDDOR reporting triggers for serious incidents and injuries.",
        "UK GDPR principles for consent records, data minimisation, and staff access scope."
    ]

    static let appApplicationRules: [String] = [
        "Incident timestamps are captured from the device clock to reduce backdating risk in EYFS records.",
        "Serious incident categories trigger RIDDOR and Ofsted workflow review before closure.",
        "Parent-notification urgency indicators support prompt safeguarding communication follow-up.",
        "Authorised collector controls help prevent unauthorised child collection events.",
        "Photo and consent records are shown in child profiles to support UK GDPR accountability."
    ]

    static let enforcementLocations: [String] = [
        "Incidents: review, escalation status, and RIDDOR-required logic.",
        "Attendance: authorised collector check-out and safeguarding reporting path.",
        "Child profile: consent records and photo-consent indicators."
    ]

    static let dataProtectionCommitments: [String] = [
        "Only assigned cohort records are shown to practitioners.",
        "Consent and safeguarding notes are visible where care decisions are made.",
        "Demo data is synthetic in development builds."
    ]

    static let childProfileConsentNote = "UK GDPR and safeguarding: consent records here should match current parent/carer permissions for media and care processing."
    static let attendanceSafeguardingNote = "Safeguarding policy: only authorised collectors complete check-out; use incident reporting for unauthorised collection attempts."
    static let incidentReviewComplianceNote = "EYFS + RIDDOR/Ofsted: review timestamp integrity and escalate serious incidents through statutory workflow before closure."
    static let incidentListComplianceNote = "Compliance monitor: parent-notification banners support EYFS safeguarding follow-up timing and escalation tracking."
}
