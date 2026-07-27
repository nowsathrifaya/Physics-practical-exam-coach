//
//  GatedContentView.swift
//  PhysicsPracticalCoach
//
//  Shown in place of any gated screen — Virtual Labs, Study Notes
//  categories, Graph Coach, ACE Practice, Answering Techniques. Presents
//  the paywall on tap rather than being a dead end.
//

import SwiftUI

struct GatedContentView: View {
    let context: String
    @State private var showingPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(context)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("This is part of Full Access \u{2014} a one-time unlock, no subscription.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("See Full Access") { showingPaywall = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: context)
        }
    }
}
