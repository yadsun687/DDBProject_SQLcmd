CREATE OR REPLACE PROCEDURE user_edit_booking(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100),
    p_booking_id INTEGER,
    p_new_checkin_date DATE,
    p_new_pay_type VARCHAR(100),
    p_new_number_of_booking INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id INTEGER;
    v_normal_user_id INTEGER;
    v_room_status BOOLEAN;
    v_existing_booking_id INTEGER;
BEGIN
    -- Check if the user exists and the password is correct
    SELECT "UserID"
    INTO v_user_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_user_name
      AND "UserPassword" = p_user_password;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;

    -- Check if the user is in the NORMAL_USER table
    SELECT "UserID(NORMAL_USER)"
    INTO v_normal_user_id
    FROM public."NORMAL_USER"
    WHERE "UserID(NORMAL_USER)" = v_user_id;

    IF v_normal_user_id IS NULL THEN
        RAISE EXCEPTION 'User is not a normal user.';
    END IF;

    -- Check if the booking belongs to the user
    SELECT "BookingID"
    INTO v_existing_booking_id
    FROM public."BOOKING" b
    WHERE b."UserID(BOOKING)" = v_user_id
      AND b."BookingID" = p_booking_id;

    IF v_existing_booking_id IS NULL THEN
        RAISE EXCEPTION 'Booking does not belong to the user.';
    END IF;

    -- Check if the room status is true
    SELECT "Status"
    INTO v_room_status
    FROM public."ROOM" r
    WHERE r."RoomID" = (SELECT "RoomID(BOOKING)" FROM public."BOOKING" WHERE "BookingID" = p_booking_id);

    IF NOT v_room_status THEN
        RAISE EXCEPTION 'Room status is not available.';
    END IF;

    -- Check for overlapping bookings for the same room
    SELECT "BookingID"
    INTO v_existing_booking_id
    FROM public."BOOKING" b
    WHERE b."RoomID(BOOKING)" = (SELECT "RoomID(BOOKING)" FROM public."BOOKING" WHERE "BookingID" = p_booking_id)
      AND b."BookingID" <> p_booking_id
      AND NOT (
          ("CheckInDate" < p_new_checkin_date AND "CheckInDate" + "NumberOfBooking" - 1 < p_new_checkin_date)
          OR
          ("CheckInDate" > p_new_checkin_date + p_new_number_of_booking - 1 AND "CheckInDate" + "NumberOfBooking" - 1 > p_new_checkin_date + p_new_number_of_booking)
      );

    IF v_existing_booking_id IS NULL THEN
        -- Update the existing booking
        UPDATE public."BOOKING"
        SET
            "CheckInDate" = p_new_checkin_date,
            "PayType" = p_new_pay_type,
            "NumberOfBooking" = p_new_number_of_booking
        WHERE "BookingID" = p_booking_id;

        RAISE NOTICE 'Booking % updated for user %.', p_booking_id, p_user_name;
    ELSE
        RAISE EXCEPTION 'Booking overlaps with an existing booking.';
    END IF;
END;
$$;