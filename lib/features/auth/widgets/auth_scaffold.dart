import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget body;
  final List<Color>? gradient;
  final String? backgroundImage;
  final bool useCard;
  final double cardPadding;

  const AuthScaffold({
    super.key,
    required this.body,
    this.gradient,
    this.backgroundImage,
    this.useCard = true,
    this.cardPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient != null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient!,
                )
              : null,
          image: backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage!),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                )
              : null,
        ),
        child: SafeArea(
          child: backgroundImage != null
              ? _buildLoginLayout(context)
              : _buildStandardLayout(context),
        ),
      ),
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: useCard
            ? Container(
                width: double.infinity,
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: body,
              )
            : body,
      ),
    );
  }

  Widget _buildLoginLayout(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(child: body),
          ),
        ),
      ],
    );
  }
}
