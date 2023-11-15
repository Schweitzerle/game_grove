import 'package:flutter/material.dart';

class GenreButton extends StatefulWidget {
  final String id;
  final String name;
  bool? isSelected;
  final VoidCallback onTap;

  GenreButton({
    Key? key,
    required this.id,
    required this.name,
    this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  _GenreButtonState createState() => _GenreButtonState();
}

class _GenreButtonState extends State<GenreButton> {
  bool isSelected = false;

  @override
  void initState() {
    isSelected = widget.isSelected!;
    super.initState();
  }

  @override
  void didUpdateWidget(GenreButton oldWidget) {
    if (oldWidget.isSelected != widget.isSelected) {
      setState(() {
        isSelected = widget.isSelected!;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected = !isSelected;
        });
        widget.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: isSelected ? Colors.blue : Colors.grey,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Text(
          widget.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
