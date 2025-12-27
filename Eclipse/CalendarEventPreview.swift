
import SwiftUI

struct CalendarEventPreview: View {
    let event: CalendarEventData
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Icon
            VStack(spacing: 0) {
                Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.8))
                
                Text(event.date.formatted(.dateTime.day()))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.9))
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Event Details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(event.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Status Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.green)
                .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black
        CalendarEventPreview(event: CalendarEventData(title: "Meeting with Team", date: Date(), duration: 3600, notes: nil))
            .padding()
    }
}
