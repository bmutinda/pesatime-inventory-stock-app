import 'package:flutter/material.dart';

class HeadingWidget extends StatelessWidget {
  final String title;

  const HeadingWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              height: 1,
              color: Colors.grey,
            ),
          ),
          Text(
            "$title",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              height: 1,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
