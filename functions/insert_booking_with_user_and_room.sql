CREATE OR REPLACE FUNCTION public.insert_booking_with_user_and_room(
    p_user_name character varying(100),
    p_user_password character varying(100),
    p_room_id integer,
    p_checkin_date date,
    p_pay_type character varying(100),
    p_number_of_booking integer
)
RETURNS integer -- Change the return type to integer for booking_id
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id integer;
    v_normal_user_id integer;
    v_room_status boolean;
    v_existing_booking_id integer;
    v_new_booking_id integer; -- Variable to hold the new booking_id
BEGIN
    -- Assuming "UserName" is unique
    SELECT "UserID"
    INTO v_user_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_user_name
    AND "UserPassword" = p_user_password;

    IF v_user_id IS NOT NULL THEN
        -- Check if the user is also in NORMAL_USER table
        SELECT "UserID(NORMAL_USER)"
        INTO v_normal_user_id
        FROM public."NORMAL_USER"
        WHERE "UserID(NORMAL_USER)" = v_user_id;

        IF v_normal_user_id IS NOT NULL THEN
            -- Check if the room status is true
            SELECT "Status"
            INTO v_room_status
            FROM public."ROOM"
            WHERE "RoomID" = p_room_id;

            IF v_room_status THEN
                -- Check for overlapping bookings for the same room
                SELECT "BookingID"
                INTO v_existing_booking_id
                FROM public."BOOKING"
                WHERE "RoomID(BOOKING)" = p_room_id
                AND NOT(
                    ("CheckInDate" < p_checkin_date AND "CheckInDate" + "NumberOfBooking"-1 < p_checkin_date)
                    OR
                    ("CheckInDate" > p_checkin_date + p_number_of_booking -1 AND "CheckInDate" + "NumberOfBooking"-1 > p_checkin_date + p_number_of_booking)
                );

                IF v_existing_booking_id IS NULL THEN
                    -- Get the maximum existing booking_id and increment by 1
                    SELECT COALESCE(MAX("BookingID"), 0) + 1
                    INTO v_new_booking_id
                    FROM public."BOOKING";

                    -- Insert the new booking
                    INSERT INTO public."BOOKING"("BookingID", "UserID(BOOKING)", "RoomID(BOOKING)", "CheckInDate", "PayType", "NumberOfBooking")
                    VALUES (v_new_booking_id, v_user_id, p_room_id, p_checkin_date, p_pay_type, p_number_of_booking);

                    -- Return the new booking_id
                    RETURN v_new_booking_id;
                ELSE
                    RAISE EXCEPTION 'Booking already exists for the given room, checkin_date, and number_of_booking';
                END IF;
            ELSE
                RAISE EXCEPTION 'Room status is not available';
            END IF;
        ELSE
            RAISE EXCEPTION 'User found, but not a normal user';
        END IF;
    ELSE
        RAISE EXCEPTION 'User not found with the given credentials';
    END IF;
END;
$$;