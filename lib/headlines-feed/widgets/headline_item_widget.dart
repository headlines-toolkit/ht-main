import 'package:flutter/material.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart'
    show Headline;

/// A widget that displays a single headline.
class HeadlineItemWidget extends StatelessWidget {
  /// Creates a [HeadlineItemWidget].
  const HeadlineItemWidget({required this.headline, super.key});

  /// The headline to display.
  final Headline headline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        child: ListTile(
          leading: Image.network(
            headline.imageUrl ??
                'https://via.placeholder.com/50x50', // Placeholder image
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error),
          ),
          title: Text(
            headline.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.source,
                  color: Theme.of(context).iconTheme.color,
                ), // Placeholder for source icon
                const SizedBox(width: 16),
                Icon(
                  Icons.category,
                  color: Theme.of(context).iconTheme.color,
                ), // Placeholder for category icon
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).iconTheme.color,
                ), // Placeholder for country icon
              ],
            ),
          ),
        ),
      ),
    );
  }
}
