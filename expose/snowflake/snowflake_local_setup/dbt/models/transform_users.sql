-- dbt/models/transform_users.sql
SELECT
    id,
    age,
    weight,
    name,
    title,
    email,
    telephone,
    gender,
    language,
    academic_degree,
    nationality,
    occupation,
    height,
    blood_type,
    address
FROM {{ source('users') }}
WHERE age > 18;