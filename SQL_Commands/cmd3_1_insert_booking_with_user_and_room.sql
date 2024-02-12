CREATE OR REPLACE PROCEDURE public.insert_booking_with_user_and_room(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100),
    p_room_id INTEGER,
    p_checkin_date DATE,
    p_pay_type VARCHAR(100),
    p_number_of_booking INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    last_login_id INTEGER;
    last_logout_id INTEGER;
    v_booking_id INTEGER;
BEGIN
    -- Get user ID based on email and password
    SELECT UserID INTO v_user_id
    FROM public.ALL_USER
    WHERE UserEmail = p_user_email AND UserPassword = p_user_password;

    -- Check if the user is found
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found with the given credentials';
    END IF;

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

    -- Check if the user is a normal user
    IF NOT EXISTS (
        SELECT 1
        FROM public.NORMAL_USER
        WHERE UserID = v_user_id
    ) THEN
        RAISE EXCEPTION 'User found, but not a normal user';
    END IF;

    -- Check if the room is available
    IF NOT EXISTS (
        SELECT 1
        FROM public.ROOM
        WHERE RoomID = p_room_id AND Status = TRUE
    ) THEN
        RAISE EXCEPTION 'Room status is not available';
    END IF;

    -- Check if a conflicting booking already exists
    IF EXISTS (
        SELECT 1
        FROM public.BOOKING
        WHERE RoomID = p_room_id
          AND NOT (
            (CheckInDate < p_checkin_date AND CheckInDate + NumberOfBooking - 1 < p_checkin_date)
            OR
            (CheckInDate > p_checkin_date + p_number_of_booking - 1 AND CheckInDate > p_checkin_date + p_number_of_booking - 1)
          )
    ) THEN
        RAISE EXCEPTION 'Booking already exists for the given room, checkin_date, and number_of_booking';
    END IF;

    -- Get the maximum existing booking_id and increment by 1
    SELECT COALESCE(MAX(BookingID), 0) + 1 INTO v_booking_id FROM public.BOOKING;

    -- Insert the booking
    INSERT INTO public.BOOKING (BookingID, RoomID, UserID, CheckInDate, PayType, NumberOfBooking)
    VALUES (v_booking_id, p_room_id, v_user_id, p_checkin_date, p_pay_type, p_number_of_booking);
END;
$$;


CALL public.insert_booking_with_user_and_room('john.doe@example.com', 'password123', 1, '2124-03-01', 'Credit Card', 2);

-- Show Result
SELECT * FROM booking