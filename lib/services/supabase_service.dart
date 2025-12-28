import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _tableName = 'led_status';
  static const int _rowId = 1; // bigint primary key

  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Read LED values from Supabase
  /// Returns: {'led1': 'red'|'blue'|'off', 'led2': 'red'|'blue'|'off'}
  Future<Map<String, String>> getLedValues() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', _rowId)
          .single();

      return {
        'led1': response['led1'] as String? ?? 'off',
        'led2': response['led2'] as String? ?? 'off',
      };
    } catch (e) {
      print('Error reading LED values: $e');
      return {
        'led1': 'off',
        'led2': 'off',
      };
    }
  }

  /// Update LED1 value
  /// value: 'red', 'blue', or 'off'
  Future<bool> updateLed1(String value) async {
    try {
      if (!['red', 'blue', 'off'].contains(value)) {
        print('Invalid LED1 value: $value');
        return false;
      }
      await _client.from(_tableName).update({'led1': value}).eq('id', _rowId);
      return true;
    } catch (e) {
      print('Error updating LED1: $e');
      return false;
    }
  }

  /// Update LED2 value
  /// value: 'red', 'blue', or 'off'
  Future<bool> updateLed2(String value) async {
    try {
      if (!['red', 'blue', 'off'].contains(value)) {
        print('Invalid LED2 value: $value');
        return false;
      }
      await _client.from(_tableName).update({'led2': value}).eq('id', _rowId);
      return true;
    } catch (e) {
      print('Error updating LED2: $e');
      return false;
    }
  }

  /// Update both LED values at once
  /// led1, led2: 'red', 'blue', or 'off'
  Future<bool> updateLeds({required String led1, required String led2}) async {
    try {
      if (!['red', 'blue', 'off'].contains(led1) ||
          !['red', 'blue', 'off'].contains(led2)) {
        print('Invalid LED values: led1=$led1, led2=$led2');
        return false;
      }
      await _client
          .from(_tableName)
          .update({'led1': led1, 'led2': led2})
          .eq('id', _rowId);
      return true;
    } catch (e) {
      print('Error updating LEDs: $e');
      return false;
    }
  }
}
