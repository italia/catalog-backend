CREATE TABLE software (
    id uuid DEFAULT uuidv7.uuidv7 () PRIMARY KEY,
    updated_at timestamp with time zone,
    publiccode jsonb NOT NULL,
    url citext NOT NULL UNIQUE,
    active boolean NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE software IS '@graphql({"name": "Software", "description": "A software."})';

CREATE TRIGGER software_moddatetime
    BEFORE UPDATE ON software
    FOR EACH ROW
    EXECUTE PROCEDURE extensions.moddatetime (updated_at);

CREATE FUNCTION software_created_at (rec software)
    RETURNS timestamp with time zone IMMUTABLE STRICT
    LANGUAGE sql
    SET search_path = '' RETURN uuidv7.uuidv7_extract_timestamp (
        rec.id
);

COMMENT ON FUNCTION software_created_at IS '@graphql({"name": "createdAt"})';

ALTER TABLE software ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON software AS PERMISSIVE
    FOR SELECT TO public
        USING (TRUE);

CREATE FUNCTION software_fts (pc jsonb)
    RETURNS tsvector IMMUTABLE STRICT
    LANGUAGE sql
    SET search_path = '' RETURN setweight (
to_tsvector('simple', coalesce(pc ->> 'name', '')), 'A') || setweight (
to_tsvector('italian', coalesce(pc -> 'description' -> 'it' ->> 'shortDescription', '')), 'B') || setweight (
to_tsvector('italian', coalesce(pc -> 'description' -> 'IT' ->> 'shortDescription', '')), 'B') || setweight (
to_tsvector('italian', coalesce(pc -> 'description' -> 'it' ->> 'longDescription', '')), 'C') || setweight (
to_tsvector('italian', coalesce(pc -> 'description' -> 'IT' ->> 'longDescription', '')), 'C'
);

CREATE INDEX ON software USING gin (software_fts (publiccode));

