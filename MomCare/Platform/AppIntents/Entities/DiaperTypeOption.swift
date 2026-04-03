import AppIntents

enum DiaperTypeOption: String, AppEnum {
    case wet
    case dirty
    case both

    nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Diaper Type"

    nonisolated(unsafe) static var caseDisplayRepresentations: [DiaperTypeOption: DisplayRepresentation] = [
        .wet: "Wet",
        .dirty: "Dirty",
        .both: "Wet and dirty"
    ]
}
