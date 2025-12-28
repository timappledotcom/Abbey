import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'pcloud_service.g.dart';

@Riverpod(keepAlive: true)
class PCloudService extends _$PCloudService {
  static const String _clientId = 'q0eDYPbJmTm';
  static const String _clientSecret = 'EGuKRoDRaOb4FxsMvORfR89SdiFX';
  // Using localhost redirect for desktop OAuth flow
  static const int _localPort = 53682;
  static const String _redirectUri = 'http://localhost:$_localPort/';

  /// The root folder name in pCloud where Abbey stores all its data
  static const String abbeyFolderName = 'Abbey';

  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'pcloud_access_token';
  static const String _apiHostKey =
      'pcloud_api_host'; // api.pcloud.com or eapi.pcloud.com
  static const String _abbeyFolderIdKey = 'pcloud_abbey_folder_id';

  HttpServer? _server;

  @override
  Future<void> build() async {
    // Check if we have a token
  }

  /// Starts the OAuth login flow with a local server to capture the callback.
  /// Returns true if authentication was successful.
  Future<bool> startLogin() async {
    // Start a local server to listen for the OAuth callback
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _localPort);
    } catch (e) {
      throw Exception('Could not start local server for OAuth: $e');
    }

    // Launch the browser for authorization
    final url = Uri.parse(
      'https://my.pcloud.com/oauth2/authorize?client_id=$_clientId&response_type=code&redirect_uri=${Uri.encodeComponent(_redirectUri)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      await _server?.close();
      throw Exception('Could not launch pCloud login');
    }

    // Wait for the OAuth callback
    try {
      await for (final request in _server!) {
        final uri = request.uri;
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];

        if (error != null) {
          // Send error response to browser
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(_buildHtmlResponse(false, 'Authorization denied: $error'));
          await request.response.close();
          await _server?.close();
          return false;
        }

        if (code != null) {
          // Exchange the code for a token
          try {
            await handleAuthCode(code);

            // Send success response to browser
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(
                _buildHtmlResponse(
                  true,
                  'Successfully connected to pCloud! You can close this window.',
                ),
              );
            await request.response.close();
            await _server?.close();
            return true;
          } catch (e) {
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.html
              ..write(
                _buildHtmlResponse(
                  false,
                  'Failed to complete authentication: $e',
                ),
              );
            await request.response.close();
            await _server?.close();
            return false;
          }
        }

        // No code or error, send a waiting response
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_buildHtmlResponse(false, 'Waiting for authorization...'));
        await request.response.close();
      }
    } catch (e) {
      await _server?.close();
      throw Exception('Error during OAuth callback: $e');
    }

    return false;
  }

  String _buildHtmlResponse(bool success, String message) {
    final color = success ? '#4CAF50' : '#f44336';
    final icon = success ? '✓' : '✗';
    return '''
<!DOCTYPE html>
<html>
<head>
  <title>Abbey - pCloud Authorization</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 16px;
      backdrop-filter: blur(10px);
    }
    .icon {
      font-size: 64px;
      color: $color;
      margin-bottom: 20px;
    }
    h1 { margin: 0 0 10px 0; }
    p { opacity: 0.8; }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">$icon</div>
    <h1>Abbey</h1>
    <p>$message</p>
  </div>
</body>
</html>
''';
  }

  // This method needs to be called when the app receives the deep link with the code
  Future<void> handleAuthCode(String code) async {
    final response = await http.get(
      Uri.parse(
        'https://api.pcloud.com/oauth2_token?client_id=$_clientId&client_secret=$_clientSecret&code=$code',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(
          key: _apiHostKey,
          value: 'api.pcloud.com',
        ); // Default to US, need to check location

        // Check location (get_apiserver)
        await _checkApiServer(data['access_token']);

        // Create the Abbey folder in pCloud root
        await _createAbbeyFolder();
      } else {
        throw Exception('Failed to get token: ${data['error']}');
      }
    } else {
      throw Exception('Network error during auth');
    }
  }

  /// Sets up the folder structure for Abbey in pCloud.
  /// For App Folder OAuth apps, the root (folderid 0) is already Applications/Abbey,
  /// so we just create subfolders directly there.
  Future<void> _createAbbeyFolder() async {
    final token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    // For App Folder OAuth apps, folderid 0 is the app's folder (Applications/Abbey)
    // We don't need to create another Abbey folder, just use the app folder directly
    const int appRootFolderId = 0;

    // Save the root folder ID (app folder) for future use
    await _storage.write(
      key: _abbeyFolderIdKey,
      value: appRootFolderId.toString(),
    );

    // Create subfolders for organization directly in the app folder
    await _ensureSubfolder('Essays', appRootFolderId);
    await _ensureSubfolder('Flows', appRootFolderId);
    await _ensureSubfolder('Backups', appRootFolderId);
    print('Abbey folder structure created successfully in app folder');
  }

  /// Public method to ensure Abbey folder structure exists. Call this after authentication.
  Future<void> ensureAbbeyFolderExists() async {
    await _createAbbeyFolder();
  }

  /// Finds a folder by name within a parent folder. Returns folder ID or null.
  Future<int?> _findFolder(String folderName, int parentFolderId) async {
    final token = await getAccessToken();
    final host = await getApiHost();
    if (token == null) return null;

    final uri = Uri.https(host, '/listfolder', {
      'access_token': token,
      'folderid': parentFolderId.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 0 && data['metadata'] != null) {
        final contents = data['metadata']['contents'] as List?;
        if (contents != null) {
          for (final item in contents) {
            if (item['isfolder'] == true && item['name'] == folderName) {
              return item['folderid'] as int;
            }
          }
        }
      }
    }
    return null;
  }

  /// Creates a folder and returns its ID.
  Future<int> _createFolder(String folderName, int parentFolderId) async {
    final token = await getAccessToken();
    final host = await getApiHost();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.https(host, '/createfolder', {
      'access_token': token,
      'folderid': parentFolderId.toString(),
      'name': folderName,
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 0 && data['metadata'] != null) {
        return data['metadata']['folderid'] as int;
      } else {
        throw Exception('Failed to create folder: ${data['error']}');
      }
    } else {
      throw Exception('Network error creating folder');
    }
  }

  /// Ensures a subfolder exists within the given parent folder.
  Future<int> _ensureSubfolder(String folderName, int parentFolderId) async {
    final existing = await _findFolder(folderName, parentFolderId);
    if (existing != null) return existing;
    return await _createFolder(folderName, parentFolderId);
  }

  /// Gets the Abbey folder ID, creating it if necessary.
  Future<int> getAbbeyFolderId() async {
    final storedId = await _storage.read(key: _abbeyFolderIdKey);
    if (storedId != null) {
      return int.parse(storedId);
    }

    // Folder ID not stored, try to find or create it
    await _createAbbeyFolder();
    final newId = await _storage.read(key: _abbeyFolderIdKey);
    if (newId == null) throw Exception('Failed to get Abbey folder ID');
    return int.parse(newId);
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

    // Ensure we're uploading to the Abbey folder structure
    final abbeyFolderId = await getAbbeyFolderId();

    // If path is provided (e.g., "Essays"), get or create that subfolder
    int targetFolderId = abbeyFolderId;
    if (path.isNotEmpty && path != '/') {
      final subfolderName = path.replaceAll('/', '');
      targetFolderId = await _ensureSubfolder(subfolderName, abbeyFolderId);
    }

    print('Uploading $filename to folder $targetFolderId...');

    final uri = Uri.https(host, '/uploadfile', {
      'access_token': token,
      'folderid': targetFolderId.toString(),
      'filename': filename,
      'nopartial': '1',
    });

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromString('file', content, filename: filename),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      if (data['result'] == 0) {
        print('Upload successful: $filename');
      } else {
        print('Upload failed: ${data['error']}');
        throw Exception('Upload failed: ${data['error']}');
      }
    } else {
      print('Upload HTTP error: ${response.statusCode} - $responseBody');
      throw Exception('Upload failed with status ${response.statusCode}');
    }
  }

  Future<String> downloadFile(String path) async {
    // Implementation for downloading
    return '';
  }

  /// Deletes a file by name from a subfolder within the Abbey folder.
  Future<void> deleteFile(String subfolder, String filename) async {
    final token = await getAccessToken();
    final host = await getApiHost();
    if (token == null) throw Exception('Not authenticated');

    final abbeyFolderId = await getAbbeyFolderId();
    int targetFolderId = abbeyFolderId;

    if (subfolder.isNotEmpty) {
      final folderId = await _findFolder(subfolder, abbeyFolderId);
      if (folderId != null) {
        targetFolderId = folderId;
      } else {
        // Folder doesn't exist, nothing to delete
        return;
      }
    }

    // Find the file ID first
    final uri = Uri.https(host, '/listfolder', {
      'access_token': token,
      'folderid': targetFolderId.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 0 && data['metadata'] != null) {
        final contents = data['metadata']['contents'] as List? ?? [];
        for (final item in contents) {
          if (item['isfolder'] != true && item['name'] == filename) {
            final fileId = item['fileid'];
            // Delete the file
            final deleteUri = Uri.https(host, '/deletefile', {
              'access_token': token,
              'fileid': fileId.toString(),
            });
            final deleteResponse = await http.get(deleteUri);
            if (deleteResponse.statusCode == 200) {
              final deleteData = jsonDecode(deleteResponse.body);
              if (deleteData['result'] == 0) {
                print('Deleted file from pCloud: $filename');
              } else {
                print('Failed to delete file: ${deleteData['error']}');
              }
            }
            return;
          }
        }
      }
    }
    print('File not found in pCloud: $subfolder/$filename');
  }

  /// Lists all files in a subfolder within the Abbey folder.
  Future<List<Map<String, dynamic>>> listFiles(String subfolder) async {
    final token = await getAccessToken();
    final host = await getApiHost();
    if (token == null) throw Exception('Not authenticated');

    final abbeyFolderId = await getAbbeyFolderId();
    int targetFolderId = abbeyFolderId;

    if (subfolder.isNotEmpty) {
      final folderId = await _findFolder(subfolder, abbeyFolderId);
      if (folderId != null) {
        targetFolderId = folderId;
      }
    }

    final uri = Uri.https(host, '/listfolder', {
      'access_token': token,
      'folderid': targetFolderId.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] == 0 && data['metadata'] != null) {
        final contents = data['metadata']['contents'] as List? ?? [];
        return contents
            .where((item) => item['isfolder'] != true)
            .map(
              (item) => {
                'name': item['name'],
                'fileid': item['fileid'],
                'size': item['size'],
                'modified': item['modified'],
              },
            )
            .toList();
      }
    }
    return [];
  }

  /// Checks if the user is authenticated with pCloud.
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Logs out from pCloud by clearing stored tokens.
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _apiHostKey);
    await _storage.delete(key: _abbeyFolderIdKey);
  }

  /// Deletes a folder by ID (use with caution!)
  Future<void> deleteFolder(int folderId) async {
    final token = await getAccessToken();
    final host = await getApiHost();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.https(host, '/deletefolderrecursive', {
      'access_token': token,
      'folderid': folderId.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != 0) {
        throw Exception('Failed to delete folder: ${data['error']}');
      }
    } else {
      throw Exception('Network error deleting folder');
    }
  }

  /// Cleans up duplicate Abbey folder if it exists (created by old bug)
  Future<bool> cleanupDuplicateAbbeyFolder() async {
    // Check if there's an "Abbey" folder inside the app folder (which is a duplicate)
    final duplicateFolder = await _findFolder('Abbey', 0);
    if (duplicateFolder != null) {
      print(
        'Found duplicate Abbey folder with ID: $duplicateFolder - deleting...',
      );
      await deleteFolder(duplicateFolder);
      print('Duplicate folder deleted');
      return true;
    }
    return false;
  }
}
