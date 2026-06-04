import 'package:inventory_app/helpers/utils/money.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title, changeText, changeValue;
  final double amount;
  final bool isChangeUp;
  final IconData icon;

  const StatCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.isChangeUp,
    required this.changeText,
    required this.changeValue,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    format(amount, decimal: 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        changeValue,
                        style: TextStyle(
                          fontSize: 14,
                          color: isChangeUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        isChangeUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                        color: isChangeUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        changeText,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(icon),
          ],
        ),
      ),
    );
  }
}

//
///
///
///

class SimpleStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isChangeUp;
  final Color color;

  const SimpleStatCard(
      {Key? key,
      required this.title,
      required this.amount,
      required this.isChangeUp,
      required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    format(amount, decimal: 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 25,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: isChangeUp ? Colors.grey[300] : Colors.red,
              ),
              child: Icon(
                isChangeUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: isChangeUp ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
