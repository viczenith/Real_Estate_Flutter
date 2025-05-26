import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'client_sidebar.dart';

/// Data model for the chart
class ChartData {
  final String time;
  final double sales;
  final double revenue;
  final double customers;

  ChartData({
    required this.time,
    required this.sales,
    required this.revenue,
    required this.customers,
  });
}

class ClientDashboard extends StatefulWidget {
  final String token; // Added token parameter
  const ClientDashboard({required this.token, super.key});

  @override
  _ClientDashboardState createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with SingleTickerProviderStateMixin {
  bool isSidebarOpen = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  // Sample data for Syncfusion chart
  final List<ChartData> salesData = [
    ChartData(time: '00:00', sales: 40, revenue: 50, customers: 30),
    ChartData(time: '03:00', sales: 55, revenue: 60, customers: 20),
    ChartData(time: '06:00', sales: 35, revenue: 40, customers: 50),
    ChartData(time: '09:00', sales: 60, revenue: 70, customers: 40),
    ChartData(time: '12:00', sales: 45, revenue: 65, customers: 60),
    ChartData(time: '15:00', sales: 70, revenue: 85, customers: 50),
    ChartData(time: '18:00', sales: 55, revenue: 60, customers: 70),
    ChartData(time: '21:00', sales: 80, revenue: 90, customers: 65),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _sidebarAnimation = Tween<double>(begin: -250, end: 0).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );
  }

  void toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
      if (isSidebarOpen) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: buildHeader(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Client Dashboard",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                SizedBox(height: 5),
                Text("Home / Dashboard", style: TextStyle(color: Colors.grey)),
                SizedBox(height: 20),

                // Summary Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    dashboardCard(
                        Icons.home, "Properties Purchased", "7", Colors.blue),
                    dashboardCard(Icons.assignment_turned_in,
                        "Fully Paid & Allocated", "5", Colors.green),
                    dashboardCard(Icons.pending_actions, "Not Fully Paid", "2",
                        Colors.orange),
                  ],
                ),

                SizedBox(height: 25),
                Text("Property Value Chart",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),

                // Syncfusion Multi-Line Chart
                buildSyncfusionChart(),

                SizedBox(height: 25),
                Text("News & Update",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),

                // News items
                buildNewsItem(
                  image: "assets/logo.png",
                  heading: "Nihil blanditiis at in nihil autem",
                  body:
                      "Itaque suscipit suscipit recusandae harum perspiciatis. Quia enim eligendi sed ut harum explicabo delectus?",
                  time: "2 hrs ago",
                ),
                buildNewsItem(
                  image: "assets/logo.png",
                  heading: "Quidem autem et impedit",
                  body:
                      "Illo nemo neque maiores vitae officiis cum eum. Rerum deleniti dicta doloribus temporibus asperiores.",
                  time: "5 hrs ago",
                ),
                buildNewsItem(
                  image: "assets/logo.png",
                  heading: "Id quia et et maxime similique coaccati",
                  body:
                      "Fugiat esse fugit illum vero beatae suscipit accusamus. Odit ipsam aspernatur reiciendis.",
                  time: "8 hrs ago",
                ),
              ],
            ),
          ),

          // Sidebar Animation
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: _sidebarAnimation.value,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: toggleSidebar,
              child: ClientSidebar(closeSidebar: toggleSidebar),
            ),
          ),
        ],
      ),
    );
  }

  // AppBar
  AppBar buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          IconButton(
            icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _sidebarController),
            color: Colors.black87,
            onPressed: toggleSidebar,
          ),
          SizedBox(width: 10),
          Text(
            "Lior & Eliora Properties",
            style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
            icon: Icon(Icons.notifications, color: Colors.blueAccent),
            onPressed: () {}),
        IconButton(
            icon: Icon(Icons.message, color: Colors.blueAccent),
            onPressed: () {}),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child:
              CircleAvatar(backgroundImage: AssetImage('assets/logo.png')),
        ),
      ],
    );
  }

  // Dashboard Card Widget
  Widget dashboardCard(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: Offset(0, 4),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            SizedBox(height: 5),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // Syncfusion Multi-Line Chart Widget
  Widget buildSyncfusionChart() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10)
        ],
      ),
      padding: EdgeInsets.all(15),
      child: SfCartesianChart(
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(),
        primaryYAxis:
            NumericAxis(minimum: 0, maximum: 100, interval: 20),
        series: <ChartSeries>[
          // Sales Series
          LineSeries<ChartData, String>(
            name: "Sales",
            dataSource: salesData,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.sales,
            markerSettings: MarkerSettings(isVisible: true),
          ),
          // Revenue Series
          LineSeries<ChartData, String>(
            name: "Revenue",
            dataSource: salesData,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.revenue,
            markerSettings: MarkerSettings(isVisible: true),
          ),
          // Customers Series
          LineSeries<ChartData, String>(
            name: "Customers",
            dataSource: salesData,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.customers,
            markerSettings: MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  // News Item Widget
  Widget buildNewsItem({
    required String image,
    required String heading,
    required String body,
    required String time,
  }) {
    return InkWell(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(image,
                  width: 70, height: 70, fit: BoxFit.cover),
            ),
            SizedBox(width: 12),
            // News Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  SizedBox(height: 5),
                  Text(
                    body,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(time,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
