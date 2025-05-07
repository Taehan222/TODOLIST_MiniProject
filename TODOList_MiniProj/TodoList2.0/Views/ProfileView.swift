//
//  ProfileView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var name: String
    @Binding var email: String

    @State private var showDeleteAlert: Bool = false
    @State private var isEditingName: Bool = false
    @State private var newName: String = ""
    @State private var showNameError: Bool = false
    @State private var errorMessage: String = ""

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
                    Spacer(minLength: 20)
                    
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                    
                    if isLoggedIn {
                        HStack {
                            if isEditingName {
                                HStack {
                                    TextField(NSLocalizedString("input_name", comment: ""), text: $newName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Button(action: {
                                        if validateName(newName) {
                                            updateName()
                                        }
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal, 50)
                                
                                if showNameError {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .padding(.top, 4)
                                }
                            } else {
                                HStack {
                                    Text(name)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.center)
                                    Button(action: {
                                        newName = name
                                        isEditingName = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal, 10)
                            }
                        }
                        
                        Text("\(NSLocalizedString("email", comment: "")): \(email)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                        
                        VStack(spacing: 10) {
                            Button(action: logOut) {
                                Text(NSLocalizedString("log_out", comment: ""))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Text(NSLocalizedString("del_account", comment: ""))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                            .confirmationDialog(NSLocalizedString("del_account_confirm", comment: ""), isPresented: $showDeleteAlert, titleVisibility: .visible) {
                                Button(NSLocalizedString("del_account", comment: ""), role: .destructive) {
                                    deleteAccount()
                                }
                                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
                            }
                        }
                        .padding(.horizontal)
                        
                    } else {
                        Text(NSLocalizedString("need_login", comment: ""))
                            .font(.title)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: AuthView()) {
                            Text(NSLocalizedString("log_in", comment: ""))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - 함수들
    private func logOut() {
        isLoggedIn = false
        name = ""
        email = ""
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set("", forKey: "name")
        UserDefaults.standard.set("", forKey: "email")
    }
    
    private func deleteAccount() {
        let db = Firestore.firestore()
        let todosRef = db.collection("users").document(email).collection("todos")
        todosRef.getDocuments { snapshot, error in
            if let error = error {
                print("회원 탈퇴 오류: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                deleteFirebaseUser()
                return
            }
            let batch = db.batch()
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            batch.commit { error in
                if let error = error {
                    print("배치 삭제 오류: \(error.localizedDescription)")
                } else {
                    print("투두 삭제 성공!")
                    deleteFirebaseUser()
                }
            }
        }
    }
    
    private func deleteFirebaseUser() {
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                print("Auth 계정 삭제 실패: \(error.localizedDescription)")
            } else {
                print("Auth 계정 삭제 성공!")
                logOut()
            }
        }
    }
    
    private func updateName() {
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["name": newName]) { error in
            if let error = error {
                print("이름 변경 실패: \(error.localizedDescription)")
            } else {
                print("이름 변경 성공!")
                name = newName
                UserDefaults.standard.set(newName, forKey: "name")
                isEditingName = false
            }
        }
    }
    
    private func validateName(_ name: String) -> Bool {
        if name.isEmpty {
            errorMessage = NSLocalizedString("name_error", comment: "")
            showNameError = true
            return false
        } else if name.count < 1 || name.count > 20 {
            errorMessage = NSLocalizedString("name_length_error", comment: "")
            showNameError = true
            return false
        }
        showNameError = false
        return true
    }
}
