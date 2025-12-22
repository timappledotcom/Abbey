import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'pcloud_service.g.dart';

@Riverpod(keepAlive: true)
class PCloudService extends _$PCloudService {
  // TODO: Replace with your actual App Key and Secret
  static const String _clientId = 'YOUR_APP_KEY'; 
  static const String _clientSecret = 'YOUR_APP_SECRET';
  static const String _redirectUri = 'https://oauth2.pcloud.com/draft/abbey'; // Or a custom scheme
  
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'pcloud_access_token';
  static const String _apiHostKey = 'pcloud_api_host'; // api.pcloud.com or eapi.pcloud.com

  @override
  Future<void> build() async {
    // Check if we have a token
  }

  Future<void> startLogin() async {
    final url = Uri.parse(
      'https://my.pcloud.com/oauth2/authorize?client_id=$_clientId&response_type=code&redirect_uri=$_redirectUri',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch pCloud login');
    }
  }

  // This method needs to be called when the app receives the deep link with the code
  Future<void> handleAuthCode(String code) async {
    final response = await http.get(Uri.parse(
      'https://api.pcloud.com/oauth2_token?client_id=$_clientId&client_secret=$_clientSecret&code=$code',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(key: _apiHostKey, value: 'api.pcloud.com'); // Default to US, need to check location
        
        // Check location (get_apiserver)
        await _checkApiServer(data['access_token']);
      } else {
        throw Exception('Failed to get token: ${data['error']}');
      }
    } else {
      throw Exception('Network error during auth');
    }
  }
  
  Future<void> _checkApiServer(String token) async {
     // pCloud might require using eapi.pcloud.com for EU users
     // We can check this by calling a method and seeing if it tells us to switch
     // Or just use the one returned if the token endpoint provides it (it usually doesn't)
     // For now, we'll assume api.pcloud.com and handle redirects if needed.
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<String> getApiHost() async {
    return await _storage.read(key: _apiHostKey) ?? 'api.pcloud.com';
  }

  Future<void> uploadFile(String path, String filename, String content) async {
    final token = await getAccessToken();
    final host = await getApiHost();
    if (token == null) throw Exception('Not authenticated');

    // 1. Create folder if not exists (we'll do this lazily or on setup)
    // For now, let's assume we upload to root or a specific folder ID
    // We need to implement folder creation logic.
    
    final uri = Uri.https(host, '/uploadfile', {
      'access_token': token,
      'path': path, // e.g., /Abbey/Essays/
      'filename': filename,
      'nopartial': '1',
    });

    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromString('file', content, filename: filename));
    
    final response = await request.send();
    if (response.statusCode != 200) {
       throw Exception('Upload failed');
    }
  }
  
  Future<String> downloadFile(String path) async {
     // Implementation for downloading
     return '';
  }
}
