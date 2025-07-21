import '../api_client.dart';
import '../api_config.dart';

class SearchResult {
  final int id;
  final String name;
  final String type;
  final String description;

  SearchResult({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'drill',
      description: json['description'] as String? ?? '',
    );
  }
}

class SearchResponse {
  final List<SearchResult> items;
  final int total;

  SearchResponse({
    required this.items,
    required this.total,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      items: (json['items'] as List<dynamic>)
          .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}

class SearchApi {
  final ApiClient _apiClient;

  SearchApi(this._apiClient);

  Future<SearchResponse> search(String query) async {
    final queryParams = <String, String>{
      'query': query,
    };

    final response = await _apiClient.get(
      ApiConfig.search,
      queryParameters: queryParams,
    );

    // Handle different response formats
    List<dynamic> itemsList;
    int total = 0;

    if (response.containsKey('data') && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      itemsList = data['items'] as List<dynamic>? ?? [];
      total = data['total'] as int? ?? itemsList.length;
    } else if (response.containsKey('items') && response['items'] is List) {
      itemsList = response['items'] as List<dynamic>;
      total = response['total'] as int? ?? itemsList.length;
    } else {
      // If response is directly a list or unexpected format
      itemsList = response is List ? response : [];
      total = itemsList.length;
    }

    return SearchResponse(
      items: itemsList
          .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: total,
    );
  }
}