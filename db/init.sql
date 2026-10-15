
CREATE TABLE IF NOT EXISTS tasks (
  id         SERIAL PRIMARY KEY,
  title      TEXT NOT NULL,
  done       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS id INTEGER,
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS done BOOLEAN,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'tasks'
      AND column_name = 'id'
      AND is_identity = 'YES'
  ) THEN
    ALTER TABLE tasks ALTER COLUMN id DROP DEFAULT;
  END IF;
END
$$;

ALTER TABLE tasks
  ALTER COLUMN title DROP DEFAULT,
  ALTER COLUMN done DROP DEFAULT,
  ALTER COLUMN created_at DROP DEFAULT;

ALTER TABLE tasks
  ALTER COLUMN id TYPE INTEGER USING id::integer,
  ALTER COLUMN title TYPE TEXT USING title::text,
  ALTER COLUMN done TYPE BOOLEAN USING done::boolean,
  ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at::timestamptz;

DO $$
DECLARE
  id_sequence TEXT;
  sequence_value BIGINT;
  sequence_is_called BOOLEAN;
  max_id INTEGER;
  id_is_identity BOOLEAN;
BEGIN
  id_sequence := pg_get_serial_sequence('tasks', 'id');

  IF id_sequence IS NULL THEN
    CREATE SEQUENCE IF NOT EXISTS tasks_id_seq;
    ALTER SEQUENCE tasks_id_seq OWNED BY tasks.id;
    id_sequence := 'tasks_id_seq';
  END IF;

  SELECT is_identity = 'YES'
  INTO id_is_identity
  FROM information_schema.columns
  WHERE table_schema = current_schema()
    AND table_name = 'tasks'
    AND column_name = 'id';

  EXECUTE format(
    'SELECT last_value, is_called FROM %s',
    id_sequence::regclass
  ) INTO sequence_value, sequence_is_called;

  SELECT MAX(id) INTO max_id FROM tasks;
  PERFORM setval(
    id_sequence::regclass,
    GREATEST(COALESCE(max_id, 0), sequence_value, 1),
    sequence_is_called OR max_id IS NOT NULL
  );

  UPDATE tasks SET id = nextval(id_sequence::regclass) WHERE id IS NULL;

  IF NOT id_is_identity THEN
    EXECUTE format(
      'ALTER TABLE tasks ALTER COLUMN id SET DEFAULT nextval(%L::regclass)',
      id_sequence
    );
  END IF;
END
$$;

UPDATE tasks SET title = '' WHERE title IS NULL;
UPDATE tasks SET done = FALSE WHERE done IS NULL;
UPDATE tasks SET created_at = NOW() WHERE created_at IS NULL;

ALTER TABLE tasks
  ALTER COLUMN title SET NOT NULL,
  ALTER COLUMN done SET NOT NULL,
  ALTER COLUMN done SET DEFAULT FALSE,
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT NOW(),
  ALTER COLUMN id SET NOT NULL;

DO $$
DECLARE
  id_attribute SMALLINT;
BEGIN
  IF EXISTS (
    SELECT id
    FROM tasks
    GROUP BY id
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION 'Cannot migrate tasks: duplicate id values must be resolved first';
  END IF;

  SELECT attnum
  INTO id_attribute
  FROM pg_attribute
  WHERE attrelid = 'tasks'::regclass
    AND attname = 'id'
    AND NOT attisdropped;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'tasks'::regclass
      AND contype = 'p'
  ) THEN
    ALTER TABLE tasks ADD CONSTRAINT tasks_id_pkey PRIMARY KEY (id);
  ELSIF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'tasks'::regclass
      AND contype IN ('p', 'u')
      AND conkey = ARRAY[id_attribute]::SMALLINT[]
  ) THEN
    ALTER TABLE tasks ADD CONSTRAINT tasks_id_key UNIQUE (id);
  END IF;
END
$$;