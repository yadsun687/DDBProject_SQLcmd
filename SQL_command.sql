CREATE OR REPLACE PROCEDURE register_all_user(
    p_user_password VARCHAR(100),
    p_user_name VARCHAR(100),
    p_user_email VARCHAR(100),
    p_role_type VARCHAR[] DEFAULT ARRAY['NORMAL'], -- default to NORMAL
    p_BirthDate DATE DEFAULT CURRENT_DATE,
    NormalUser_Address VARCHAR[] DEFAULT NULL,
    NormalUser_Telephone VARCHAR[] DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_user_id INTEGER;
    role VARCHAR;
    i INTEGER;
BEGIN
    -- Check for uniqueness of username, email, and password
    IF EXISTS (
        SELECT 1
        FROM public."ALL_USER"
        WHERE "UserName" = p_user_name
           AND "UserPassword" = p_user_password
    ) THEN
        RAISE EXCEPTION 'User with the same username, email, or password already exists.';
    END IF;

    -- Generate a new UserID
    SELECT COALESCE(MAX("UserID"), 0) + 1 INTO new_user_id FROM public."ALL_USER";

    -- Insert the new user into the ALL_USER table
    INSERT INTO public."ALL_USER"("UserID", "UserPassword", "UserName", "UserEmail", "RecentLogin")
    VALUES (new_user_id, p_user_password, p_user_name, p_user_email, '0001-01-01');

    -- Iterate through the roles and insert the user into corresponding role tables
    FOREACH role IN ARRAY p_role_type
    LOOP
        IF role = 'NORMAL' THEN
            INSERT INTO public."NORMAL_USER"("UserID(NORMAL_USER)", "BirthDate")
            VALUES (new_user_id, p_BirthDate);

            -- Use loop to INSERT NormalUser_Address only if it doesn't already exist
            FOR i IN 1..array_length(NormalUser_Address, 1)
            LOOP
                BEGIN
                    INSERT INTO public."NormalUser_Address"("UserID(NormalUser_Address)", "UserAddress")
                    VALUES (new_user_id, NormalUser_Address[i]);
                EXCEPTION
                    WHEN unique_violation THEN
                        -- Ignore duplicate entries
                        CONTINUE;
                END;
            END LOOP;

            -- Use loop to INSERT NormalUser_Telephone only if it doesn't already exist
            FOR i IN 1..array_length(NormalUser_Telephone, 1)
            LOOP
                BEGIN
                    INSERT INTO public."NormalUser_Telephone"("UserID(NormalUser_Telephone)", "UserTelephone")
                    VALUES (new_user_id, NormalUser_Telephone[i]);
                EXCEPTION
                    WHEN unique_violation THEN
                        -- Ignore duplicate entries
                        CONTINUE;
                END;
            END LOOP;
            
        ELSIF role = 'ADMIN' THEN
            INSERT INTO public."ADMIN"("UserID(ADMIN)")
            VALUES (new_user_id);
        ELSIF role = 'MANAGER' THEN
            INSERT INTO public."HOTEL_MANAGER"("UserID(HOTEL_MANAGER)")
            VALUES (new_user_id);
        END IF;
    END LOOP;

    -- Raise a NOTICE with the new_user_id
    RAISE NOTICE 'New user registered with UserID: %', new_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE login_user(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Find the user ID based on the provided username and password
    SELECT "UserID" INTO user_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_user_name AND "UserPassword" = p_user_password;

    -- If the user is found, update the RecentLogin field to today's date
    IF user_id IS NOT NULL THEN
        UPDATE public."ALL_USER"
        SET "RecentLogin" = CURRENT_DATE
        WHERE "UserID" = user_id;

        RAISE NOTICE 'User logged in with UserID: %', user_id;
    ELSE
        RAISE NOTICE 'Login failed. User not found or incorrect credentials.';
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE logout_user(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
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

        RAISE NOTICE 'User logged out with UserID: %', user_id;
    ELSE
        RAISE NOTICE 'Logout failed. User not found or incorrect credentials.';
    END IF;
END;
$$;


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

-- Create the view
CREATE OR REPLACE VIEW view_bookings AS
SELECT
    b."BookingID",
    b."UserID(BOOKING)",
    u."UserName",
	u."UserPassword",
    u."UserEmail",
    u."RecentLogin",
    b."RoomID(BOOKING)",
    b."CheckInDate",
    b."PayType",
    b."NumberOfBooking",
    h."HotelName",
    hb."BranchName",
    hb."Location",
    d."RoomDecor",
    d."Accessibility Features",
    d."RoomType",
    d."View",
    d."Building/Floor",
    d."Bathroom",
    d."BedConfiguration",
    d."Services",
    d."RoomSize",
    d."Wi-Fi",
    d."MaxPeople",
    d."Smoking",
    bf."Facility",
    sm."Measure",
    tr."Transportation",
    tel."BranchTelephone",
    ms."Strategy" AS marketing_strategy,
    tech."Technology"
FROM public."BOOKING" b
JOIN public."ROOM" r ON b."RoomID(BOOKING)" = r."RoomID"
JOIN public."DETAILS" d ON r."DetailsID(ROOM)" = d."DetailsID"
JOIN public."HOTEL_BRANCH" hb ON r."BranchID(ROOM)" = hb."BranchID"
JOIN public."HOTEL" h ON hb."HotelID(HOTEL_BRANCH)" = h."HotelID"
JOIN public."ALL_USER" u ON b."UserID(BOOKING)" = u."UserID"
LEFT JOIN public."Branch_Facilities" bf ON r."BranchID(ROOM)" = bf."BranchID(Branch_Facilities)"
LEFT JOIN public."Branch_SecurityMeasures" sm ON r."BranchID(ROOM)" = sm."BranchID(Branch_SecurityMeasures)"
LEFT JOIN public."Branch_Transportation" tr ON r."BranchID(ROOM)" = tr."BranchID(Branch_Transportation)"
LEFT JOIN public."Branch_Telephone" tel ON r."BranchID(ROOM)" = tel."BranchID(Branch_Telephone)"
LEFT JOIN public."Hotel_MarketingStrategy" ms ON hb."HotelID(HOTEL_BRANCH)" = ms."HotelID(Hotel_MarketingStrategy)"
LEFT JOIN public."Hotel_Technology" tech ON hb."HotelID(HOTEL_BRANCH)" = tech."HotelID(Hotel_Technology)";

-- Create the function for normal users
CREATE OR REPLACE FUNCTION user_view_bookings(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100)
)
RETURNS TABLE (
    "BookingID" INTEGER,
    "UserID" INTEGER,
    "UserName" VARCHAR(100),
    "UserPassword" VARCHAR(100),
    "UserEmail" VARCHAR(100),
    "RecentLogin" DATE,
    "RoomID" INTEGER,
    "CheckInDate" DATE,
    "PayType" VARCHAR(100),
    "NumberOfBooking" INTEGER,
    "HotelName" VARCHAR(100),
    "BranchName" VARCHAR(100),
    "Location" VARCHAR(100),
    "RoomDecor" VARCHAR(100),
    "Accessibility Features" VARCHAR(100),
    "RoomType" VARCHAR(100),
    "View" VARCHAR(100),
    "Building/Floor" VARCHAR(100),
    "Bathroom" VARCHAR(100),
    "BedConfiguration" VARCHAR(100),
    "Services" VARCHAR(100),
    "RoomSize" INTEGER,
    "Wi-Fi" BOOLEAN,
    "MaxPeople" INTEGER,
    "Smoking" BOOLEAN,
    "Facility" VARCHAR(100),
    "Measure" VARCHAR(100),
    "Transportation" VARCHAR(100),
    "BranchTelephone" VARCHAR(100),
    "MarketingStrategy" VARCHAR(100),
    "Technology" VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b."BookingID",
        b."UserID(BOOKING)",
        u."UserName",
        u."UserPassword",
        u."UserEmail",
        u."RecentLogin",
        b."RoomID(BOOKING)",
        b."CheckInDate",
        b."PayType",
        b."NumberOfBooking",
        h."HotelName",
        hb."BranchName",
        hb."Location",
        d."RoomDecor",
        d."Accessibility Features",
        d."RoomType",
        d."View",
        d."Building/Floor",
        d."Bathroom",
        d."BedConfiguration",
        d."Services",
        d."RoomSize",
        d."Wi-Fi",
        d."MaxPeople",
        d."Smoking",
        bf."Facility",
        sm."Measure",
        tr."Transportation",
        tel."BranchTelephone",
        ms."Strategy" AS marketing_strategy,
        tech."Technology"
    FROM public."BOOKING" b
    JOIN public."ROOM" r ON b."RoomID(BOOKING)" = r."RoomID"
    JOIN public."DETAILS" d ON r."DetailsID(ROOM)" = d."DetailsID"
    JOIN public."HOTEL_BRANCH" hb ON r."BranchID(ROOM)" = hb."BranchID"
    JOIN public."HOTEL" h ON hb."HotelID(HOTEL_BRANCH)" = h."HotelID"
    JOIN public."ALL_USER" u ON b."UserID(BOOKING)" = u."UserID"
    LEFT JOIN public."Branch_Facilities" bf ON r."BranchID(ROOM)" = bf."BranchID(Branch_Facilities)"
    LEFT JOIN public."Branch_SecurityMeasures" sm ON r."BranchID(ROOM)" = sm."BranchID(Branch_SecurityMeasures)"
    LEFT JOIN public."Branch_Transportation" tr ON r."BranchID(ROOM)" = tr."BranchID(Branch_Transportation)"
    LEFT JOIN public."Branch_Telephone" tel ON r."BranchID(ROOM)" = tel."BranchID(Branch_Telephone)"
    LEFT JOIN public."Hotel_MarketingStrategy" ms ON hb."HotelID(HOTEL_BRANCH)" = ms."HotelID(Hotel_MarketingStrategy)"
    LEFT JOIN public."Hotel_Technology" tech ON hb."HotelID(HOTEL_BRANCH)" = tech."HotelID(Hotel_Technology)"
    WHERE u."UserName" = p_user_name AND u."UserPassword" = p_user_password;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;
END;
$$;



-- Create the function for admin users
CREATE OR REPLACE FUNCTION admin_view_bookings()
RETURNS TABLE (
    "BookingID" INTEGER,
    "UserID" INTEGER,
    "UserName" VARCHAR(100),
    "UserPassword" VARCHAR(100),
    "UserEmail" VARCHAR(100),
    "RecentLogin" DATE,
    "RoomID" INTEGER,
    "CheckInDate" DATE,
    "PayType" VARCHAR(100),
    "NumberOfBooking" INTEGER,
    "HotelName" VARCHAR(100),
    "BranchName" VARCHAR(100),
    "Location" VARCHAR(100),
    "RoomDecor" VARCHAR(100),
    "Accessibility Features" VARCHAR(100),
    "RoomType" VARCHAR(100),
    "View" VARCHAR(100),
    "Building/Floor" VARCHAR(100),
    "Bathroom" VARCHAR(100),
    "BedConfiguration" VARCHAR(100),
    "Services" VARCHAR(100),
    "RoomSize" INTEGER,
    "Wi-Fi" BOOLEAN,
    "MaxPeople" INTEGER,
    "Smoking" BOOLEAN,
    "Facility" VARCHAR(100),
    "Measure" VARCHAR(100),
    "Transportation" VARCHAR(100),
    "BranchTelephone" VARCHAR(100),
    "MarketingStrategy" VARCHAR(100),
    "Technology" VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM view_bookings;
END;
$$;

SELECT * FROM user_view_bookings('john_doe', 'password123');

-- Create the function for normal users
CREATE OR REPLACE FUNCTION user_view_all_room(
    p_user_name VARCHAR(100),
    p_user_password VARCHAR(100)
)
RETURNS TABLE (
    "RoomID" INTEGER,
    "HotelName" VARCHAR(100),
    "BranchName" VARCHAR(100),
    "Location" VARCHAR(100),
    "RoomDecor" VARCHAR(100),
    "AccessibilityFeatures" VARCHAR(100),
    "RoomType" VARCHAR(100),
    "View" VARCHAR(100),
    "BuildingFloor" VARCHAR(100),
    "Bathroom" VARCHAR(100),
    "BedConfiguration" VARCHAR(100),
    "Services" VARCHAR(100),
    "RoomSize" INTEGER,
    "WiFi" BOOLEAN,
    "MaxPeople" INTEGER,
    "Smoking" BOOLEAN,
    "Facility" VARCHAR(100),
    "Measure" VARCHAR(100),
    "Transportation" VARCHAR(100),
    "MarketingStrategy" VARCHAR(100),
    "Technology" VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_id INTEGER;
    is_today_recent_login BOOLEAN;
BEGIN
    -- Check if the user exists and the password is correct
    SELECT "UserID"
    INTO user_id
    FROM public."ALL_USER"
    WHERE "UserName" = p_user_name
      AND "UserPassword" = p_user_password;

    IF user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid username or password.';
    END IF;

    -- Check if the user is in the NORMAL_USER table
    IF NOT EXISTS (
        SELECT 1
        FROM public."NORMAL_USER"
        WHERE "UserID(NORMAL_USER)" = user_id
    ) THEN
        RAISE EXCEPTION 'User is not in NORMAL_USER table.';
    END IF;

    -- Check if RecentLogin is today
    SELECT true
    INTO is_today_recent_login
    FROM public."ALL_USER"
    WHERE "UserID" = user_id
      AND "RecentLogin" = CURRENT_DATE;

    IF NOT is_today_recent_login THEN
        RAISE EXCEPTION 'RecentLogin is not today.';
    END IF;

    -- Retrieve the user's bookings along with related information
    RETURN QUERY
    SELECT
        r."RoomID",
        h."HotelName",
        hb."BranchName",
        hb."Location",
        d."RoomDecor",
        d."Accessibility Features",
        d."RoomType",
        d."View",
        d."Building/Floor",
        d."Bathroom",
        d."BedConfiguration",
        d."Services",
        d."RoomSize",
        d."Wi-Fi",
        d."MaxPeople",
        d."Smoking",
        bf."Facility",
        sm."Measure",
        tr."Transportation",
        ms."Strategy" AS "MarketingStrategy",
        tech."Technology"
    FROM public."ROOM" r
    JOIN public."DETAILS" d ON r."DetailsID(ROOM)" = d."DetailsID"
    JOIN public."HOTEL_BRANCH" hb ON r."BranchID(ROOM)" = hb."BranchID"
    JOIN public."HOTEL" h ON hb."HotelID(HOTEL_BRANCH)" = h."HotelID"
    LEFT JOIN public."Branch_Facilities" bf ON r."BranchID(ROOM)" = bf."BranchID(Branch_Facilities)"
	LEFT JOIN public."Branch_SecurityMeasures" sm ON r."BranchID(ROOM)" = sm."BranchID(Branch_SecurityMeasures)"
	LEFT JOIN public."Branch_Transportation" tr ON r."BranchID(ROOM)" = tr."BranchID(Branch_Transportation)"
	LEFT JOIN public."Branch_Telephone" tel ON r."BranchID(ROOM)" = tel."BranchID(Branch_Telephone)"
	LEFT JOIN public."Hotel_MarketingStrategy" ms ON hb."HotelID(HOTEL_BRANCH)" = ms."HotelID(Hotel_MarketingStrategy)"
	LEFT JOIN public."Hotel_Technology" tech ON hb."HotelID(HOTEL_BRANCH)" = tech."HotelID(Hotel_Technology)"
    WHERE r."Status" = true;
END;
$$;



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
$$


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