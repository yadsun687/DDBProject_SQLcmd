CREATE OR REPLACE PROCEDURE admins_delete_bookings(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100),
    p_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    -- Get user ID based on email and password
    SELECT UserID INTO v_user_id
    FROM ALL_USER
    WHERE UserEmail = p_user_email AND UserPassword = p_user_password;

    -- Check if the user is found
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found with the given credentials';
    END IF;

    -- Check if the user is an admin
    IF NOT EXISTS (
        SELECT 1
        FROM admins
        WHERE UserID = v_user_id
    ) THEN
        RAISE EXCEPTION 'User found, but not an admin';
    END IF;

    -- Check if the booking exists
    IF NOT EXISTS (
        SELECT 1
        FROM BOOKING
        WHERE BookingID = p_booking_id
    ) THEN
        RAISE EXCEPTION 'Booking not found with the given ID';
    END IF;

    -- Delete the booking
    DELETE FROM BOOKING
    WHERE BookingID = p_booking_id;
END;
$$;


--test function
CALL admins_delete_bookings('john.doe@example.com', 'password123', 2);

--show result
SELECT * FROM booking ORDER BY bookingid ASC;