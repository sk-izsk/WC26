import SwiftUI

struct StandingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        if let groupStanding = viewModel.currentGroupStanding {
            VStack(alignment: .leading, spacing: 10) {
                tableHeader

                VStack(spacing: 4) {
                    ForEach(groupStanding.standings) { row in
                        standingsRow(row)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        } else {
            VStack {
                Text("No standings available")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 60)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            headerCell("Pos", width: 24, alignment: .center)
            headerCell("Team", alignment: .leading)
            headerCell("P", width: 26, alignment: .center)
            headerCell("W", width: 26, alignment: .center)
            headerCell("D", width: 26, alignment: .center)
            headerCell("L", width: 26, alignment: .center)
            headerCell("GF", width: 26, alignment: .center)
            headerCell("GA", width: 26, alignment: .center)
            headerCell("GD", width: 26, alignment: .center)
            headerCell("Pts", width: 28, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .glassPanel(cornerRadius: 14, opacity: viewModel.cardOpacity * 0.82)
    }

    private func headerCell(_ text: String, width: CGFloat? = nil, alignment: Alignment = .leading) -> some View {
        Group {
            if let width {
                Text(text.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(width: width, alignment: alignment)
            } else {
                Text(text.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    }

    private func standingsRow(_ row: StandingRow) -> some View {
        Button {
            viewModel.showDetails(for: row)
        } label: {
            HStack(spacing: 0) {
                Text("\(row.position)")
                    .frame(width: 24)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    RemoteFlagView(url: row.flagURL, size: 18)
                    Text(row.team)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                numberCell(row.played)
                numberCell(row.won)
                numberCell(row.drawn)
                numberCell(row.lost)
                numberCell(row.goalsFor)
                numberCell(row.goalsAgainst)
                numberCell(row.goalDifference)
                numberCell(row.points, width: 28, bold: true)
            }
            .font(.system(size: 11))
            .foregroundColor(.textPrimary)
            .frame(height: 34)
            .padding(.horizontal, 8)
            .background(rowBackground(for: row.position))
            .glassPanel(cornerRadius: 12, opacity: viewModel.cardOpacity * 0.66)
        }
        .buttonStyle(.plain)
    }

    private func numberCell(_ value: Int, width: CGFloat = 26, bold: Bool = false) -> some View {
        Text("\(value)")
            .font(.system(size: 11, weight: bold ? .bold : .regular))
            .monospacedDigit()
            .frame(width: width)
            .multilineTextAlignment(.center)
    }

    private func rowBackground(for position: Int) -> Color {
        .white.opacity(0.02)
    }
}
