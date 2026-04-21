import XCTest
@testable import AsdfghjklCore

final class GridPartitionerTests: XCTestCase {
    func testColumnRangesDistributeEvenlyAcrossScreens() {
        let twoScreens = GridPartitioner.columnRanges(totalColumns: 10, screenCount: 2)
        XCTAssertEqual(twoScreens, [0...4, 5...9])

        let threeScreens = GridPartitioner.columnRanges(totalColumns: 10, screenCount: 3)
        XCTAssertEqual(threeScreens, [0...3, 4...6, 7...9])
    }

    func testSlicesShiftLayoutToColumnRange() {
        let layout = GridLayout()
        let slice = GridSlice(
            screenRect: GridRect(x: 0, y: 0, width: 100, height: 100),
            columnRange: 5...9,
            baseLayout: layout
        )

        XCTAssertEqual(slice.layout.columns, 5)
        XCTAssertEqual(slice.layout.coordinate(for: "y"), GridCoordinate(row: 1, column: 0))
        XCTAssertNil(slice.layout.coordinate(for: "q"))
    }

    func testFiveColumnLayoutsUseFullGridOnEachScreen() {
        let layout = GridLayout(preset: .colemak5)
        let screens = [
            GridRect(x: 0, y: 0, width: 100, height: 100),
            GridRect(x: 100, y: 0, width: 100, height: 100)
        ]

        let slices = GridPartitioner.slices(for: screens, layout: layout)

        XCTAssertTrue(GridPartitioner.prefersFullLayoutPerScreen(for: screens, layout: layout))
        XCTAssertEqual(slices.count, 2)
        XCTAssertEqual(slices[0].layout.columns, 5)
        XCTAssertEqual(slices[1].layout.columns, 5)
        XCTAssertEqual(slices[0].layout.coordinate(for: "o"), GridCoordinate(row: 0, column: 4))
        XCTAssertEqual(slices[1].layout.coordinate(for: "q"), GridCoordinate(row: 1, column: 0))
    }
}
