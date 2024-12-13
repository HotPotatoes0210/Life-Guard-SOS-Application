import SwiftUI
import Combine
import CoreLocation
import Foundation



@main
struct LifeGuardApp: App {
    init() {
        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = NotificationDelegate() // Handle foreground notifications
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(RealTimeLocation())
                .environmentObject(ConfirmUser())
        }
    }
}


struct EmergencyPopupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedEmergency: EmergencyType? = nil
    let trigger = OtherSituationPopupView.message_trigger
    @Binding var shouldRefreshAlert: Bool

    var body: some View {
        VStack {
            Text("What is your emergency?")
                .font(.headline)
                .padding(.bottom, 20)

            ForEach(EmergencyType.allCases, id: \.self) { type in
                Button(action: {
                    print(trigger)
                    selectedEmergency = type
                    print(selectedEmergency?.rawValue as Any)
                    if selectedEmergency?.rawValue != "Other Situation" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            shouldRefreshAlert = true
                            dismiss()
                        }
                    }
                    if selectedEmergency?.rawValue == "Other Situation" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            shouldRefreshAlert = true
                            dismiss()
                        }
                    }
                }) {
                    Text(type.displayName)
                        .frame(width: 350, height: 50)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(30)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .sheet(item: $selectedEmergency) { emergency in
            EmergencyDetailPopupView(emergencyType: emergency, shouldRefreshAlert: $shouldRefreshAlert)
                .presentationDetents([.fraction(0.5)])
                .interactiveDismissDisabled(true)
        }
    }
}

enum EmergencyType: String, CaseIterable, Identifiable {
    case fire = "Fire Accident 🔥"
    case traffic = "Traffic Accident 🚘"
    case trespassing = "Trespassing 🚷"
    case disaster = "Natural Disaster 🌪️"
    case other = "Other Situation"

    var id: String { self.rawValue }

    var displayName: String {
        self.rawValue
    }
}
struct ConfirmView: View{
    var body: some View{
        VStack{
            Text("Emergency department is on the way!").font(.headline)
            Text("Please remain calm and wait for assistance.")
            Label("",systemImage: "checkmark.circle.fill").foregroundStyle(Color.green).frame(width: 100,height: 100).font(.system(size: 100))
            Text("In this time, please use Life Guard Assistant to get more guidance").multilineTextAlignment(.center)
        }.padding()
    }
}

struct OtherSituationPopupView: View {
    @State private var custom_message: String = ""
    @State private var showEmptyMessageAlert = false
    @State public var showEmergencyPopup = false
    @EnvironmentObject var confirmUser: ConfirmUser
    @EnvironmentObject var confirmLocation: RealTimeLocation
    @Environment(\.dismiss) var dismiss
    @State private var check_message = false
    @State private var showConfirmView = false
    let historydb = History_database()
    @Binding var shouldRefreshAlert: Bool
    
    // Add a closure to handle parent view dismissal
    var parentDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            VStack {
                Text("Please write down your emergency information here!")
                    .font(.headline)
                
                TextField("Write your message here", text: $custom_message)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: 350, alignment: .top)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                
                Button(action: {
                    if custom_message.isEmpty {
                        showEmptyMessageAlert = true
                    }
                    else {
                        showEmergencyPopup = true
                        check_message = true
                        Task {
                            let time = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                            await historydb.insertHistory(
                                history_content: "Signal is triggered with the message: \(custom_message)",
                                username: confirmUser.confirmUsername,
                                time: time,
                                address: confirmLocation.confirmedLocation
                            )
                            shouldRefreshAlert = true
                        }
                        showConfirmView = true
                        
                        // Dismiss all popups after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            showConfirmView = false
                            shouldRefreshAlert = true
                            dismiss() // Dismiss OtherSituationPopupView
                            parentDismiss?() // Dismiss parent EmergencyPopupView
                        }
                    }
                }) {
                    Text("Submit")
                        .frame(width: 350, height: 50)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(30)
                }
                .alert(isPresented: $showEmptyMessageAlert) {
                    Alert(title: Text("Warning"), message: Text("Please write your message before submitting."), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
            .sheet(isPresented: $showConfirmView) {
                        ConfirmView().presentationDetents([.fraction(0.5)])
            }
        }
    }
    func message_trigger()-> Bool{
        if check_message == true{
            return true
        }
        else{
            return false
        }
    }
}


struct EmergencyDetailPopupView: View {
    @EnvironmentObject var confirmUser: ConfirmUser
    @EnvironmentObject var confirmLocation: RealTimeLocation
    let emergencyType: EmergencyType
    @Binding var shouldRefreshAlert: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            EmergencyContentView(for: emergencyType, confirmuser: confirmUser.confirmUsername , confirmAddress: confirmLocation.confirmedLocation, shouldRefreshAlert: $shouldRefreshAlert, parentDismiss: {
                dismiss()
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .padding()
    }
}

@ViewBuilder
private func EmergencyContentView(for type: EmergencyType , confirmuser: String, confirmAddress: String, shouldRefreshAlert: Binding<Bool>, parentDismiss: @escaping () -> Void) -> some View {
    @EnvironmentObject var confirmUser: ConfirmUser
    @EnvironmentObject var confirmLocation: RealTimeLocation
    let historydb = History_database()
    @State var custom_message: String = ""
    switch type {
    case .fire:
        VStack{
            Text("Firefighter is on the way!").font(.headline)
            Text("Please remain calm and wait for assistance.")
            Label("",systemImage: "checkmark.circle.fill").foregroundStyle(Color.green).frame(width: 100,height: 100).font(.system(size: 100))
            Text("In this time, please use Life Guard Assistant to get more guidance").multilineTextAlignment(.center)
        }.onAppear{
            Task{
                let historyContent = "Attention: A fire has been reported. Please stay away until the fire is extinguished"
                let time = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short) // Time formatted
                
                await historydb.insertHistory(history_content: historyContent, username: confirmuser,  time: time, address: confirmAddress)
                shouldRefreshAlert.wrappedValue = true
            }
        }
    case .traffic:
        VStack{
            Text("Ambulance is on the way!").font(.headline)
            Text("Please remain calm and wait for assistance.")
            Label("",systemImage: "checkmark.circle.fill").foregroundStyle(Color.green).frame(width: 100,height: 100).font(.system(size: 100))
            Text("In this time, please use Life Guard Assistant to get more guidance").multilineTextAlignment(.center)
        }.onAppear{
            Task{
                let historyContent = "Attention: There is a car accident, vehicle nearby please pay attention and drive safely"
                let time = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short) // Time formatted
                
                await historydb.insertHistory(history_content: historyContent, username: confirmuser,  time: time, address: confirmAddress)
                shouldRefreshAlert.wrappedValue = true
            }
        }
    case .trespassing:
        VStack{
            Text("Police is on the way!").font(.headline)
            Text("Please remain calm and wait for assistance.")
            Label("",systemImage: "checkmark.circle.fill").foregroundStyle(Color.green).frame(width: 100,height: 100).font(.system(size: 100))
            Text("In this time, please use Life Guard Assistant to get more guidance").multilineTextAlignment(.center)
        }.onAppear{
            Task{
                let historyContent = "Danger: Trespassing has been reported nearby, please keep your house safe and stay inside until the police arrive"
                let time = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short) // Time formatted
                
                await historydb.insertHistory(history_content: historyContent, username: confirmuser,  time: time, address: confirmAddress)
                shouldRefreshAlert.wrappedValue = true
            }
        }
    case .disaster:
        VStack{
            Text("Emergency department is on the way!").font(.headline)
            Text("Please remain calm and wait for assistance.")
            Label("",systemImage: "checkmark.circle.fill").foregroundStyle(Color.green).frame(width: 100,height: 100).font(.system(size: 100))
            Text("In this time, please use Life Guard Assistant to get more guidance").multilineTextAlignment(.center)
        }.onAppear{
            Task{
                let historyContent = "Danger: Natural disaster (earthquake, hurricane, tornado, storm) has been reported, please evacuate to the nearest shelter immediately until everything is safe"
                let time = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short) // Time formatted
                
                await historydb.insertHistory(history_content: historyContent, username: confirmuser,  time: time, address: confirmAddress)
                shouldRefreshAlert.wrappedValue = true
            }
        }
    case .other:
        OtherSituationPopupView(shouldRefreshAlert: shouldRefreshAlert, parentDismiss: parentDismiss).presentationDetents([.fraction(0.5)])
    }
}



struct LifeGuardMainPageView: View {
    @State var content_accident:String = "Attention: There is a car accident, vehicle nearby please pay attention and drive safety"
    
    @State var fire_accident: String = "Attention: A fire has been reported. Please stay away until the fire is extinguished"
    

    @State var tresspassing_accident: String = "Danger: Trespassing has been reported nearby, please keep your house safe and stay inside until the police arrive"
    
    @State var natural_disasterL : String = "Danger: Natural disaster (earthquake, hurricane, tornado, storm) has been reported, please evacuate to the nearest shelter immediately until everything is safe"
    
    @State private var time = 0
    
    @State private var showAlert = false
    
    @StateObject var deviceLocationService = DeviceLocationService.shared
    
    @State var tokens: Set<AnyCancellable>=[]
    
    @State var coordinate: (lat: Double, lon: Double) = (0,0)
    
    @State var address: String = "Location detection is off"
    
    @State var real_time: String = ""
    
    @State private var showEmergencyPopup = false
    
    @EnvironmentObject var confirmLocation: RealTimeLocation
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var isSignOut: Bool = false
    
    let history_database = History_database()
    
    @Binding var isLoggedIn: Bool
    
    @State private var latestAlert: (content: String, address: String) = ("No alerts", "")
    
    @State private var shouldRefreshAlert = false
    
    func getTime() -> String
    {
        let time = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: time)
    }
    
    
    //location update function
    func observeCoodinateUpdate(){
        deviceLocationService.coordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { coordinates in
                self.coordinate = (coordinates.latitude, coordinates.longitude)
            }
            .store(in: &tokens)
    }
    
    //location access denied
    func observeLocationAccessDenied(){
        deviceLocationService.deniedLocationAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("The location is denied")
                self.coordinate = (0,0)
            }
            .store(in: &tokens)
    }
    
    // Function to toggle SOS mode
    func SOS() {
        if time % 2 == 0 {
            registerNotification(message_incoming: latestAlert.content)
            print("On")
        } else {
            print("Off")
        }
        time += 1
    }
    
    func fetchAddress(completion: @escaping (String) -> Void) {
            getAddressFromCoordinates(latitude: coordinate.lat, longtitude: coordinate.lon) { fetchedAddress in
                DispatchQueue.main.async {
                    address = fetchedAddress ?? "Unable to fetch address."
                    completion(address)
                }
            }
        }
        
    func fetchLatestAlert() async {
        if let latest = await history_database.getLatestHistory() {
            DispatchQueue.main.async {
                self.latestAlert = (content: latest.content, address: latest.address)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack{
                HStack{
                    NavigationLink(destination: ChatBotView()){
                        Label("Menu", systemImage: "note")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 30))
                            .frame(width: 50, height: 50)
                    }
                    Spacer()
                    NavigationLink(destination:UserInfoView()) {
                                            Label("User Info", systemImage: "person.circle")
                                                .labelStyle(.iconOnly)
                                                .font(.system(size: 30))
                                                .frame(width: 50, height: 50)
                                        }
                }.padding().frame(maxWidth:.infinity)
                
                VStack {
                    Text("SOS Mode")
                    Button(action: {
                        showAlert = true
                        observeCoodinateUpdate()
                        deviceLocationService.requestLocationUpdate()
                        
                    }) {
                        Label("SOS Button", systemImage: "exclamationmark.triangle.fill")
                            .imageScale(.large)
                            .labelStyle(.iconOnly)
                            .font(.system(size: 25))
                            .controlSize(.extraLarge)
                            .frame(width: 100, height: 100)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.extraLarge)
                    .tint(time % 2 == 0 ? .green : .red) // Change color based on time
                    .alert(isPresented: $showAlert) {
                        if time % 2 == 0 {
                            return Alert(
                                title: Text("Activate SOS"),
                                message: Text("Are you sure you want to activate SOS mode?"),
                                primaryButton: .destructive(Text("Yes")) {
                                    fetchAddress { fetchedAddress in
                                                        address = fetchedAddress
                                                        confirmLocation.updateLocation(Location: address)
                                                        SOS()
                                                        showEmergencyPopup.toggle()
                                                    }
                                },
                                secondaryButton: .cancel(Text("No"))
                            )
                        } else {
                            return Alert(
                                title: Text("Deactivate SOS"),
                                message: Text("Do you want to turn off the SOS mode?"),
                                primaryButton: .destructive(Text("Yes")) {
                                    SOS()
                                    observeLocationAccessDenied()
                                    address = "Location detection is off"
                                },
                                secondaryButton: .cancel(Text("No"))
                            )
                        }
                    }.sheet(isPresented: $showEmergencyPopup){
                        EmergencyPopupView(shouldRefreshAlert: $shouldRefreshAlert).presentationDetents([.fraction(0.5)]).interactiveDismissDisabled(true)
                    }
                }
                .padding()
               
                ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .frame(width: 360, height: 200)
                                .foregroundStyle(Color.accentColor)
                                .padding()
                            ScrollView {
                                VStack {
                                    Text("ALERT SIGNAL")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(latestAlert.content)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 5)
                                    
                                    Text("Address: \(latestAlert.address)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 5)
                                }
                                .frame(width: 350, alignment: .center)
                                .padding(.top, 10)
                            }
                            .frame(width: 350, height: 150) // Set the frame size of ScrollView
                            
                        }
                        .onAppear {
                            Task {
                                await fetchLatestAlert()
                            }
                        }
                        .onChange(of: shouldRefreshAlert) { newValue in
                            if newValue {
                                Task {
                                    await fetchLatestAlert()
                                    shouldRefreshAlert = false
                                }
                            }
                        }
                        
                ZStack{
                    // Alert history button
                    NavigationLink(destination: HistoryView()) {
                        Label("Alert history", systemImage: "")
                            .padding(50)
                            .frame(width: 300,height: 50)
                            .foregroundStyle(Color.white)
                            .background(Color.gray)
                            .cornerRadius(30)
                            

                    }
                }
                VStack{
                    //Current location
                    Text("Current location:").font(.headline)
                    Text(address)
                }
                VStack{
                    Button(action:{
                        isLoggedIn = false
                    })
                    {
                        Text("Sign Out")
                    }
                }
            }
        }
    }
}

// View for the main content
struct ContentView: View {
    @State var isLoggedIn: Bool = false
    @StateObject private var confirmUser = ConfirmUser() // Make sure it's an @StateObject
    @StateObject private var confirmLocation = RealTimeLocation()

    var body: some View {
        VStack {
            if !isLoggedIn {
                LoginView(isLoggedIn: $isLoggedIn)
                    .environmentObject(confirmUser)
                    .environmentObject(confirmLocation)
            } else {
                LifeGuardMainPageView(isLoggedIn: $isLoggedIn)
                    .environmentObject(confirmUser)
                    .environmentObject(confirmLocation)
            }
        }
        .animation(.easeOut(duration: 1.0), value: isLoggedIn)
    }
}
