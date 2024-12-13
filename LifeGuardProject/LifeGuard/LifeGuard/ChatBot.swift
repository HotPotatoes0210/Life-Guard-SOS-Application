//
//  ChatBot.swift
//  LifeGuard
//
//  Created by Đại Việt Hưng Trần on 11/30/24.
//
import SwiftUI
import Ollama

class ChatBotServer {
    let client = Client.default
    let customClient = Client(host: URL(string: "http://localhost:11434")!, userAgent: "Hung.LifeGuard/1.0")
    var answer: String = ""
    func ChatResponse(prompt:String) async -> String {
        do{
            let response = try await client.chat(
                model: "llava:7b-v1.6-mistral-q3_K_S",
                messages: [
                    .system("You are an AI assistant that will help users to answer the question related to Emergency situation such as fire, disaster , traffic accident, tresspassing, etc. You are not authorized to answer any other question which not related to Emergency situation. Provide user tips and guidline to keep the user safe when the user need help or if not you can answer shortly"),
                    .user(prompt)
                ]
            )
            answer = String(response.message.content)
        }catch{
            print(error)
        }
        return answer
    }
}

struct ChatBotView: View {
    @State var text: String = ""
    @State private var isEditing: Bool = false
    @State private var inputText: String = ""
    @State private var isSubmit: Bool = false
    @State private var  message: String = "Welcome to the chat bot"
    @State private var displayedMessage: String = ""
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil
    let chatbot = ChatBotServer()
    
    func startTypingEffect() {
           displayedMessage = ""
           currentIndex = 0
           timer?.invalidate()
           
           timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
               if currentIndex < message.count {
                   let index = message.index(message.startIndex, offsetBy: currentIndex)
                   displayedMessage.append(message[index])
                   currentIndex += 1
               } else {
                   timer?.invalidate()
               }
           }
       }
    
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 360, height: 400)
                        .foregroundColor(Color.accentColor)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if isSubmit {
                    ScrollView {
                        Text(displayedMessage)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                            .padding(20)
                            .frame(maxWidth: 340, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 20)
                } else {
                    Text("Welcome to the chat bot")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(20)
                        .frame(maxWidth: 340, maxHeight: 380)
                }
            }
            .navigationTitle("Life Guard Assistant")
        }
        .frame(width: 400, height: 500)
        VStack{
            if isEditing {
                TextField("Type your prompt here...", text: $inputText)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: 350, alignment: .top)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                Button(action: {
                    Task{
                        let response = await chatbot.ChatResponse(prompt: inputText)
                        DispatchQueue.main.async {
                            message = response
                            isSubmit = true
                            startTypingEffect()
                        }
                        isSubmit.toggle()
                    }
                }){
                    Text("Submit").multilineTextAlignment(.center)
                        .frame(minWidth: 0, maxWidth: 350, alignment: .top)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .cornerRadius(20)
                }
            }
            Button(action: {
                if isEditing{
                    print("Submit text")
                }
                isEditing.toggle()
            })
            {
                Text(isEditing ? "Cancel" : "Press here to chat with Life Guard AI assistant")
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: 350, alignment: .top)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    
            }
        }
        Spacer()
    }
}

#Preview {
    ChatBotView()
}
