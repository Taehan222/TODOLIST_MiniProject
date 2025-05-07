//
//  LanguageManager.swift
//  TodoList2.0
//
//  Created by 윤태한 on 2/12/25.
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    @AppStorage("selectedLanguage") var currentLanguage: String = "ko" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            Bundle.setLanguage(currentLanguage) // 언어 변경 시 이 함수를 호출
        }
    }
    
    func changeLanguage(to language: String) {
        currentLanguage = language
    }
}

extension Bundle {
    private static var customBundle: Bundle?

    // 언어 설정 메서드
    static func setLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            // 기본 언어로 돌아감 (예: 번들이 없을 때)
            customBundle = nil
            return
        }
        customBundle = languageBundle
    }

    // 커스텀 번들에서 localizedString을 호출하는 함수
    func localizedStringForKey(_ key: String, value: String?, table tableName: String?) -> String {
        return Bundle.customBundle?.localizedString(forKey: key, value: value, table: tableName) ?? localizedString(forKey: key, value: value, table: tableName)
    }
}
