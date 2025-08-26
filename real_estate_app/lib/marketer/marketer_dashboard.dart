import 'package:flutter/material.dart';
import 'package:real_estate_app/shared/app_side.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:real_estate_app/shared/app_layout.dart';
import 'package:real_estate_app/marketer/marketer_bottom_nav.dart';

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

class MarketerDashboard extends StatefulWidget {
  final String token;
  const MarketerDashboard({required this.token, super.key});

  @override
  _MarketerDashboardState createState() => _MarketerDashboardState();
}

class _MarketerDashboardState extends State<MarketerDashboard> {
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
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'Marketer Dashboard',
      token: widget.token,
      side: AppSide.marketer,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        // Attach the beautiful bottom nav here
        bottomNavigationBar: MarketerBottomNav(
          currentIndex: 0,
          token: widget.token,
          chatBadge: 1,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  "Marketer Dashboard",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Text("Home / Dashboard", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

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

                const SizedBox(height: 25),
                Text("Property Value Chart",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Syncfusion Multi-Line Chart
                buildSyncfusionChart(),

                const SizedBox(height: 25),
                Text("News & Update",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dashboard Card Widget
  Widget dashboardCard(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 4),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(15),
      child: SfCartesianChart(
        legend: Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(minimum: 0, maximum: 100, interval: 20),
        series: <ChartSeries>[
          // Sales Series
          LineSeries<ChartData, String>(
            name: "Sales",
            dataSource: salesData,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.sales,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
          // Revenue Series
          LineSeries<ChartData, String>(
            name: "Revenue",
            dataSource: salesData,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.revenue,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
          // Customers Series
          LineSeries<ChartData, String>(
            name: "Customers",
            dataSource: salesData,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.customers,
            markerSettings: const MarkerSettings(isVisible: true),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  Image.asset(image, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(time,
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
