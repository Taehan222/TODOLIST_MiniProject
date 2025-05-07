//
//  LoginFormView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI
import FirebaseFirestore

struct LoginFormView: View {
    @Binding var isLoggedIn: Bool
    @Binding var name: String
    @Binding var email: String

    @State private var enteredName: String = ""
    @State private var enteredEmail: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var isEmailValid: Bool = true
    @State private var isFormValid: Bool = false

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("log_in", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField(NSLocalizedString("name", comment: ""), text: $enteredName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: enteredName) { _ in
                    validateForm()
                }

            TextField(NSLocalizedString("email", comment: ""), text: $enteredEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: enteredEmail) { newValue in
                    isEmailValid = newValue.count >= 5
                    validateForm()
                }
            
            if !isEmailValid {
                Text(NSLocalizedString("login_email_error", comment: ""))
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                loginUser()
            }) {
                Text(NSLocalizedString("log_in", comment: ""))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!isFormValid)
            .padding()

            Spacer()
        }
        .padding()
        .navigationBarTitle(NSLocalizedString("log_in", comment: ""), displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text(NSLocalizedString("login_fail", comment: "")),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func validateForm() {
        isEmailValid = enteredEmail.count >= 5 && isValidEmail(enteredEmail)
        isFormValid = !enteredName.isEmpty && isEmailValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }

    private func loginUser() {
        let trimmedEmail = enteredEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedName.isEmpty else {
            alertMessage = NSLocalizedString("form_error_empty", comment: "")
            showAlert = true
            return
        }
        
        if trimmedEmail.count < 5 {
            alertMessage = NSLocalizedString("login_email_error", comment: "")
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(trimmedEmail).collection("todos").getDocuments { snapshot, error in
            if let error = error {
                print("할 일 목록 조회 오류: \(error.localizedDescription)")
                alertMessage = NSLocalizedString("login_fail", comment: "")
                showAlert = true
                return
            }

            if let snapshot = snapshot, !snapshot.isEmpty {
                name = trimmedName
                email = trimmedEmail
                isLoggedIn = true
                
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(trimmedName, forKey: "name")
                UserDefaults.standard.set(trimmedEmail, forKey: "email")
                
                print("로그인 성공: \(trimmedEmail)")
            } else {
                alertMessage = NSLocalizedString("login_email_error", comment: "")
                showAlert = true
                print("로그인 실패: 해당 이메일로 할 일 목록이 없습니다.")
            }
        }

    }

}
