
import OctoKit
import SwiftUI

public struct BugReporterView: View {
    @State var title = ""
    @State var description = ""
    
    @Binding var isShown: Bool
    let ghOwner = Bundle.main.infoDictionary?["GitHubOwner"] as? String
    let ghRepo = Bundle.main.infoDictionary?["GitHubRepo"] as? String
    
    let version = Bundle.main.infoDictionary?["CFBundleVersion"]
    
    public var body: some View {
        NavigationStack {
            Form {
                TextField("Bug Title", text: $title)
                TextField("Bug Description", text: $description)
                Button("Submit") {
                    guard let owner = ghOwner, let repo = ghRepo else {
                        print("Info values not configured correctly")
                        return
                    }
                    let capturedTitle = title
                    let capturedDescription = description
                    reportBug(bugReport: BugReport(title: capturedTitle, body: capturedDescription, owner: owner, repo: repo))
                    isShown = false
                }
            }
            .navigationTitle("Report A Bug")
            .toolbar {
                ToolbarItem {
                    Button("Cancel") {
                        isShown = false
                    }
                }
            }
        }
    }
    
    public init(isShown: Binding<Bool>) {
        self._isShown = isShown
    }
}

struct BugReport {
    let title: String
    let body: String
    let owner: String
    let repo: String
    let assignees: [String]? = nil
    let labels: [String]? = nil
}

func reportBug(bugReport: BugReport) {
    var urlComponents = URLComponents(string: "https://ios-bugreporter.onrender.com/issue/new-bug")
    
    // Add query parameters
    urlComponents?.queryItems = [
        URLQueryItem(name: "owner", value: bugReport.owner),
        URLQueryItem(name: "repo", value: bugReport.repo),
        URLQueryItem(name: "title", value: bugReport.title),
        URLQueryItem(name: "body", value: bugReport.body)
    ]
    
    // Add optional parameters if they exist
    if let assignees = bugReport.assignees, !assignees.isEmpty {
        urlComponents?.queryItems?.append(URLQueryItem(name: "assignees", value: assignees.joined(separator: ",")))
    }
    if let labels = bugReport.labels, !labels.isEmpty {
        urlComponents?.queryItems?.append(URLQueryItem(name: "labels", value: labels.joined(separator: ",")))
    }
    
    guard let url = urlComponents?.url else {
        print(NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    print("Attempting to create issue at URL: \(url.absoluteString)")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print(error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print(NSError(domain: "InvalidResponse", code: 0, userInfo: nil))
            return
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        if let data = data, let responseString = String(data: data, encoding: .utf8) {
            print("Full response:")
            print(responseString)
            
            if (200...299).contains(httpResponse.statusCode) {
                print("Success: \(responseString)")
            } else {
                print(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: ["response": responseString]))
            }
        } else {
            print(NSError(domain: "NoData", code: 0, userInfo: nil))
        }
    }.resume()
}
