//
//  Todo.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Todo 모델
struct Todo: Codable, Identifiable {
    @DocumentID var id: String?
    var localId: String?
    var task: String
    var isCompleted: Bool
    var timestamp: Timestamp
    var location: String

    enum CodingKeys: String, CodingKey {
        case id, task, isCompleted, timestamp, location, localId
    }
}
