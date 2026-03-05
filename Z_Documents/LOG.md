flutter: supabase.supabase_flutter: INFO: ***** Supabase init completed *****
flutter: error DatabaseException(Error Domain=SqfliteDarwinDatabase Code=1 "duplicate column name: subscription_expires_at" UserInfo={NSLocalizedDescription=duplicate column name: subscription_expires_at}) sql 'ALTER TABLE settings ADD COLUMN subscription_expires_at INTEGER' args [] during open, closing...
flutter: error DatabaseException(Error Domain=SqfliteDarwinDatabase Code=1 "duplicate column name: subscription_expires_at" UserInfo={NSLocalizedDescription=duplicate column name: subscription_expires_at}) sql 'ALTER TABLE settings ADD COLUMN subscription_expires_at INTEGER' args [] during open, closing...
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: DatabaseException(Error Domain=SqfliteDarwinDatabase Code=1 "duplicate column name: subscription_expires_at" UserInfo={NSLocalizedDescription=duplicate column name: subscription_expires_at}) sql 'ALTER TABLE settings ADD COLUMN subscription_expires_at INTEGER' args []
#0      wrapDatabaseException (package:sqflite_platform_interface/src/platform_exception.dart:12:7)
<asynchronous suspension>
#1      SqfliteDatabaseMixin.txnSynchronized (package:sqflite_common/src/database_mixin.dart:554:16)
<asynchronous suspension>
#2      DatabaseHelper._migrateToVersion15 (package:fitness_log_app/data/database/database_helper.dart:325:5)
<asynchronous suspension>
#3      DatabaseHelper._onUpgrade (package:fitness_log_app/data/database/database_helper.dart:319:7)
<asynchronous suspension>
#4      SqfliteDatabaseMixin.doOpen.<anonymous closure> (package:sqflite_common/src/database_mixin.dart:1143:19)
<asynchronous suspension>
#5      SqfliteData<…>
-[WFIsolatedShortcutRunner init] Taking sandbox extensions for execution
-[WFIsolatedShortcutRunner init]_block_invoke Sandbox extensions acquired
Indexing for request: <WFToolKitIndexingRequest: 0x600001703b00>, changeset: .partial(updatedCount: 1 removedCount: 0 updated: ["com.fitnesslog.fitnessLogApp"], removed: []), priority: 31
Resolved Preferred localizations: [BackgroundShortcutRunner.ToolKitIndexer.(unknown context at $100242284).(unknown context at $10024228c).LocaleWithUsage(locale: en (fixed en), usage: __C.WFLocalizationUsage(_rawValue: display), preferenceOrder: 0), BackgroundShortcutRunner.ToolKitIndexer.(unknown context at $100242284).(unknown context at $10024228c).LocaleWithUsage(locale: ja (fixed ja), usage: __C.WFLocalizationUsage(_rawValue: display), preferenceOrder: 0), BackgroundShortcutRunner.ToolKitIndexer.(unknown context at $100242284).(unknown context at $10024228c).LocaleWithUsage(locale: en (fixed en), usage: __C.WFLocalizationUsage(_rawValue: languageModel), preferenceOrder: 1)]
Indexed: 0
Errored: 0
Skipped: [:]
Finished in 1.592545s
-[WFIsolatedShortcutRunner unaliveProcess] Releasing sandbox extensions
Syncing files to device iPhone 17 Pro...                         2,746ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on iPhone 17 Pro is available at: http://127.0.0.1:63949/qUjwSYKE7Vo=/
The Flutter DevTools debugger and profiler on iPhone 17 Pro is available at:
http://127.0.0.1:63949/qUjwSYKE7Vo=/devtools/?uri=ws://127.0.0.1:63949/qUjwSYKE7Vo=/ws
flutter: error DatabaseException(Error Domain=SqfliteDarwinDatabase Code=1 "duplicate column name: subscription_expires_at" UserInfo={NSLocalizedDescription=duplicate column name: subscription_expires_at}) sql 'ALTER TABLE settings ADD COLUMN subscription_expires_at INTEGER' args [] during open, closing...
flutter: error DatabaseException(Error Domain=SqfliteDarwinDatabase Code=1 "duplicate column name: subscription_expires_at" UserInfo={NSLocalizedDescription=duplicate column name: subscription_expires_at}) sql 'ALTER TABLE settings ADD COLUMN subscription_expires_at INTEGER' args [] during open, closing...