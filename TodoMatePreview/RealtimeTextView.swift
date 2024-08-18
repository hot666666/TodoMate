import SwiftUI

struct TextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.never)
            .cornerRadius(5)
            .frame(minHeight: 25)
            .fixedSize(horizontal: false, vertical: true)
            .background(.ultraThinMaterial)
    }
}

extension View {
    func textEditorStyle() -> some View {
        self.modifier(TextEditorStyle())
    }
}

// MARK: - Models

@Observable
class TextItem: Identifiable {
    let id: String = UUID().uuidString
    var content: String
    
    init(content: String = "") {
        self.content = content
    }
}

// MARK: - Views
struct RealtimeTextView: View {
    var item: TextItem
    @FocusState.Binding var focusedId: String?
    
    
    var body: some View {
        TextEditor(text: Bindable(item).content)
            .textEditorStyle()
            .focused($focusedId, equals: item.id)
            .shadow(radius: focusedId == item.id ? 5 : 0)
            .onTapGesture { focusedId = item.id }
    }
}

struct ContentView: View {
    @State private var items: [TextItem] = []
    @FocusState private var focusedId: String?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { clearFocus() }
                        .border(Color.yellow)
                    
                    VStack(spacing: 10) {
                        ForEach(items) { item in
                            RealtimeTextView(item: item, focusedId: $focusedId)
                                .frame(width: 150)
                        }
                        
                        AddItemButton(action: addNewItem)
                    }
                }
            }
            .background(Color.white.opacity(0.2))
        }
    }
}
 
extension ContentView {
    private func clearFocus() {
        print("Touched Outside")
        focusedId = nil
    }
    
    private func addNewItem() {
        let newItem = TextItem()
        items.append(newItem)
        focusedId = newItem.id
    }
}

struct AddItemButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.app.fill")
        }
        .border(Color.yellow)
    }
}


// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 300, height: 300)
}
