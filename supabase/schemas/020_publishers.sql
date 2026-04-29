CREATE TABLE publishers (
    id uuid DEFAULT uuidv7.uuidv7 () PRIMARY KEY,
    updated_at timestamp with time zone,
    email text NOT NULL,
    description text,
    alternative_id text,
    active boolean NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE publishers IS '@graphql({"name": "Publisher", "description": "A publisher."})';

CREATE TRIGGER publishers_moddatetime
    BEFORE UPDATE ON publishers
    FOR EACH ROW
    EXECUTE PROCEDURE extensions.moddatetime (updated_at);

CREATE FUNCTION publishers_created_at (rec publishers)
    RETURNS timestamp with time zone IMMUTABLE STRICT
    LANGUAGE sql
    SET search_path = '' RETURN uuidv7.uuidv7_extract_timestamp (
        rec.id
);

COMMENT ON FUNCTION publishers_created_at IS '@graphql({"name": "createdAt"})';

ALTER TABLE publishers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON publishers AS PERMISSIVE
    FOR SELECT TO public
        USING (TRUE);

