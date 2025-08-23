import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:real_estate_app/admin/models/add_estate_plot_model.dart';
import 'package:real_estate_app/admin/models/admin_chat_model.dart';
import 'package:real_estate_app/admin/models/admin_dashboard_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart'; 
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:real_estate_app/admin/models/add_plot_size.dart';
// ignore: unused_import
import 'package:real_estate_app/admin/models/add_amenities_model.dart';
import 'package:real_estate_app/admin/models/estate_details_model.dart';
// ignore: unused_import
import 'package:real_estate_app/admin/models/admin_user_registration.dart';
import 'package:real_estate_app/admin/models/plot_allocation_model.dart';
import 'package:real_estate_app/admin/models/plot_size_number_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  final String baseUrl = 'http://172.24.49.208:8000/api';

  /// Login using username and password.
  Future<String> login(String email, String password) async {
    final url = '$baseUrl/api-token-auth/';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      // Send "email" field, as the backend requires it.
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // User Registration API Call
  Future<void> registerAdminUser(
      Map<String, dynamic> userData, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin-user-registration/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  // Fetch clients from the backend
  Future<List<Map<String, dynamic>>> fetchClients(String token) async {
    final url = Uri.parse('$baseUrl/clients/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load clients: ${response.statusCode}');
    }
  }

  // Get client detail
  Future<Map<String, dynamic>> getClientDetail({
    required int clientId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/client/$clientId/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['profile_image'] != null &&
          !data['profile_image'].startsWith('http')) {
        data['profile_image'] = '$baseUrl${data['profile_image']}';
      }
      return data;
    } else {
      throw Exception('Failed to fetch client details');
    }
  }

  // Update client profile
  Future<void> updateClientProfile({
    required int clientId,
    required String token,
    String? fullName,
    String? about,
    String? company,
    String? job,
    String? country,
    String? address,
    String? phone,
    String? email,
    File? profileImage,
  }) async {
    final uri = Uri.parse('$baseUrl/client/$clientId/');
    final request = http.MultipartRequest('PUT', uri);

    // Auth token
    request.headers['Authorization'] = 'Token $token';
    request.headers['Accept'] = 'application/json';

    // Helper to add only non-null, non-empty fields
    void addField(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        request.fields[key] = value;
      }
    }

    addField('full_name', fullName);
    addField('about', about);
    addField('company', company);
    addField('job', job);
    addField('country', country);
    addField('address', address);
    addField('phone', phone);
    addField('email', email);

    // Attach image file if present
    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        profileImage.path,
      ));
    }

    // Send request
    final response = await request.send();

    // Handle response
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to update client: $responseBody');
    }
  }

  // Delete client
  Future<bool> deleteClient(String token, String clientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/client/$clientId/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete client');
    }
  }

  // Fetch marketers from the backend
  Future<List<Map<String, dynamic>>> fetchMarketers(String token) async {
    final url = Uri.parse('$baseUrl/marketers/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load marketers: ${response.statusCode}');
    }
  }

  // Get marketer detail
  Future<Map<String, dynamic>> getMarketerDetail({
    required int marketerId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/marketers/$marketerId/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if the profile_image field is not null and handle dynamic URLs
      if (data['profile_image'] != null &&
          !data['profile_image'].startsWith('http')) {
        data['profile_image'] = '$baseUrl${data['profile_image']}';
      }

      return data;
    } else {
      throw Exception('Failed to fetch marketer details');
    }
  }

  // Update marketer profile
  Future<void> updateMarketerProfile({
    required int marketerId,
    required String token,
    String? fullName,
    String? about,
    String? company,
    String? job,
    String? country,
    String? address,
    String? phone,
    String? email,
    File? profileImage,
  }) async {
    final uri = Uri.parse('$baseUrl/marketers/$marketerId/');
    final request = http.MultipartRequest('PUT', uri);

    // Auth token
    request.headers['Authorization'] = 'Token $token';
    request.headers['Accept'] = 'application/json';

    // Helper to add only non-null, non-empty fields
    void addField(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        request.fields[key] = value;
      }
    }

    addField('full_name', fullName);
    addField('about', about);
    addField('company', company);
    addField('job', job);
    addField('country', country);
    addField('address', address);
    addField('phone', phone);
    addField('email', email);

    // Attach image file if present
    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        profileImage.path,
      ));
    }

    // Send request
    final response = await request.send();

    // Handle response
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to update marketer: $responseBody');
    }
  }

  // Delete marketer
  Future<bool> deleteMarketer(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/marketers/$id/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete marketer');
    }
  }

  /// Get the current user's profile.
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = '$baseUrl/users/me/';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.body}');
    }
  }

  /// Fetch Admin Dashboard Data from the dynamic JSON endpoint.
  Future<AdminDashboardData> fetchAdminDashboard(String token) async {
    final url = '$baseUrl/admin/dashboard-data/';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) {
      return AdminDashboardData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load dashboard data: ${response.body}');
    }
  }

  /// Fetch a list of estates from the admin estate list endpoint.
  // Future<List<dynamic>> fetchAdminEstateList(String token) async {
  //   final url = '$baseUrl/admin/estate-list/';
  //   final response = await http.get(
  //     Uri.parse(url),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Token $token',
  //     },
  //   );
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception('Failed to load admin estates: ${response.body}');
  //   }
  // }

  /// - Allocation details
  Future<Map<String, dynamic>> fetchEstateFullAllocationDetails(
      String estateId, String token) async {
    final url = '$baseUrl/estate-full-allocation-details/$estateId/';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      switch (response.statusCode) {
        case 200:
          return json.decode(response.body);
        case 404:
          throw Exception('Estate not found');
        case 401:
          throw Exception('Authentication failed: Invalid or expired token');
        case 403:
          throw Exception('Permission denied: Check your access rights');
        case 500:
          throw Exception('Server error: Please try again later');
        default:
          throw Exception(
              'Failed to load estate details: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message} (Check your connection)');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Future<void> updateAllocatedPlotForEstate(
  //     String allocationId,
  //     Map<String, dynamic> data,
  //     String token,
  // ) async {
  //   final uri = Uri.parse('$baseUrl/update-allocated-plot-for-estate/$allocationId/');
  //   final response = await http.patch(
  //     uri,
  //     headers: {
  //       'Authorization': 'Token $token',
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode(data),
  //   );
  //   if (response.statusCode != 200) {
  //     final body = jsonDecode(response.body);
  //     throw Exception(body);
  //   }
  // }

  Future<void> updateAllocatedPlotForEstate(
    String allocationId,
    Map<String, dynamic> data,
    String token,
  ) async {
    final uri =
        Uri.parse('$baseUrl/update-allocated-plot-for-estate/$allocationId/');

    final resp = await http.patch(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (resp.statusCode != 200) {
      final error = jsonDecode(resp.body);
      throw Exception(error['detail'] ?? 'Failed to update allocation');
    }
  }

  /// Load estate plots with nested plot size units and plot numbers for dynamic UI updates.
  Future<List<dynamic>> loadPlots(String token, int estateId) async {
    final url = '$baseUrl/load-plots/?estate_id=$estateId';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load plots: ${response.body}');
    }
  }

  /// Delete an allocation by its ID.
  Future<bool> deleteAllocation(String token, int allocationId) async {
    final url = '$baseUrl/delete-allocation/';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({'allocation_id': allocationId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to delete allocation: ${response.body}');
    }
  }

  /// Download allocation data as CSV.
  /// The response will contain CSV data that you can handle accordingly.
  Future<http.Response> downloadAllocations(String token, int estateId) async {
    final url = '$baseUrl/download-allocations/?estate_id=$estateId';
    return await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
  }

  /// Download estate details as a PDF.
  Future<http.Response> downloadEstatePDF(String token, int estateId) async {
    final url = '$baseUrl/download-estate-pdf/$estateId/';
    return await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );
  }

  Future<Map<String, dynamic>> getEstatePlot({
    required String estateId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/estates/$estateId/plot/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to load estate plot. Status: ${response.statusCode}');
    }
  }

  Future<void> updateEstatePlot({
    required String estateId,
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/estates/$estateId/plot/');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update estate plot: ${response.body}');
    }
  }

  Future<void> updateAllocatedPlot(
      String id, Map<String, dynamic> data, String token) async {
    final url = Uri.parse('$baseUrl/update-allocated-plot/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update allocation: ${response.body}');
    }
  }

  final Dio _dio = Dio();
  Future<void> uploadEstateLayout({
    required String estateId,
    required File layoutImage,
    required String token,
  }) async {
    try {
      final formData = FormData.fromMap({
        'estate': estateId,
        'layout_image': await MultipartFile.fromFile(layoutImage.path),
      });

      final response = await _dio.post(
        '$baseUrl/upload-estate-layout/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Token $token'},
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to upload layout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  // get-plot-sizes
  Future<List<PlotSize>> getPlotSizesForEstate({
    required String estateId,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/get-plot-sizes/$estateId/',
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      if (response.statusCode == 200) {
        final data = response.data as List;
        // Convert each dynamic json map into a PlotSize instance
        return data
            .map((json) =>
                PlotSize(id: json['id'].toString(), size: json['size']))
            .toList();
      } else {
        throw Exception('Failed to load plot sizes');
      }
    } catch (e) {
      throw Exception('Error fetching plot sizes: $e');
    }
  }

  /// Upload prototype
  Future<void> uploadEstatePrototype({
    required String estateId,
    required String plotSizeId,
    required File prototypeImage,
    required String title,
    required String description,
    required String token,
  }) async {
    try {
      final formData = FormData.fromMap({
        'estate': estateId,
        'plot_size': plotSizeId,
        'prototype_image': await MultipartFile.fromFile(prototypeImage.path),
        'Title': title,
        'Description': description,
      });

      final response = await _dio.post(
        '$baseUrl/upload-prototype/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Token $token'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to upload prototype: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Uploads a floor plan via the Django API.
  Future<void> uploadFloorPlan({
    required String estateId,
    required String plotSizeId,
    required File floorPlanImage,
    required String planTitle,
    String? description,
    required String token,
  }) async {
    final formData = FormData.fromMap({
      'estate': estateId,
      'plot_size': plotSizeId,
      'floor_plan_image': await MultipartFile.fromFile(floorPlanImage.path),
      'plan_title': planTitle,
      if (description != null && description.isNotEmpty)
        'description': description,
    });

    final response = await _dio.post(
      '$baseUrl/upload-floor-plan/',
      data: formData,
      options: Options(headers: {'Authorization': 'Token $token'}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to upload floor plan: ${response.statusCode}');
    }
  }

  /// Update estate amenities via the Django API
  Future<void> updateEstateAmenities({
    required String estateId,
    required List<String> amenities,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-estate-amenities/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'estate': estateId,
        'amenities': amenities,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update amenities: ${response.statusCode}');
    }
  }

  /// Fetch available amenities from the API
  Future<List<dynamic>> getAvailableAmenities(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get-available-amenities/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load amenities: ${response.statusCode}');
    }
  }

  /// Updates the work progress for the estate
  Future<void> updateWorkProgress({
    required String estateId,
    required String progressStatus,
    required String token,
  }) async {
    final response = await _dio.post(
      '$baseUrl/update-work-progress/$estateId/',
      data: {'progress_status': progressStatus},
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to update progress: ${response.statusCode}');
    }
  }

  /// Fetches the current estate map data using a GET request.
  Future<Map<String, dynamic>?> getEstateMap({
    required String estateId,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/update-estate-map/$estateId/',
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load map data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the estate map with new data using a POST request.
  Future<void> updateEstateMap({
    required String estateId,
    required String latitude,
    required String longitude,
    String? googleMapLink,
    required String token,
  }) async {
    final data = {
      'latitude': latitude,
      'longitude': longitude,
      if (googleMapLink != null) 'google_map_link': googleMapLink,
    };
    try {
      final response = await _dio.post(
        '$baseUrl/update-estate-map/$estateId/',
        data: data,
        options: Options(headers: {'Authorization': 'Token $token'}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update map: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Estate Details
  Future<Estate> getEstateDetails(String estateId, String token) async {
    final url = Uri.parse('$baseUrl/estate-details/$estateId/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Estate.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      throw Exception('Estate not found');
    } else {
      throw Exception('Failed to load estate details: ${response.statusCode}');
    }
  }

  ////// ADD ESTATE PLOTS

  /// Fetch the list of all estates.
  Future<List<Map<String, dynamic>>> fetchEstates(
      {required String token}) async {
    final url = Uri.parse('$baseUrl/estates/');
    final response = await http.get(url, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Could not fetch estates. Please try again.");
    }
  }

  // Update/Edit Estate
  Future<void> updateEstate({
    required String token,
    required String estateId,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/estates/$estateId/');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update estate. Status code: ${response.statusCode}');
    }
  }

  /// Fetch details for Add Estate Plot for a given estate.
  Future<EstatePlotDetails> fetchAddEstatePlotDetails({
    required int estateId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/get-add-estate-plot-details/$estateId/');
    final response = await http.get(url, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return EstatePlotDetails.fromJson(data);
    } else {
      throw Exception(
          "Could not retrieve plot details. Please try again later.");
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    try {
      final responseBody = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        final errorData =
            responseBody is Map ? responseBody : {'message': response.body};
        throw ApiException(
          message: errorData['message']?.toString() ?? 'An error occurred',
          details: errorData['details']?.toString() ??
              errorData['error']?.toString() ??
              'Please try again later',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException(
        message: 'Failed to process response',
        details: e.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> submitEstatePlot({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/add-estate-plot/');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error',
        details: e.message,
        statusCode: 0,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error',
        details: e.toString(),
        statusCode: 0,
      );
    }
  }

// PLOT ALLOCATION
  Future<List<ClientForPlotAllocation>> fetchClientsForPlotAllocation(
      String token) async {
    final url = Uri.parse('$baseUrl/clients/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((e) =>
              ClientForPlotAllocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load clients (${response.statusCode})');
    }
  }

  Future<List<EstateForPlotAllocation>> fetchEstatesForPlotAllocation(
      String token) async {
    final url = Uri.parse('$baseUrl/estates/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data
          .map((e) =>
              EstateForPlotAllocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load estates (${response.statusCode})');
    }
  }

  Future<PlotAllocationResponse> loadPlotsForPlotAllocation(
      int estateId, String token) async {
    final url = Uri.parse(
        '$baseUrl/load-plots-for-plot-allocation/?estate_id=$estateId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PlotAllocationResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Bad request');
      } else if (response.statusCode == 404) {
        throw Exception('Estate not found');
      } else {
        throw Exception('Failed to load plots (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createAllocation({
    required int clientId,
    required int estateId,
    required int plotSizeUnitId,
    int? plotNumberId,
    required String paymentType,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/update-allocation/');

    final body = {
      'client_id': clientId,
      'estate_id': estateId,
      'plot_size_unit_id': plotSizeUnitId,
      'payment_type': paymentType,
      if (paymentType == 'full') 'plot_number_id': plotNumberId!,
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final err =
          data['errors'] ?? data['message'] ?? 'Failed to allocate plot';
      throw Exception(err.toString());
    }
  }

  //? ADD ESTATE
  Future<Map<String, dynamic>> addEstate({
    required String token,
    required String estateName,
    required String location,
    required String estateSize,
    required String titleDeed,
  }) async {
    final url = Uri.parse('$baseUrl/add-estate/');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // These keys must match your Django EstateSerializer fields:
        'name': estateName,
        'location': location,
        'estate_size': estateSize,
        'title_deed': titleDeed,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Estate added successfully.'};
    } else {
      try {
        final data = jsonDecode(response.body);
        // serializer errors come back under 'error'
        final err = data['error'] ?? data;
        return {'success': false, 'message': err.toString()};
      } catch (_) {
        return {'success': false, 'message': 'Unknown error occurred.'};
      }
    }
  }

  // ---------------- PLOT SIZE METHODS ----------------

  Future<List<AddPlotSize>> fetchPlotSizes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/plot-sizes/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((e) => AddPlotSize.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load plot sizes: ${response.statusCode}');
    }
  }

  Future<AddPlotSize> createPlotSize(String size, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/plot-sizes/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'size': size}),
    );

    if (response.statusCode == 201) {
      return AddPlotSize.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create plot size: ${response.statusCode}');
    }
  }

  Future<void> deletePlotSize(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/plot-sizes/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete plot size: ${response.statusCode}');
    }
  }

  Future<void> updatePlotSize(int id, String newSize, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/plot-sizes/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'size': newSize}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update plot size: ${response.statusCode}');
    }
  }

  // ---------------- PLOT NUMBER METHODS ----------------

  // Plot Numbers API Calls
  Future<List<AddPlotNumber>> fetchPlotNumbers(String token,
      {int page = 1, int perPage = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/plot-numbers/?page=$page&per_page=$perPage'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((e) => AddPlotNumber.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load plot numbers: ${response.statusCode}');
    }
  }

  Future<AddPlotNumber> createPlotNumber(String number, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/plot-numbers/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'number': number}),
    );

    if (response.statusCode == 201) {
      return AddPlotNumber.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create plot number: ${response.statusCode}');
    }
  }

  Future<void> deletePlotNumber(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/plot-numbers/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete plot number: ${response.statusCode}');
    }
  }

  Future<void> updatePlotNumber(int id, String newNumber, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/plot-numbers/$id/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'number': newNumber}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update plot number: ${response.statusCode}');
    }
  }

  // ADMIN CLIENT CHAT LIST
  Future<List<Chat>> fetchClientChats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/client-chats/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          if (kDebugMode) {
            print('No chats available');
          }
          return [];
        }
        return data.map((chatJson) => Chat.fromJson(chatJson)).toList();
      } else {
        final errorMsg =
            'Failed to load client chats: ${response.statusCode} - ${response.body}';
        if (kDebugMode) {
          print(errorMsg);
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching chats: $e');
      }
      rethrow;
    }
  }


  Future<List<Message>> fetchChatThread(String token, String clientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client-chats/$clientId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((msgJson) => Message.fromJson(msgJson)).toList();
    } else {
      throw Exception('Failed to load thread: ${response.statusCode}');
    }
  }


  Future<Message> sendAdminMessage({
    required String token,
    required String clientId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/client-chats/$clientId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'content': content, 'message_type': 'enquiry'}),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  requestPasswordReset(String mail) {}


  // CLIENT SIDE

  /// Estate plot details Views
  Future<Map<String, dynamic>> fetchClientEstatePlotDetail({
    required int estateId,
    required String token,
    int? plotSizeId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final clientPath = Uri.parse('$baseUrl/clients/estates/$estateId/')
        .replace(queryParameters: plotSizeId != null ? {'plot_size': plotSizeId.toString()} : null);
    final canonicalPath = Uri.parse('$baseUrl/estates/$estateId/')
        .replace(queryParameters: plotSizeId != null ? {'plot_size': plotSizeId.toString()} : null);

    Future<http.Response> _get(Uri uri) {
      return http.get(uri, headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }).timeout(timeout);
    }

    http.Response resp;
    try {
      resp = await _get(clientPath);
      if (resp.statusCode == 404) {
        // try canonical
        resp = await _get(canonicalPath);
      }
    } on Exception {
      // network/timeout -> rethrow to be handled by callers
      rethrow;
    }

    // now handle resp as you already do: check status codes, decode, normalize, etc.
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
      // (run your normalize steps here)
      return data;
    }

    // existing error handling...
    switch (resp.statusCode) {
      case 404:
        throw Exception('Estate not found (404).');
      case 401:
        throw Exception('Authentication failed. Please re-login (401).');
      case 403:
        throw Exception('Permission denied (403).');
      case 500:
        throw Exception('Server error (500). Try again later.');
      default:
        throw Exception('Failed to load estate detail: ${resp.statusCode} - ${resp.body}');
    }
  }

  // PROFILE METHODS
  Future<Map<String, dynamic>> getClientDetailByToken({
    required String token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/profile/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;

      // --- normalize top-level profile_image to absolute URL ---
      final img = data['profile_image'];
      if (img != null && img is String && img.isNotEmpty && !img.startsWith('http')) {
        final prefix = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
        data['profile_image'] = '$prefix$img';
      }

      // --- normalize assigned_marketer into Map<String, dynamic>? with safe keys ---
      final amRaw = data['assigned_marketer'];
      if (amRaw == null) {
        data['assigned_marketer'] = null;
      } else {
        Map<String, dynamic> am;
        if (amRaw is Map<String, dynamic>) {
          am = Map<String, dynamic>.from(amRaw);
        } else if (amRaw is Map) {
          am = Map<String, dynamic>.from(amRaw.map((k, v) => MapEntry(k.toString(), v)));
        } else {
          // unexpected shape -> null
          data['assigned_marketer'] = null;
          return data;
        }

        // normalize name keys
        am['full_name'] = (am['full_name']?.toString().isNotEmpty == true)
            ? am['full_name'].toString()
            : (am['name']?.toString() ?? '');

        String? marketerImage;
        if (am['profile_image'] is String && (am['profile_image'] as String).isNotEmpty) {
          marketerImage = am['profile_image'] as String;
        } else if (am['avatar'] is String && (am['avatar'] as String).isNotEmpty) {
          marketerImage = am['avatar'] as String;
        } else if (am['image'] is String && (am['image'] as String).isNotEmpty) {
          marketerImage = am['image'] as String;
        }

        if (marketerImage != null && !marketerImage.startsWith('http')) {
          final prefix = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
          marketerImage = '$prefix$marketerImage';
        }
        am['profile_image'] = marketerImage;

        // ensure phone/email are string or null
        am['phone'] = am['phone']?.toString();
        am['email'] = am['email']?.toString();

        data['assigned_marketer'] = am;
      }

      return data;
    }

    String msg = 'Failed to load profile: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<Map<String, dynamic>> updateClientProfileByToken({
    required String token,
    String? fullName,
    String? about,
    String? company,
    String? job,
    String? country,
    String? address,
    String? phone,
    String? email,
    File? profileImage,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/profile/update/');
    final request = http.MultipartRequest('POST', uri);

    // Headers (MultipartRequest sets content-type for multipart)
    request.headers['Authorization'] = 'Token $token';
    request.headers['Accept'] = 'application/json';

    if (fullName != null) request.fields['full_name'] = fullName;
    if (about != null) request.fields['about'] = about;
    if (company != null) request.fields['company'] = company;
    if (job != null) request.fields['job'] = job;
    if (country != null) request.fields['country'] = country;
    if (address != null) request.fields['address'] = address;
    if (phone != null) request.fields['phone'] = phone;
    if (email != null) request.fields['email'] = email;

    if (profileImage != null) {
      final mimeType = lookupMimeType(profileImage.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      final multipartFile = await http.MultipartFile.fromPath(
        'profile_image',
        profileImage.path,
        contentType: MediaType(parts[0], parts[1]),
      );
      request.files.add(multipartFile);
    }

    final streamed = await request.send().timeout(timeout);
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // Return parsed response as map (or empty map if no body)
      if (resp.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // attempt to use server message
    String msg = 'Failed to update profile: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<dynamic> getValueAppreciation({
    required String token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/appreciation/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      // Accept List or Map (or null/empty)
      return decoded;
    }

    String msg = 'Failed to load appreciation: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<List<dynamic>> getClientProperties({
    required String token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/properties/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final alt = decoded['transactions'] ?? decoded['results'] ?? decoded['data'] ?? decoded['items'];
        if (alt is List) return alt;
      }
      // fallback: wrap single object in a list
      return decoded is Map ? [decoded] : <dynamic>[];
    }

    String msg = 'Failed to load properties: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<List<dynamic>> getClientTransactions({
    required String token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/transactions/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        final alt = decoded['transactions'] ?? decoded['results'] ?? decoded['data'] ?? decoded['items'];
        if (alt is List) return alt;
      }
      return decoded is Map ? [decoded] : <dynamic>[];
    }

    String msg = 'Failed to load transactions: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<void> changePasswordByToken({
    required String token,
    required String currentPassword,
    required String newPassword,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/change-password/');

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    ).timeout(timeout);

    if (resp.statusCode == 200 || resp.statusCode == 204) return;

    String message = 'Failed to change password: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) message = j['detail'].toString();
    } catch (_) {}
    throw Exception('$message ${resp.body}');
  }

  Future<Map<String, dynamic>> getTransactionDetail({
    required String token,
    required int transactionId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/transaction/$transactionId/details/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    String msg = 'Failed to load transaction: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<List<dynamic>> getTransactionPayments({
    required String token,
    required int transactionId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/transaction/payments/?transaction_id=$transactionId');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(resp.body) as Map<String, dynamic>;
      return (body['payments'] as List<dynamic>) ;
    }

    String msg = 'Failed to load payments: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }



  Future<List<dynamic>> fetchTransactionPaymentsApi({
    required String token,
    required int transactionId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/clients/transaction/payments/')
        .replace(queryParameters: {'transaction_id': transactionId.toString()});

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      },
    ).timeout(timeout);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(resp.body) as Map<String, dynamic>;
      final payments = body['payments'] as List<dynamic>? ?? <dynamic>[];
      return payments;
    }

    String msg = 'Failed to load payments: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }



  Future<File> downloadReceiptByReference({
    required String token,
    required String reference,
    void Function(int, int)? onProgress,
    bool openAfterDownload = true,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final safeRef = Uri.encodeComponent(reference);
    // Remove '/clients' from the URL
    final url = '$base/payment/receipt/$safeRef/';

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/receipt_$safeRef.pdf';
    final file = File(filePath);

    try {
      final resp = await _dio.get<List<int>>(
        url,
        options: Options(
          headers: {'Authorization': 'Token $token'},
          responseType: ResponseType.bytes,
          validateStatus: (s) => s != null && s < 500,
        ),
        onReceiveProgress: (rec, total) {
          if (onProgress != null) onProgress(rec, total);
        },
      ).timeout(timeout);

      final status = resp.statusCode ?? 0;
      if (status == 200 && resp.data != null && resp.data!.isNotEmpty) {
        await file.writeAsBytes(resp.data!, flush: true);
        if (openAfterDownload) await OpenFile.open(file.path);
        return file;
      } else if (status == 403) {
        throw Exception('Forbidden: you are not allowed to access this receipt (403)');
      } else if (status == 404) {
        throw Exception('Receipt not found (404)');
      } else {
        final text = resp.data != null ? String.fromCharCodes(resp.data!) : '';
        throw Exception('Failed to download (status: $status) $text');
      }
    } on DioError catch (e) {
      throw Exception('Network/download error: ${e.message}');
    }
  }

  Future<File> downloadReceiptByTransactionId({
    required String token,
    required int transactionId,
    void Function(int, int)? onProgress,
    bool openAfterDownload = true,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    // Remove '/clients' from the URL
    final url = '$base/transaction/$transactionId/receipt/';

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/receipt_txn_$transactionId.pdf';
    final file = File(filePath);

    try {
      final resp = await _dio.get<List<int>>(
        url,
        options: Options(
          headers: {'Authorization': 'Token $token'},
          responseType: ResponseType.bytes,
          validateStatus: (s) => s != null && s < 500,
        ),
        onReceiveProgress: (rec, total) {
          if (onProgress != null) onProgress(rec, total);
        },
      ).timeout(timeout);

      final status = resp.statusCode ?? 0;
      if (status == 200 && resp.data != null && resp.data!.isNotEmpty) {
        await file.writeAsBytes(resp.data!, flush: true);
        if (openAfterDownload) await OpenFile.open(file.path);
        return file;
      } else if (status == 403) {
        throw Exception('Forbidden: you are not allowed to access this receipt (403)');
      } else if (status == 404) {
        throw Exception('Receipt not found (404)');
      } else {
        final text = resp.data != null ? String.fromCharCodes(resp.data!) : '';
        throw Exception('Failed to download (status: $status) $text');
      }
    } on DioError catch (e) {
      throw Exception('Network/download error: ${e.message}');
    }
  }
  
  
  // Future<File> downloadReceiptByReference({
  //     required String token,
  //     required String reference,
  //     void Function(int, int)? onProgress,
  //     bool openAfterDownload = true,
  //     Duration timeout = const Duration(seconds: 60),
  //   }) async {
  //     final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  //     final safeRef = Uri.encodeComponent(reference);
  //     final url = '$base/clients/payment/receipt/$safeRef/';

  //     final dir = await getTemporaryDirectory();
  //     final filePath = '${dir.path}/receipt_$safeRef.pdf';
  //     final file = File(filePath);

  //     try {
  //       final resp = await _dio.get<List<int>>(
  //         url,
  //         options: Options(
  //           headers: {'Authorization': 'Token $token'},
  //           responseType: ResponseType.bytes,
  //           validateStatus: (s) => s != null && s < 500,
  //         ),
  //         onReceiveProgress: (rec, total) {
  //           if (onProgress != null) onProgress(rec, total);
  //         },
  //       ).timeout(timeout);

  //       final status = resp.statusCode ?? 0;
  //       if (status == 200 && resp.data != null && resp.data!.isNotEmpty) {
  //         await file.writeAsBytes(resp.data!, flush: true);
  //         if (openAfterDownload) await OpenFile.open(file.path);
  //         return file;
  //       } else if (status == 403) {
  //         throw Exception('Forbidden: you are not allowed to access this receipt (403)');
  //       } else if (status == 404) {
  //         throw Exception('Receipt not found (404)');
  //       } else {
  //         final text = resp.data != null ? String.fromCharCodes(resp.data!) : '';
  //         throw Exception('Failed to download (status: $status) $text');
  //       }
  //     } on DioError catch (e) {
  //       throw Exception('Network/download error: ${e.message}');
  //     }
  //   }

  // Future<File> downloadReceiptByTransactionId({
  //   required String token,
  //   required int transactionId,
  //   void Function(int, int)? onProgress,
  //   bool openAfterDownload = true,
  //   Duration timeout = const Duration(seconds: 60),
  // }) async {
  //   final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  //   final url = '$base/clients/transaction/$transactionId/receipt/';

  //   final dir = await getTemporaryDirectory();
  //   final filePath = '${dir.path}/receipt_txn_$transactionId.pdf';
  //   final file = File(filePath);

  //   try {
  //     final resp = await _dio.get<List<int>>(
  //       url,
  //       options: Options(
  //         headers: {'Authorization': 'Token $token'},
  //         responseType: ResponseType.bytes,
  //         validateStatus: (s) => s != null && s < 500,
  //       ),
  //       onReceiveProgress: (rec, total) {
  //         if (onProgress != null) onProgress(rec, total);
  //       },
  //     ).timeout(timeout);

  //     final status = resp.statusCode ?? 0;
  //     if (status == 200 && resp.data != null && resp.data!.isNotEmpty) {
  //       await file.writeAsBytes(resp.data!, flush: true);
  //       if (openAfterDownload) await OpenFile.open(file.path);
  //       return file;
  //     } else if (status == 403) {
  //       throw Exception('Forbidden: you are not allowed to access this receipt (403)');
  //     } else if (status == 404) {
  //       throw Exception('Receipt not found (404)');
  //     } else {
  //       final text = resp.data != null ? String.fromCharCodes(resp.data!) : '';
  //       throw Exception('Failed to download (status: $status) $text');
  //     }
  //   } on DioError catch (e) {
  //     throw Exception('Network/download error: ${e.message}');
  //   }
  // }

  // NOTIFICATIONS
  Future<List<dynamic>> getNotifications({
    required String token,
    bool? read,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final qp = <String, String>{};
    if (read != null) qp['read'] = read ? 'true' : 'false';

    final uri = Uri.parse('$baseUrl/client/notifications/${qp.isNotEmpty ? '?${Uri(queryParameters: qp).query}' : ''}');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body);
      List<dynamic> items = [];

      // Handle common DRF shapes
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['results'] is List) {
          items = decoded['results'];
        } else if (decoded['data'] is List) {
          items = decoded['data'];
        } else if (decoded['notifications'] is List) {
          items = decoded['notifications'];
        } else {
          // sometimes API returns single object -> wrap if it looks like a notification
          // but prefer returning empty list to avoid surprises
          items = <dynamic>[];
        }
      }

      // Normalize each item to a safe Map<String,dynamic>
      final normalized = items.map((e) {
        if (e is Map<String, dynamic>) {
          return _normalizeUserNotificationMap(Map<String, dynamic>.from(e));
        }
        // try to convert Map-like objects
        if (e is Map) {
          return _normalizeUserNotificationMap(Map<String, dynamic>.from(e.map((k, v) => MapEntry(k.toString(), v))));
        }
        return e;
      }).toList();

      return normalized;
    }

    String msg = 'Failed to load notifications: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Future<Map<String, dynamic>> getNotificationDetail({
    required String token,
    required int id,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/client/notifications/$id/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
      return _normalizeUserNotificationMap(Map<String, dynamic>.from(data));
    }

    String msg = 'Failed to load notification detail: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }


  Future<Map<String, dynamic>> markNotificationRead({
    required String token,
    required int id,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/client/notifications/$id/mark-read/');

    final resp = await http.post(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    String msg = 'Failed to mark notification read: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }


  Future<Map<String, int>> getNotificationStats({
    required String token,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = Uri.parse('$baseUrl/client/notifications/stats/');

    final resp = await http.get(uri, headers: {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    }).timeout(timeout);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
      final unread = data['unread'];
      final read = data['read'];
      return {
        'unread': (unread is int) ? unread : int.tryParse('$unread') ?? 0,
        'read': (read is int) ? read : int.tryParse('$read') ?? 0,
      };
    }

    String msg = 'Failed to load notification stats: ${resp.statusCode}';
    try {
      final j = jsonDecode(resp.body);
      if (j is Map && j['detail'] != null) msg = j['detail'].toString();
    } catch (_) {}
    throw Exception('$msg ${resp.body}');
  }

  Map<String, dynamic> _normalizeUserNotificationMap(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);

    if (m.containsKey('notification') && m['notification'] is Map) {
      final n = Map<String, dynamic>.from(m['notification'] as Map);
      n['title'] = n['title']?.toString() ?? (m['title']?.toString() ?? '');
      n['message'] = n['message']?.toString() ?? (m['message']?.toString() ?? '');
      n['created_at'] = n['created_at']?.toString() ?? (m['created_at']?.toString() ?? '');
      n['notification_type'] = n['notification_type'] ?? n['type'] ?? m['notification_type'] ?? m['type'];
      m['notification'] = n;
    } else {
      // Build fallback nested notification if API returned flattened fields
      m['notification'] = <String, dynamic>{
        'id': m['notification_id'] ?? m['id'],
        'title': m['title']?.toString() ?? '',
        'message': m['message']?.toString() ?? '',
        'created_at': m['created_at']?.toString() ?? '',
        'notification_type': m['notification_type'] ?? m['type'],
      };
    }

    // Normalize 'read' to boolean
    final r = m['read'];
    if (r is bool) {
      // nothing to do
    } else if (r is String) {
      m['read'] = r.toLowerCase() == 'true';
    } else if (r is num) {
      m['read'] = r != 0;
    } else {
      m['read'] = false;
    }

    // Normalize any image fields inside nested notification (optional)
    try {
      final notif = m['notification'] as Map<String, dynamic>;
      for (final k in ['profile_image', 'image', 'floor_plan_image', 'prototype_image']) {
        if (notif.containsKey(k) && notif[k] is String) {
          final s = notif[k] as String;
          if (s.isNotEmpty && !s.startsWith('http')) {
            final prefix = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
            notif[k] = '$prefix$s';
          }
        }
      }
      m['notification'] = notif;
    } catch (_) {}

    return m;
  }


}
