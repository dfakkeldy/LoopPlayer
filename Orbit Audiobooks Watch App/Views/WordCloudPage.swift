import SwiftUI

// MARK: - Word Cloud Page

struct WordCloudPage: View {
    let viewModel: WatchViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("Current Chapter")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if viewModel.currentWordCloud.isEmpty {
                Text("No word cloud yet.\nTranscribe on your iPhone\nto see top words here.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            } else {
                wordGrid
            }
        }
        .padding(.horizontal, 8)
    }

    private var wordGrid: some View {
        let words = viewModel.currentWordCloud.prefix(10)
        let maxCount = words.first?.count ?? 1

        return VStack(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.element.id) { _, word in
                Text(word.word)
                    .font(.system(size: fontSize(for: word.count, max: maxCount), design: .rounded))
                    .fontWeight(fontWeight(for: word.count, max: maxCount))
                    .foregroundStyle(.primary.opacity(opacity(for: word.count, max: maxCount)))
                    .lineLimit(1)
            }
        }
    }

    private func fontSize(for count: Int, max: Int) -> CGFloat {
        let fraction = CGFloat(count) / CGFloat(max)
        return 8 + fraction * 12  // 8pt → 20pt
    }

    private func fontWeight(for count: Int, max: Int) -> Font.Weight {
        let fraction = CGFloat(count) / CGFloat(max)
        if fraction > 0.7 { return .bold }
        if fraction > 0.4 { return .semibold }
        if fraction > 0.2 { return .medium }
        return .regular
    }

    private func opacity(for count: Int, max: Int) -> Double {
        let fraction = CGFloat(count) / CGFloat(max)
        return 0.4 + Double(fraction) * 0.6
    }
}
