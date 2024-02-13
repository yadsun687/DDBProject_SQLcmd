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
    -- Check for uniqueness of email and password
    IF EXISTS (
        SELECT 1
        FROM ALL_USER
        WHERE UserEmail = p_user_email
           AND UserPassword = p_user_password
    ) THEN
        RAISE NOTICE 'User with the same email and password already exists. So no new user is registered.';
        RETURN;
    ELSEIF EXISTS (
        SELECT 1
        FROM ALL_USER
        WHERE UserEmail = p_user_email
    ) THEN
        RAISE EXCEPTION 'User with the same email already exists';
    END IF;

    -- Generate a new UserID
    SELECT COALESCE(MAX(UserID), 0) + 1 INTO new_user_id FROM ALL_USER;

    -- Insert the new user into the ALL_USER table
    INSERT INTO ALL_USER(UserID, UserPassword, UserName, UserEmail)
    VALUES (new_user_id, p_user_password, p_user_name, p_user_email);

    -- Iterate through the roles and insert the user into corresponding role tables
    FOREACH role IN ARRAY p_role_type
    LOOP
        CASE role
            WHEN 'NORMAL' THEN
                INSERT INTO NORMAL_USER(UserID, BirthDate)
                VALUES (new_user_id, p_BirthDate);

                -- Use loop to INSERT NormalUser_Address only if it doesn't already exist
                FOR i IN 1..COALESCE(array_length(NormalUser_Address, 1), 0)
                LOOP
                    BEGIN
                        INSERT INTO NormalUser_Address(UserID, UserAddress)
                        VALUES (new_user_id, NormalUser_Address[i]);
                    EXCEPTION
                        WHEN unique_violation THEN
                            -- Ignore duplicate entries
                            CONTINUE;
                    END;
                END LOOP;

                -- Use loop to INSERT NormalUser_Telephone only if it doesn't already exist
                FOR i IN 1..COALESCE(array_length(NormalUser_Telephone, 1), 0)
                LOOP
                    BEGIN
                        INSERT INTO NormalUser_Telephone(UserID, UserTelephone)
                        VALUES (new_user_id, NormalUser_Telephone[i]);
                    EXCEPTION
                        WHEN unique_violation THEN
                            -- Ignore duplicate entries
                            CONTINUE;
                    END;
                END LOOP;

            WHEN 'ADMIN' THEN
                INSERT INTO ADMINS(UserID)
                VALUES (new_user_id);

            WHEN 'MANAGER' THEN
                INSERT INTO HOTEL_MANAGER(UserID)
                VALUES (new_user_id);

            ELSE
                RAISE EXCEPTION 'Invalid role type: %', role;
        END CASE;
    END LOOP;

    -- Raise a NOTICE with the new_user_id
    RAISE NOTICE 'New user registered with UserID: %', new_user_id;
END;
$$;

CALL register_all_user('NewUserPassword', 'NewUser', 'newuser@example.com', ARRAY['NORMAL', 'ADMIN'], CURRENT_DATE, ARRAY['123 Main St', '456 Oak Ave'], ARRAY['555-1234', '555-5678']);

-- Show Result
SELECT * FROM public.all_user ORDER BY userid ASC 