import SwiftUI

struct ContentView: View {
    @State private var viewModel = RequestViewModel()
    var body: some View {
        VStack {
            Text("Testing requests")
               .font(.largeTitle)
               .bold()
            
            Spacer()
            
            Picker("Request type", selection: $viewModel.selectedType) {
                ForEach(RequestType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            
            Button("Make request") {
                Task {
                    await viewModel.sendRequest()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            
            Spacer()
            
            ScrollView {
                       if viewModel.isLoading {
                           ProgressView()
                       } else if viewModel.responseText.isEmpty {
                           Text("Здесь будет ответ сервера")
                               .foregroundStyle(.secondary)
                       } else {
                           Text(viewModel.responseText)
                               .font(.system(.body, design: .monospaced))
                       }
                   }
        }
        .padding()
    }
}
