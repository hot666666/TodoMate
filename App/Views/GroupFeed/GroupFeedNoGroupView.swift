//
//  GroupFeedNoGroupView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct GroupFeedNoGroupView: View {
  var body: some View {
    ScrollView {
      VStack {
        VStack(spacing: 32) {
          JoinGroupCard()
          CreateGroupCard()
        } // Inner VStack
        .padding(.top, 32)
        .padding(32)
        .frame(maxWidth: 600) // Reduced width
        .frame(maxWidth: .infinity)
        Spacer()
      }
      .frame(minHeight: 600) // Minimum height effectively to allow scrolling if needed, but centering otherwise
      .containerRelativeFrame(.vertical)
    } // ScrollView
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
    .accessibilityIdentifier("GroupFeedNoGroupView")
  }
}

// MARK: - Subviews

private struct JoinGroupCard: View {
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "person.badge.plus") // material: group_add
        .font(.system(size: 60)) // text-6xl
        .foregroundStyle(Color.blue)

      Text("Join a Group with an Invitation Code")
        .font(.title2) // text-2xl
        .fontWeight(.semibold)
        .foregroundStyle(Color(nsColor: .labelColor))

      Text(
        "Have an invitation code from your team or friends? Enter it below to join their group and start collaborating instantly.",
      )
      .font(.body)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .frame(maxWidth: 450)

      HStack(spacing: 12) {
        TextField("Enter invitation code", text: .constant(""))
          .textFieldStyle(.plain)
          .padding(10)
          .background(Color.white.opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.secondary.opacity(0.2), lineWidth: 1),
          )

        Button {
          // Join action
        } label: {
          Text("Join")
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
        }
        .buttonStyle(.card(padding: .init(top: 10, leading: 20, bottom: 10, trailing: 20)))
      }
      .frame(maxWidth: 400)
    }
    .padding(32)
    .frame(maxWidth: .infinity) // Match width behavior
    .cardContainer(cornerRadius: 16)
  }
}

private struct CreateGroupCard: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "person.2.circle.fill") // material: group
        .font(.system(size: 48)) // text-5xl
        .foregroundStyle(Color.green) // emerald -> green

      Text("Create Your Own Group")
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(Color(nsColor: .labelColor))

      Text("Start a new group for your project, team, or friends. It's quick and easy!")
        .font(.footnote) // text-sm
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button {
        // Create group action
      } label: {
        Text("Create Group")
          .fontWeight(.medium)
          .foregroundStyle(.green)
      }
      .buttonStyle(.card(padding: .init(top: 8, leading: 16, bottom: 8, trailing: 16)))
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .cardContainer(cornerRadius: 12)
  }
}

#Preview {
  GroupFeedNoGroupView()
    .frame(width: 1000, height: 800)
}
