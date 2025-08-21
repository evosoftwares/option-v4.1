import 'package:flutter/material.dart';
import '../../models/favorite_location.dart';
import '../place_picker_screen.dart';

class FavoritesStep extends StatefulWidget {

  const FavoritesStep({
    super.key,
    required this.initialFavorites,
    required this.onSave,
    required this.onNext,
  });
  final List<FavoriteLocation> initialFavorites;
  final Function(List<FavoriteLocation>) onSave;
  final VoidCallback onNext;

  @override
  State<FavoritesStep> createState() => _FavoritesStepState();
}

class _FavoritesStepState extends State<FavoritesStep> {
  final List<FavoriteLocation> _favoritePlaces = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _favoritePlaces.addAll(widget.initialFavorites);
  }

  Future<void> _handleNext() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    widget.onSave(_favoritePlaces);
    widget.onNext();
  }

  Future<void> _addFavoritePlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlacePickerScreen(
          isForFavorites: true,
        ),
      ),
    );

    if (result != null && result is FavoriteLocation) {
      setState(() {
        final exists = _favoritePlaces.any((f) =>
            (f.placeId != null && f.placeId == result.placeId) ||
            (f.latitude == result.latitude && f.longitude == result.longitude),);
        if (!exists) {
          _favoritePlaces.add(result);
        }
      });
    }
  }

  void _removeFavoritePlace(int index) {
    setState(() {
      _favoritePlaces.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Locais favoritos',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seus locais favoritos para viagens mais rápidas',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addFavoritePlace,
              icon: Icon(Icons.add, color: colorScheme.onSurface),
              label: Text(
                'Adicionar local',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _favoritePlaces.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum local favorito ainda',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _favoritePlaces.length,
                    itemBuilder: (context, index) {
                      final loc = _favoritePlaces[index];
                      return Card(
                        color: colorScheme.surfaceContainerHighest,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            loc.type.icon,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            loc.name,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            loc.address,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _removeFavoritePlace(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Finalizar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                widget.onSave(_favoritePlaces);
                widget.onNext();
              },
              child: Text(
                'Pular esta etapa',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}