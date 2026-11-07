import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Silent Moon artwork from Figma node 3:2990, composed in its original order.
class SilentMoonArt extends StatelessWidget {
  const SilentMoonArt({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 369,
        height: 229,
        child: Stack(
          children: [
            Positioned(left: 0, top: 129.4, child: _asset('branch')),
            Positioned(left: 50.55, top: 11.04, child: _asset('bird-mint')),
            Positioned(left: 175.53, top: 17.47, child: _asset('bird-pink')),
            Positioned(left: 164.57, top: 0, child: _asset('sleep-sparks')),
          ],
        ),
      ),
    ),
  );

  Widget _asset(String name) =>
      SvgPicture.asset('assets/silent_moon/$name.svg');
}
