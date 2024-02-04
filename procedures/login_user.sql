CREATE OR REPLACE PROCEDURE login_user(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Find the user ID based on the provided username and password
    SELECT "UserID" INTO user_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_user_name AND "UserPassword" = p_user_password;

    -- If the user is found, update the RecentLogin field to today's date
    IF user_id IS NOT NULL THEN
        UPDATE public."ALL_USER"
        SET "RecentLogin" = CURRENT_DATE
        WHERE "UserID" = user_id;

        RAISE NOTICE 'User logged in with UserID: %', user_id;
    ELSE
        RAISE NOTICE 'Login failed. User not found or incorrect credentials.';
    END IF;
END;
$$;
