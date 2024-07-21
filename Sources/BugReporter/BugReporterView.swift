
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
                    createGitHubIssue(owner: owner, repo: repo, issue: GitHubIssue(title: capturedTitle, body: capturedDescription, assignees: [], labels: ["bug"]))
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

struct GitHubIssue: Codable {
    let title: String
    let body: String
    let assignees: [String]
    let labels: [String]
}

func createGitHubIssue(owner: String, repo: String, issue: GitHubIssue) {
    let urlString = "https://ios-bugreporter.onrender.com/issue/\(owner)/\(repo)"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let jsonData = try JSONEncoder().encode(issue)
        request.httpBody = jsonData
        
        print("Attempting to create issue at URL: \(urlString)")
        print("Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                print("Issue created successfully")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
            } else {
                print("Error creating issue. Status code: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Error response: \(responseString)")
                }
            }
        }.resume()
    } catch {
        print("Error encoding issue: \(error.localizedDescription)")
    }
}
