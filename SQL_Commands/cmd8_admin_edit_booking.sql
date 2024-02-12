CREATE OR REPLACE PROCEDURE admins_edit_bookings(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100),
    p_booking_id INTEGER,
    p_new_checkin_date DATE DEFAULT NULL,
    p_new_pay_type VARCHAR(100) DEFAULT NULL,
    p_new_number_of_booking INTEGER DEFAULT NULL
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
        RAISE EXCEPTION 'Booking not found';
    END IF;

    -- Update the booking with the new values if provided
    UPDATE BOOKING
    SET 
        CheckInDate = COALESCE(p_new_checkin_date, CheckInDate),
        PayType = COALESCE(p_new_pay_type, PayType),
        NumberOfBooking = COALESCE(p_new_number_of_booking, NumberOfBooking)
    WHERE BookingID = p_booking_id;
END;
$$;

--test fucntion
CALL admins_edit_bookings( 'john.doe@example.com' , 'password123' , 2 , '2024-02-12' , 'Cash' , 2);

--show result
SELECT * FROM booking ORDER BY bookingid ASC;