import SwiftUI

@main
struct TravelJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
                .background(Color(UIColor { t in
                    t.userInterfaceStyle == .dark
                        ? UIColor(red: 0.114, green: 0.102, blue: 0.086, alpha: 1)
                        : UIColor(red: 0.937, green: 0.910, blue: 0.855, alpha: 1)
                }))
        }
    }
}
