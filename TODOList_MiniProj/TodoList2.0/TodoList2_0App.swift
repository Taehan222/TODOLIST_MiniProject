//
//  TodoList2_0App.swift
//  TodoList2.0
//
//  Created by 윤태한 on 2/10/25.
//

import SwiftUI
import Firebase

@main
struct TodoList2_0App: App {
    @StateObject private var languageManager = LanguageManager() // LanguageManager 추가
    
    // 앱이 시작될 때 Firebase 초기화
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager) // LanguageManager를 환경 객체로 전달
        }
    }
}
