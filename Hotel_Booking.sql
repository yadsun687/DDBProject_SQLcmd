--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.1

-- Started on 2024-02-07 06:48:35 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 872 (class 1247 OID 57803)
-- Name: LoginType; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public."LoginType" AS ENUM (
    'LOGIN',
    'LOGOUT'
);


ALTER TYPE public."LoginType" OWNER TO root;

--
-- TOC entry 252 (class 1255 OID 58000)
-- Name: admin_delete_booking(character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.admin_delete_booking(IN p_user_name character varying, IN p_user_password character varying, IN p_booking_id integer)
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


ALTER PROCEDURE public.admin_delete_booking(IN p_user_name character varying, IN p_user_password character varying, IN p_booking_id integer) OWNER TO root;

--
-- TOC entry 253 (class 1255 OID 58001)
-- Name: admin_edit_booking(character varying, character varying, integer, date, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.admin_edit_booking(IN p_admin_name character varying, IN p_admin_password character varying, IN p_booking_id integer, IN p_new_checkin_date date, IN p_new_pay_type character varying, IN p_new_number_of_booking integer)
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


ALTER PROCEDURE public.admin_edit_booking(IN p_admin_name character varying, IN p_admin_password character varying, IN p_booking_id integer, IN p_new_checkin_date date, IN p_new_pay_type character varying, IN p_new_number_of_booking integer) OWNER TO root;

--
-- TOC entry 236 (class 1255 OID 57995)
-- Name: admin_view_bookings(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.admin_view_bookings() RETURNS TABLE("BookingID" integer, "UserID" integer, "UserName" character varying, "UserPassword" character varying, "UserEmail" character varying, "RecentLogin" date, "RoomID" integer, "CheckInDate" date, "PayType" character varying, "NumberOfBooking" integer, "HotelName" character varying, "BranchName" character varying, "Location" character varying, "RoomDecor" character varying, "Accessibility Features" character varying, "RoomType" character varying, "View" character varying, "Building/Floor" character varying, "Bathroom" character varying, "BedConfiguration" character varying, "Services" character varying, "RoomSize" integer, "Wi-Fi" boolean, "MaxPeople" integer, "Smoking" boolean, "Facility" character varying, "Measure" character varying, "Transportation" character varying, "BranchTelephone" character varying, "MarketingStrategy" character varying, "Technology" character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM view_bookings;
END;
$$;


ALTER FUNCTION public.admin_view_bookings() OWNER TO root;

--
-- TOC entry 237 (class 1255 OID 57996)
-- Name: create_login_log(integer, public."LoginType", date); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.create_login_log(user_id integer, login_type public."LoginType", login_date_time date) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO public."LoginLog"("Type", "Date-time", "UserID")
	VALUES (login_type, CURRENT_DATE, user_id);
END;	
$$;


ALTER FUNCTION public.create_login_log(user_id integer, login_type public."LoginType", login_date_time date) OWNER TO root;

--
-- TOC entry 249 (class 1255 OID 57997)
-- Name: insert_booking_with_user_and_room(character varying, character varying, integer, date, character varying, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.insert_booking_with_user_and_room(p_user_name character varying, p_user_password character varying, p_room_id integer, p_checkin_date date, p_pay_type character varying, p_number_of_booking integer) RETURNS integer
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


ALTER FUNCTION public.insert_booking_with_user_and_room(p_user_name character varying, p_user_password character varying, p_room_id integer, p_checkin_date date, p_pay_type character varying, p_number_of_booking integer) OWNER TO root;

--
-- TOC entry 254 (class 1255 OID 58002)
-- Name: login_user(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.login_user(IN p_user_name character varying, IN p_user_password character varying)
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

        -- Call the create_login_log function after a successful login
        PERFORM create_login_log(user_id, 'LOGIN', CURRENT_DATE);

    ELSE
        RAISE NOTICE 'Login failed. User not found or incorrect credentials.';
    END IF;
END;
$$;


ALTER PROCEDURE public.login_user(IN p_user_name character varying, IN p_user_password character varying) OWNER TO root;

--
-- TOC entry 255 (class 1255 OID 58003)
-- Name: logout_user(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.logout_user(IN p_user_name character varying, IN p_user_password character varying)
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

		 -- Call the create_login_log function after a user logout
        PERFORM create_login_log(user_id, 'LOGOUT', CURRENT_DATE);
		
        RAISE NOTICE 'User logged out with UserID: %', user_id;
    ELSE
        RAISE NOTICE 'Logout failed. User not found or incorrect credentials.';
    END IF;
END;
$$;


ALTER PROCEDURE public.logout_user(IN p_user_name character varying, IN p_user_password character varying) OWNER TO root;

--
-- TOC entry 256 (class 1255 OID 58004)
-- Name: register_all_user(character varying, character varying, character varying, character varying[], date, character varying[], character varying[]); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.register_all_user(IN p_user_password character varying, IN p_user_name character varying, IN p_user_email character varying, IN p_role_type character varying[] DEFAULT ARRAY['NORMAL'::text], IN p_birthdate date DEFAULT CURRENT_DATE, IN normaluser_address character varying[] DEFAULT NULL::character varying[], IN normaluser_telephone character varying[] DEFAULT NULL::character varying[])
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


ALTER PROCEDURE public.register_all_user(IN p_user_password character varying, IN p_user_name character varying, IN p_user_email character varying, IN p_role_type character varying[], IN p_birthdate date, IN normaluser_address character varying[], IN normaluser_telephone character varying[]) OWNER TO root;

--
-- TOC entry 257 (class 1255 OID 58005)
-- Name: user_delete_booking(character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.user_delete_booking(IN p_user_name character varying, IN p_user_password character varying, IN p_booking_id integer)
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


ALTER PROCEDURE public.user_delete_booking(IN p_user_name character varying, IN p_user_password character varying, IN p_booking_id integer) OWNER TO root;

--
-- TOC entry 258 (class 1255 OID 58006)
-- Name: user_edit_booking(character varying, character varying, integer, date, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.user_edit_booking(IN p_user_name character varying, IN p_user_password character varying, IN p_booking_id integer, IN p_new_checkin_date date, IN p_new_pay_type character varying, IN p_new_number_of_booking integer)
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


ALTER PROCEDURE public.user_edit_booking(IN p_user_name character varying, IN p_user_password character varying, IN p_booking_id integer, IN p_new_checkin_date date, IN p_new_pay_type character varying, IN p_new_number_of_booking integer) OWNER TO root;

--
-- TOC entry 250 (class 1255 OID 57998)
-- Name: user_view_all_room(character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.user_view_all_room(p_user_name character varying, p_user_password character varying) RETURNS TABLE("RoomID" integer, "HotelName" character varying, "BranchName" character varying, "Location" character varying, "RoomDecor" character varying, "AccessibilityFeatures" character varying, "RoomType" character varying, "View" character varying, "BuildingFloor" character varying, "Bathroom" character varying, "BedConfiguration" character varying, "Services" character varying, "RoomSize" integer, "WiFi" boolean, "MaxPeople" integer, "Smoking" boolean, "Facility" character varying, "Measure" character varying, "Transportation" character varying, "MarketingStrategy" character varying, "Technology" character varying)
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


ALTER FUNCTION public.user_view_all_room(p_user_name character varying, p_user_password character varying) OWNER TO root;

--
-- TOC entry 251 (class 1255 OID 57999)
-- Name: user_view_bookings(character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.user_view_bookings(p_user_name character varying, p_user_password character varying) RETURNS TABLE("BookingID" integer, "UserID" integer, "UserName" character varying, "UserPassword" character varying, "UserEmail" character varying, "RecentLogin" date, "RoomID" integer, "CheckInDate" date, "PayType" character varying, "NumberOfBooking" integer, "HotelName" character varying, "BranchName" character varying, "Location" character varying, "RoomDecor" character varying, "Accessibility Features" character varying, "RoomType" character varying, "View" character varying, "Building/Floor" character varying, "Bathroom" character varying, "BedConfiguration" character varying, "Services" character varying, "RoomSize" integer, "Wi-Fi" boolean, "MaxPeople" integer, "Smoking" boolean, "Facility" character varying, "Measure" character varying, "Transportation" character varying, "BranchTelephone" character varying, "MarketingStrategy" character varying, "Technology" character varying)
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


ALTER FUNCTION public.user_view_bookings(p_user_name character varying, p_user_password character varying) OWNER TO root;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 57807)
-- Name: ADMIN; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."ADMIN" (
    "UserID(ADMIN)" integer NOT NULL
);


ALTER TABLE public."ADMIN" OWNER TO root;

--
-- TOC entry 216 (class 1259 OID 57812)
-- Name: ALL_USER; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."ALL_USER" (
    "UserID" integer NOT NULL,
    "UserPassword" character varying(100),
    "UserName" character varying(100),
    "UserEmail" character varying(100),
    "RecentLogin" date
);


ALTER TABLE public."ALL_USER" OWNER TO root;

--
-- TOC entry 217 (class 1259 OID 57817)
-- Name: BOOKING; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."BOOKING" (
    "BookingID" integer NOT NULL,
    "UserID(BOOKING)" integer,
    "RoomID(BOOKING)" integer,
    "CheckInDate" date,
    "PayType" character varying(100),
    "NumberOfBooking" integer
);


ALTER TABLE public."BOOKING" OWNER TO root;

--
-- TOC entry 218 (class 1259 OID 57822)
-- Name: Branch_Facilities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Branch_Facilities" (
    "BranchID(Branch_Facilities)" integer NOT NULL,
    "Facility" character varying(100)
);


ALTER TABLE public."Branch_Facilities" OWNER TO root;

--
-- TOC entry 219 (class 1259 OID 57827)
-- Name: Branch_SecurityMeasures; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Branch_SecurityMeasures" (
    "BranchID(Branch_SecurityMeasures)" integer,
    "Measure" character varying(100)
);


ALTER TABLE public."Branch_SecurityMeasures" OWNER TO root;

--
-- TOC entry 220 (class 1259 OID 57830)
-- Name: Branch_Telephone; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Branch_Telephone" (
    "BranchID(Branch_Telephone)" integer,
    "BranchTelephone" character varying(100)
);


ALTER TABLE public."Branch_Telephone" OWNER TO root;

--
-- TOC entry 221 (class 1259 OID 57833)
-- Name: Branch_Transportation; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Branch_Transportation" (
    "BranchID(Branch_Transportation)" integer,
    "Transportation" character varying(100)
);


ALTER TABLE public."Branch_Transportation" OWNER TO root;

--
-- TOC entry 222 (class 1259 OID 57836)
-- Name: DETAILS; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."DETAILS" (
    "DetailsID" integer NOT NULL,
    "RoomDecor" character varying(100),
    "Accessibility Features" character varying(100),
    "RoomType" character varying(100),
    "View" character varying(100),
    "Building/Floor" character varying(100),
    "Bathroom" character varying(100),
    "BedConfiguration" character varying(100),
    "Services" character varying(100),
    "RoomSize" integer,
    "Wi-Fi" boolean,
    "MaxPeople" integer,
    "Smoking" boolean
);


ALTER TABLE public."DETAILS" OWNER TO root;

--
-- TOC entry 223 (class 1259 OID 57843)
-- Name: Details_Amentities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Details_Amentities" (
    "DetailsID(Details_Amentities)" integer NOT NULL,
    "Amentities" character varying(100)
);


ALTER TABLE public."Details_Amentities" OWNER TO root;

--
-- TOC entry 224 (class 1259 OID 57848)
-- Name: HOTEL; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."HOTEL" (
    "HotelID" integer NOT NULL,
    "UserID(HOTEL_MANAGER)" integer,
    "HotelName" character varying(100),
    "BrandIdentity" character varying(100)
);


ALTER TABLE public."HOTEL" OWNER TO root;

--
-- TOC entry 225 (class 1259 OID 57853)
-- Name: HOTEL_BRANCH; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."HOTEL_BRANCH" (
    "HotelID(HOTEL_BRANCH)" integer,
    "BranchID" integer NOT NULL,
    "BranchName" character varying(100),
    "Location" character varying(100),
    "DecorAndTheme" character varying(100),
    "Rating/Reviews" integer,
    "ParkingAvailability" boolean,
    "ParkingTypeParking" character varying(100),
    "ParkingCostParking" integer
);


ALTER TABLE public."HOTEL_BRANCH" OWNER TO root;

--
-- TOC entry 226 (class 1259 OID 57858)
-- Name: HOTEL_MANAGER; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."HOTEL_MANAGER" (
    "UserID(HOTEL_MANAGER)" integer NOT NULL
);


ALTER TABLE public."HOTEL_MANAGER" OWNER TO root;

--
-- TOC entry 227 (class 1259 OID 57863)
-- Name: Hotel_MarketingStrategy; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Hotel_MarketingStrategy" (
    "HotelID(Hotel_MarketingStrategy)" integer NOT NULL,
    "Strategy" character varying(100)
);


ALTER TABLE public."Hotel_MarketingStrategy" OWNER TO root;

--
-- TOC entry 228 (class 1259 OID 57868)
-- Name: Hotel_Technology; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."Hotel_Technology" (
    "HotelID(Hotel_Technology)" integer NOT NULL,
    "Technology" character varying(100)
);


ALTER TABLE public."Hotel_Technology" OWNER TO root;

--
-- TOC entry 234 (class 1259 OID 57894)
-- Name: LoginLog; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."LoginLog" (
    "LoginID" bigint NOT NULL,
    "Type" public."LoginType" NOT NULL,
    "Date-time" date NOT NULL,
    "UserID" integer NOT NULL
);


ALTER TABLE public."LoginLog" OWNER TO root;

--
-- TOC entry 233 (class 1259 OID 57893)
-- Name: LoginLog_LoginID_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public."LoginLog_LoginID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."LoginLog_LoginID_seq" OWNER TO root;

--
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 233
-- Name: LoginLog_LoginID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public."LoginLog_LoginID_seq" OWNED BY public."LoginLog"."LoginID";


--
-- TOC entry 229 (class 1259 OID 57873)
-- Name: NORMAL_USER; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."NORMAL_USER" (
    "UserID(NORMAL_USER)" integer NOT NULL,
    "BirthDate" date
);


ALTER TABLE public."NORMAL_USER" OWNER TO root;

--
-- TOC entry 230 (class 1259 OID 57878)
-- Name: NormalUser_Address; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."NormalUser_Address" (
    "UserID(NormalUser_Address)" integer NOT NULL,
    "UserAddress" character varying(100)
);


ALTER TABLE public."NormalUser_Address" OWNER TO root;

--
-- TOC entry 231 (class 1259 OID 57883)
-- Name: NormalUser_Telephone; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."NormalUser_Telephone" (
    "UserID(NormalUser_Telephone)" integer NOT NULL,
    "UserTelephone" character varying(100)
);


ALTER TABLE public."NormalUser_Telephone" OWNER TO root;

--
-- TOC entry 232 (class 1259 OID 57888)
-- Name: ROOM; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public."ROOM" (
    "BranchID(ROOM)" integer,
    "RoomID" integer NOT NULL,
    "DetailsID(ROOM)" integer,
    "Status" boolean,
    "PriceNormal" integer,
    "PriceWeekend" integer,
    "PriceEvent" integer
);


ALTER TABLE public."ROOM" OWNER TO root;

--
-- TOC entry 235 (class 1259 OID 58007)
-- Name: view_bookings; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.view_bookings AS
 SELECT b."BookingID",
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
   FROM (((((((((((public."BOOKING" b
     JOIN public."ROOM" r ON ((b."RoomID(BOOKING)" = r."RoomID")))
     JOIN public."DETAILS" d ON ((r."DetailsID(ROOM)" = d."DetailsID")))
     JOIN public."HOTEL_BRANCH" hb ON ((r."BranchID(ROOM)" = hb."BranchID")))
     JOIN public."HOTEL" h ON ((hb."HotelID(HOTEL_BRANCH)" = h."HotelID")))
     JOIN public."ALL_USER" u ON ((b."UserID(BOOKING)" = u."UserID")))
     LEFT JOIN public."Branch_Facilities" bf ON ((r."BranchID(ROOM)" = bf."BranchID(Branch_Facilities)")))
     LEFT JOIN public."Branch_SecurityMeasures" sm ON ((r."BranchID(ROOM)" = sm."BranchID(Branch_SecurityMeasures)")))
     LEFT JOIN public."Branch_Transportation" tr ON ((r."BranchID(ROOM)" = tr."BranchID(Branch_Transportation)")))
     LEFT JOIN public."Branch_Telephone" tel ON ((r."BranchID(ROOM)" = tel."BranchID(Branch_Telephone)")))
     LEFT JOIN public."Hotel_MarketingStrategy" ms ON ((hb."HotelID(HOTEL_BRANCH)" = ms."HotelID(Hotel_MarketingStrategy)")))
     LEFT JOIN public."Hotel_Technology" tech ON ((hb."HotelID(HOTEL_BRANCH)" = tech."HotelID(Hotel_Technology)")));


ALTER VIEW public.view_bookings OWNER TO root;

--
-- TOC entry 3294 (class 2604 OID 57897)
-- Name: LoginLog LoginID; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."LoginLog" ALTER COLUMN "LoginID" SET DEFAULT nextval('public."LoginLog_LoginID_seq"'::regclass);


--
-- TOC entry 3490 (class 0 OID 57807)
-- Dependencies: 215
-- Data for Name: ADMIN; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3491 (class 0 OID 57812)
-- Dependencies: 216
-- Data for Name: ALL_USER; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3492 (class 0 OID 57817)
-- Dependencies: 217
-- Data for Name: BOOKING; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3493 (class 0 OID 57822)
-- Dependencies: 218
-- Data for Name: Branch_Facilities; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3494 (class 0 OID 57827)
-- Dependencies: 219
-- Data for Name: Branch_SecurityMeasures; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3495 (class 0 OID 57830)
-- Dependencies: 220
-- Data for Name: Branch_Telephone; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3496 (class 0 OID 57833)
-- Dependencies: 221
-- Data for Name: Branch_Transportation; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3497 (class 0 OID 57836)
-- Dependencies: 222
-- Data for Name: DETAILS; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3498 (class 0 OID 57843)
-- Dependencies: 223
-- Data for Name: Details_Amentities; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3499 (class 0 OID 57848)
-- Dependencies: 224
-- Data for Name: HOTEL; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3500 (class 0 OID 57853)
-- Dependencies: 225
-- Data for Name: HOTEL_BRANCH; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3501 (class 0 OID 57858)
-- Dependencies: 226
-- Data for Name: HOTEL_MANAGER; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3502 (class 0 OID 57863)
-- Dependencies: 227
-- Data for Name: Hotel_MarketingStrategy; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3503 (class 0 OID 57868)
-- Dependencies: 228
-- Data for Name: Hotel_Technology; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3509 (class 0 OID 57894)
-- Dependencies: 234
-- Data for Name: LoginLog; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3504 (class 0 OID 57873)
-- Dependencies: 229
-- Data for Name: NORMAL_USER; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3505 (class 0 OID 57878)
-- Dependencies: 230
-- Data for Name: NormalUser_Address; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3506 (class 0 OID 57883)
-- Dependencies: 231
-- Data for Name: NormalUser_Telephone; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3507 (class 0 OID 57888)
-- Dependencies: 232
-- Data for Name: ROOM; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 233
-- Name: LoginLog_LoginID_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public."LoginLog_LoginID_seq"', 1, false);


--
-- TOC entry 3296 (class 2606 OID 57811)
-- Name: ADMIN ADMIN_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."ADMIN"
    ADD CONSTRAINT "ADMIN_pkey" PRIMARY KEY ("UserID(ADMIN)");


--
-- TOC entry 3298 (class 2606 OID 57816)
-- Name: ALL_USER ALL_USER_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."ALL_USER"
    ADD CONSTRAINT "ALL_USER_pkey" PRIMARY KEY ("UserID");


--
-- TOC entry 3300 (class 2606 OID 57821)
-- Name: BOOKING BOOKING_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."BOOKING"
    ADD CONSTRAINT "BOOKING_pkey" PRIMARY KEY ("BookingID");


--
-- TOC entry 3302 (class 2606 OID 57826)
-- Name: Branch_Facilities Branch_Facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Branch_Facilities"
    ADD CONSTRAINT "Branch_Facilities_pkey" PRIMARY KEY ("BranchID(Branch_Facilities)");


--
-- TOC entry 3304 (class 2606 OID 57842)
-- Name: DETAILS DETAILS_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."DETAILS"
    ADD CONSTRAINT "DETAILS_pkey" PRIMARY KEY ("DetailsID");


--
-- TOC entry 3306 (class 2606 OID 57847)
-- Name: Details_Amentities Details_Amentities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Details_Amentities"
    ADD CONSTRAINT "Details_Amentities_pkey" PRIMARY KEY ("DetailsID(Details_Amentities)");


--
-- TOC entry 3310 (class 2606 OID 57857)
-- Name: HOTEL_BRANCH HOTEL_BRANCH_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."HOTEL_BRANCH"
    ADD CONSTRAINT "HOTEL_BRANCH_pkey" PRIMARY KEY ("BranchID");


--
-- TOC entry 3312 (class 2606 OID 57862)
-- Name: HOTEL_MANAGER HOTEL_MANAGER_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."HOTEL_MANAGER"
    ADD CONSTRAINT "HOTEL_MANAGER_pkey" PRIMARY KEY ("UserID(HOTEL_MANAGER)");


--
-- TOC entry 3308 (class 2606 OID 57852)
-- Name: HOTEL HOTEL_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."HOTEL"
    ADD CONSTRAINT "HOTEL_pkey" PRIMARY KEY ("HotelID");


--
-- TOC entry 3314 (class 2606 OID 57867)
-- Name: Hotel_MarketingStrategy Hotel_MarketingStrategy_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Hotel_MarketingStrategy"
    ADD CONSTRAINT "Hotel_MarketingStrategy_pkey" PRIMARY KEY ("HotelID(Hotel_MarketingStrategy)");


--
-- TOC entry 3316 (class 2606 OID 57872)
-- Name: Hotel_Technology Hotel_Technology_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Hotel_Technology"
    ADD CONSTRAINT "Hotel_Technology_pkey" PRIMARY KEY ("HotelID(Hotel_Technology)");


--
-- TOC entry 3326 (class 2606 OID 57899)
-- Name: LoginLog LoginLog_Pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."LoginLog"
    ADD CONSTRAINT "LoginLog_Pkey" PRIMARY KEY ("LoginID");


--
-- TOC entry 3318 (class 2606 OID 57877)
-- Name: NORMAL_USER NORMAL_USER_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."NORMAL_USER"
    ADD CONSTRAINT "NORMAL_USER_pkey" PRIMARY KEY ("UserID(NORMAL_USER)");


--
-- TOC entry 3320 (class 2606 OID 57882)
-- Name: NormalUser_Address NormalUser_Address_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."NormalUser_Address"
    ADD CONSTRAINT "NormalUser_Address_pkey" PRIMARY KEY ("UserID(NormalUser_Address)");


--
-- TOC entry 3322 (class 2606 OID 57887)
-- Name: NormalUser_Telephone NormalUser_Telephone_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."NormalUser_Telephone"
    ADD CONSTRAINT "NormalUser_Telephone_pkey" PRIMARY KEY ("UserID(NormalUser_Telephone)");


--
-- TOC entry 3324 (class 2606 OID 57892)
-- Name: ROOM ROOM_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."ROOM"
    ADD CONSTRAINT "ROOM_pkey" PRIMARY KEY ("RoomID");


--
-- TOC entry 3330 (class 2606 OID 57915)
-- Name: Branch_Facilities BranchID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Branch_Facilities"
    ADD CONSTRAINT "BranchID" FOREIGN KEY ("BranchID(Branch_Facilities)") REFERENCES public."HOTEL_BRANCH"("BranchID");


--
-- TOC entry 3331 (class 2606 OID 57920)
-- Name: Branch_SecurityMeasures BranchID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Branch_SecurityMeasures"
    ADD CONSTRAINT "BranchID" FOREIGN KEY ("BranchID(Branch_SecurityMeasures)") REFERENCES public."HOTEL_BRANCH"("BranchID") NOT VALID;


--
-- TOC entry 3332 (class 2606 OID 57925)
-- Name: Branch_Telephone BranchID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Branch_Telephone"
    ADD CONSTRAINT "BranchID" FOREIGN KEY ("BranchID(Branch_Telephone)") REFERENCES public."HOTEL_BRANCH"("BranchID") NOT VALID;


--
-- TOC entry 3333 (class 2606 OID 57930)
-- Name: Branch_Transportation BranchID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Branch_Transportation"
    ADD CONSTRAINT "BranchID" FOREIGN KEY ("BranchID(Branch_Transportation)") REFERENCES public."HOTEL_BRANCH"("BranchID");


--
-- TOC entry 3343 (class 2606 OID 57980)
-- Name: ROOM BranchID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."ROOM"
    ADD CONSTRAINT "BranchID" FOREIGN KEY ("BranchID(ROOM)") REFERENCES public."HOTEL_BRANCH"("BranchID") NOT VALID;


--
-- TOC entry 3334 (class 2606 OID 57935)
-- Name: Details_Amentities DetailsID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Details_Amentities"
    ADD CONSTRAINT "DetailsID" FOREIGN KEY ("DetailsID(Details_Amentities)") REFERENCES public."DETAILS"("DetailsID");


--
-- TOC entry 3344 (class 2606 OID 57985)
-- Name: ROOM DetailsID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."ROOM"
    ADD CONSTRAINT "DetailsID" FOREIGN KEY ("DetailsID(ROOM)") REFERENCES public."DETAILS"("DetailsID") NOT VALID;


--
-- TOC entry 3336 (class 2606 OID 57945)
-- Name: HOTEL_BRANCH HotelID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."HOTEL_BRANCH"
    ADD CONSTRAINT "HotelID" FOREIGN KEY ("HotelID(HOTEL_BRANCH)") REFERENCES public."HOTEL"("HotelID");


--
-- TOC entry 3338 (class 2606 OID 57955)
-- Name: Hotel_MarketingStrategy HotelID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Hotel_MarketingStrategy"
    ADD CONSTRAINT "HotelID" FOREIGN KEY ("HotelID(Hotel_MarketingStrategy)") REFERENCES public."HOTEL"("HotelID") NOT VALID;


--
-- TOC entry 3339 (class 2606 OID 57960)
-- Name: Hotel_Technology HotelID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."Hotel_Technology"
    ADD CONSTRAINT "HotelID" FOREIGN KEY ("HotelID(Hotel_Technology)") REFERENCES public."HOTEL"("HotelID") NOT VALID;


--
-- TOC entry 3328 (class 2606 OID 57905)
-- Name: BOOKING RoomID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."BOOKING"
    ADD CONSTRAINT "RoomID" FOREIGN KEY ("RoomID(BOOKING)") REFERENCES public."ROOM"("RoomID") NOT VALID;


--
-- TOC entry 3327 (class 2606 OID 57900)
-- Name: ADMIN UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."ADMIN"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(ADMIN)") REFERENCES public."ALL_USER"("UserID") NOT VALID;


--
-- TOC entry 3329 (class 2606 OID 57910)
-- Name: BOOKING UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."BOOKING"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(BOOKING)") REFERENCES public."NORMAL_USER"("UserID(NORMAL_USER)") NOT VALID;


--
-- TOC entry 3335 (class 2606 OID 57940)
-- Name: HOTEL UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."HOTEL"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(HOTEL_MANAGER)") REFERENCES public."HOTEL_MANAGER"("UserID(HOTEL_MANAGER)") NOT VALID;


--
-- TOC entry 3337 (class 2606 OID 57950)
-- Name: HOTEL_MANAGER UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."HOTEL_MANAGER"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(HOTEL_MANAGER)") REFERENCES public."ALL_USER"("UserID") NOT VALID;


--
-- TOC entry 3340 (class 2606 OID 57965)
-- Name: NORMAL_USER UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."NORMAL_USER"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(NORMAL_USER)") REFERENCES public."ALL_USER"("UserID") NOT VALID;


--
-- TOC entry 3341 (class 2606 OID 57970)
-- Name: NormalUser_Address UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."NormalUser_Address"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(NormalUser_Address)") REFERENCES public."NORMAL_USER"("UserID(NORMAL_USER)") NOT VALID;


--
-- TOC entry 3342 (class 2606 OID 57975)
-- Name: NormalUser_Telephone UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."NormalUser_Telephone"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID(NormalUser_Telephone)") REFERENCES public."NORMAL_USER"("UserID(NORMAL_USER)");


--
-- TOC entry 3345 (class 2606 OID 57990)
-- Name: LoginLog UserID; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public."LoginLog"
    ADD CONSTRAINT "UserID" FOREIGN KEY ("UserID") REFERENCES public."ALL_USER"("UserID");


-- Completed on 2024-02-07 06:48:35 UTC

--
-- PostgreSQL database dump complete
--

