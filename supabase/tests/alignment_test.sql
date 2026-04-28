BEGIN;
SELECT
    plan (3);
SELECT
    results_eq ($$
        SELECT
            pg_column_size(ROW ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', 'epoch', 'https://github.com/italia', TRUE)::code_hostings) $$, $$
        VALUES (91) $$, 'Size of a “code_hostings” row');
SELECT
    results_eq ($$
        SELECT
            pg_column_size(ROW ('00000000-0000-0000-0000-000000000000', 'epoch', 'test@example.com', 'foo', 'pcm', 'https://example.com', TRUE)::publishers) $$, $$
        VALUES (94) $$, 'Size of a “publishers” row');
SELECT
    results_eq ($$
        SELECT
            pg_column_size(ROW ('00000000-0000-0000-0000-000000000000', 'epoch', 'https://github.com/italia/foo', '{"publiccodeYmlVersion":"0.5"}', TRUE)::software) $$, $$
        VALUES (115) $$, 'Size of a “software” row');
SELECT
    *
FROM
    finish ();
ROLLBACK;

