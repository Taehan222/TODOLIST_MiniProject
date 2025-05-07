//
//  FeedbackView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI
import FirebaseFirestore

struct FeedbackView: View {
    let email: String
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var submissionSuccess: Bool? = nil
    @State private var characterCount: Int = 0
    @State private var isCharacterLimitExceeded: Bool = false

    private var db = Firestore.firestore()
    
    init(email: String) {
        self.email = email
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("message_input", comment: ""))) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                        .onChange(of: feedbackText) { newValue in
                            if newValue.count > 100 {
                                feedbackText = String(newValue.prefix(100))
                            }
                            characterCount = feedbackText.count
                            isCharacterLimitExceeded = characterCount > 100
                        }
                }

                if isCharacterLimitExceeded {
                    Text(NSLocalizedString("character_limit_exceeded", comment: ""))
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Text("\(characterCount)/100")

                if let success = submissionSuccess {
                    Text(success ? NSLocalizedString("send_success", comment: "") : "피드백 제출에 실패했습니다.")
                        .foregroundColor(success ? .green : .red)
                }
            }
            .navigationBarTitle(NSLocalizedString("send_feedback", comment: ""), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("send", comment: "")) {
                        submitFeedback()
                    }
                    .disabled(feedbackText.isEmpty || isSubmitting || isCharacterLimitExceeded)
                }
            }
        }
    }

    private func submitFeedback() {
        guard !feedbackText.isEmpty, !email.isEmpty else { return }

        isSubmitting = true

        let feedbackData: [String: Any] = [
            "email": email,
            "feedback": feedbackText,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("feedback").addDocument(data: feedbackData) { error in
            isSubmitting = false
            if let error = error {
                print("Error submitting feedback: \(error)")
                submissionSuccess = false
            } else {
                submissionSuccess = true
                feedbackText = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
