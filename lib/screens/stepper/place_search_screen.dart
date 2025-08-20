import 'package:flutter/material.dart';
import '../../services/location_service.dart';

class PlaceSearchScreen extends StatefulWidget {
  final LocationService locationService;

  const PlaceSearchScreen({
    super.key,
    required this.locationService,
  });

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await widget.locationService.searchPlaces(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Erro na busca: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Local'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Digite o nome ou endereço do local...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Digite para buscar locais'
                  : 'Nenhum resultado encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(place['mainText'] ?? ''),
          subtitle: Text(place['secondaryText'] ?? ''),
          onTap: () => _selectPlace(place),
        );
      },
    );
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    try {
      final placeDetails = await widget.locationService.getPlaceDetails(
        place['placeId'],
      );

      if (placeDetails != null && mounted) {
        Navigator.pop(context, {
          'name': placeDetails['name'],
          'address': placeDetails['formattedAddress'],
          'lat': placeDetails['lat'],
          'lng': placeDetails['lng'],
        });
      }
    } catch (e) {
      print('Erro ao obter detalhes do lugar: $e');
    }
  }
}