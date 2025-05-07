//
//  SettingView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("textSize") private var textSize: Double = 14.0
    @AppStorage("selectedLanguage") private var selectedLanguage = "ko"
    
    let languages = [
        ("ko", "한국어"),
        ("ja", "日本語"),
        ("en", "English")
    ]
    
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isShowingFeedback: Bool = false
    @Binding var email: String
    @Environment(\.colorScheme) var colorScheme
    
    var overallBackground: Color {
        colorScheme == .dark ?
            Color(red: 12/255, green: 12/255, blue: 16/255) :
            Color(red: 240/255, green: 240/255, blue: 232/255)
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                overallBackground.ignoresSafeArea()
                Form {
                    Section(header: Text(NSLocalizedString("ui_setting", comment: "")).font(.headline)) {
                        Toggle(NSLocalizedString("dark_mode", comment: ""), isOn: $isDarkMode)
                    }
                    
                    Section(header: Text(NSLocalizedString("text_size", comment: "")).font(.headline)) {
                        Slider(value: $textSize, in: 10...30, step: 1)
                        Text("\(Int(textSize)) pt")
                            .font(.system(size: CGFloat(textSize)))
                    }
                    
                    Section(header: Text(NSLocalizedString("language", comment: "")).font(.headline)) {
                        Button(action: {
                            openAppSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text(NSLocalizedString("language", comment: ""))
                            }
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("developer", comment: "")).font(.headline)) {
                        Text("TAEHAN YOON")
                        Button(action: {
                            isShowingFeedback = true
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                Text(NSLocalizedString("send_feedback", comment: ""))
                            }
                        }
                    }
                    
                    Text(appVersion)
                        .foregroundColor(.gray)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(NSLocalizedString("settings_title", comment: ""))
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .sheet(isPresented: $isShowingFeedback) {
                FeedbackView(email: email)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingView(email: .constant("user@example.com"))
        .environmentObject(LanguageManager())
}
