import UIKit

/// Centralized haptic feedback service for all user interactions
/// Every user action should trigger appropriate haptic feedback
final class HapticService {
    static let shared = HapticService()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        prepareAll()
    }

    /// Prepare all generators for immediate response
    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Button Taps

    /// Light tap feedback for standard button presses
    func lightTap() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium tap feedback for important actions
    func mediumTap() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Heavy tap feedback for significant actions (placing buildings, confirming)
    func heavyTap() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    /// Soft tap for subtle interactions
    func softTap() {
        softImpact.impactOccurred()
        softImpact.prepare()
    }

    /// Rigid tap for precise interactions
    func rigidTap() {
        rigidImpact.impactOccurred()
        rigidImpact.prepare()
    }

    // MARK: - Selection Changes

    /// Selection changed feedback (scrolling through options, tab switches)
    func selectionChanged() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    // MARK: - Notifications

    /// Success feedback (item saved, building placed, review completed)
    func success() {
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    /// Warning feedback (streak at risk, items overdue)
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }

    /// Error feedback (action failed, invalid input)
    func error() {
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }

    // MARK: - Composite Patterns

    /// Building placed pattern - satisfying sequence
    func buildingPlaced() {
        heavyImpact.impactOccurred(intensity: 0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumImpact.impactOccurred(intensity: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
            self?.prepareAll()
        }
    }

    /// Knowledge captured pattern - quick confirming tap
    func knowledgeCaptured() {
        mediumImpact.impactOccurred(intensity: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.lightImpact.impactOccurred(intensity: 0.5)
            self?.prepareAll()
        }
    }

    /// Review correct ("Got it") pattern - satisfying confirmation
    func reviewCorrect() {
        mediumImpact.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
            self?.prepareAll()
        }
    }

    /// Review incorrect ("Forgot") pattern - gentle acknowledgment, not punishing
    func reviewIncorrect() {
        softImpact.impactOccurred(intensity: 0.5)
        softImpact.prepare()
    }

    /// Swipe navigation pattern
    func swipe() {
        lightImpact.impactOccurred(intensity: 0.4)
        lightImpact.prepare()
    }

    /// Card flip/reveal pattern
    func cardFlip() {
        rigidImpact.impactOccurred(intensity: 0.5)
        rigidImpact.prepare()
    }

    /// Streak milestone achieved pattern - celebration sequence
    func streakMilestone() {
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumImpact.impactOccurred(intensity: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.mediumImpact.impactOccurred(intensity: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
            self?.prepareAll()
        }
    }

    /// Era unlocked pattern - major achievement celebration
    func eraUnlocked() {
        heavyImpact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.heavyImpact.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.heavyImpact.impactOccurred(intensity: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.mediumImpact.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
            self?.prepareAll()
        }
    }

    /// Walk completed pattern - session end celebration
    func walkCompleted() {
        mediumImpact.impactOccurred(intensity: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.mediumImpact.impactOccurred(intensity: 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
            self?.prepareAll()
        }
    }

    /// Drag start pattern
    func dragStart() {
        lightImpact.impactOccurred(intensity: 0.6)
        lightImpact.prepare()
    }

    /// Drag over valid target pattern
    func dragOverValid() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    /// Drop completed pattern
    func dropCompleted() {
        mediumImpact.impactOccurred(intensity: 0.7)
        mediumImpact.prepare()
    }

    /// Tab switch pattern
    func tabSwitch() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    /// Modal presented pattern
    func modalPresented() {
        lightImpact.impactOccurred(intensity: 0.5)
        lightImpact.prepare()
    }

    /// Modal dismissed pattern
    func modalDismissed() {
        softImpact.impactOccurred(intensity: 0.4)
        softImpact.prepare()
    }

    /// Delete action pattern
    func deleteAction() {
        rigidImpact.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.warning)
            self?.prepareAll()
        }
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Add haptic feedback to any tap gesture
    func hapticTap(_ style: HapticStyle = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            style.trigger()
            action()
        }
    }
}

enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error

    func trigger() {
        switch self {
        case .light: HapticService.shared.lightTap()
        case .medium: HapticService.shared.mediumTap()
        case .heavy: HapticService.shared.heavyTap()
        case .soft: HapticService.shared.softTap()
        case .rigid: HapticService.shared.rigidTap()
        case .selection: HapticService.shared.selectionChanged()
        case .success: HapticService.shared.success()
        case .warning: HapticService.shared.warning()
        case .error: HapticService.shared.error()
        }
    }
}
