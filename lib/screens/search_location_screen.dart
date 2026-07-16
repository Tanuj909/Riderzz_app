import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riderzz_app/models/photon_place.dart';
import 'package:riderzz_app/repositories/location_repository.dart';
import 'package:riderzz_app/utils/debounce.dart';
import 'package:riderzz_app/widgets/search_textfield.dart';
import 'package:riderzz_app/widgets/search_result_tile.dart';

class SearchLocationScreen extends StatefulWidget {
  final String hintText;

  const SearchLocationScreen({
    super.key,
    this.hintText = 'Search for area, street, city...',
  });

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocationRepository _locationRepository = LocationRepository();
  final Debouncer _debouncer = Debouncer(milliseconds: 400);

  List<PhotonPlace> _suggestions = [];
  bool _isLoading = false;
  String _activeSearchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    debugPrint('SearchScreen: _onSearchChanged called with: "$query"');
    if (query.trim().length < 3) {
      // Just cancel any pending timer, don't dispose the debouncer
      _debouncer.run(() {}); // replace pending action with no-op
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _errorMessage = null;
        _activeSearchQuery = '';
      });
      return;
    }

    debugPrint('SearchScreen: Scheduling debounced search for: "$query"');
    _debouncer.run(() => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    debugPrint('SearchScreen: _performSearch called for: "$query"');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activeSearchQuery = query;
    });

    try {
      final results = await _locationRepository.search(query);
      debugPrint('SearchScreen: Got ${results.length} results for: "$query"');

      // Verify that this response is still for the most recent query
      if (_activeSearchQuery == query) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      } else {
        debugPrint('SearchScreen: Stale response for "$query", active is "$_activeSearchQuery"');
      }
    } catch (e) {
      debugPrint('SearchScreen: Error during search: $e');
      if (_activeSearchQuery == query) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
          _errorMessage = 'An error occurred while searching';
        });
        _showErrorSnackBar('Network error or search failed. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF121214), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF121214),
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchTextField(
              controller: _searchController,
              focusNode: _focusNode,
              hintText: widget.hintText,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE1E1E6)),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31C2E)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.outfit(
            color: const Color(0xFF6C6F79),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_searchController.text.trim().length >= 3 && _suggestions.isEmpty) {
      return Center(
        child: Text(
          'No places found',
          style: GoogleFonts.outfit(
            color: const Color(0xFF6C6F79),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE7E7EB),
      ),
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        return SearchResultTile(
          place: place,
          onTap: () {
            Navigator.pop(context, place);
          },
        );
      },
    );
  }
}
