import 'package:flutter/material.dart';

class OnBoardingWidget extends StatelessWidget {
  const OnBoardingWidget({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    final titleSize = w * 0.045;
    final subtitleSize = w * 0.028;
    final imageHeight = size.height * (w > 600 ? 0.45 : 0.38);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: imageHeight, fit: BoxFit.contain),

          SizedBox(height: w * 0.06),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          SizedBox(height: w * 0.03),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleSize,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
