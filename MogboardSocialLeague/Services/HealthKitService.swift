import Foundation
import HealthKit

@Observable
@MainActor
class HealthKitService {
    static let shared = HealthKitService()

    var isAuthorized = false
    var currentHeartRate: Double = 0
    var sessionHeartRates: [Double] = []

    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?

    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [heartRateType]
        let writeTypes: Set<HKSampleType> = []

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    func startMonitoringHeartRate() {
        guard isAvailable, isAuthorized else { return }
        sessionHeartRates = []
        currentHeartRate = 0

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    func stopMonitoringHeartRate() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    func fetchHeartRateData(from startDate: Date, to endDate: Date) async -> [Double] {
        guard isAvailable, isAuthorized else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let bpmValues = (samples as? [HKQuantitySample])?.map {
                    $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                } ?? []
                continuation.resume(returning: bpmValues)
            }
            self.healthStore.execute(query)
        }
    }

    nonisolated private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }

        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let bpmValues = heartRateSamples.map { $0.quantity.doubleValue(for: bpmUnit) }

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.sessionHeartRates.append(contentsOf: bpmValues)
            if let latest = bpmValues.last {
                self.currentHeartRate = latest
            }
        }
    }

    func generateSimulatedSession(durationSeconds: Int) -> (avg: Double, max: Int, min: Int) {
        let baseHR = Double.random(in: 72...95)
        let maxHR = Int(baseHR + Double.random(in: 30...65))
        let minHR = Int(baseHR - Double.random(in: 5...15))
        let avgHR = Double.random(in: Double(minHR + 10)...Double(maxHR - 10))
        return (avg: avgHR, max: maxHR, min: minHR)
    }
}
