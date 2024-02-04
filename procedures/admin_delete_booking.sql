CREATE OR REPLACE PROCEDURE admin_delete_booking(
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

    -- Check if user_id exists in ADMIN table
    IF NOT EXISTS (
        SELECT 1
        FROM public."ADMIN"
        WHERE "UserID(ADMIN)" = user_id
    ) THEN
        RAISE EXCEPTION 'User does not exist in ADMIN table.';
    END IF;

    -- Check if the booking belongs to the user
    IF NOT EXISTS (
        SELECT 1
        FROM public."ADMIN_BOOKING" AB
        WHERE AB."UserID(ADMIN)" = user_id
          AND AB."BookingID" = p_booking_id
    ) THEN
        RAISE EXCEPTION 'Booking does not belong to the user.';
    END IF;

    -- Delete the booking
    DELETE FROM public."BOOKING"
    WHERE "BookingID" = p_booking_id;

    RAISE NOTICE 'Booking % deleted for admin user %.', p_booking_id, p_user_name;
END;
$$;