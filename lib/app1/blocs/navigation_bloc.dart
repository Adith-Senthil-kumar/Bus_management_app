import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(HomeState()) {
    // Define event-to-state mappings
    on<NavigateToHome>((event, emit) => emit(HomeState()));

    on<NavigateToBus>((event, emit) => emit(BusState()));

    on<NavigateToDriver>((event, emit) => emit(DriverState()));

    on<NavigateTonotification>((event, emit) => emit(NotificationState()));

    on<NavigateTosettings>((event, emit) => emit(SettingsState()));

    on<NavigateTofeedback>((event, emit) => emit(FeedbackState()));

    on<NavigateToreport>((event, emit) => emit(ReportState()));

    on<NavigateToPerformanceInsights>((event, emit) => emit(PerformanceInsightsState()));

    on<NavigateToCrowdAnalysis>((event, emit) => emit(CrowdAnalysisState()));

    on<NavigateToRoutePerformance>((event, emit) => emit(RoutePerformanceState()));

    on<NavigateToroute>((event, emit) => emit(RouteState()));

    on<NavigateTotracking>((event, emit) => emit(TrackingState()));

    on<NavigateTouser>((event, emit) => emit(UserState()));

    on<NavigateToaccount>((event, emit) => emit(AccountState()));
    on<NavigateTocontact>((event, emit) => emit(ContactState()));

    // Assuming DriverPageState and StudentPageState are already defined
    on<NavigateToDrivers>((event, emit) => emit(DriverPageState())); // Added state for drivers
    on<NavigateToStudents>((event, emit) => emit(StudentPageState())); // Added state for students
    on<NavigateToProfileSettings>((event, emit) => emit(ProfileSettingsState()));
    on<NavigateToThemes>((event, emit) => emit(ThemesState()));
    on<NavigateToDownloads>((event, emit) => emit(DownloadsState()));
    on<NavigateToAnalytics>((event, emit) => emit(AnalyticsState()));
  }
}