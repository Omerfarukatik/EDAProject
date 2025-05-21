import 'package:flutter/material.dart';

class CustomToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const CustomToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title),
        trailing: GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 50,
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: value ? Colors.deepPurple : Colors.grey.shade400,
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
