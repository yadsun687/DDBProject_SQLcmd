-- PROCEDURE: public.logout_user(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.logout_user(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.logout_user(
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

    -- If the user is found, update the RecentLogin field to '0001-01-01'
    IF user_id IS NOT NULL THEN
        UPDATE public."ALL_USER"
        SET "RecentLogin" = '0001-01-01'::DATE
        WHERE "UserID" = user_id;

		 -- Call the create_login_log function after a user logout
        PERFORM create_login_log(user_id, 'LOGOUT', CURRENT_DATE);
		
        RAISE NOTICE 'User logged out with UserID: %', user_id;
    ELSE
        RAISE NOTICE 'Logout failed. User not found or incorrect credentials.';
    END IF;
END;
$BODY$;