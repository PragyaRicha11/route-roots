import 'package:flutter/material.dart';
import 'passenger_page.dart';
import 'driver_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
  @override
  _RoleSelectionPageState createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route-Roots"),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(icon: Icon(Icons.search), text: "Find Ride"), Tab(icon: Icon(Icons.directions_car), text: "Offer Ride")]),
      ),
      body: TabBarView(controller: _tabController, children: const [PassengerPage(), DriverPage()]),
    );
  }
}