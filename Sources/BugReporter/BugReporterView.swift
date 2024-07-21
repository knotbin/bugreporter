
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

struct BugReport: Codable {
    let title: String
    let body: String
    let owner: String
    let repo: String
}

func reportBug(bugReport: BugReport) {
    let urlString = "https://ios-bugreporter.onrender.com/issue/new-bug"
    guard let url = URL(string: urlString) else {
        print(NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let jsonData = try JSONEncoder().encode(bugReport)
        request.httpBody = jsonData
        
        print("Attempting to create issue at URL: \(urlString)")
        print("Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
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
            
            if (200...299).contains(httpResponse.statusCode) {
                if let data = data {
                    print(data)
                } else {
                    print(NSError(domain: "NoData", code: 0, userInfo: nil))
                }
            } else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Error response: \(responseString)")
                }
                print(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil))
            }
        }.resume()
    } catch {
        print(error)
    }
}
