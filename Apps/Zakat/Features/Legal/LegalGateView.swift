import SwiftUI

struct LegalGateView: View {
    @Environment(AppSession.self) private var session
    @State private var accepted = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Before you begin")
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                            .foregroundStyle(Palette.forest)
                        Text("Read and accept the terms to continue.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }

                    VStack(spacing: 10) {
                        ForEach(LegalDocument.allCases) { document in
                            NavigationLink {
                                LegalDocumentView(document: document)
                            } label: {
                                ProfileRow(title: document.title, systemImage: "doc.text")
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Toggle(isOn: $accepted) {
                        Text("I am 18+ and I accept the terms.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.ink)
                    }
                    .tint(Palette.moss)
                    .padding(.top, 8)

                    PrimaryButton(title: "Continue", enabled: accepted) {
                        session.acceptLegal()
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                Text(document.body)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LegalIndexView: View {
    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(LegalDocument.allCases) { document in
                        NavigationLink {
                            LegalDocumentView(document: document)
                        } label: {
                            ProfileRow(title: document.title, systemImage: "doc.text")
                        }
                        .buttonStyle(.plain)
                    }
                    Text("You can reopen these anytime.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .navigationTitle("Legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
