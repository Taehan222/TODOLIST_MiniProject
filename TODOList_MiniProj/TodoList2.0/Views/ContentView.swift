//
//  ContentView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = UserDefaults.standard.bool(forKey: "isLoggedIn")
    @State private var name: String = UserDefaults.standard.string(forKey: "name") ?? ""
    @State private var email: String = UserDefaults.standard.string(forKey: "email") ?? ""
    @State private var selectedTab: Int
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init(initialTab: Int = 0) {
            _selectedTab = State(initialValue: initialTab)
        }

    var body: some View {
        TabView(selection: $selectedTab) {
            TODOView(email: email, selectedTab: $selectedTab)
                .tabItem {
                    Label("TO-DO", systemImage: "checklist")
                }
                .tag(0)

            ProfileView(isLoggedIn: $isLoggedIn, name: $name, email: $email)
                .tabItem {
                    Label(NSLocalizedString("profile", comment: ""), systemImage: "person")
                }
                .tag(1)

            SettingView(email: $email)
                .tabItem {
                    Label(NSLocalizedString("settings", comment: ""), systemImage: "gear")
                }
                .tag(2)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            if UserDefaults.standard.bool(forKey: "isLoggedIn") == false {
                selectedTab = 1
            }
        }
    }
}
