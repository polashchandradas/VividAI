import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        NavigationView {
            HomeView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(ServiceContainer.shared)
}
