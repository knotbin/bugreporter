
import OctoKit
import SwiftUI

public struct BugReporterView: View {
    @State var title = ""
    @State var description = ""
    
    @Binding var isShown: Bool
    
    let ghToken = Bundle.main.infoDictionary?["GitHubToken"] as? String
    let ghOwner = Bundle.main.infoDictionary?["GitHubOwner"] as? String
    let ghRepo = Bundle.main.infoDictionary?["GitHubRepo"] as? String
    
    let version = Bundle.main.infoDictionary?["CFBundleVersion"]
    
    public var body: some View {
        NavigationStack {
            Form {
                TextField("Bug Title", text: $title)
                TextField("Bug Description", text: $description)
                Button("Submit") {
                    guard let token = ghToken, let owner = ghOwner, let repo = ghRepo else {
                        print("Info values not configured correctly")
                        return
                    }
                    let capturedTitle = title
                    let capturedDescription = description
                    Task {
                        await createGitHubIssue(owner: owner, repo: repo, title: capturedTitle, body: capturedDescription, assignees: [], milestone: 0, labels: ["bug"], token: token)
                    }
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

public struct GitHubIssue: Codable {
    let title: String
    let body: String
    let assignees: [String]
    let milestone: Int
    let labels: [String]
}

func createGitHubIssue(owner: String, repo: String, title: String, body: String, assignees: [String], milestone: Int, labels: [String], token: String) async {
    let config = TokenConfiguration(token)
    let octokit = Octokit(config)
    
    octokit.postIssue(owner: owner, repository: repo, title: title, body: body) { result in
        switch result {
        case .success(let issue):
            print("Issue created: \(issue)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}
