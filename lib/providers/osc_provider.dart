import 'package:flutter/foundation.dart';
import '../services/osc_service.dart';
import '../models/game_result.dart';

/// Provider for Open Shop Channel homebrew browsing
class OSCProvider with ChangeNotifier {
  final OSCService _oscService = OSCService();
  
  List<GameResult> _homebrewResults = [];
  bool _isLoading = false;
  String _selectedCategory = '';
  String _searchQuery = '';
  String _error = '';
  
  // Getters
  List<GameResult> get homebrewResults => _homebrewResults;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get error => _error;
  Map<String, String> get categories => _oscService.getCategories();
  
  /// Search homebrew applications
  Future<void> searchHomebrew(String query, {String? category}) async {
    if (query.isEmpty && category == null) {
      _homebrewResults = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _searchQuery = query;
    _error = '';
    notifyListeners();
    
    try {
      final results = await _oscService.searchHomebrew(query, category: category);
      _homebrewResults = results;
      _error = '';
    } catch (e) {
      _error = 'Failed to search homebrew: $e';
      _homebrewResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load homebrew by category
  Future<void> loadHomebrewByCategory(String category) async {
    _isLoading = true;
    _selectedCategory = category;
    _error = '';
    notifyListeners();
    
    try {
      final results = await _oscService.getHomebrewByCategory(category);
      _homebrewResults = results;
      _error = '';
    } catch (e) {
      _error = 'Failed to load homebrew category: $e';
      _homebrewResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load popular homebrew
  Future<void> loadPopularHomebrew() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final results = await _oscService.getPopularHomebrew();
      _homebrewResults = results;
      _error = '';
    } catch (e) {
      _error = 'Failed to load popular homebrew: $e';
      _homebrewResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clear search results
  void clearResults() {
    _homebrewResults = [];
    _searchQuery = '';
    _error = '';
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}