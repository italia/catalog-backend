CREATE EXTENSION IF NOT EXISTS "moddatetime" WITH SCHEMA "extensions";

CREATE SCHEMA IF NOT EXISTS "uuidv7";

SET check_function_bodies = OFF;

CREATE OR REPLACE FUNCTION uuidv7.uuidv7 (timestamp with time zone DEFAULT clock_timestamp())
    RETURNS uuid
    LANGUAGE sql
    PARALLEL SAFE
    SET search_path TO ''
    AS $function$
    -- Replace the first 48 bits of a uuidv4 with the current
    -- number of milliseconds since 1970-01-01 UTC
    -- and set the "ver" field to 7 by setting additional bits
    SELECT
        encode(set_bit(set_bit(overlay(uuid_send(gen_random_uuid ())
                    PLACING substring(int8send((extract(epoch FROM $1) * 1000)::bigint)
                    FROM 3)
                FROM 1 FOR 6), 52, 1), 53, 1), 'hex')::uuid;
$function$;

CREATE OR REPLACE FUNCTION uuidv7.uuidv7_boundary (timestamp with time zone)
    RETURNS uuid
    LANGUAGE sql
    STABLE PARALLEL SAFE STRICT
    SET search_path TO ''
    AS $function$
    /* uuid fields: version=0b0111, variant=0b10 */
    SELECT
        encode(overlay('\x00000000000070008000000000000000'::bytea PLACING substring(int8send(floor(extract(epoch FROM $1) * 1000)::bigint)
                    FROM 3)
                FROM 1 FOR 6), 'hex')::uuid;
$function$;

CREATE OR REPLACE FUNCTION uuidv7.uuidv7_extract_timestamp (uuid)
    RETURNS timestamp with time zone
    LANGUAGE sql
    IMMUTABLE PARALLEL SAFE STRICT
    SET search_path TO ''
    AS $function$
    SELECT
        to_timestamp(
        RIGHT (substring(uuid_send($1)
                FROM 1 FOR 6)::text, -1)::bit(48)::int8 -- milliseconds
        / 1000.0);
$function$;

CREATE OR REPLACE FUNCTION uuidv7.uuidv7_sub_ms (timestamp with time zone DEFAULT clock_timestamp())
    RETURNS uuid
    LANGUAGE sql
    PARALLEL SAFE
    SET search_path TO ''
    AS $function$
    SELECT
        encode(substring(int8send(floor(t_ms)::int8)
                FROM 3) || int2send((7 << 12)::int2 | ((t_ms - floor(t_ms)) * 4096)::int2) || substring(uuid_send(gen_random_uuid ())
    FROM 9 FOR 8), 'hex')::uuid
    FROM (
        SELECT
            extract(epoch FROM $1) * 1000 AS t_ms) s
$function$;

CREATE TABLE "public"."code_hostings" (
    "id" uuid NOT NULL DEFAULT uuidv7.uuidv7 (),
    "publisher_id" uuid NOT NULL,
    "updated_at" timestamp with time zone,
    "url" text NOT NULL,
    "is_group" boolean NOT NULL DEFAULT TRUE
);

CREATE TABLE "public"."publishers" (
    "id" uuid NOT NULL DEFAULT uuidv7.uuidv7 (),
    "updated_at" timestamp with time zone,
    "email" text NOT NULL,
    "description" text,
    "alternative_id" text,
    "active" boolean NOT NULL DEFAULT TRUE
);

CREATE TABLE "public"."software" (
    "id" uuid NOT NULL DEFAULT uuidv7.uuidv7 (),
    "updated_at" timestamp with time zone,
    "publiccode" jsonb NOT NULL,
    "url" text NOT NULL,
    "active" boolean NOT NULL DEFAULT TRUE
);

CREATE UNIQUE INDEX code_hostings_pkey ON public.code_hostings USING btree (id);

CREATE INDEX code_hostings_publisher_id_idx ON public.code_hostings USING btree (publisher_id);

CREATE UNIQUE INDEX publishers_pkey ON public.publishers USING btree (id);

CREATE UNIQUE INDEX software_pkey ON public.software USING btree (id);

ALTER TABLE "public"."code_hostings"
    ADD CONSTRAINT "code_hostings_pkey" PRIMARY KEY USING INDEX "code_hostings_pkey",
    ADD CONSTRAINT "code_hostings_publisher_id_fkey" FOREIGN KEY (publisher_id) REFERENCES public.publishers (id) ON UPDATE CASCADE ON DELETE CASCADE NOT valid, VALIDATE CONSTRAINT "code_hostings_publisher_id_fkey", ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."publishers"
    ADD CONSTRAINT "publishers_pkey" PRIMARY KEY USING INDEX "publishers_pkey", ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."software"
    ADD CONSTRAINT "software_pkey" PRIMARY KEY USING INDEX "software_pkey", ENABLE ROW LEVEL SECURITY;

SET check_function_bodies = OFF;

CREATE OR REPLACE FUNCTION public.code_hostings_created_at (rec public.code_hostings)
    RETURNS timestamp with time zone
    LANGUAGE sql
    IMMUTABLE STRICT
    SET search_path TO '' RETURN uuidv7.uuidv7_extract_timestamp ((rec).id
);

CREATE OR REPLACE FUNCTION public.publishers_created_at (rec public.publishers)
    RETURNS timestamp with time zone
    LANGUAGE sql
    IMMUTABLE STRICT
    SET search_path TO '' RETURN uuidv7.uuidv7_extract_timestamp ((rec).id
);

CREATE OR REPLACE FUNCTION public.software_created_at (rec public.software)
    RETURNS timestamp with time zone
    LANGUAGE sql
    IMMUTABLE STRICT
    SET search_path TO '' RETURN uuidv7.uuidv7_extract_timestamp ((rec).id
);

GRANT DELETE ON TABLE "public"."code_hostings" TO "anon";

GRANT INSERT ON TABLE "public"."code_hostings" TO "anon";

GRANT REFERENCES ON TABLE "public"."code_hostings" TO "anon";

GRANT SELECT ON TABLE "public"."code_hostings" TO "anon";

GRANT TRIGGER ON TABLE "public"."code_hostings" TO "anon";

GRANT TRUNCATE ON TABLE "public"."code_hostings" TO "anon";

GRANT UPDATE ON TABLE "public"."code_hostings" TO "anon";

GRANT DELETE ON TABLE "public"."code_hostings" TO "authenticated";

GRANT INSERT ON TABLE "public"."code_hostings" TO "authenticated";

GRANT REFERENCES ON TABLE "public"."code_hostings" TO "authenticated";

GRANT SELECT ON TABLE "public"."code_hostings" TO "authenticated";

GRANT TRIGGER ON TABLE "public"."code_hostings" TO "authenticated";

GRANT TRUNCATE ON TABLE "public"."code_hostings" TO "authenticated";

GRANT UPDATE ON TABLE "public"."code_hostings" TO "authenticated";

GRANT DELETE ON TABLE "public"."code_hostings" TO "service_role";

GRANT INSERT ON TABLE "public"."code_hostings" TO "service_role";

GRANT REFERENCES ON TABLE "public"."code_hostings" TO "service_role";

GRANT SELECT ON TABLE "public"."code_hostings" TO "service_role";

GRANT TRIGGER ON TABLE "public"."code_hostings" TO "service_role";

GRANT TRUNCATE ON TABLE "public"."code_hostings" TO "service_role";

GRANT UPDATE ON TABLE "public"."code_hostings" TO "service_role";

GRANT DELETE ON TABLE "public"."publishers" TO "anon";

GRANT INSERT ON TABLE "public"."publishers" TO "anon";

GRANT REFERENCES ON TABLE "public"."publishers" TO "anon";

GRANT SELECT ON TABLE "public"."publishers" TO "anon";

GRANT TRIGGER ON TABLE "public"."publishers" TO "anon";

GRANT TRUNCATE ON TABLE "public"."publishers" TO "anon";

GRANT UPDATE ON TABLE "public"."publishers" TO "anon";

GRANT DELETE ON TABLE "public"."publishers" TO "authenticated";

GRANT INSERT ON TABLE "public"."publishers" TO "authenticated";

GRANT REFERENCES ON TABLE "public"."publishers" TO "authenticated";

GRANT SELECT ON TABLE "public"."publishers" TO "authenticated";

GRANT TRIGGER ON TABLE "public"."publishers" TO "authenticated";

GRANT TRUNCATE ON TABLE "public"."publishers" TO "authenticated";

GRANT UPDATE ON TABLE "public"."publishers" TO "authenticated";

GRANT DELETE ON TABLE "public"."publishers" TO "service_role";

GRANT INSERT ON TABLE "public"."publishers" TO "service_role";

GRANT REFERENCES ON TABLE "public"."publishers" TO "service_role";

GRANT SELECT ON TABLE "public"."publishers" TO "service_role";

GRANT TRIGGER ON TABLE "public"."publishers" TO "service_role";

GRANT TRUNCATE ON TABLE "public"."publishers" TO "service_role";

GRANT UPDATE ON TABLE "public"."publishers" TO "service_role";

GRANT DELETE ON TABLE "public"."software" TO "anon";

GRANT INSERT ON TABLE "public"."software" TO "anon";

GRANT REFERENCES ON TABLE "public"."software" TO "anon";

GRANT SELECT ON TABLE "public"."software" TO "anon";

GRANT TRIGGER ON TABLE "public"."software" TO "anon";

GRANT TRUNCATE ON TABLE "public"."software" TO "anon";

GRANT UPDATE ON TABLE "public"."software" TO "anon";

GRANT DELETE ON TABLE "public"."software" TO "authenticated";

GRANT INSERT ON TABLE "public"."software" TO "authenticated";

GRANT REFERENCES ON TABLE "public"."software" TO "authenticated";

GRANT SELECT ON TABLE "public"."software" TO "authenticated";

GRANT TRIGGER ON TABLE "public"."software" TO "authenticated";

GRANT TRUNCATE ON TABLE "public"."software" TO "authenticated";

GRANT UPDATE ON TABLE "public"."software" TO "authenticated";

GRANT DELETE ON TABLE "public"."software" TO "service_role";

GRANT INSERT ON TABLE "public"."software" TO "service_role";

GRANT REFERENCES ON TABLE "public"."software" TO "service_role";

GRANT SELECT ON TABLE "public"."software" TO "service_role";

GRANT TRIGGER ON TABLE "public"."software" TO "service_role";

GRANT TRUNCATE ON TABLE "public"."software" TO "service_role";

GRANT UPDATE ON TABLE "public"."software" TO "service_role";

CREATE POLICY "Enable read access for all users" ON "public"."code_hostings" AS permissive
    FOR SELECT TO public
        USING (TRUE);

CREATE POLICY "Enable read access for all users" ON "public"."publishers" AS permissive
    FOR SELECT TO public
        USING (TRUE);

CREATE POLICY "Enable read access for all users" ON "public"."software" AS permissive
    FOR SELECT TO public
        USING (TRUE);

CREATE TRIGGER code_hostings_moddatetime
    BEFORE UPDATE ON public.code_hostings
    FOR EACH ROW
    EXECUTE FUNCTION extensions.moddatetime ('updated_at');

CREATE TRIGGER publishers_moddatetime
    BEFORE UPDATE ON public.publishers
    FOR EACH ROW
    EXECUTE FUNCTION extensions.moddatetime ('updated_at');

CREATE TRIGGER software_moddatetime
    BEFORE UPDATE ON public.software
    FOR EACH ROW
    EXECUTE FUNCTION extensions.moddatetime ('updated_at');

COMMENT ON SCHEMA public IS '@graphql({"inflect_names": true})';

COMMENT ON TABLE code_hostings IS '@graphql({"name": "CodeHosting", "description": "A code hosting site."})';

COMMENT ON FUNCTION code_hostings_created_at IS '@graphql({"name": "createdAt"})';

COMMENT ON CONSTRAINT code_hostings_publisher_id_fkey ON code_hostings IS '@graphql({"local_name": "codeHostings"})';

COMMENT ON TABLE publishers IS '@graphql({"name": "Publisher", "description": "A publisher."})';

COMMENT ON FUNCTION publishers_created_at IS '@graphql({"name": "createdAt"})';

COMMENT ON TABLE software IS '@graphql({"name": "Software", "description": "A software."})';

COMMENT ON FUNCTION software_created_at IS '@graphql({"name": "createdAt"})';

