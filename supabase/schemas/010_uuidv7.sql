CREATE SCHEMA uuidv7;

-- From https://github.com/dverite/postgres-uuidv7-sql
/* See the UUID Version 7 specification at
https://www.rfc-editor.org/rfc/rfc9562#name-uuid-version-7 */
/* Main function to generate a uuidv7 value with millisecond precision */
CREATE FUNCTION uuidv7.uuidv7 (timestamptz DEFAULT CLOCK_TIMESTAMP())
    RETURNS uuid
    AS $$
    -- Replace the first 48 bits of a uuidv4 with the current
    -- number of milliseconds since 1970-01-01 UTC
    -- and set the "ver" field to 7 by setting additional bits
    SELECT
        encode(set_bit(set_bit(overlay(uuid_send(gen_random_uuid ())
                    PLACING substring(int8send((extract(epoch FROM $1) * 1000)::bigint)
                    FROM 3)
                FROM 1 FOR 6), 52, 1), 53, 1), 'hex')::uuid;
$$
LANGUAGE sql
VOLATILE parallel safe SET search_path = '';

COMMENT ON FUNCTION uuidv7.uuidv7 (TIMESTAMPTZ) IS 'Generate a uuid-v7 value with a 48-bit timestamp (millisecond precision) and 74 bits of randomness';


/* Version with the "rand_a" field containing sub-milliseconds (method 3 of the spec)
clock_timestamp() is hoped to provide enough precision and consecutive
calls to not happen fast enough to output the same values in that field.
The uuid is the concatenation of:
- 6 bytes with the current Unix timestamp (number of milliseconds since 1970-01-01 UTC)
- 2 bytes with
- 4 bits for the "ver" field
- 12 bits for the fractional part after the milliseconds
- 8 bytes of randomness from the second half of a uuidv4
 */
CREATE FUNCTION uuidv7.uuidv7_sub_ms (timestamptz DEFAULT CLOCK_TIMESTAMP())
    RETURNS uuid
    AS $$
    SELECT
        encode(substring(int8send(floor(t_ms)::int8)
                FROM 3) || int2send((7 << 12)::int2 | ((t_ms - floor(t_ms)) * 4096)::int2) || substring(uuid_send(gen_random_uuid ())
    FROM 9 FOR 8), 'hex')::uuid
    FROM (
        SELECT
            extract(epoch FROM $1) * 1000 AS t_ms) s
$$
LANGUAGE sql
VOLATILE parallel safe SET search_path = '';

COMMENT ON FUNCTION uuidv7.uuidv7_sub_ms (TIMESTAMPTZ) IS 'Generate a uuid-v7 value with a 60-bit timestamp (sub-millisecond precision) and 62 bits of randomness';


/* Extract the timestamp in the first 6 bytes of the uuidv7 value.
Use the fact that 'xHHHHH' (where HHHHH are hexadecimal numbers)
can be cast to bit(N) and then to int8.
 */
CREATE FUNCTION uuidv7.uuidv7_extract_timestamp (uuid)
    RETURNS timestamptz
    AS $$
    SELECT
        to_timestamp(
        RIGHT (substring(uuid_send($1)
                FROM 1 FOR 6)::text, -1)::bit(48)::int8 -- milliseconds
        / 1000.0);
$$
LANGUAGE sql
IMMUTABLE STRICT parallel safe SET search_path = '';

COMMENT ON FUNCTION uuidv7.uuidv7_extract_timestamp (UUID) IS 'Return the timestamp stored in the first 48 bits of the UUID v7 value';

CREATE FUNCTION uuidv7.uuidv7_boundary (timestamptz)
    RETURNS uuid
    AS $$
    /* uuid fields: version=0b0111, variant=0b10 */
    SELECT
        encode(overlay('\x00000000000070008000000000000000'::bytea PLACING substring(int8send(floor(extract(epoch FROM $1) * 1000)::bigint)
                    FROM 3)
                FROM 1 FOR 6), 'hex')::uuid;
$$
LANGUAGE sql
STABLE STRICT parallel safe SET search_path = '';

COMMENT ON FUNCTION uuidv7.uuidv7_boundary (TIMESTAMPTZ) IS 'Generate a non-random uuidv7 with the given timestamp (first 48 bits) and all random bits to 0. As the smallest possible uuidv7 for that timestamp, it may be used as a boundary for partitions.';

