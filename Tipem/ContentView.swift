//
//  ContentView.swift
//  Playground
//
//  Created by Robin Drexler on 2020-05-12.
//  Copyright © 2020 Robin Drexler. All rights reserved.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published var tips = [10, 15, 18, 20, 25, 30]
    @Published var tipPercentage: Double
    @Published var selectedTipPercentage: Int {
        didSet {
            self.tipPercentage = Double(self.selectedTipPercentage)
        }
    }
    
    @Published var price: Double? = nil
    
    init(defaultTip: Int) {
        self.selectedTipPercentage = defaultTip
        self.tipPercentage = Double(defaultTip)
    }
    
}

let CLOSED_KEYBOARD_PADDING = CGFloat(50)
let ARBITRARY_REASONABLE_MAX_NUMBER = Double(9999999);

struct ContentView: View {
    private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        ).eraseToAnyPublisher()
    }
    
    private var numberReadFormatter: NumberFormatter {
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .decimal
        return numFormatter
    }
    
    
    
    private var currencyFormatter: NumberFormatter {
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .decimal
        return numFormatter
    }
    
    func readDecimal(_ amount: String) -> Double? {
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .decimal
        
        return numFormatter.number(from: amount) as! Double?
    }
    
    func formatCurrency(_ amount: Double) -> String? {
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = .currency
        
        return numFormatter.string(from: amount as NSNumber)
    }
    
    
    @ObservedObject var viewModel = ContentViewModel(defaultTip: 18)
    @State var bottomPadding = CLOSED_KEYBOARD_PADDING
    @State var typedPrice = ""
    
    
    var body: some View {
        var price = readDecimal(typedPrice)
        let isPriceValid = price != nil
        price = min(price ?? 0, ARBITRARY_REASONABLE_MAX_NUMBER)
        var totalAmount: Double?
        var tipAmount: Double?
        
        if (isPriceValid) {
            tipAmount = price! / 100 * viewModel.tipPercentage
            totalAmount = price! + tipAmount!
        }
                
        
        return VStack() {
            if (isPriceValid) {
                VStack {
                    AmountDisplay(title: "Tip", amount: formatCurrency(tipAmount!) ?? "")
                        .padding(.top)
                    AmountDisplay(title: "Total", amount: formatCurrency(totalAmount!) ?? "")
                        .padding(.top)
                    
                }.padding(.bottom)
                    .transition(.move(edge: .top))
                    .animation(typedPrice.count == 1 ? .default : nil)
            } else {
                DisplayCanvas {
                    VStack(spacing: 16) {
                        Text("💸 Leave a tip 💸")
                            .bold()
                        Text("👇")
                    }
                }.font(.largeTitle)
                    .padding(.bottom)
                    .transition(.move(edge: .top))
                    .animation(.default)
            }
            Spacer()
            VStack(alignment: .leading) {
                Text("Price")
                    .font(.caption)
                TextField("10.00", text: $typedPrice)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                
            }
            .padding(.bottom)
            HStack {
                Text("\(String(format: "%.0f", viewModel.tipPercentage)) %")
                    .font(.caption)
                Slider(value: $viewModel.tipPercentage, in: 10...30, step: 1) {
                    Text("hallo")
                }
            }
            Picker(selection: $viewModel.selectedTipPercentage, label: EmptyView()) {
                ForEach(viewModel.tips, id: \.self) { percentage in
                    Text("\(percentage) %")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }.onReceive(keyboardHeightPublisher) {height in
            withAnimation {
                self.bottomPadding = height <= CGFloat(0) ? CLOSED_KEYBOARD_PADDING : height + 16
            }
        }
        .padding(.horizontal)
        .padding(.bottom, bottomPadding)
        
    }
    
}

struct AmountDisplay: View {
    let title: String
    let amount: String
    
    var body: some View {
        DisplayCanvas {
            VStack {
                Text(self.title).fontWeight(.light)
                Text(self.amount).bold().font(.title)
            }
            
        }
        
    }
}

struct DisplayCanvas<Content: View>: View {
    
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack() {
            Rectangle()
                .foregroundColor(.blue)
                .cornerRadius(8)
                .shadow(radius: 8)
            content()
        } .foregroundColor(.white)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


