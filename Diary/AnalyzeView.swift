//
//  AnalyzeView.swift
//  Diary
//
//  Created by 宋易軒 on 2025/2/12.
//

import SwiftUI

struct AnalyzeView: View {
    @Environment(\.dismiss) var dismiss  //  用於返回

    var body: some View {
        NavigationView {
            VStack {
                Text("AnalyzeView")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
            .navigationTitle("AnalyzeView")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                    }
                }
            }
        }
    }
}
