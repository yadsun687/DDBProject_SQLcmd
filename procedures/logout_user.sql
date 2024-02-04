CREATE OR REPLACE PROCEDURE logout_user(
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

    -- If the user is found, update the RecentLogin field to '0001-01-01'
    IF user_id IS NOT NULL THEN
        UPDATE public."ALL_USER"
        SET "RecentLogin" = '0001-01-01'::DATE
        WHERE "UserID" = user_id;

        RAISE NOTICE 'User logged out with UserID: %', user_id;
    ELSE
        RAISE NOTICE 'Logout failed. User not found or incorrect credentials.';
    END IF;
END;
$$;