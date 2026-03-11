import Foundation

struct DevelopmentStrategy: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let philosophy: String
    let principles: [String]  // 3 bullets

    static let all: [DevelopmentStrategy] = [
        DevelopmentStrategy(
            id: "babywise",
            name: "Babywise",
            philosophy: "Parent-directed feeding on a flexible schedule to help babies sleep through the night.",
            principles: [
                "Feed on a 2.5-3hr schedule, not on demand",
                "Eat-Wake-Sleep cycle structures the day",
                "Consistent schedule builds predictability"
            ]
        ),
        DevelopmentStrategy(
            id: "ferber",
            name: "Ferber Method",
            philosophy: "Graduated extinction approach helping babies learn to self-soothe at sleep time.",
            principles: [
                "Put baby down drowsy but awake",
                "Check in at increasing intervals if crying",
                "Consistency over 3-7 nights establishes the habit"
            ]
        ),
        DevelopmentStrategy(
            id: "wonder-weeks",
            name: "Wonder Weeks",
            philosophy: "Baby development follows predictable mental leaps with fussy periods and breakthroughs.",
            principles: [
                "Ten developmental leaps in the first 20 months",
                "Fussy periods signal upcoming cognitive jumps",
                "Each leap brings new perceptual abilities"
            ]
        ),
        DevelopmentStrategy(
            id: "attachment",
            name: "Attachment Parenting",
            philosophy: "Building a strong parent-child bond through proximity, responsiveness, and connection.",
            principles: [
                "Respond promptly to baby's cries",
                "Babywearing and co-sleeping (safely) encouraged",
                "Breastfeeding on demand as long as mutually desired"
            ]
        ),
        DevelopmentStrategy(
            id: "montessori",
            name: "Montessori",
            philosophy: "Child-led learning in a prepared environment that respects the child's natural development.",
            principles: [
                "Floor bed and low furniture promote independence",
                "Simple, natural toys support open-ended play",
                "Observe before intervening - trust the child's process"
            ]
        )
    ]
}
