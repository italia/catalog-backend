CREATE TABLE software (
    id uuid DEFAULT uuidv7.uuidv7 () PRIMARY KEY,
    updated_at timestamp with time zone,
    url text NOT NULL,
    publiccode jsonb NOT NULL,
    active boolean NOT NULL DEFAULT TRUE
);

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

COMMENT ON FUNCTION software_created_at IS e'@graphql({"name": "createdAt"})';

