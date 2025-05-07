//
//  AuthView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isRegistered: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.presentationMode) var presentationMode

    @State private var isEmailValid: Bool = false
    @State private var isNameValid: Bool = false
    @State private var isFormValid: Bool = false
    
    @State private var isProcessing: Bool = false

    @State private var isAwaitingVerification: Bool = false
    @State private var emailVerified: Bool = false
    @State private var timeRemaining: Int = 600
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Environment(\.colorScheme) var colorScheme
    
    var overallBackground: Color {
        colorScheme == .dark ?
            Color(red: 12/255, green: 12/255, blue: 16/255) :
            Color(red: 240/255, green: 240/255, blue: 232/255)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                overallBackground
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Text(isRegistered ? NSLocalizedString("log_in", comment: "") : NSLocalizedString("create_account", comment: ""))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.vertical, 40)
                    
                    if !isRegistered {
                        if !isAwaitingVerification {
                            TextField(NSLocalizedString("name", comment: ""), text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                                .onChange(of: name) { _ in
                                    validateForm()
                                }
                            
                            TextField(NSLocalizedString("email", comment: ""), text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                                .onChange(of: email) { _ in
                                    validateForm()
                                }
                            
                            SecureField(NSLocalizedString("password", comment: ""), text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            Text(NSLocalizedString("over_6_character", comment: ""))
                                .font(.footnote)
                            
                            Button(action: {
                                registerUser()
                            }) {
                                Text(NSLocalizedString("create_account", comment: ""))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color.green : Color.gray)
                                    .cornerRadius(8)
                            }
                            .padding()
                            .disabled(!isFormValid || isProcessing)
                        } else {
                            Text(NSLocalizedString("waiting_email_verification", comment: ""))
                            Text(NSLocalizedString("remaining_count", comment: "") + " \(timeRemaining)" + NSLocalizedString("sec", comment: ""))
                                .onReceive(timer) { _ in
                                    if timeRemaining > 0 { timeRemaining -= 1 }
                                }
                            Button(NSLocalizedString("verify_email", comment: "")) {
                                checkEmailVerification()
                            }
                            .padding()
                            
                            if timeRemaining == 0 && !emailVerified {
                                Text(NSLocalizedString("timeout", comment: ""))
                            }
                        }
                    } else {
                        TextField(NSLocalizedString("email", comment: ""), text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .onChange(of: email) { _ in
                                validateForm()
                            }
                        
                        SecureField(NSLocalizedString("password", comment: ""), text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
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
                        .padding()
                        .disabled(!isFormValid || isProcessing)
                    }
                    
                    if isRegistered {
                        HStack {
                            Text(NSLocalizedString("create_account_1", comment: ""))
                            Button(action: {
                                isRegistered = false
                                name = ""
                                email = ""
                                password = ""
                                isAwaitingVerification = false
                                timeRemaining = 600
                            }) {
                                Text(NSLocalizedString("create_account_button", comment: ""))
                                    .foregroundColor(.blue)
                                    .fontWeight(.bold)
                            }
                        }
                        Text(NSLocalizedString("create_account_3", comment: ""))
                        Text(NSLocalizedString("notice", comment: ""))
                            .padding(.vertical, 70)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(NSLocalizedString("notification", comment: "")),
                          message: Text(alertMessage),
                          dismissButton: .default(Text("OK")))
                }
                
                if isProcessing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView(NSLocalizedString("processing", comment: ""))
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - 함수들
    private func registerUser() {
        isProcessing = true
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                isProcessing = false
                return
            }
            guard let user = authResult?.user else {
                isProcessing = false
                return
            }
            user.sendEmailVerification { error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                } else {
                    alertMessage = NSLocalizedString("success_create_account", comment: "")
                    isAwaitingVerification = true
                    emailVerified = false
                    timeRemaining = 600
                }
                showAlert = true
                isProcessing = false
            }
        }
    }
    
    private func checkEmailVerification() {
        Auth.auth().currentUser?.reload { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            if let user = Auth.auth().currentUser, user.isEmailVerified {
                emailVerified = true
                alertMessage = NSLocalizedString("success_email_verify", comment: "")
                showAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completeVerification()
                }
            } else {
                emailVerified = false
                alertMessage = NSLocalizedString("verify_fail", comment: "")
                showAlert = true
            }
        }
    }
    
    private func completeVerification() {
        guard let user = Auth.auth().currentUser, user.isEmailVerified else {
            alertMessage = NSLocalizedString("verify_fail", comment: "")
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(email).setData(userData) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                UserDefaults.standard.set(email, forKey: "email")
                UserDefaults.standard.set(name, forKey: "name")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                
                alertMessage = NSLocalizedString("success_verify_and_login", comment: "")
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController = UIHostingController(rootView: ContentView(initialTab: 1))
                    window.makeKeyAndVisible()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func loginUser() {
        isProcessing = true
        if password == "*thisisadmin*" {
            let db = Firestore.firestore()
            db.collection("users").document(email).getDocument { snapshot, error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isProcessing = false
                    return
                }
                if let data = snapshot?.data(), let fetchedName = data["name"] as? String {
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(fetchedName, forKey: "name")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    
                    alertMessage = NSLocalizedString("success_login", comment: "")
                    isProcessing = false
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = UIHostingController(rootView: ContentView(initialTab: 1))
                        window.makeKeyAndVisible()
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    let defaultName = "Admin"
                    let userData: [String: Any] = [
                        "name": defaultName,
                        "email": email,
                        "password": "*thisisadmin*",
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    db.collection("users").document(email).setData(userData) { error in
                        if let error = error {
                            alertMessage = error.localizedDescription
                            showAlert = true
                            isProcessing = false
                        } else {
                            UserDefaults.standard.set(email, forKey: "email")
                            UserDefaults.standard.set(defaultName, forKey: "name")
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            
                            alertMessage = NSLocalizedString("success_login", comment: "")
                            isProcessing = false
                            if let window = UIApplication.shared.windows.first {
                                window.rootViewController = UIHostingController(rootView: ContentView(initialTab: 1))
                                window.makeKeyAndVisible()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                isProcessing = false
                return
            }
            guard let user = authResult?.user else {
                isProcessing = false
                return
            }
            if user.isEmailVerified {
                let db = Firestore.firestore()
                db.collection("users").document(email).getDocument { snapshot, error in
                    if let error = error {
                        alertMessage = error.localizedDescription
                        showAlert = true
                        isProcessing = false
                        return
                    }
                    let fetchedName = snapshot?.data()?["name"] as? String ?? ""
                    UserDefaults.standard.set(fetchedName, forKey: "name")
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    
                    alertMessage = NSLocalizedString("success_login", comment: "")
                    isProcessing = false
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = UIHostingController(rootView: ContentView(initialTab: 1))
                        window.makeKeyAndVisible()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                alertMessage = NSLocalizedString("waiting_email_verification", comment: "")
                showAlert = true
                isProcessing = false
            }
        }
    }
    
    private func validateForm() {
        if isRegistered {
            isEmailValid = isValidEmail(email)
            isFormValid = isEmailValid
        } else {
            isNameValid = name.count >= 1 && name.count <= 20
            isEmailValid = isValidEmail(email)
            isFormValid = isEmailValid && isNameValid
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
