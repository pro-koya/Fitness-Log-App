-- Pro 同期用 Supabase スキーマ
-- Supabase ダッシュボードの SQL Editor で実行してください。
-- 接続情報は lib/core/supabase_config.dart に設定してください。

-- exercise_master (種目マスタ)
CREATE TABLE IF NOT EXISTS exercise_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  body_part TEXT,
  is_custom INTEGER NOT NULL DEFAULT 0,
  record_type TEXT NOT NULL DEFAULT 'reps',
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
ALTER TABLE exercise_master ENABLE ROW LEVEL SECURITY;
CREATE POLICY "exercise_master_user" ON exercise_master
  FOR ALL USING (auth.uid() = user_id);

-- workout_sessions (ワークアウトセッション)
CREATE TABLE IF NOT EXISTS workout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed')),
  started_at BIGINT NOT NULL,
  completed_at BIGINT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "workout_sessions_user" ON workout_sessions
  FOR ALL USING (auth.uid() = user_id);

-- workout_exercises (セッション内種目)
CREATE TABLE IF NOT EXISTS workout_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercise_master(id),
  order_index INTEGER NOT NULL,
  memo TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "workout_exercises_user" ON workout_exercises
  FOR ALL USING (auth.uid() = user_id);

-- set_records (セット記録)
CREATE TABLE IF NOT EXISTS set_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercise_master(id),
  set_number INTEGER NOT NULL,
  weight_kg REAL NOT NULL,
  weight_lb REAL NOT NULL,
  reps INTEGER,
  duration_seconds INTEGER,
  distance_meters REAL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
ALTER TABLE set_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "set_records_user" ON set_records
  FOR ALL USING (auth.uid() = user_id);

-- exercise_goals (種目別目標・Pro)
CREATE TABLE IF NOT EXISTS exercise_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercise_master(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('weight', 'reps', 'volume', 'time', 'distance')),
  goal_value REAL NOT NULL,
  deadline_ts BIGINT,
  priority INTEGER NOT NULL DEFAULT 2,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
ALTER TABLE exercise_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "exercise_goals_user" ON exercise_goals
  FOR ALL USING (auth.uid() = user_id);

-- body_weight_records (体重記録)
CREATE TABLE IF NOT EXISTS body_weight_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_kg REAL NOT NULL,
  weight_lb REAL NOT NULL,
  memo TEXT,
  recorded_at BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);
ALTER TABLE body_weight_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "body_weight_records_user" ON body_weight_records
  FOR ALL USING (auth.uid() = user_id);
