// navigation_event.dart

abstract class NavigationEvent {}

class NavigateToHome extends NavigationEvent {}
class NavigateToBus extends NavigationEvent {}
class NavigateToDriver extends NavigationEvent {}
class NavigateTonotification extends NavigationEvent {}
class NavigateTosettings extends NavigationEvent {}
class NavigateTofeedback extends NavigationEvent {}
class NavigateToreport extends NavigationEvent {}
class NavigateToPerformanceInsights extends NavigationEvent {}
class NavigateToCrowdAnalysis extends NavigationEvent {}
class NavigateToRoutePerformance extends NavigationEvent {}
class NavigateToroute extends NavigationEvent {}
class NavigateTotracking extends NavigationEvent {}
class NavigateTouser extends NavigationEvent {}
class NavigateToaccount extends NavigationEvent {}
class NavigateTocontact extends NavigationEvent {}

class NavigateToDrivers extends NavigationEvent {} // Event for navigating to the Driver page
class NavigateToStudents extends NavigationEvent {} // Event for navigating to the Student page
class NavigateToProfileSettings extends NavigationEvent {}

class NavigateToThemes extends NavigationEvent {}

class NavigateToDownloads extends NavigationEvent {}

class NavigateToAnalytics extends NavigationEvent {}
