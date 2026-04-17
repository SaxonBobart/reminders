//
//  RemindersTests.swift
//  RemindersTests
//
//  Created by Saxon Bobart on 17/4/2026.
//

import Testing
import Foundation
@testable import Reminders

struct ReminderTests {

    @Test func createsWithDefaults() {
        let r = Reminder(title: "Buy milk")
        #expect(r.title == "Buy milk")
        #expect(r.isCompleted == false)
    }

    @Test func createsCompleted() {
        let r = Reminder(title: "Done already", isCompleted: true)
        #expect(r.isCompleted)
    }

    @Test func togglesCompletion() {
        var r = Reminder(title: "Walk dog")
        #expect(r.isCompleted == false)
        r.isCompleted.toggle()
        #expect(r.isCompleted)
        r.isCompleted.toggle()
        #expect(r.isCompleted == false)
    }

    @Test func generatesUniqueIDs() {
        let a = Reminder(title: "A")
        let b = Reminder(title: "A")
        #expect(a.id != b.id)
    }
}
