import '../api/services/search_api.dart';
import '../utils/local_storage.dart';

class SearchRepository {
  final SearchApi _api;
  final LocalStorage _localStorage;

  SearchRepository(this._api, this._localStorage);

  Future<SearchResponse> search(String query) async {
    try {
      final response = await _api.search(query);
      
      // Cache the search results
      await _localStorage.setItem(
        'last_search_$query',
        {
          'items': response.items.map((item) => {
            'id': item.id,
            'name': item.name,
            'type': item.type,
            'description': item.description,
          }).toList(),
          'total': response.total,
        },
      );
      
      return response;
    } catch (e) {
      // Try to get from local cache on failure
      final cached = await _localStorage.getItem('last_search_$query');
      if (cached != null) {
        return SearchResponse.fromJson(cached);
      }
      
      // If no cache available, rethrow the error
      rethrow;
    }
  }
}