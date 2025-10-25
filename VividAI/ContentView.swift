import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var unifiedState: UnifiedAppStateManager
    
    var body: some View {
        NavigationView {
            HomeView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(UnifiedAppStateManager.shared)
}
