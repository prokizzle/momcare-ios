import Testing
import Foundation
@testable import MomCare

@Suite("SelfCareGridItem Tests")
struct SelfCareGridItemTests {

    @Test("defaultGrid returns all 9 action types")
    func defaultGridCount() {
        let grid = SelfCareGridItem.defaultGrid()
        #expect(grid.count == 9)
    }

    @Test("defaultGrid items are in expected order")
    func defaultGridOrder() {
        let grid = SelfCareGridItem.defaultGrid()
        #expect(grid[0].actionType == .water)
        #expect(grid[1].actionType == .meal)
        #expect(grid[2].actionType == .brushTeeth)
    }

    @Test("defaultGrid items are all visible and not custom")
    func defaultGridDefaults() {
        let grid = SelfCareGridItem.defaultGrid()
        for item in grid {
            #expect(item.isVisible == true)
            #expect(item.isCustom == false)
            #expect(item.customName == nil)
            #expect(item.customIcon == nil)
        }
    }

    @Test("sortOrder is sequential starting from 0")
    func defaultGridSortOrder() {
        let grid = SelfCareGridItem.defaultGrid()
        for (index, item) in grid.enumerated() {
            #expect(item.sortOrder == index)
        }
    }

    @Test("fixture creates valid default")
    func fixtureDefault() {
        let item = SelfCareGridItem.fixture()
        #expect(item.isVisible == true)
        #expect(item.isCustom == false)
    }
}
