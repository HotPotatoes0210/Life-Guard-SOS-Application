
import SwiftUI

class ConfirmUser: ObservableObject {
    @Published var confirmUsername: String = "None"
    
    func updateUser(Username: String) {
        confirmUsername = Username
    }
}

class RealTimeLocation: ObservableObject {
    @Published var confirmedLocation: String = "None"
    
    func updateLocation(Location: String) {
        confirmedLocation = Location
    }
}

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var message: String = ""
    @Binding var isLoggedIn: Bool
    
    @EnvironmentObject var confirmUser: ConfirmUser  // Use EnvironmentObject to share data
    let dbManager = DatabaseManager()
    
    func saveLoginState(username: String) {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(username, forKey: "loggedInUsername")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Login")
                    .font(.largeTitle)
                    .padding(.bottom, 40)
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    print("Login pressed")
                    if dbManager.authenticate(username: username, password: password) {
                        print("Good")
                        isLoggedIn = true
                        confirmUser.updateUser(Username: username) // Update global user state
                        print(confirmUser.confirmUsername)
                    } else {
                        print("Bad")
                    }
                }) {
                    Text("Login")
                        .frame(minWidth: 0, maxWidth: 100)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                
                NavigationLink(destination: SignUpView()) {
                    Label("Sign Up", systemImage: "")
                        .frame(minWidth: 0, maxWidth: 100)
                        .padding()
                }
            }
        }
    }
}



struct SignUpView: View{
    @State var username: String = ""
    @State var password: String = ""
    @State var confirm_password: String = ""
    @State var phone_number: String = ""
    @State var email: String = ""
    @State var full_name: String = ""
    
    let dbManager = DatabaseManager()
    
    var body: some View{
        NavigationView {
            VStack{
                Text("Sign Up").font(.largeTitle).padding(.bottom, 40)
                Text("Be a part of our community!").font(.footnote)
                
                TextField("Full name", text: $full_name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                SecureField("Confirm Password", text: $confirm_password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if username.isEmpty || password.isEmpty || confirm_password.isEmpty || email.isEmpty || full_name.isEmpty {
                        print("Please fill in all the fields.")
                        return
                    }
                    if password != confirm_password {
                        print("Password do not match")
                        return
                    }
                    if !email.contains("@") || !email.contains(".") {
                        print("Invalid email address")
                        return
                    }
                    do {
                        try dbManager.insertUser(username: username, password: password, phone_number: phone_number, email: email, full_name: full_name)
                        print("Registered successfully")
                    }catch {
                        print(error.localizedDescription)
                    }
                    
                }) {
                    Text("Submit")
                        .frame(minWidth: 0, maxWidth: 100)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
    }
}

struct UserInfoView: View {
    @EnvironmentObject var confirmUser: ConfirmUser // Access the shared ConfirmUser object
    @State var phoneNumber: String = "Not updated yet"
    @State var email: String = "Not updated yet"
    @State var full_name: String = "Not updated yet"
    @State var isLoggedIn: Bool = false
    
    let dbManager = DatabaseManager()
    
    var body: some View {
        NavigationView {
            VStack{
                Text("Full name: \(full_name)")
                Text("Phone number: \(phoneNumber)")
                Text("Email: \(email)")
            }
            .onAppear {
                // Fetch user info based on the username stored in ConfirmUser
                if let userInfo = dbManager.fetchUserInfo(username: confirmUser.confirmUsername) {
                    print("Fetching user info for: \(confirmUser.confirmUsername)")
                    full_name = userInfo.full_name
                    phoneNumber = userInfo.phone_number
                    email = userInfo.email
                }
            }
        }.navigationTitle("User Info")
    }
}

#Preview {
    ContentView()
}
