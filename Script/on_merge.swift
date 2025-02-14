//
//  on_merge.swift
//
//  A simple script to process files and generate a README.md file.
//  It's not supposed to be pretty, it's supposed to work. 😉
//
//  Created by Piotr Jeremicz on 4.02.2025.
//

import Foundation

// MARK: - Constants
let year = 2025
let name = "Swift Student Challenge"

let templateFileName = "Template.md"
let submissionsDirectoryName = "Submission"

let template = #"""
Name:
Status:
Technologies:

AboutMeUrl:
SourceUrl:
VideoUrl:

<!---
EXAMPLE
Name: John Appleseed
Status: Submitted <or> Accepted <or> Rejected
Technologies: SwiftUI, RealityKit, CoreGraphic

AboutMeUrl: https://linkedin.com/in/johnappleseed
SourceUrl: https://github.com/johnappleseed/wwdc2025
VideoUrl: https://youtu.be/ABCDE123456
-->

"""#

// MARK: - Find potential Template.md files
let fileManager = FileManager.default
let rootFiles = (try? fileManager.contentsOfDirectory(atPath: ".")) ?? []
let potentialTemplateFiles = rootFiles.filter { $0.hasSuffix(".md") && $0 != "README.md" }

// MARK: - Load potential template files
var potentialTemplates = [(filename: String, content: String)]()
for file in potentialTemplateFiles {
    guard let content = try? String(contentsOfFile: file, encoding: .utf8) else { continue }
    potentialTemplates.append((filename: file, content: content))
}

// MARK: - Validate potential template files and prepare new filename
var validatedTemplates = [(originalFilename: String, newFilename: String, content: String)]()
for potentialTemplate in potentialTemplates {
    let lines = potentialTemplate.content.split(separator: "\n")
    
    guard lines.count >= 6 else { continue }
    guard lines[0].hasPrefix("Name:") && lines[0].count > "Name: ".count else { continue }
    guard lines[1].hasPrefix("Status:") && lines[1].count > "Status: ".count else { continue }
    guard lines[2].hasPrefix("Technologies:") && lines[2].count > "Technologies: ".count else { continue }
    guard lines[3].hasPrefix("AboutMeUrl:") else { continue }
    guard lines[4].hasPrefix("SourceUrl:") else { continue }
    guard lines[5].hasPrefix("VideoUrl:") else { continue }
    
    let newFilename = lines[0].replacingOccurrences(of: "Name: ", with: "").lowercased().replacingOccurrences(of: " ", with: "") + ".md"
    validatedTemplates.append(
        (
            originalFilename: potentialTemplate.filename,
            newFilename: newFilename,
            content: potentialTemplate.content
        )
    )
}

// MARK: - Create Submission directory
if !fileManager.fileExists(atPath: submissionsDirectoryName) {
    try? fileManager.createDirectory(atPath: submissionsDirectoryName, withIntermediateDirectories: true, attributes: nil)
}

// MARK: - Relocate validated template file and rename it
for validatedTemplate in validatedTemplates {
    do {
        // First remove, later create new one. If the removal will fail the result will not produce two independent files.
        try fileManager.removeItem(atPath: "\(validatedTemplate.originalFilename)")
        try validatedTemplate.content.write(
            toFile: "\(submissionsDirectoryName)/\(validatedTemplate.newFilename)",
            atomically: true,
            encoding: .utf8
        )
    } catch {
        continue
    }
}

// MARK: - Clean template file
try? template.write(toFile: "Template.md", atomically: true, encoding: .utf8)

// MARK: - Submission model
struct Submission {
    let name: String
    let status: Status
    let technologies: [String]
    
    let aboutMeUrl: URL?
    let sourceUrl: URL?
    let videoUrl: URL?
    
    enum Status: String {
        case submitted = "Submitted"
        case accepted = "Accepted"
        case rejected = "Rejected"
        
        var iconURLString: String {
            switch self {
            case .submitted:
                "https://img.shields.io/badge/submitted-grey?style=for-the-badge"
            case .accepted:
                "https://img.shields.io/badge/accepted-green?style=for-the-badge"
            case .rejected:
                "https://img.shields.io/badge/rejected-firebrick?style=for-the-badge"
            }
        }
    }
    
    var row: String {
        let nameRow = if let aboutMeUrl {
            "[\(name)](\(aboutMeUrl.absoluteString))"
        } else {
            "\(name)"
        }
        
        let sourceRow: String = if let sourceUrl {
            "[GitHub](\(sourceUrl.absoluteString))"
        } else {
            "-"
        }
        
        let videoUrl = if let videoUrl {
            "[YouTube](\(videoUrl.absoluteString))"
        } else {
            "-"
        }
        
        let technologiesRow = technologies.joined(separator: ", ")
        
        let statusRow: String = "![\(status.rawValue)](\(status.iconURLString))"
        
        return "|" + [
            nameRow,
            sourceRow,
            videoUrl,
            technologiesRow,
            statusRow
        ].joined(separator: "|") + "|"
    }
}

// MARK: - Load all submission files into Submission model
let submissionFiles = (try? fileManager.contentsOfDirectory(atPath: submissionsDirectoryName)) ?? []

var submissions = [Submission]()
for submissionFile in submissionFiles {
    guard let content = try? String(contentsOfFile: "\(submissionsDirectoryName)/\(submissionFile)", encoding: .utf8) else { continue }
    
    let lines = content.split(separator: "\n")
    guard lines.count >= 6 else { continue }
    
    let name: String? = if lines[0].hasPrefix("Name:") {
        lines[0].replacingOccurrences(of: "Name: ", with: "")
    } else { nil }
    
    let status: Submission.Status? = if lines[1].hasPrefix("Status:") {
        .init(
            rawValue: lines[1].replacingOccurrences(of: "Status: ", with: "")
        )
    } else { nil }
    
    let technologies: [String] = if lines[2].hasPrefix("Technologies:") {
        lines[2].replacingOccurrences(of: "Technologies: ", with: "").split(separator: ", ").map { String($0) }
    } else { [] }
    
    let aboutMeUrl: URL? = if lines[3].hasPrefix("AboutMeUrl:") {
        URL(string: lines[3].replacingOccurrences(of: "AboutMeUrl:", with: "").replacingOccurrences(of: " ", with: ""))
    } else { nil }
    
    let sourceUrl: URL? = if lines[4].hasPrefix("SourceUrl:") {
        URL(string: lines[4].replacingOccurrences(of: "SourceUrl:", with: "").replacingOccurrences(of: " ", with: ""))
    } else { nil }
    
    let videoUrl: URL? = if lines[5].hasPrefix("VideoUrl:") {
        URL(string: lines[5].replacingOccurrences(of: "VideoUrl:", with: "").replacingOccurrences(of: " ", with: ""))
    } else { nil }
    
    guard let name, let status else { continue }
    submissions.append(
        .init(
            name: name,
            status: status,
            technologies: technologies,
            aboutMeUrl: aboutMeUrl,
            sourceUrl: sourceUrl,
            videoUrl: videoUrl
        )
    )
}

// MARK: - Generate new README.md file from template
var readmeFile: String {
"""
# WWDC \(year) - \(name)
![WWDC\(year) Logo](logo.png)

List of student submissions for the WWDC \(year) - \(name).

### How to add your submission?
1. [Click here](https://github.com/wwdc/\(year)/edit/main/Template.md) to fork this repository and edit the `Template.md` file.
2. Fill out the document based on the example in the comment below.
3. Make a new Pull Request and wait for the review.

### Submissions

Submissions: \(submissions.count)\\
Accepted: \(submissions.filter { $0.status == .accepted }.count)

| Name | Source |    Video    | Technologies | Status |
|-----:|:------:|:-----------:|:-------------|:------:|
\(submissions.sorted(by: { $0.name < $1.name}).map(\.row).joined(separator: "\n"))
"""
}

print(readmeFile)
