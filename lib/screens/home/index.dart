import 'package:inventory_app/widgets/cards.dart';
import 'package:inventory_app/widgets/headings.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          PopupMenuButton<int>(
            onSelected: (item) => {},
            itemBuilder: (context) => const [
              PopupMenuItem<int>(value: 0, child: Text('Settings')),
              PopupMenuItem<int>(value: 1, child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                color: Colors.blue.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Analytics",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        DateTimeRange? result = await showDateRangePicker(
                          context: context,
                          firstDate:
                              DateTime(2021, 1, 1), // the earliest allowable
                          lastDate: DateTime.now(), // the latest allowable
                          currentDate: DateTime.now(),
                          saveText: 'Done',
                        );
                      },
                      child: const Text(
                        "Jan,2022 - Apr 2022",
                        style: TextStyle(fontSize: 14),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: HeadingWidget(
                title: "TODAY'S PERFORMANCE 💰",
              ),
            ),
            const SliverToBoxAdapter(
              child: StatCard(
                title: "Total Sales",
                amount: 100000,
                isChangeUp: true,
                changeText: "compared to yesterday",
                changeValue: "2.5%",
                icon: Icons.point_of_sale,
              ),
            ),
            const SliverToBoxAdapter(
              child: StatCard(
                title: "Total ORDERS 🍷",
                amount: 632,
                isChangeUp: true,
                changeText: "compared to yesterday",
                changeValue: "40%",
                icon: Icons.point_of_sale,
              ),
            ),
            const SliverToBoxAdapter(
              child: StatCard(
                title: "Total Expenses",
                amount: 50000,
                isChangeUp: false,
                changeText: "compared to yesterday",
                changeValue: "10.5%",
                icon: Icons.money_off,
              ),
            ),
            const SliverToBoxAdapter(
              child: StatCard(
                title: "Total Profit / Loss",
                amount: 50000,
                isChangeUp: true,
                changeText: "compared to yesterday",
                changeValue: "20%",
                icon: Icons.trending_up,
              ),
            ),
            const SliverToBoxAdapter(
              child: HeadingWidget(
                title: "BREAKDOWN BY LOCATION",
              ),
            ),
            const SliverToBoxAdapter(
              child: SimpleStatCard(
                color: Colors.white,
                title: "BAR",
                amount: 10700,
                isChangeUp: true,
              ),
            ),
            const SliverToBoxAdapter(
              child: SimpleStatCard(
                color: Color.fromARGB(255, 174, 228, 255),
                title: "KITCHEN",
                amount: 5150,
                isChangeUp: false,
              ),
            ),
            const SliverToBoxAdapter(
              child: SimpleStatCard(
                color: Color.fromARGB(255, 241, 255, 88),
                title: "SWIMMING POOL",
                amount: 20400,
                isChangeUp: true,
              ),
            ),
            const SliverToBoxAdapter(
              child: HeadingWidget(
                title: "BREAKDOWN BY CASHIER",
              ),
            ),
            const SliverToBoxAdapter(
              child: SimpleStatCard(
                color: Color.fromARGB(255, 245, 134, 214),
                title: "BONIFACE - 🍮 BAR",
                amount: 10700,
                isChangeUp: true,
              ),
            ),
            const SliverToBoxAdapter(
              child: SimpleStatCard(
                color: Color.fromARGB(255, 144, 254, 152),
                title: "EUNICE - 🍮 KITCHEN",
                amount: 5150,
                isChangeUp: false,
              ),
            ),
            const SliverToBoxAdapter(
              child: SimpleStatCard(
                color: Color.fromARGB(255, 255, 209, 118),
                title: "DENNIS - 🍮 SWIMMING POOL",
                amount: 20400,
                isChangeUp: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
