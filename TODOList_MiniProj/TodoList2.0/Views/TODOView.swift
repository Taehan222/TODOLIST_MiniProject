//
//  TODOView.swift
//  TodoList2.0
//
//  Created by 윤태한 on 5/1/25.
//

import SwiftUI
import FirebaseFirestore

struct TODOView: View {
    let email: String
    @Binding var selectedTab: Int

    @State private var todos: [Todo] = []
    @State private var isShowingAddTodo: Bool = false
    @State private var isShowingLoginAlert: Bool = false
    @AppStorage("textSize") private var textSize: Double = 14.0

    private var db = Firestore.firestore()
    private let localEmail = "test@test.com"
    
    @Environment(\.colorScheme) var colorScheme
    
    var overallBackground: Color {
        colorScheme == .dark ?
            Color(red: 12/255, green: 12/255, blue: 16/255) :
            Color(red: 240/255, green: 240/255, blue: 232/255)
    }
    
    var incompleteBackground: Color {
        colorScheme == .dark ?
            Color(red: 64/255, green: 64/255, blue: 64/255) :
            Color.white
    }
    
    var completedBackground: Color {
        colorScheme == .dark ?
            Color(red: 44/255, green: 44/255, blue: 44/255) :
            Color(red: 248/255, green: 248/255, blue: 245/255)
    }

    init(email: String, selectedTab: Binding<Int>) {
        self.email = email.isEmpty ? localEmail : email
        self._selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                overallBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if todos.isEmpty {
                        Spacer()
                        Text("할 일이 없습니다.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    } else {
                        List {
                            ForEach(todos) { todo in
                                TodoRowView(todo: todo, textSize: textSize) {
                                    withAnimation {
                                        updateTodoCompletion(todo, newValue: !todo.isCompleted)
                                    }
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(todo.isCompleted ? completedBackground : incompleteBackground)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onDelete(perform: deleteTodo)
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    if email == localEmail {
                        Text(NSLocalizedString("local_mode", comment: ""))
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if !email.isEmpty {
                        Text("Email: \(email)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Button(action: { isShowingAddTodo = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing))
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 4, y: 4)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("my_to_do_list", comment: ""))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .onAppear { fetchTodos() }
            .sheet(isPresented: $isShowingAddTodo) {
                AddTodoView { title, location in
                    addTodo(title: title, location: location)
                }
            }
            .alert(isPresented: $isShowingLoginAlert) {
                Alert(
                    title: Text(NSLocalizedString("need_login", comment: "")),
                    message: Text(NSLocalizedString("move_profile", comment: "")),
                    dismissButton: .default(Text("OK"), action: { selectedTab = 1 })
                )
            }
        }
    }

    // MARK: - 데이터 불러오기
    private func fetchTodos() {
        if email == localEmail {
            if let data = UserDefaults.standard.data(forKey: "localTodos") {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .millisecondsSince1970
                    let decodedTodos = try decoder.decode([Todo].self, from: data)
                    todos = decodedTodos
                } catch {
                    print("로컬 todos 디코딩 오류: \(error.localizedDescription)")
                }
            }
        } else {
            db.collection("users").document(email).collection("todos")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Firestore todos 불러오기 오류: \(error)")
                        return
                    }
                    todos = snapshot?.documents.compactMap { doc -> Todo? in
                        try? doc.data(as: Todo.self)
                    } ?? []
                }
        }
    }

    // MARK: - 할 일 추가하기
    private func addTodo(title: String, location: String?) {
        let newTodo = Todo(
            task: title,
            isCompleted: false,
            timestamp: Timestamp(date: Date()),
            location: location ?? ""
        )

        if email == localEmail {
            var localTodo = newTodo
            localTodo.localId = UUID().uuidString
            todos.append(localTodo)
            saveLocalTodos()
        } else {
            guard !title.isEmpty, !email.isEmpty else { return }
            do {
                _ = try db.collection("users").document(email).collection("todos").addDocument(from: newTodo)
            } catch {
                print("Firestore에 할 일 추가 오류: \(error)")
            }
        }
    }

    // MARK: - 할 일 삭제
    private func deleteTodo(at offsets: IndexSet) {
        if email == localEmail {
            todos.remove(atOffsets: offsets)
            saveLocalTodos()
        } else {
            for index in offsets {
                let todo = todos[index]
                if let id = todo.id {
                    db.collection("users").document(email).collection("todos").document(id).delete()
                }
            }
        }
    }

    // MARK: - 할 일 완료 상태 업데이트
    private func updateTodoCompletion(_ todo: Todo, newValue: Bool) {
        if email == localEmail {
            if let index = todos.firstIndex(where: { $0.localId == todo.localId }) {
                todos[index].isCompleted = newValue
                saveLocalTodos()
            }
        } else {
            guard let id = todo.id else { return }
            db.collection("users").document(email).collection("todos").document(id)
                .updateData(["isCompleted": newValue])
        }
    }

    // MARK: - 로컬 저장
    private func saveLocalTodos() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let data = try encoder.encode(todos)
            UserDefaults.standard.set(data, forKey: "localTodos")
        } catch {
            print("로컬 todos 저장 오류: \(error.localizedDescription)")
        }
    }
}

// MARK: - 카드형 디자인의 할 일 항목 뷰
struct TodoRowView: View {
    let todo: Todo
    let textSize: Double
    let toggleAction: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleAction) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.task)
                    .font(.system(size: CGFloat(textSize), weight: .medium))
                    .foregroundColor(todo.isCompleted ? .gray : .primary)
                    .strikethrough(todo.isCompleted, color: .gray)
                    .onTapGesture {
                        toggleAction()
                    }
                
                if !todo.location.isEmpty {
                    Text(todo.location)
                        .font(.system(size: CGFloat(textSize - 2)))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, CGFloat(textSize - 9))
        .background(EmptyView())

    }
}

// MARK: - 추가 입력 폼 (시트)
struct AddTodoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var newTodoTitle: String = ""
    @State private var newTodoLocation: String = ""
    @State private var titleErrorMessage: String? = nil
    @State private var locationErrorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    var onSave: (String, String) -> Void

    @Environment(\.colorScheme) var colorScheme
    var overallBackground: Color {
        colorScheme == .dark ?
            Color(red: 12/255, green: 12/255, blue: 16/255) :
            Color(red: 245/255, green: 245/255, blue: 240/255)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text(NSLocalizedString("add_to_do_form", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)) {
                        
                        TextField(NSLocalizedString("new_to_do", comment: ""), text: $newTodoTitle)
                            .padding()
                            .cornerRadius(10)
                            .autocapitalization(.sentences)
                            .disableAutocorrection(true)
                            .onChange(of: newTodoTitle) { newValue in
                                titleErrorMessage = newValue.count > 30 ? NSLocalizedString("max_30", comment: "") : nil
                            }
                        
                        if let titleErrorMessage = titleErrorMessage {
                            Text(titleErrorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        TextField(NSLocalizedString("new_to_do_location", comment: ""), text: $newTodoLocation)
                            .padding()
                            .cornerRadius(10)
                            .autocapitalization(.sentences)
                            .disableAutocorrection(true)
                            .onChange(of: newTodoLocation) { newValue in
                                locationErrorMessage = newValue.count > 30 ? NSLocalizedString("max_30", comment: "") : nil
                            }
                        
                        if let locationErrorMessage = locationErrorMessage {
                            Text(locationErrorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                }
                .background(overallBackground)
                
                Button(action: {
                    if newTodoTitle.isEmpty || newTodoTitle.count > 30 {
                        showErrorAlert = true
                    } else {
                        onSave(newTodoTitle, newTodoLocation)
                        dismiss()
                    }
                }) {
                    Text(NSLocalizedString("save", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text(NSLocalizedString("invalid_title", comment: "")),
                        message: Text(NSLocalizedString("title_error_message", comment: "")),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding(.top, 20)
            .navigationTitle(NSLocalizedString("add_new_to_do", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
        .background(overallBackground)
    }
}
