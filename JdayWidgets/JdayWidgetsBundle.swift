import WidgetKit
import SwiftUI

@main
struct JdayWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayProgressWidget()
        TodayTasksWidget()
        MonthCalendarWidget()
        TodayBriefWidget()
    }
}
