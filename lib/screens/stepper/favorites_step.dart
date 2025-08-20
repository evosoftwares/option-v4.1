import 'package:flutter/material.dart';
import 'package:uber_clone/screens/placePicker_screen.dart';

class FavoritesStep extends StatefulWidget {
  final List<String> initialFavorites;
  final Function(List<String>) onSave;
  final VoidCallback onNext;

  const FavoritesStep({
    super.key,
    required this.initialFavorites,
    required this.onSave,
    required this.onNext,
  });

  @override
  State<FavoritesStep> createState() => _FavoritesStepState();
}

class _FavoritesStepState extends State<FavoritesStep> {
  final List<String> _favoritePlaces = [];
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

  void _addFavoritePlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlacePickerScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        if (!_favoritePlaces.contains(result)) {
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Locais favoritos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione seus locais favoritos para viagens mais rápidas',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addFavoritePlace,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar local',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
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
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum local favorito ainda',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _favoritePlaces.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.place,
                            color: Colors.white,
                          ),
                          title: Text(
                            _favoritePlaces[index],
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
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
              onPressed: _isLoading
                  ? null
                  : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
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
              child: const Text(
                'Pular esta etapa',
                style: TextStyle(
                  color: Colors.grey,
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