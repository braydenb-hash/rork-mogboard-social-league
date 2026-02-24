import SwiftUI

struct SessionType: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let defaultDuration: Int
    let scoringRule: ScoringRule

    enum ScoringRule {
        case standard
        case endurance
        case maxSpike
        case zoneChaser
    }

    static let all: [SessionType] = [
        SessionType(
            id: "freestyle",
            name: "QUICK GRIND",
            subtitle: "Standard chaos. Points from avg BPM + spike bonus.",
            icon: "bolt.heart.fill",
            color: MogboardTheme.accent,
            defaultDuration: 600,
            scoringRule: .standard
        ),
        SessionType(
            id: "endurance",
            name: "GOON SESH",
            subtitle: "Longer = more deranged. Massive duration multiplier.",
            icon: "figure.run",
            color: .orange,
            defaultDuration: 1800,
            scoringRule: .endurance
        ),
        SessionType(
            id: "max_spike",
            name: "CORTISOL HUNT",
            subtitle: "Chase the peak. Your nervous system is the enemy.",
            icon: "bolt.fill",
            color: .red,
            defaultDuration: 300,
            scoringRule: .maxSpike
        ),
        SessionType(
            id: "zone_chaser",
            name: "THE MEWING ROOM",
            subtitle: "Stay in zone 130–160. Consistency is the only personality trait that matters.",
            icon: "waveform.path.ecg",
            color: .cyan,
            defaultDuration: 900,
            scoringRule: .zoneChaser
        ),
    ]

    func calculatePoints(avgBpm: Double, maxBpm: Int, minBpm: Int, duration: Int) -> Int {
        switch scoringRule {
        case .standard:
            let base = Int(avgBpm * 0.5)
            let spike = maxBpm >= 150 ? 25 : 0
            let mult = max(1, duration / 300)
            return (base + spike) * mult

        case .endurance:
            let base = Int(avgBpm * 0.3)
            let mult = max(1, duration / 180)
            return base * mult

        case .maxSpike:
            let base = Int(avgBpm * 0.3)
            let spikeBonus: Int
            if maxBpm >= 180 { spikeBonus = 100 }
            else if maxBpm >= 170 { spikeBonus = 75 }
            else if maxBpm >= 160 { spikeBonus = 50 }
            else if maxBpm >= 150 { spikeBonus = 25 }
            else { spikeBonus = 0 }
            return base + spikeBonus * 3

        case .zoneChaser:
            let zoneCenter = 145.0
            let deviation = abs(avgBpm - zoneCenter)
            let zoneScore = max(0, Int(100 - deviation * 2))
            let consistency = max(0, 50 - (maxBpm - minBpm))
            let mult = max(1, duration / 300)
            return (zoneScore + consistency) * mult
        }
    }
}
