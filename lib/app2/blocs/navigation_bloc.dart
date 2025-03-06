import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:busbuddy/app2/blocs/navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
 
  NavigationBloc() : super(Home1State()) {
    // Define event-to-state mappings
    
    on<NavigateToBusDetails>((event, emit) => emit(BusDetailsState()));
    on<NavigateToHome1>((event, emit) => emit(Home1State()));
    on<NavigateToLocation>((event, emit) => emit(LocationState()));
    on<NavigateToSearch>((event, emit) => emit(SearchState()));
    on<NavigateToNotification>((event, emit) => emit(NotificationState()));
    on<NavigateTosettings>((event, emit) => emit(SettingsState()));
    on<NavigateTofeedback>((event, emit) => emit(FeedbackState()));
    on<NavigateTocontacts>((event, emit) => emit(ContactsState()));
    on<NavigateToaccount>((event, emit) => emit(accountState()));
    on<NavigateTolive>((event, emit) => emit(LiveState()));
    on<NavigateToThemes>((event, emit) => emit(ThemesState()));
  }
}


