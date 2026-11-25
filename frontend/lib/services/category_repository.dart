import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<CategoryModel>> fetchAll() async {
    try {
      final rows = await _db.from('categories').select().order('created_at');
      return rows.map((r) => CategoryModel.fromJson(r)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<CategoryModel> add(String name, Color color) async {
    try {
      final row = await _db
          .from('categories')
          .insert({
            'name': name.trim(),
            'color': CategoryModel.colorToHex(color),
          })
          .select()
          .single();
      return CategoryModel.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Danh mục này đã tồn tại!');
      }
      throw Exception(e.message);
    }
  }

  Future<void> setVisible(String id, bool isVisible) async {
    try {
      await _db.from('categories').update({'is_visible': isVisible}).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> showAll() async {
    try {
      // Phải có điều kiện lọc: Supabase chặn UPDATE không có WHERE
      await _db
          .from('categories')
          .update({'is_visible': true})
          .eq('is_visible', false);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
