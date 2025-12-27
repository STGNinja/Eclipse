//
//  HealthKitManager.swift
//  Eclipse
//
//  Created by Antigravity on 12/23/25.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var stepCount: Double = 0
    @Published var sleepHours: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.healthDataUnavailable
        }
        
        // Data types we want to read
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.activitySummaryType()
        ]
        
        // Data types we (might) want to write/update later, strictly handled if needed
        let shareTypes: Set<HKSampleType> = [] 

        try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
        
        await MainActor.run {
            self.isAuthorized = true
        }
        
        // Initial fetch after auth
        try? await fetchAllData()
    }
    
    private func checkAuthorizationStatus() {
        // HKHealthStore doesn't expose "isAuthorized" for reading directly.
        // We attempt to fetch data immediately. If it succeeds, we know we have access.
        Task {
            do {
                try await fetchAllData()
                await MainActor.run {
                    self.isAuthorized = true
                }
            } catch {
                print("HealthKit init check failed (expected if not authed): \(error)")
                await MainActor.run {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchAllData() async throws {
        async let steps = fetchSteps()
        async let sleep = fetchSleepAnalysis()
        async let hr = fetchHeartRate()
        
        let (sCount, sHours, hRate) = try await (steps, sleep, hr)
        
        await MainActor.run {
            self.stepCount = sCount
            self.sleepHours = sHours
            self.heartRate = hRate
        }
    }
    
    /// Fetches steps for today
    func fetchSteps() async throws -> Double {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0.0
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetches latest heart rate
    func fetchHeartRate() async throws -> Double {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0.0) // No data
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: heartRate)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetches sleep analysis for the last night
    func fetchSleepAnalysis() async throws -> Double {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Look back 24 hours to catch last night's sleep
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 0, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                // Filter for "Asleep" samples (InBed is often just lying down)
                // Note: WatchOS tracks .asleepREM, .asleepCore, .asleepDeep. .asleep is deprecated/generic.
                // We'll calculate simple duration for now. 
                
                var totalSleepSeconds: TimeInterval = 0
                
                for sample in results {
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    if value == .asleep || value == .asleepCore || value == .asleepDeep || value == .asleepREM {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                let hours = totalSleepSeconds / 3600.0
                continuation.resume(returning: hours)
            }
            healthStore.execute(query)
        }
    }
}

enum HealthError: Error {
    case healthDataUnavailable
}
