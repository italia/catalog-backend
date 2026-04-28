CREATE TABLE code_hostings (
    id uuid DEFAULT uuidv7.uuidv7 () PRIMARY KEY,
    publisher_id uuid NOT NULL REFERENCES publishers,
    updated_at timestamp with time zone,
    url text NOT NULL,
    is_group boolean NOT NULL DEFAULT TRUE
);

CREATE INDEX ON code_hostings (publisher_id);

CREATE TRIGGER code_hostings_moddatetime
    BEFORE UPDATE ON code_hostings
    FOR EACH ROW
    EXECUTE PROCEDURE extensions.moddatetime (updated_at);

CREATE FUNCTION code_hostings_created_at (rec code_hostings)
    RETURNS timestamp with time zone IMMUTABLE STRICT
    LANGUAGE sql
    SET search_path = '' RETURN uuidv7.uuidv7_extract_timestamp (
        rec.id
);

COMMENT ON FUNCTION code_hostings_created_at IS e'@graphql({"name": "createdAt"})';

ALTER TABLE code_hostings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON code_hostings AS PERMISSIVE
    FOR SELECT TO public
        USING (TRUE);

