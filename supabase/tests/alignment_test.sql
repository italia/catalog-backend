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
            pg_column_size(ROW ('00000000-0000-0000-0000-000000000000', 'epoch', 'Acme Inc.', 'test@example.com', 'pcm', TRUE)::publishers) $$, $$
        VALUES (80) $$, 'Size of a “publishers” row');
SELECT
    results_eq ($$
        SELECT
            pg_column_size(ROW ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000000', 'epoch', '{"publiccodeYmlVersion":"0.5"}', 'https://github.com/italia/foo', TRUE)::software) $$, $$
        VALUES (131) $$, 'Size of a “software” row');
SELECT
    *
FROM
    finish ();
ROLLBACK;

