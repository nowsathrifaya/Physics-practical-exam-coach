//
//  PaywallView.swift
//  PhysicsPracticalCoach
//
//  Shown wherever a gated feature is tapped — contextual, not a cold
//  generic upsell screen the student has to hunt for.
//

import SwiftUI

struct PaywallView: View {
    /// What the student was trying to do when this paywall appeared —
    /// shown as the headline, so the pitch feels like a direct answer to
    /// what they just tapped rather than a generic ad.
    var context: String = "Unlock everything"
    @Environment(\.dismiss) private var dismiss
    @State private var purchases = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                        Text(context)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text("One-time purchase. No subscription, no ads, ever.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 14) {
                        benefitRow(icon: "flask.fill", text: "Unlimited attempts on every Virtual Lab experiment")
                        benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Full Graph Coach, Apparatus Trainer, and ACE Practice")
                        benefitRow(icon: "book.fill", text: "Every Study Notes category and Answering Technique")
                        benefitRow(icon: "checkmark.seal.fill", text: "All future updates included \u{2014} no extra cost")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    purchaseSection

                    if let errorMessage = purchases.lastErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .font(.footnote)
                    .disabled(purchases.purchaseInProgress)

                    Text("Payment will be charged to your Apple ID account. This is a one-time purchase with no recurring charge.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .onChange(of: purchases.isPro) { _, isPro in
                if isPro { dismiss() }
            }
            .task {
                if purchases.product == nil {
                    await purchases.loadProduct()
                }
            }
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text).font(.subheadline)
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if purchases.isLoadingProduct {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 14)
        } else if let product = purchases.product {
            Button {
                Task { await purchases.purchase() }
            } label: {
                HStack {
                    if purchases.purchaseInProgress {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock for \(product.displayPrice)")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchases.purchaseInProgress)
        } else {
            Text("Pricing unavailable right now \u{2014} check your connection and try again.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
