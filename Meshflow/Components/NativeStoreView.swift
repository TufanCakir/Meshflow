import StoreKit
import SwiftUI

/// A reusable StoreKit storefront for subscriptions and one-time purchases.
struct NativeStoreView: View {
    enum Section: Hashable {
        case subscriptions
        case oneTimePurchases
    }

    struct Copy {
        let sectionLabel: String
        let subscriptions: String
        let oneTimePurchases: String
        let loading: String
        let unavailableTitle: String
        let unavailableDescription: String
        let retry: String
        let footer: String
    }

    let subscriptionGroupID: String
    let oneTimeProducts: [Product]
    let isLoading: Bool
    let hasLoadedProducts: Bool
    let statusMessage: String
    let copy: Copy
    let reload: () async -> Void

    @State private var selectedSection: Section = .subscriptions

    var body: some View {
        VStack(spacing: 12) {
            Picker(copy.sectionLabel, selection: $selectedSection) {
                Text(copy.subscriptions).tag(Section.subscriptions)
                Text(copy.oneTimePurchases).tag(Section.oneTimePurchases)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch selectedSection {
            case .subscriptions:
                subscriptionStore
            case .oneTimePurchases:
                oneTimePurchaseStore
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    private var subscriptionStore: some View {
        SubscriptionStoreView(groupID: subscriptionGroupID)
            .subscriptionStoreControlStyle(.compactPicker)
            .storeButton(.visible, for: .restorePurchases)
    }

    private var oneTimePurchaseStore: some View {
        ScrollView {
            Group {
                if isLoading || !hasLoadedProducts {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(copy.loading)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 96)
                } else if oneTimeProducts.isEmpty {
                    ContentUnavailableView {
                        Label(copy.unavailableTitle, systemImage: "cart.badge.questionmark")
                    } description: {
                        Text(copy.unavailableDescription)
                    } actions: {
                        Button(copy.retry) {
                            Task {
                                await reload()
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        StoreView(
                            products: oneTimeProducts,
                            prefersPromotionalIcon: true
                        )
                        .productViewStyle(.compact)
                        .productDescription(.visible)
                        .storeButton(.visible, for: .restorePurchases)

                        Text(copy.footer)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
