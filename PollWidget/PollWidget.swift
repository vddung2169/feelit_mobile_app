import WidgetKit
import SwiftUI

// MARK: - Timeline
struct PollEntry: TimelineEntry {
    let date: Date
    let card: WidgetCard
}

struct PollProvider: TimelineProvider {
    private let cards = WidgetSampleData.cards

    func placeholder(in context: Context) -> PollEntry {
        PollEntry(date: Date(), card: cards[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (PollEntry) -> Void) {
        completion(PollEntry(date: Date(), card: cards[0]))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PollEntry>) -> Void) {
        // Xoay vòng qua 6 card, mỗi card hiện 30 phút.
        var entries: [PollEntry] = []
        let now = Date()
        for i in 0..<cards.count {
            let date = Calendar.current.date(byAdding: .minute, value: i * 30, to: now)!
            entries.append(PollEntry(date: date, card: cards[i]))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Card view
struct PollWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PollEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: entry.card.gradientColors,
                startPoint: .topLeading, endPoint: .bottom
            )
            // overlay tối ở đáy cho dễ đọc chữ
            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.7)],
                startPoint: .center, endPoint: .bottom
            )
            content
                .padding(family == .systemSmall ? 12 : 16)
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemSmall: smallLayout
        case .systemLarge: largeLayout
        default:           mediumLayout
        }
    }

    // MARK: Small
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                badge
                Spacer()
                if let h = entry.card.headline {
                    Text(h.value)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Color(hex: h.colorHex))
                }
            }
            Spacer(minLength: 6)
            Text(entry.card.question)
                .font(.system(size: 14, weight: .heavy))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 6)
            if let first = entry.card.options.first {
                miniBar(first)
            }
        }
    }

    // MARK: Medium
    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                badge
                Spacer()
                headlineBox
            }
            Spacer(minLength: 2)
            authorRow
            Text(entry.card.question)
                .font(.system(size: 17, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if entry.card.layout == .binary {
                HStack(spacing: 8) {
                    ForEach(Array(entry.card.options.prefix(2).enumerated()), id: \.offset) { _, o in
                        binaryPill(o)
                    }
                }
            } else if let lead = entry.card.options.first(where: { $0.highlighted }) ?? entry.card.options.first {
                optionRow(lead)
            }
        }
    }

    // MARK: Large
    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                badge
                Spacer()
                headlineBox
            }
            Spacer(minLength: 4)
            authorRow
            Text(entry.card.question)
                .font(.system(size: 22, weight: .heavy))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            if entry.card.layout == .binary {
                HStack(spacing: 10) {
                    ForEach(Array(entry.card.options.enumerated()), id: \.offset) { _, o in
                        binaryPill(o)
                    }
                }
            } else {
                VStack(spacing: 7) {
                    ForEach(Array(entry.card.options.enumerated()), id: \.offset) { _, o in
                        optionRow(o)
                    }
                }
            }
            Text(entry.card.footer)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Pieces
    private var badge: some View {
        Text(entry.card.badge)
            .font(.system(size: 9, weight: .heavy))
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Color(hex: entry.card.badgeHex), in: Capsule())
    }

    @ViewBuilder private var headlineBox: some View {
        if let h = entry.card.headline {
            VStack(alignment: .trailing, spacing: 1) {
                Text(h.value)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color(hex: h.colorHex))
                Text(h.label)
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var authorRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: 20, height: 20)
                .background(.white, in: RoundedRectangle(cornerRadius: 6))
            Text(entry.card.author)
                .font(.system(size: 12, weight: .heavy))
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#4ADE80"))
            Spacer()
            Text(entry.card.closing)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    // thanh option dạng binary (title trên, % dưới), có fill theo %
    private func binaryPill(_ o: WidgetOption) -> some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                o.tint.frame(width: geo.size.width * CGFloat(o.percent) / 100)
            }
            VStack(spacing: 1) {
                Text(o.title).font(.system(size: 14, weight: .heavy))
                Text(o.detail ?? "\(o.percent)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 44)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(o.highlighted ? 0.5 : 0), lineWidth: 1.5)
        )
    }

    // option dạng multiple (title trái, % phải), có fill theo %
    private func optionRow(_ o: WidgetOption) -> some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                o.tint.frame(width: geo.size.width * CGFloat(o.percent) / 100)
            }
            HStack {
                Text(o.title).font(.system(size: 13, weight: .bold))
                Spacer()
                Text(o.detail ?? "\(o.percent)%")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(o.highlighted ? Color(hex: "#FFD66B") : .white.opacity(0.78))
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 38)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(o.highlighted ? 0.5 : 0), lineWidth: 1.5)
        )
    }

    private func miniBar(_ o: WidgetOption) -> some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                o.tint.frame(width: geo.size.width * CGFloat(o.percent) / 100)
            }
            HStack {
                Text(o.title).font(.system(size: 12, weight: .heavy))
                Spacer()
                Text("\(o.percent)%").font(.system(size: 12, weight: .heavy))
            }
            .padding(.horizontal, 11)
        }
        .frame(height: 32)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
}

// MARK: - Widget
struct PollWidget: Widget {
    let kind = "PollWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PollProvider()) { entry in
            PollWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("Flash Poll")
        .description("Các poll thị trường mới nhất, vuốt lên xem trong app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct PollWidgetBundle: WidgetBundle {
    var body: some Widget {
        PollWidget()
    }
}
