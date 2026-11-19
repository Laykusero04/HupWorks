0056 (B3) cannot be rolled back with SQL: the dropped seller_profiles columns
(address, birth_year, birth_month, birth_day) are only recoverable from a
backup / PITR. The same data was copied into seller_private_details
(date_of_birth, street_address) by step 1 of that migration.
