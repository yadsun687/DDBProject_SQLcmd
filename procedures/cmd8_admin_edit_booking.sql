CREATE OR REPLACE PROCEDURE admin_edit_booking(
    p_admin_name VARCHAR(100),
    p_admin_password VARCHAR(100),
    p_booking_id INTEGER,
    p_new_checkin_date DATE,
    p_new_pay_type VARCHAR(100),
    p_new_number_of_booking INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin_id INTEGER;
    v_room_status BOOLEAN;
    v_existing_booking_id INTEGER;
BEGIN
    -- Assuming "UserName" is unique for admins
    SELECT "UserID"
    INTO v_admin_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_admin_name
    AND "UserPassword" = p_admin_password;

    IF v_admin_id IS NOT NULL THEN
        -- Check if the booking exists
        SELECT "BookingID"
        INTO v_existing_booking_id
        FROM public."BOOKING"
        WHERE "BookingID" = p_booking_id;

        IF v_existing_booking_id IS NOT NULL THEN
            -- Check if the room status is true
            SELECT "Status"
            INTO v_room_status
            FROM public."ROOM"
            WHERE "RoomID" = (SELECT "RoomID(BOOKING)" FROM public."BOOKING" WHERE "BookingID" = p_booking_id);

            IF v_room_status THEN
                -- Check for overlapping bookings for the same room
                SELECT "BookingID"
                INTO v_existing_booking_id
                FROM public."BOOKING"
                WHERE "RoomID(BOOKING)" = (SELECT "RoomID(BOOKING)" FROM public."BOOKING" WHERE "BookingID" = p_booking_id)
                AND NOT(
                    ("CheckInDate" < p_new_checkin_date AND "CheckInDate" + p_new_number_of_booking - 1 < p_new_checkin_date)
                    OR
                    ("CheckInDate" > p_new_checkin_date + p_new_number_of_booking - 1 AND "CheckInDate" + p_new_number_of_booking - 1 > p_new_checkin_date + p_new_number_of_booking)
                );

                IF v_existing_booking_id IS NULL THEN
                    -- Update the existing booking
                    UPDATE public."BOOKING"
                    SET "CheckInDate" = p_new_checkin_date,
                        "PayType" = p_new_pay_type,
                        "NumberOfBooking" = p_new_number_of_booking
                    WHERE "BookingID" = p_booking_id;

                    RAISE NOTICE 'Booking % updated by admin %.', p_booking_id, p_admin_name;
                ELSE
                    RAISE EXCEPTION 'New booking dates overlap with an existing booking.';
                END IF;
            ELSE
                RAISE EXCEPTION 'Room status is not available';
            END IF;
        ELSE
            RAISE EXCEPTION 'Booking does not exist.';
        END IF;
    ELSE
        RAISE EXCEPTION 'Admin not found with the given credentials';
    END IF;
END;
$$;