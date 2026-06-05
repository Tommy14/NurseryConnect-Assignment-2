# SE4020 - Mobile Application Design and Development

## Assignment 02 - Submission Repository

**BSc (Hons) in Information Technology, Year 4 - Semester 1, 2026**

This is your submission repository for Assignment 02. Everything you submit for this assignment lives here: your two codebases, your report, your UI mockups, your AI usage logs, and your demo video link. Read this file fully before you start committing.

---

## What this assignment contains

Assignment 02 has two parts and is worth **25%** of the module.

| Part | What it is | Marks |
|------|------------|-------|
| **Part A** (compulsory) | An iPadOS **or** macOS app built in SwiftUI, extending your Assignment 1 NurseryConnect work | 10 |
| **Part B** (pick one) | Option 1: a watchOS companion app **(5 marks)** or Option 2: a visionOS spatial app **(15 marks)** | up to 15 |

You commit **two codebases** (Part A and your chosen Part B option) and **one report** that covers both parts.

**Deadline:** 3rd June 2026
**Vivas:** 6th and 7th June 2026

---

## Repository structure

```
se4020-2026-Assignment02/
├── README.md                  <- this file (do not edit)
├── STUDENT_DETAILS.md         <- FILL THIS IN FIRST
├── .gitignore                 <- Xcode/Swift ignore rules (already set up)
│
├── PartA-iPadOS-macOS/        <- your Part A Xcode project goes here
│
├── PartB/
│   ├── Option1-watchOS/       <- use ONLY if you chose Option 1
│   └── Option2-visionOS/      <- use ONLY if you chose Option 2
│
├── Report/                    <- single report covering Part A AND Part B
│
├── UI-Mockups/                <- your 3+ AI-generated mockup variations
│
├── AI-Usage/                  <- AI prompt and response logs
│
└── Demo/                      <- link to your demo video
```

You only complete the Part B option you chose. **Delete the folder for the option you did not pick**, or leave it empty with its README intact. Do not submit both Part B options.

---

## How to use this repository

1. **Accept the assignment** through the link shared on the course LMS. This creates your own private copy of this repository under the `SE4020` organisation.
2. **Open `STUDENT_DETAILS.md` and fill it in** as your very first commit, so we can identify your submission.
3. Develop Part A inside `PartA-iPadOS-macOS/`.
4. Develop your chosen Part B option inside the matching folder under `PartB/`.
5. Add your mockups, AI logs, report, and demo link to their folders.
6. **Commit and push regularly.** We look at your commit history. A single large commit on the deadline is a red flag for plagiarism and for AI code you cannot explain.

---

## Submission checklist

Tick these off before the deadline. Each folder has its own README with detail.

- [x] `STUDENT_DETAILS.md` completed (name, student ID, Part A platform, Part B option chosen)
- [x] **Part A** Xcode project committed and builds without errors
- [x] Part A integrates at least one approved advanced library (not MapKit, Core Data, or Localisation)
- [x] Part A uses at least one iPadOS/macOS native feature
- [x] **Part B** (your chosen option) committed
- [x] **At least 3** distinct AI-generated UI mockup variations added to `UI-Mockups/`
- [x] **Report** added to `Report/` covering both Part A and Part B
- [x] AI usage logs completed in `AI-Usage/` (both code generation and UI mockup)
- [x] Demo video link added in `Demo/README.md`
- [x] All code is your own and you can explain every line in the viva

---

## Important rules

- **No login or authentication.** Your app launches straight into its main functionality.
- **Write your own code.** AI assistance is allowed, but you must attach all prompts and responses, and you must be able to explain everything in the viva. Code that closely matches public tutorials or other students will be treated as plagiarism.
- **This is an individual assignment.** Do not share code, mockups, or design decisions with other students.
- Your mark depends on the quality, depth, and thoughtfulness of your work, not on picking a unique feature.

If anything here is unclear, raise it on the course forum before the deadline, not after.
