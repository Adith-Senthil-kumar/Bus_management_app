// navigation_state.dart

abstract class NavigationState {}

class HomeState extends NavigationState {}
class BusState extends NavigationState {}
class DriverState extends NavigationState {}
class NotificationState extends NavigationState {}
class SettingsState extends NavigationState {}
class FeedbackState extends NavigationState {}
class ReportState extends NavigationState {}
class PerformanceInsightsState extends NavigationState {}
class CrowdAnalysisState extends NavigationState {}
class RoutePerformanceState extends NavigationState {}
class RouteState extends NavigationState {}
class TrackingState extends NavigationState {}
class UserState extends NavigationState {}
class AccountState extends NavigationState {}
class ContactState extends NavigationState {}

class DriverPageState extends NavigationState {} // State for Driver Page
class StudentPageState extends NavigationState {} // State for Student Page
class ProfileSettingsState extends NavigationState {}

class ThemesState extends NavigationState {}

class DownloadsState extends NavigationState {}

class AnalyticsState extends NavigationState {}
