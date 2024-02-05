-- PROCEDURE: public.login_user(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.login_user(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.login_user(
	IN p_user_name character varying,
	IN p_user_password character varying)
LANGUAGE 'plpgsql'
AS $BODY$
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

        -- Call the create_login_log function after a successful login
        PERFORM create_login_log(user_id, 'some_login_type', CURRENT_DATE);

    ELSE
        RAISE NOTICE 'Login failed. User not found or incorrect credentials.';
    END IF;
END;
$BODY$;
