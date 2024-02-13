CREATE OR REPLACE Procedure public.user_delete_booking(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100),
    p_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    last_login_id INTEGER;
    last_logout_id INTEGER;
BEGIN
    -- Get user ID based on email and password
    SELECT UserID INTO v_user_id
    FROM public.ALL_USER
    WHERE UserEmail = p_user_email AND UserPassword = p_user_password;

    -- Get the last login and logout IDs for the user
    SELECT MAX(CASE WHEN logout IS NULL THEN logid END) INTO last_login_id
    FROM public.LOGS
    WHERE UserID = v_user_id;

    SELECT MAX(CASE WHEN logout IS NOT NULL THEN logid END) INTO last_logout_id
    FROM public.LOGS
    WHERE UserID = v_user_id;

    -- Check if the user is currently logged in
    IF last_login_id IS NULL OR (last_logout_id IS NOT NULL AND last_logout_id > last_login_id) THEN
        RAISE EXCEPTION 'User is not currently logged in.';
    END IF;

    -- Check if the user is found
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found with the given credentials';
    END IF;

    -- Check if the booking exists
    IF NOT EXISTS (
        SELECT 1
        FROM public.BOOKING
        WHERE BookingID = p_booking_id
    ) THEN
        RAISE EXCEPTION 'Booking not found with the given ID';
    END IF;

    -- Check if the user owns the booking
    IF NOT EXISTS (
        SELECT 1
        FROM public.BOOKING b
        JOIN public.ALL_USER u ON b.UserID = u.UserID
        WHERE b.BookingID = p_booking_id AND u.UserEmail = p_user_email
    ) THEN
        RAISE EXCEPTION 'User does not own the booking with the given ID';
    END IF;

    -- Delete the booking
    DELETE FROM public.BOOKING
    WHERE BookingID = p_booking_id;
END;
$$;


--login user first to grant permission in viewing data
CALL login_user('john.doe@example.com', 'password123');

--function call
CALL public.user_delete_booking('john.doe@example.com', 'password123', 2);

--show result
SELECT * FROM booking ORDER BY bookingid ASC;
