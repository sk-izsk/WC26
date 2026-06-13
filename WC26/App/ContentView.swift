//
//  ContentView.swift
//  WC26
//
//  Created by Shaikh Zeeshan Murshed on 2026-06-12.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderView()

                TabBarView()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        if viewModel.activeTab == .fixtures {
                            DateStripView()

                            if viewModel.isLoading && viewModel.matches.isEmpty {
                                LoadingSkeletonView()
                            } else if let errorMessage = viewModel.errorMessage, viewModel.matches.isEmpty {
                                ErrorStateView(message: errorMessage) {
                                    viewModel.refresh()
                                }
                            } else {
                                MatchListView()
                            }
                        } else {
                            GroupSelectorView()

                            if viewModel.isLoading && viewModel.standings.isEmpty {
                                LoadingSkeletonView()
                            } else if let errorMessage = viewModel.errorMessage, viewModel.standings.isEmpty {
                                ErrorStateView(message: errorMessage) {
                                    viewModel.refresh()
                                }
                            } else {
                                StandingsView()
                            }
                        }
                    }
                }
            }
            if let sheet = viewModel.activeSheet {
                Button(action: viewModel.dismissActiveSheet) {
                    Color.black.opacity(0.32)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)

                modalView(for: sheet)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(1)
            }
        }
        .frame(width: 380, height: 600)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                LinearGradient(
                    colors: [
                        Color.black.opacity(viewModel.panelOpacity + 0.08),
                        Color.liquidGlow.opacity(0.18),
                        Color.black.opacity(viewModel.panelOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [
                        Color.liquidHighlight.opacity(0.20),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 12,
                    endRadius: 240
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.glassStroke.opacity(0.9), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [Color.white.opacity(0.24), Color.white.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            InAppNotificationBannerHost()
                .environmentObject(viewModel)
                .zIndex(2)
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.activeSheet?.id)
    }

    @ViewBuilder
    private func modalView(for sheet: AppViewModel.ActiveSheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView()
                .environmentObject(viewModel)
        case .match:
            if let match = viewModel.selectedMatch {
                MatchDetailView(match: match)
                    .environmentObject(viewModel)
            }
        case .team:
            if let teamDetail = viewModel.selectedTeamDetail {
                TeamDetailView(teamDetail: teamDetail)
                    .environmentObject(viewModel)
            }
        }
    }
}
