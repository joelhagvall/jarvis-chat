import SwiftUI

struct SessionRow: View {
    let session: ChatSession
    let isSelected: Bool
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var isHovering = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(session.updatedAt) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(session.updatedAt) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: session.updatedAt)
    }

    var body: some View {
        HStack(spacing: JarvisTheme.Spacing.sm) {
            Circle()
                .fill(isSelected ? JarvisTheme.Colors.blue : JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.medium))
                .frame(width: 6, height: 6)
                .shadow(color: isSelected ? JarvisTheme.Colors.blue : .clear, radius: 4)

            if isEditing {
                TextField("", text: $editedTitle, onCommit: {
                    if !editedTitle.isEmpty {
                        onRename(editedTitle)
                    }
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .font(JarvisTheme.Typography.mono(12))
                .foregroundStyle(JarvisTheme.Colors.blue)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(JarvisTheme.Typography.mono(12))
                        .foregroundStyle(isSelected ? JarvisTheme.Colors.blue : Color.white.opacity(JarvisTheme.Opacity.solid))
                        .lineLimit(1)

                    Text(formattedDate)
                        .font(JarvisTheme.Typography.mono(9))
                        .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.medium))
                }
            }

            Spacer()

            if isHovering && !isEditing {
                HStack(spacing: 4) {
                    Button(action: {
                        editedTitle = session.title
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(JarvisTheme.Colors.blue.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, JarvisTheme.Spacing.md)
        .padding(.vertical, JarvisTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.small)
                .fill(isSelected ? JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.subtle) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.small)
                .stroke(isSelected ? JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.medium) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
