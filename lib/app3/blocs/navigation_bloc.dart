import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(HomeState()) {
    // Map navigation events to their respective states
    on<NavigateToHome>((event, emit) => emit(HomeState()));
    on<NavigateToaccount>((event, emit) => emit(accountState()));
    on<NavigateTocontacts>((event, emit) => emit(contactsState()));
    on<NavigateTofeedback>((event, emit) => emit(feedbackState()));
    on<NavigateTonotification>((event, emit) => emit(notificationState()));
    on<NavigateTopassenger>((event, emit) => emit(passengerState()));
    on<NavigateToscanner>((event, emit) => emit(scannerState()));
    on<NavigateTosetting>((event, emit) => emit(settingState()));
    on<NavigateToThemes>((event, emit) => emit(ThemesState()));
  }
}