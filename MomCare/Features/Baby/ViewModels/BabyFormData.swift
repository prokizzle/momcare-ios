import Foundation

struct BabyFormData: Sendable {
    var name: String
    var dateOfBirth: Date
    var biologicalSex: Baby.BiologicalSex?
    var feedingMethod: Baby.FeedingMethod
    var birthWeight: Double?
    var birthLength: Double?
    var birthHeadCircumference: Double?
    var photoData: Data?
}
