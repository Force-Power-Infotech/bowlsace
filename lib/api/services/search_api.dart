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
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
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

    return SearchResponse.fromJson(response);
  }
}
