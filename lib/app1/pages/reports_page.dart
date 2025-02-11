import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:busbuddy/app1/blocs/navigation_state.dart';

import 'report_pages/key_metrics_report.dart';
import 'report_pages/performance_insights_report.dart';
import 'report_pages/route_performance_report.dart';

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<NavigationBloc>().add(NavigateToHome());
        Navigator.pop(context); // Close the page when the back button is pressed
        return Future.value(false); // Prevent the default back navigation behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Set the Scaffold background to white
        appBar: AppBar(
          centerTitle: true, // Center the title
          title: Text(
            'Reports',
            style: TextStyle(color: Colors.white), // Ensure title is white
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF3764A7),
                  Color(0xFF28497B),
                  Color(0xFF152741),
                ],
                stops: [0.36, 0.69, 1.0],
              ),
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              context.read<NavigationBloc>().add(NavigateToHome());
              Navigator.pop(context);
            },
          ),
        ),
        body: Row(
          children: [
            // NavigationRail with white background
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Set the background color of the NavigationRail to white
                border: Border(
                  right: BorderSide(
                    color: const Color.fromARGB(255, 147, 147, 147), // Outline color
                    width: 1.0, // Outline width
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Explicitly set NavigationRail's background to white
                selectedIndex: _getSelectedIndexFromState(context),
                onDestinationSelected: (index) {
                  context.read<NavigationBloc>().add(_mapIndexToEvent(index));
                },
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.article, color: Colors.black),
                    label: Text(
                      'Metrics',
                      style: TextStyle(color: Colors.black), // Label color black
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.access_time, color: Colors.black),
                    label: Text(
                      'Insights',
                      style: TextStyle(color: Colors.black), // Label color black
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.directions_bus, color: Colors.black),
                    label: Text(
                      'Route',
                      style: TextStyle(color: Colors.black), // Label color black
                    ),
                  ),
                ],
                selectedLabelTextStyle: TextStyle(
                  color: Colors.blue, // Highlight selected label with blue
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Colors.black.withOpacity(0.6), // Unselected labels in grayish black
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BlocBuilder<NavigationBloc, NavigationState>(
                  builder: (context, state) {
                    return _buildReportPage(state);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get the selected index based on state
  int _getSelectedIndexFromState(BuildContext context) {
    final state = context.watch<NavigationBloc>().state;
    if (state is ReportState) {
      return 0; // Key Metrics report
    } else if (state is PerformanceInsightsState) {
      return 1; // Performance Insights report
    } else if (state is RoutePerformanceState) {
      return 2; // Route Performance report
    }
    return 0; // Default index
  }

  // Helper method to map selected index to event
  NavigationEvent _mapIndexToEvent(int index) {
    switch (index) {
      case 0:
        return NavigateToreport();
      case 1:
        return NavigateToPerformanceInsights();
      case 2:
        return NavigateToRoutePerformance();
      default:
        return NavigateToHome();
    }
  }

  // Method to display the selected report page
  Widget _buildReportPage(NavigationState state) {
    if (state is ReportState) {
      return KeyMetricsReport(); // Default report page
    }
    if (state is PerformanceInsightsState) {
      return PerformanceInsightsReport();
    }
    if (state is RoutePerformanceState) {
      return RoutePerformanceReport();
    }
    return Center(child: Text('Select a report')); // If no state matches
  }
}