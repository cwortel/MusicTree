import SwiftUI

/// Displays credits grouped by role
struct CreditListView: View {
    let credits: [Credit]

    private var grouped: [(String, [Credit])] {
        let dict = Dictionary(grouping: credits) { $0.role }
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Credits")
                .font(.headline)
                .padding(.horizontal)

            ForEach(grouped, id: \.0) { role, people in
                VStack(alignment: .leading, spacing: 4) {
                    Text(role)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    ForEach(people) { person in
                        HStack {
                            Text(person.name)
                                .font(.body)
                            if let tracks = person.tracks, !tracks.isEmpty {
                                Text("(\(tracks))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
