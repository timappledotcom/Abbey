import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';

part 'flow_repository.g.dart';

@riverpod
FlowRepository flowRepository(Ref ref) {
  return FlowRepository(ref.watch(appDatabaseProvider));
}

class FlowRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  FlowRepository(this._db);

  Future<Essay> getOrCreateFlowEssay() async {
    // 1. Check if a Flow Essay already exists
    final existingEssay =
        await (_db.select(_db.essays)
              ..where((tbl) => tbl.isFlow.equals(true))
              ..limit(1))
            .getSingleOrNull();

    if (existingEssay != null) {
      return existingEssay;
    }

    // 2. If not, create the hierarchy (Project -> Chapter -> Essay)
    return _db.transaction(() async {
      // Check/Create System Project
      final projectId = 'system-flow-project';
      final projectExists = await (_db.select(
        _db.projects,
      )..where((tbl) => tbl.id.equals(projectId))).getSingleOrNull();

      if (projectExists == null) {
        await _db
            .into(_db.projects)
            .insert(
              ProjectsCompanion(
                id: Value(projectId),
                title: const Value('System'),
                description: const Value('Internal system project'),
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }

      // Check/Create Flow Chapter
      final chapterId = 'system-flow-chapter';
      final chapterExists = await (_db.select(
        _db.chapters,
      )..where((tbl) => tbl.id.equals(chapterId))).getSingleOrNull();

      if (chapterExists == null) {
        await _db
            .into(_db.chapters)
            .insert(
              ChaptersCompanion(
                id: Value(chapterId),
                projectId: Value(projectId),
                title: const Value('Flow Journal'),
                orderIndex: const Value(0),
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );
      }

      // Create Flow Essay
      final essayId = _uuid.v4();
      final essay = EssaysCompanion(
        id: Value(essayId),
        chapterId: Value(chapterId),
        title: const Value('Flow Stream'),
        content: const Value(''),
        orderIndex: const Value(0),
        isFlow: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      await _db.into(_db.essays).insert(essay);

      return await (_db.select(
        _db.essays,
      )..where((tbl) => tbl.id.equals(essayId))).getSingle();
    });
  }

  Future<void> updateFlowContent(String id, String content) async {
    await (_db.update(_db.essays)..where((tbl) => tbl.id.equals(id))).write(
      EssaysCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update the flow essay content directly
  Future<void> updateFlowEssay(String content) async {
    final essay = await getOrCreateFlowEssay();
    await updateFlowContent(essay.id, content);
  }
}
