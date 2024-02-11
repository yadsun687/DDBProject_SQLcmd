CREATE OR REPLACE PROCEDURE register_all_user(
    p_user_password VARCHAR(100),
    p_user_name VARCHAR(100),
    p_user_email VARCHAR(100),
    p_role_type VARCHAR[] DEFAULT ARRAY['NORMAL'], -- default to NORMAL
    p_BirthDate DATE DEFAULT CURRENT_DATE,
    NormalUser_Address VARCHAR[] DEFAULT NULL,
    NormalUser_Telephone VARCHAR[] DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_user_id INTEGER;
    role VARCHAR;
    i INTEGER;
BEGIN
    -- Check for uniqueness of username, email, and password
    IF EXISTS (
        SELECT 1
        FROM public."ALL_USER"
        WHERE "UserName" = p_user_name
           AND "UserPassword" = p_user_password
    ) THEN
        RAISE EXCEPTION 'User with the same username, email, or password already exists.';
    END IF;

    -- Generate a new UserID
    SELECT COALESCE(MAX("UserID"), 0) + 1 INTO new_user_id FROM public."ALL_USER";

    -- Insert the new user into the ALL_USER table
    INSERT INTO public."ALL_USER"("UserID", "UserPassword", "UserName", "UserEmail", "RecentLogin")
    VALUES (new_user_id, p_user_password, p_user_name, p_user_email, '0001-01-01');

    -- Iterate through the roles and insert the user into corresponding role tables
    FOREACH role IN ARRAY p_role_type
    LOOP
        IF role = 'NORMAL' THEN
            INSERT INTO public."NORMAL_USER"("UserID(NORMAL_USER)", "BirthDate")
            VALUES (new_user_id, p_BirthDate);

            -- Use loop to INSERT NormalUser_Address only if it doesn't already exist
            FOR i IN 1..array_length(NormalUser_Address, 1)
            LOOP
                BEGIN
                    INSERT INTO public."NormalUser_Address"("UserID(NormalUser_Address)", "UserAddress")
                    VALUES (new_user_id, NormalUser_Address[i]);
                EXCEPTION
                    WHEN unique_violation THEN
                        -- Ignore duplicate entries
                        CONTINUE;
                END;
            END LOOP;

            -- Use loop to INSERT NormalUser_Telephone only if it doesn't already exist
            FOR i IN 1..array_length(NormalUser_Telephone, 1)
            LOOP
                BEGIN
                    INSERT INTO public."NormalUser_Telephone"("UserID(NormalUser_Telephone)", "UserTelephone")
                    VALUES (new_user_id, NormalUser_Telephone[i]);
                EXCEPTION
                    WHEN unique_violation THEN
                        -- Ignore duplicate entries
                        CONTINUE;
                END;
            END LOOP;
            
        ELSIF role = 'ADMIN' THEN
            INSERT INTO public."ADMIN"("UserID(ADMIN)")
            VALUES (new_user_id);
        ELSIF role = 'MANAGER' THEN
            INSERT INTO public."HOTEL_MANAGER"("UserID(HOTEL_MANAGER)")
            VALUES (new_user_id);
        END IF;
    END LOOP;

    -- Raise a NOTICE with the new_user_id
    RAISE NOTICE 'New user registered with UserID: %', new_user_id;
END;
$$;