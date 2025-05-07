//
//  SignupFormView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI

struct SignupFormView: View {
    @Binding var isLoggedIn: Bool
    @Binding var name: String
    @Binding var email: String
    
    @State private var enteredName: String = ""
    @State private var enteredEmail: String = ""
    @State private var isEmailValid: Bool = true
    @State private var isFormValid: Bool = false
    @State private var showWelcomeAlert: Bool = false

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("create_account", comment: ""))
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
                name = enteredName
                email = enteredEmail
                isLoggedIn = true
                
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(enteredName, forKey: "name")
                UserDefaults.standard.set(enteredEmail, forKey: "email")
                
                showWelcomeAlert = true
            }) {
                Text(NSLocalizedString("create_account", comment: ""))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.green : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!isFormValid)
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle(NSLocalizedString("create_account", comment: ""), displayMode: .inline)
        .alert(isPresented: $showWelcomeAlert) {
            Alert(
                title: Text(NSLocalizedString("welcome_title", comment: "")),
                message: Text(String(format: NSLocalizedString("welcome_message", comment: ""), enteredName)),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
}

#Preview {
    SignupFormView(isLoggedIn: .constant(false), name: .constant(""), email: .constant(""))
}
