//
//  ProfileView.swift
//  LoopKitUI
//
//  Created by Jonas Björkert on 2023-04-22.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation
import AVFoundation
import HealthKit
import LoopKit
import SwiftUI

enum ActiveAlert {
    case load, delete, error
}

public struct ProfileView: View {
    @ObservedObject public var viewModel: ProfileViewModel
    @Environment(\.dismissAction) var dismissAction
    @State private var newProfileName: String = ""
    @State private var isAddingNewProfile = false
    @State private var selectedProfileIndex: Int? = nil

    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    private var dismissButton: some View {
        Button(action: dismissAction) {
            Text(LocalizedString("Done", comment: "Text for dismiss button"))
                .bold()
        }
    }

    public var body: some View {
        ZStack {
            NavigationView {
                ConfigurationPageScrollView(
                    content: {
                        VStack(alignment: .leading) {
                            Text("Press '+' to save the current glucose target range, carb ratio, basal rates, and insulin sensitivity settings as a new profile. Tap on a profile to review settings. You can then decide to load or delete the profile.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding([.leading, .trailing])
                                .fixedSize(horizontal: false, vertical: true) // this allows the text to wrap
                                .textCase(nil) // keeps the original text casing

                            if !viewModel.profiles.isEmpty {
                                List {
                                    ForEach(viewModel.profiles.indices, id: \.self) { index in
                                        if let profile = try? viewModel.getProfile(from: viewModel.profiles[index]) {
                                            NavigationLink(destination: ProfilePreviewView(viewModel: viewModel, profile: profile)) {
                                                Text(viewModel.profiles[index].name)
                                            }
                                        }
                                    }
                                }.padding(.top, -15)
                            }
                        }
                    },
                    actionArea: { EmptyView() } // no action area in this case
                )
                .navigationBarItems(
                    leading: Button(action: { withAnimation { isAddingNewProfile = true } }) {
                        Image(systemName: "plus")
                    },
                    trailing: dismissButton
                )
                .navigationTitle(Text(LocalizedString("Profiles", comment: "Title on ProfileView")))
            }
            .navigationBarHidden(false)
            .background(Color(.systemGroupedBackground))

            if isAddingNewProfile {
                DarkenedOverlay()

                NewProfileEditor(
                    isPresented: $isAddingNewProfile,
                    newProfileName: newProfileName,
                    viewModel: viewModel
                )
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.default))
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static let preview_glucoseScheduleItems = [
        RepeatingScheduleValue(startTime: 0, value: DoubleRange(80...90)),
        RepeatingScheduleValue(startTime: 1800, value: DoubleRange(90...100)),
        RepeatingScheduleValue(startTime: 3600, value: DoubleRange(100...110))
    ]

    static let preview_therapySettings = TherapySettings(
        glucoseTargetRangeSchedule: GlucoseRangeSchedule(unit: .milligramsPerDeciliter, dailyItems: preview_glucoseScheduleItems),
        correctionRangeOverrides: CorrectionRangeOverrides(preMeal: DoubleRange(88...99),
                                                           workout: DoubleRange(99...111),
                                                           unit: .milligramsPerDeciliter),
        maximumBolus: 4,
        suspendThreshold: GlucoseThreshold.init(unit: .milligramsPerDeciliter, value: 60),
        insulinSensitivitySchedule: InsulinSensitivitySchedule(unit: HKUnit.milligramsPerDeciliter.unitDivided(by: HKUnit.internationalUnit()), dailyItems: []),
        carbRatioSchedule: nil,
        basalRateSchedule: BasalRateSchedule(dailyItems: [RepeatingScheduleValue(startTime: 0, value: 0.2), RepeatingScheduleValue(startTime: 1800, value: 0.75)]))

    static let preview_supportedBasalRates = [0.2, 0.5, 0.75, 1.0]
    static let preview_supportedBolusVolumes = [1.0, 2.0, 3.0]
    static let preview_supportedMaximumBolusVolumes = [5.0, 10.0, 15.0]

    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel(therapySettings: preview_therapySettings))
    }
}
