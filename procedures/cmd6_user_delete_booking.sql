CREATE OR REPLACE PROCEDURE user_delete_booking(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100),
    p_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Check if the user exists and the password is correct
    SELECT "UserID" INTO user_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_user_name
      AND "UserPassword" = p_user_password;

    -- Check if user_id exists in Normal_user table
    IF NOT EXISTS (
        SELECT 1
        FROM public."NORMAL_USER"
        WHERE "UserID(NORMAL_USER)" = user_id
    ) THEN
        RAISE EXCEPTION 'User does not exist in Normal_user table.';
    END IF;

    -- Check if the user has logged in today
    IF (SELECT "RecentLogin" FROM public."ALL_USER" WHERE "UserID" = user_id) <> CURRENT_DATE THEN
        RAISE EXCEPTION 'User has not logged in today.';
    END IF;

    -- Check if the booking belongs to the user
    IF NOT EXISTS (
        SELECT 1
        FROM public."BOOKING" b
        WHERE b."UserID(BOOKING)" = user_id
          AND b."BookingID" = p_booking_id
    ) THEN
        RAISE EXCEPTION 'Booking does not belong to the user.';
    END IF;

    -- Delete the booking
    DELETE FROM public."BOOKING"
    WHERE "BookingID" = p_booking_id;

    RAISE NOTICE 'Booking % deleted for user %.', p_booking_id, p_user_name;
END;
$$;