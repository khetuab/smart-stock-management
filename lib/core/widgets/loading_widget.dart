import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool fullScreen;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.fullScreen = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? theme.primaryColor,
            ),
            strokeWidth: 3,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: Colors.white.withOpacity(0.9),
        body: Center(
          child: content,
        ),
      );
    }

    return Center(
      child: content,
    );
  }
}