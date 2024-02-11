--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.1

-- Started on 2024-02-11 12:53:04 UTC

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
-- TOC entry 235 (class 1255 OID 24681)
-- Name: admins_delete_bookings(character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.admins_delete_bookings(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    -- Get user ID based on email and password
    SELECT UserID INTO v_user_id
    FROM public.ALL_USER
    WHERE UserEmail = p_user_email AND UserPassword = p_user_password;

    -- Check if the user is found
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found with the given credentials';
    END IF;

    -- Check if the user is an admin
    IF NOT EXISTS (
        SELECT 1
        FROM public.admins
        WHERE UserID = v_user_id
    ) THEN
        RAISE EXCEPTION 'User found, but not an admin';
    END IF;

    -- Check if the booking exists
    IF NOT EXISTS (
        SELECT 1
        FROM public.BOOKING
        WHERE BookingID = p_booking_id
    ) THEN
        RAISE EXCEPTION 'Booking not found with the given ID';
    END IF;

    -- Delete the booking
    DELETE FROM public.BOOKING
    WHERE BookingID = p_booking_id;
END;
$$;


ALTER PROCEDURE public.admins_delete_bookings(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer) OWNER TO root;

--
-- TOC entry 247 (class 1255 OID 24682)
-- Name: admins_edit_bookings(character varying, character varying, integer, date, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.admins_edit_bookings(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer, IN p_new_checkin_date date DEFAULT NULL::date, IN p_new_pay_type character varying DEFAULT NULL::character varying, IN p_new_number_of_booking integer DEFAULT NULL::integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    -- Get user ID based on email and password
    SELECT UserID INTO v_user_id
    FROM public.ALL_USER
    WHERE UserEmail = p_user_email AND UserPassword = p_user_password;

    -- Check if the user is found
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found with the given credentials';
    END IF;

    -- Check if the user is an admin
    IF NOT EXISTS (
        SELECT 1
        FROM public.admins
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


ALTER PROCEDURE public.admins_edit_bookings(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer, IN p_new_checkin_date date, IN p_new_pay_type character varying, IN p_new_number_of_booking integer) OWNER TO root;

--
-- TOC entry 248 (class 1255 OID 24683)
-- Name: admins_view_all_bookings(character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.admins_view_all_bookings(p_user_email character varying, p_user_password character varying) RETURNS TABLE(bookingid integer, userid integer, checkindate date, paytype character varying, numberofbooking integer, roomid integer, hotelid integer, hotelname character varying, branchid integer, branchname character varying, branch_location character varying, decorandtheme character varying, rating_reviews integer, parkingavailability boolean, parkingtypeparking character varying, parkingcostparking integer, roomdecor character varying, accessibilityfeatures character varying, roomtype character varying, roomview character varying, buildingfloor character varying, bathroom character varying, bedconfiguration character varying, services character varying, roomsize integer, wifi boolean, maxpeople integer, smoking boolean, facility character varying, measure character varying, transportation character varying, marketingstrategy character varying, technology character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    -- Check if the user exists and the password is correct
    SELECT all_user.userid INTO v_user_id
    FROM public.all_user
    WHERE all_user.useremail = p_user_email AND all_user.userpassword = p_user_password;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid email or password.';
    END IF;

    -- Check if the user is in the admins table
    IF NOT EXISTS (
        SELECT 1
        FROM public.admins
        WHERE admins.userid = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is not an admin.';
    END IF;

    -- Return booking details
    RETURN QUERY
    SELECT
        b.bookingid,
        b.userid,
        b.checkindate,
        b.paytype,
        b.numberofbooking,
        r.roomid,
        h.hotelid,
        h.hotelname,
        hb.branchid,
        hb.branchname,
        hb.branch_location,
        hb.decorandtheme,
        hb.rating_reviews,
        hb.parkingavailability,
        hb.parkingtypeparking,
        hb.parkingcostparking,
        d.roomdecor,
        da.amentities AS accessibilityfeatures,
        d.roomtype,
        d.roomview,
        d.building_floor AS buildingfloor,
        d.bathroom,
        d.bedconfiguration,
        d.services,
        d.roomsize,
        d.wifi,
        d.maxpeople,
        d.smoking,
        bf.facility,
        sm.measure,
        tr.transportation,
        ms.strategy AS marketingstrategy,
        tech.technology
    FROM 
        public.booking b
    JOIN 
        public.room r ON b.roomid = r.roomid
    JOIN 
        public.details d ON r.detailsid = d.detailsid
    JOIN 
        public.details_amentities da ON d.detailsid = da.detailsid
    JOIN 
        public.hotel_branch hb ON r.branchid = hb.branchid
    JOIN 
        public.hotel h ON hb.hotelid = h.hotelid
    LEFT JOIN 
        public.branch_facilities bf ON r.branchid = bf.branchid
    LEFT JOIN 
        public.branch_securitymeasures sm ON r.branchid = sm.branchid
    LEFT JOIN 
        public.branch_transportation tr ON r.branchid = tr.branchid
    LEFT JOIN 
        public.hotel_marketingstrategy ms ON hb.hotelid = ms.hotelid
    LEFT JOIN 
        public.hotel_technology tech ON hb.hotelid = tech.hotelid;
END;
$$;


ALTER FUNCTION public.admins_view_all_bookings(p_user_email character varying, p_user_password character varying) OWNER TO root;

--
-- TOC entry 249 (class 1255 OID 24684)
-- Name: insert_booking_with_user_and_room(character varying, character varying, integer, date, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.insert_booking_with_user_and_room(IN p_user_email character varying, IN p_user_password character varying, IN p_room_id integer, IN p_checkin_date date, IN p_pay_type character varying, IN p_number_of_booking integer)
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


ALTER PROCEDURE public.insert_booking_with_user_and_room(IN p_user_email character varying, IN p_user_password character varying, IN p_room_id integer, IN p_checkin_date date, IN p_pay_type character varying, IN p_number_of_booking integer) OWNER TO root;

--
-- TOC entry 250 (class 1255 OID 24685)
-- Name: login_user(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.login_user(IN p_user_email character varying, IN p_user_password character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Find the user ID and the last logout timestamp based on the provided email and password
    SELECT AU.userID INTO user_id
    FROM ALL_USER AS AU
    WHERE AU.Useremail = p_user_email AND AU.UserPassword = p_user_password;

    IF user_id IS NOT NULL AND user_id IN (SELECT userid FROM normal_user) AND user_id NOT IN (SELECT userid FROM logs WHERE logout IS NULL) THEN
        -- Insert log entry
        INSERT INTO logs(logid, login, logout, userid)
        VALUES (COALESCE((SELECT MAX(logid) + 1 FROM logs), 1), CURRENT_TIMESTAMP, NULL, user_id)
        RETURNING user_id INTO user_id;
        -- Raise a NOTICE with the user_id for successful login
        RAISE NOTICE 'User with email % logged in successfully. UserID: %', p_user_email, user_id;
    ELSE
        -- Raise an exception for unsuccessful login
        RAISE EXCEPTION 'Invalid email or password, or user is not a normal user, or already logged in';
    END IF;
END;
$$;


ALTER PROCEDURE public.login_user(IN p_user_email character varying, IN p_user_password character varying) OWNER TO root;

--
-- TOC entry 251 (class 1255 OID 24686)
-- Name: logout_user(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.logout_user(IN p_user_email character varying, IN p_user_password character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_id INTEGER;
BEGIN
    -- Find the user ID and the last logout timestamp based on the provided email and password
    SELECT AU.userID INTO user_id
    FROM ALL_USER AS AU
    WHERE AU.Useremail = p_user_email AND AU.UserPassword = p_user_password;

    IF user_id IS NOT NULL AND user_id IN (SELECT userid FROM normal_user) AND user_id IN (SELECT userid FROM logs WHERE logout IS NULL) THEN
        UPDATE logs
        SET logout = CURRENT_TIMESTAMP
        WHERE userid = user_id AND logout IS NULL
        RETURNING user_id INTO user_id;
        -- Raise a NOTICE with the user_id for successful logout
        RAISE NOTICE 'User with email % logged out successfully. UserID: %', p_user_email, user_id;
    ELSE
        -- Raise an exception for unsuccessful logout
        RAISE EXCEPTION 'Invalid email or password, or user is not a normal user, or already logged out';
    END IF;
END;
$$;


ALTER PROCEDURE public.logout_user(IN p_user_email character varying, IN p_user_password character varying) OWNER TO root;

--
-- TOC entry 252 (class 1255 OID 24687)
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
    -- Check for uniqueness of email and password
    IF EXISTS (
        SELECT 1
        FROM ALL_USER
        WHERE UserEmail = p_user_email
           AND UserPassword = p_user_password
    ) THEN
        RAISE EXCEPTION 'User with the same email and password already exists.';
    END IF;

    -- Generate a new UserID
    SELECT COALESCE(MAX(UserID), 0) + 1 INTO new_user_id FROM ALL_USER;

    -- Insert the new user into the ALL_USER table
    INSERT INTO ALL_USER(UserID, UserPassword, UserName, UserEmail)
    VALUES (new_user_id, p_user_password, p_user_name, p_user_email);

    -- Iterate through the roles and insert the user into corresponding role tables
    FOREACH role IN ARRAY p_role_type
    LOOP
        CASE role
            WHEN 'NORMAL' THEN
                INSERT INTO NORMAL_USER(UserID, BirthDate)
                VALUES (new_user_id, p_BirthDate);

                -- Use loop to INSERT NormalUser_Address only if it doesn't already exist
                FOR i IN 1..COALESCE(array_length(NormalUser_Address, 1), 0)
                LOOP
                    BEGIN
                        INSERT INTO NormalUser_Address(UserID, UserAddress)
                        VALUES (new_user_id, NormalUser_Address[i]);
                    EXCEPTION
                        WHEN unique_violation THEN
                            -- Ignore duplicate entries
                            CONTINUE;
                    END;
                END LOOP;

                -- Use loop to INSERT NormalUser_Telephone only if it doesn't already exist
                FOR i IN 1..COALESCE(array_length(NormalUser_Telephone, 1), 0)
                LOOP
                    BEGIN
                        INSERT INTO NormalUser_Telephone(UserID, UserTelephone)
                        VALUES (new_user_id, NormalUser_Telephone[i]);
                    EXCEPTION
                        WHEN unique_violation THEN
                            -- Ignore duplicate entries
                            CONTINUE;
                    END;
                END LOOP;

            WHEN 'ADMIN' THEN
                INSERT INTO ADMINS(UserID)
                VALUES (new_user_id);

            WHEN 'MANAGER' THEN
                INSERT INTO HOTEL_MANAGER(UserID)
                VALUES (new_user_id);

            ELSE
                RAISE EXCEPTION 'Invalid role type: %', role;
        END CASE;
    END LOOP;

    -- Raise a NOTICE with the new_user_id
    RAISE NOTICE 'New user registered with UserID: %', new_user_id;
END;
$$;


ALTER PROCEDURE public.register_all_user(IN p_user_password character varying, IN p_user_name character varying, IN p_user_email character varying, IN p_role_type character varying[], IN p_birthdate date, IN normaluser_address character varying[], IN normaluser_telephone character varying[]) OWNER TO root;

--
-- TOC entry 253 (class 1255 OID 24688)
-- Name: user_delete_booking(character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.user_delete_booking(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer)
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


ALTER PROCEDURE public.user_delete_booking(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer) OWNER TO root;

--
-- TOC entry 254 (class 1255 OID 24689)
-- Name: user_edit_booking(character varying, character varying, integer, date, character varying, integer); Type: PROCEDURE; Schema: public; Owner: root
--

CREATE PROCEDURE public.user_edit_booking(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer, IN p_new_checkin_date date DEFAULT NULL::date, IN p_new_pay_type character varying DEFAULT NULL::character varying, IN p_new_number_of_booking integer DEFAULT NULL::integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
    last_login_id INTEGER;
    last_logout_id INTEGER;
    v_old_checkin_date DATE;
    v_old_pay_type VARCHAR(100);
    v_old_number_of_booking INTEGER;
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

    -- Check if the user is a normal user
    IF NOT EXISTS (
        SELECT 1
        FROM public.NORMAL_USER
        WHERE UserID = v_user_id
    ) THEN
        RAISE EXCEPTION 'User found, but not a normal user';
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
        WHERE b.BookingID = p_booking_id AND u.UserEmail = p_user_email  AND u.userpassword = p_user_password
    ) THEN
        RAISE EXCEPTION 'User does not own the booking with the given ID';
    END IF;

    -- Get the old values of the booking
    SELECT CheckInDate, PayType, NumberOfBooking
    INTO v_old_checkin_date, v_old_pay_type, v_old_number_of_booking
    FROM BOOKING
    WHERE BookingID = p_booking_id;

    -- Update the booking with the new values if provided
    UPDATE BOOKING
    SET 
        CheckInDate = COALESCE(p_new_checkin_date, v_old_checkin_date),
        PayType = COALESCE(p_new_pay_type, v_old_pay_type),
        NumberOfBooking = COALESCE(p_new_number_of_booking, v_old_number_of_booking)
    WHERE BookingID = p_booking_id;
END;
$$;


ALTER PROCEDURE public.user_edit_booking(IN p_user_email character varying, IN p_user_password character varying, IN p_booking_id integer, IN p_new_checkin_date date, IN p_new_pay_type character varying, IN p_new_number_of_booking integer) OWNER TO root;

--
-- TOC entry 255 (class 1255 OID 24690)
-- Name: user_view_all_room(character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.user_view_all_room(p_user_email character varying, p_user_password character varying) RETURNS TABLE(roomid integer, hotelname character varying, branchname character varying, locations character varying, roomdecor character varying, accessibilityfeatures character varying, roomtype character varying, roomview character varying, buildingfloor character varying, bathroom character varying, bedconfiguration character varying, services character varying, roomsize integer, wifi boolean, maxpeople integer, smoking boolean, facility character varying, measure character varying, transportation character varying, marketingstrategy character varying, technology character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_id INTEGER;
    last_login_id INTEGER;
    last_logout_id INTEGER;
BEGIN
    -- Check if the user exists and the password is correct
    SELECT UserID INTO user_id
    FROM public.ALL_USER
    WHERE UserEmail = p_user_email AND UserPassword = p_user_password;

    IF user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid email or password.';
    END IF;

    -- Check if the user is in the NORMAL_USER table
    IF NOT EXISTS (
        SELECT 1
        FROM public.NORMAL_USER
        WHERE UserID = user_id
    ) THEN
        RAISE EXCEPTION 'User is not in NORMAL_USER table.';
    END IF;

    -- Retrieve the last login and logout logids for the user
    SELECT 
        MAX(CASE WHEN logout IS NULL THEN logid END) INTO last_login_id
    FROM public.LOGS
    WHERE UserID = user_id;

    SELECT 
        MAX(CASE WHEN logout IS NOT NULL THEN logid END) INTO last_logout_id
    FROM public.LOGS
    WHERE UserID = user_id;

    IF last_login_id IS NULL OR (last_logout_id IS NOT NULL AND last_logout_id > last_login_id) THEN
        RAISE EXCEPTION 'User is not currently logged in.';
    END IF;

    -- Retrieve the user's bookings along with related information
    RETURN QUERY
    SELECT
        r.RoomID,
        h.HotelName,
        hb.BranchName,
        hb.Branch_Location AS Locations,
        d.RoomDecor,
        da.Amentities,
        d.RoomType,
        d.RoomView,
        d.Building_Floor AS BuildingFloor,
        d.Bathroom,
        d.BedConfiguration,
        d.Services,
        d.RoomSize,
        d.Wifi,
        d.MaxPeople,
        d.Smoking,
        bf.Facility,
        sm.Measure,
        tr.Transportation,
        ms.Strategy AS MarketingStrategy,
        tech.Technology
    FROM public.ROOM r
    JOIN public.DETAILS d ON r.DetailsID = d.DetailsID
	JOIN public.Details_Amentities da ON d.DetailsID = da.DetailsID
    JOIN public.HOTEL_BRANCH hb ON r.BranchID = hb.BranchID
    JOIN public.HOTEL h ON hb.HotelID = h.HotelID
    LEFT JOIN public.BRANCH_FACILITIES bf ON r.BranchID = bf.BranchID
    LEFT JOIN public.BRANCH_SECURITYMEASURES sm ON r.BranchID = sm.BranchID
    LEFT JOIN public.BRANCH_TRANSPORTATION tr ON r.BranchID = tr.BranchID
    LEFT JOIN public.BRANCH_TELEPHONE tel ON r.BranchID = tel.BranchID
    LEFT JOIN public.HOTEL_MARKETINGSTRATEGY ms ON hb.HotelID = ms.HotelID
    LEFT JOIN public.HOTEL_TECHNOLOGY tech ON hb.HotelID = tech.HotelID
    WHERE r.Status = true;
END;
$$;


ALTER FUNCTION public.user_view_all_room(p_user_email character varying, p_user_password character varying) OWNER TO root;

--
-- TOC entry 256 (class 1255 OID 24691)
-- Name: user_view_his_booking(character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.user_view_his_booking(p_user_email character varying, p_user_password character varying) RETURNS TABLE(bookingid integer, userid integer, checkindate date, paytype character varying, numberofbooking integer, roomid integer, hotelid integer, hotelname character varying, branchid integer, branchname character varying, branchlocation character varying, decorandtheme character varying, ratingreviews integer, parkingavailability boolean, parkingtypeparking character varying, parkingcostparking integer, roomdecor character varying, accessibilityfeatures character varying, roomtype character varying, roomview character varying, buildingfloor character varying, bathroom character varying, bedconfiguration character varying, services character varying, roomsize integer, wifi boolean, maxpeople integer, smoking boolean, facility character varying, measure character varying, transportation character varying, marketingstrategy character varying, technology character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INTEGER;
    last_login_id INTEGER;
    last_logout_id INTEGER;
BEGIN
    -- Check if the user exists and the password is correct
    SELECT all_user.userid INTO v_user_id
    FROM public.all_user
    WHERE all_user.useremail = p_user_email AND all_user.userpassword = p_user_password;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Invalid email or password.';
    END IF;

    -- Check if the user is in the NORMAL_USER table
    IF NOT EXISTS (
        SELECT 1
        FROM public.normal_user
        WHERE normal_user.userid = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is not in NORMAL_USER table.';
    END IF;

    -- Retrieve the last login and logout logids for the user
    SELECT 
        MAX(CASE WHEN logs.logout IS NULL THEN logs.logid END) INTO last_login_id
    FROM public.logs
    WHERE logs.userid = v_user_id;

    SELECT 
        MAX(CASE WHEN logs.logout IS NOT NULL THEN logs.logid END) INTO last_logout_id
    FROM public.logs
    WHERE logs.userid = v_user_id;

    IF last_login_id IS NULL OR (last_logout_id IS NOT NULL AND last_logout_id > last_login_id) THEN
        RAISE EXCEPTION 'User is not currently logged in.';
    END IF;

    RETURN QUERY
    SELECT
        b.bookingid,
        b.userid,
        b.checkindate,
        b.paytype,
        b.numberofbooking,
        r.roomid,
        h.hotelid,
        h.hotelname,
        hb.branchid,
        hb.branchname,
        hb.branch_location,
        hb.decorandtheme,
        hb.rating_reviews,
        hb.parkingavailability,
        hb.parkingtypeparking,
        hb.parkingcostparking,
        d.roomdecor,
        da.amentities AS accessibilityfeatures,
        d.roomtype,
        d.roomview,
        d.building_floor AS buildingfloor,
        d.bathroom,
        d.bedconfiguration,
        d.services,
        d.roomsize,
        d.wifi,
        d.maxpeople,
        d.smoking,
        bf.facility,
        sm.measure,
        tr.transportation,
        ms.strategy AS marketingstrategy,
        tech.technology
    FROM 
        public.booking b
    JOIN 
        public.room r ON b.roomid = r.roomid
    JOIN 
        public.details d ON r.detailsid = d.detailsid
    JOIN 
        public.details_amentities da ON d.detailsid = da.detailsid
    JOIN 
        public.hotel_branch hb ON r.branchid = hb.branchid
    JOIN 
        public.hotel h ON hb.hotelid = h.hotelid
    LEFT JOIN 
        public.branch_facilities bf ON r.branchid = bf.branchid
    LEFT JOIN 
        public.branch_securitymeasures sm ON r.branchid = sm.branchid
    LEFT JOIN 
        public.branch_transportation tr ON r.branchid = tr.branchid
    LEFT JOIN 
        public.hotel_marketingstrategy ms ON hb.hotelid = ms.hotelid
    LEFT JOIN 
        public.hotel_technology tech ON hb.hotelid = tech.hotelid
    WHERE 
        r.status = TRUE AND b.userid = v_user_id;

END;
$$;


ALTER FUNCTION public.user_view_his_booking(p_user_email character varying, p_user_password character varying) OWNER TO root;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 24693)
-- Name: admins; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.admins (
    userid integer NOT NULL
);


ALTER TABLE public.admins OWNER TO root;

--
-- TOC entry 216 (class 1259 OID 24696)
-- Name: all_user; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.all_user (
    userid integer NOT NULL,
    userpassword character varying(100),
    username character varying(100),
    useremail character varying(100)
);


ALTER TABLE public.all_user OWNER TO root;

--
-- TOC entry 217 (class 1259 OID 24699)
-- Name: booking; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.booking (
    bookingid integer NOT NULL,
    userid integer,
    roomid integer,
    checkindate date,
    paytype character varying(100),
    numberofbooking integer
);


ALTER TABLE public.booking OWNER TO root;

--
-- TOC entry 218 (class 1259 OID 24702)
-- Name: branch_facilities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_facilities (
    branchid integer NOT NULL,
    facility character varying(100) NOT NULL
);


ALTER TABLE public.branch_facilities OWNER TO root;

--
-- TOC entry 219 (class 1259 OID 24705)
-- Name: branch_securitymeasures; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_securitymeasures (
    branchid integer NOT NULL,
    measure character varying(100) NOT NULL
);


ALTER TABLE public.branch_securitymeasures OWNER TO root;

--
-- TOC entry 220 (class 1259 OID 24708)
-- Name: branch_telephone; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_telephone (
    branchid integer NOT NULL,
    branchtelephone character varying(100) NOT NULL
);


ALTER TABLE public.branch_telephone OWNER TO root;

--
-- TOC entry 221 (class 1259 OID 24711)
-- Name: branch_transportation; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_transportation (
    branchid integer NOT NULL,
    transportation character varying(100) NOT NULL,
    transportation_id integer NOT NULL
);


ALTER TABLE public.branch_transportation OWNER TO root;

--
-- TOC entry 234 (class 1259 OID 24906)
-- Name: branch_transportation_transportation_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.branch_transportation ALTER COLUMN transportation_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.branch_transportation_transportation_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 222 (class 1259 OID 24714)
-- Name: details; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.details (
    detailsid integer NOT NULL,
    roomdecor character varying(100),
    accessibility_features character varying(100),
    roomtype character varying(100),
    roomview character varying(100),
    building_floor character varying(100),
    bathroom character varying(100),
    bedconfiguration character varying(100),
    services character varying(100),
    roomsize integer,
    wifi boolean,
    maxpeople integer,
    smoking boolean
);


ALTER TABLE public.details OWNER TO root;

--
-- TOC entry 223 (class 1259 OID 24719)
-- Name: details_amentities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.details_amentities (
    detailsid integer NOT NULL,
    amentities character varying(100) NOT NULL
);


ALTER TABLE public.details_amentities OWNER TO root;

--
-- TOC entry 224 (class 1259 OID 24722)
-- Name: hotel; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel (
    hotelid integer NOT NULL,
    userid integer,
    hotelname character varying(100),
    brandidentity character varying(100)
);


ALTER TABLE public.hotel OWNER TO root;

--
-- TOC entry 225 (class 1259 OID 24725)
-- Name: hotel_branch; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_branch (
    hotelid integer NOT NULL,
    branchid integer NOT NULL,
    branchname character varying(100),
    branch_location character varying(100),
    decorandtheme character varying(100),
    rating_reviews integer,
    parkingavailability boolean,
    parkingtypeparking character varying(100),
    parkingcostparking integer
);


ALTER TABLE public.hotel_branch OWNER TO root;

--
-- TOC entry 226 (class 1259 OID 24728)
-- Name: hotel_manager; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_manager (
    userid integer NOT NULL
);


ALTER TABLE public.hotel_manager OWNER TO root;

--
-- TOC entry 227 (class 1259 OID 24731)
-- Name: hotel_marketingstrategy; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_marketingstrategy (
    hotelid integer NOT NULL,
    strategy character varying(100) NOT NULL
);


ALTER TABLE public.hotel_marketingstrategy OWNER TO root;

--
-- TOC entry 228 (class 1259 OID 24734)
-- Name: hotel_technology; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_technology (
    hotelid integer NOT NULL,
    technology character varying(100) NOT NULL
);


ALTER TABLE public.hotel_technology OWNER TO root;

--
-- TOC entry 229 (class 1259 OID 24737)
-- Name: logs; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.logs (
    logid integer NOT NULL,
    userid integer,
    logout timestamp without time zone,
    login timestamp without time zone
);


ALTER TABLE public.logs OWNER TO root;

--
-- TOC entry 230 (class 1259 OID 24740)
-- Name: normal_user; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.normal_user (
    userid integer NOT NULL,
    birthdate date
);


ALTER TABLE public.normal_user OWNER TO root;

--
-- TOC entry 231 (class 1259 OID 24743)
-- Name: normaluser_address; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.normaluser_address (
    userid integer NOT NULL,
    useraddress character varying(100) NOT NULL
);


ALTER TABLE public.normaluser_address OWNER TO root;

--
-- TOC entry 232 (class 1259 OID 24746)
-- Name: normaluser_telephone; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.normaluser_telephone (
    userid integer NOT NULL,
    usertelephone character varying(100) NOT NULL
);


ALTER TABLE public.normaluser_telephone OWNER TO root;

--
-- TOC entry 233 (class 1259 OID 24749)
-- Name: room; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.room (
    branchid integer NOT NULL,
    roomid integer NOT NULL,
    detailsid integer,
    status boolean,
    pricenormal integer,
    priceweekend integer,
    priceevent integer
);


ALTER TABLE public.room OWNER TO root;

--
-- TOC entry 3493 (class 0 OID 24693)
-- Dependencies: 215
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.admins VALUES (1);
INSERT INTO public.admins VALUES (4);


--
-- TOC entry 3494 (class 0 OID 24696)
-- Dependencies: 216
-- Data for Name: all_user; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.all_user VALUES (1, 'password123', 'John Doe', 'john.doe@example.com');
INSERT INTO public.all_user VALUES (2, 'password1234', 'John Doe', 'com');
INSERT INTO public.all_user VALUES (3, 'password123', 'JohnDoe', '@example.com');
INSERT INTO public.all_user VALUES (4, 'passw1221ord123', 'JohnDoe2', 'jo132hn.doe@example.com');


--
-- TOC entry 3495 (class 0 OID 24699)
-- Dependencies: 217
-- Data for Name: booking; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.booking VALUES (2, 1, 1, '3024-03-10', 'Credit Card', 2);


--
-- TOC entry 3496 (class 0 OID 24702)
-- Dependencies: 218
-- Data for Name: branch_facilities; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3497 (class 0 OID 24705)
-- Dependencies: 219
-- Data for Name: branch_securitymeasures; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3498 (class 0 OID 24708)
-- Dependencies: 220
-- Data for Name: branch_telephone; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3499 (class 0 OID 24711)
-- Dependencies: 221
-- Data for Name: branch_transportation; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3500 (class 0 OID 24714)
-- Dependencies: 222
-- Data for Name: details; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.details VALUES (1, 'Modern', 'Wheelchair Accessible', 'Standard', 'City View', '5th Floor', 'Private', 'Double Bed', 'Cleaning Service', 30, true, 2, false);


--
-- TOC entry 3501 (class 0 OID 24719)
-- Dependencies: 223
-- Data for Name: details_amentities; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.details_amentities VALUES (1, 'Free Wi-Fi');


--
-- TOC entry 3502 (class 0 OID 24722)
-- Dependencies: 224
-- Data for Name: hotel; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.hotel VALUES (1, 1, 'Sample Hotel', 'Sample Brand');


--
-- TOC entry 3503 (class 0 OID 24725)
-- Dependencies: 225
-- Data for Name: hotel_branch; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.hotel_branch VALUES (1, 1, 'Main Branch', 'City Center', 'Modern', 4, true, 'Valet Parking', 10);


--
-- TOC entry 3504 (class 0 OID 24728)
-- Dependencies: 226
-- Data for Name: hotel_manager; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.hotel_manager VALUES (1);


--
-- TOC entry 3505 (class 0 OID 24731)
-- Dependencies: 227
-- Data for Name: hotel_marketingstrategy; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3506 (class 0 OID 24734)
-- Dependencies: 228
-- Data for Name: hotel_technology; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- TOC entry 3507 (class 0 OID 24737)
-- Dependencies: 229
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.logs VALUES (11, 1, '2024-02-06 15:51:38.98359', '2024-02-05 16:47:08.243433');
INSERT INTO public.logs VALUES (12, 1, '2024-02-06 15:52:21.399947', '2024-02-06 15:52:14.663735');
INSERT INTO public.logs VALUES (13, 1, NULL, '2024-02-06 15:54:07.735037');


--
-- TOC entry 3508 (class 0 OID 24740)
-- Dependencies: 230
-- Data for Name: normal_user; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.normal_user VALUES (1, '1990-01-01');
INSERT INTO public.normal_user VALUES (2, '2024-02-05');
INSERT INTO public.normal_user VALUES (3, '1990-01-01');
INSERT INTO public.normal_user VALUES (4, '2024-02-06');


--
-- TOC entry 3509 (class 0 OID 24743)
-- Dependencies: 231
-- Data for Name: normaluser_address; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.normaluser_address VALUES (1, '123 Main St');
INSERT INTO public.normaluser_address VALUES (1, '456 Oak St');
INSERT INTO public.normaluser_address VALUES (3, '123 Main St');
INSERT INTO public.normaluser_address VALUES (3, '456 Oak St');
INSERT INTO public.normaluser_address VALUES (4, '123 Main St');
INSERT INTO public.normaluser_address VALUES (4, '456 Oak Ave');


--
-- TOC entry 3510 (class 0 OID 24746)
-- Dependencies: 232
-- Data for Name: normaluser_telephone; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.normaluser_telephone VALUES (1, '555-1234');
INSERT INTO public.normaluser_telephone VALUES (1, '555-5678');
INSERT INTO public.normaluser_telephone VALUES (3, '555-1234');
INSERT INTO public.normaluser_telephone VALUES (3, '555-5678');
INSERT INTO public.normaluser_telephone VALUES (4, '555-1234');
INSERT INTO public.normaluser_telephone VALUES (4, '555-5678');


--
-- TOC entry 3511 (class 0 OID 24749)
-- Dependencies: 233
-- Data for Name: room; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.room VALUES (1, 1, 1, true, 100, 120, 150);


--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 234
-- Name: branch_transportation_transportation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.branch_transportation_transportation_id_seq', 0, false);


--
-- TOC entry 3305 (class 2606 OID 24753)
-- Name: details DETAILS_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details
    ADD CONSTRAINT "DETAILS_pkey" PRIMARY KEY (detailsid);


--
-- TOC entry 3286 (class 2606 OID 24754)
-- Name: booking NumberOfBooking; Type: CHECK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE public.booking
    ADD CONSTRAINT "NumberOfBooking" CHECK ((numberofbooking <= 3)) NOT VALID;


--
-- TOC entry 3287 (class 2606 OID 24755)
-- Name: booking NumberOfBooking2; Type: CHECK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE public.booking
    ADD CONSTRAINT "NumberOfBooking2" CHECK ((numberofbooking >= 0)) NOT VALID;


--
-- TOC entry 3329 (class 2606 OID 24757)
-- Name: room ROOM_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT "ROOM_pkey" PRIMARY KEY (branchid, roomid);


--
-- TOC entry 3331 (class 2606 OID 24759)
-- Name: room RoomID; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT "RoomID" UNIQUE (roomid);


--
-- TOC entry 3289 (class 2606 OID 24761)
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (userid);


--
-- TOC entry 3291 (class 2606 OID 24763)
-- Name: all_user all_user_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.all_user
    ADD CONSTRAINT all_user_pkey PRIMARY KEY (userid);


--
-- TOC entry 3293 (class 2606 OID 24765)
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (bookingid);


--
-- TOC entry 3311 (class 2606 OID 24767)
-- Name: hotel_branch branch; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_branch
    ADD CONSTRAINT branch UNIQUE (branchid);


--
-- TOC entry 3295 (class 2606 OID 24769)
-- Name: branch_facilities branch_facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_facilities
    ADD CONSTRAINT branch_facilities_pkey PRIMARY KEY (branchid, facility);


--
-- TOC entry 3297 (class 2606 OID 24771)
-- Name: branch_securitymeasures branch_measure_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_securitymeasures
    ADD CONSTRAINT branch_measure_pkey PRIMARY KEY (branchid, measure);


--
-- TOC entry 3299 (class 2606 OID 24773)
-- Name: branch_telephone branch_telephone_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_telephone
    ADD CONSTRAINT branch_telephone_pkey PRIMARY KEY (branchid, branchtelephone);


--
-- TOC entry 3301 (class 2606 OID 24903)
-- Name: branch_transportation branch_transportation_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT branch_transportation_pkey PRIMARY KEY (branchid, transportation_id);


--
-- TOC entry 3307 (class 2606 OID 24777)
-- Name: details_amentities details_amentities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details_amentities
    ADD CONSTRAINT details_amentities_pkey PRIMARY KEY (detailsid, amentities);


--
-- TOC entry 3313 (class 2606 OID 24779)
-- Name: hotel_branch hotel_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_branch
    ADD CONSTRAINT hotel_branch_pkey PRIMARY KEY (hotelid, branchid);


--
-- TOC entry 3315 (class 2606 OID 24781)
-- Name: hotel_manager hotel_manager_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_manager
    ADD CONSTRAINT hotel_manager_pkey PRIMARY KEY (userid);


--
-- TOC entry 3317 (class 2606 OID 24783)
-- Name: hotel_marketingstrategy hotel_marketingstrategy_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_marketingstrategy
    ADD CONSTRAINT hotel_marketingstrategy_pkey PRIMARY KEY (hotelid, strategy);


--
-- TOC entry 3309 (class 2606 OID 24785)
-- Name: hotel hotel_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel
    ADD CONSTRAINT hotel_pkey PRIMARY KEY (hotelid);


--
-- TOC entry 3319 (class 2606 OID 24787)
-- Name: hotel_technology hotel_technology_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_technology
    ADD CONSTRAINT hotel_technology_pkey PRIMARY KEY (hotelid, technology);


--
-- TOC entry 3321 (class 2606 OID 24789)
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (logid);


--
-- TOC entry 3323 (class 2606 OID 24791)
-- Name: normal_user normal_user_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normal_user
    ADD CONSTRAINT normal_user_pkey PRIMARY KEY (userid);


--
-- TOC entry 3325 (class 2606 OID 24793)
-- Name: normaluser_address normaluser_address_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_address
    ADD CONSTRAINT normaluser_address_pkey PRIMARY KEY (userid, useraddress);


--
-- TOC entry 3327 (class 2606 OID 24795)
-- Name: normaluser_telephone normaluser_telephone_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_telephone
    ADD CONSTRAINT normaluser_telephone_pkey PRIMARY KEY (userid, usertelephone);


--
-- TOC entry 3303 (class 2606 OID 24901)
-- Name: branch_transportation transportation_unique; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT transportation_unique UNIQUE (transportation);


--
-- TOC entry 3336 (class 2606 OID 24796)
-- Name: branch_securitymeasures Branch_SecurityMeasures; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_securitymeasures
    ADD CONSTRAINT "Branch_SecurityMeasures" FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- TOC entry 3345 (class 2606 OID 24801)
-- Name: logs UserIDLogs; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT "UserIDLogs" FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- TOC entry 3333 (class 2606 OID 24806)
-- Name: booking booking_room; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_room FOREIGN KEY (roomid) REFERENCES public.room(roomid) NOT VALID;


--
-- TOC entry 3334 (class 2606 OID 24811)
-- Name: booking booking_user; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_user FOREIGN KEY (userid) REFERENCES public.normal_user(userid) NOT VALID;


--
-- TOC entry 3335 (class 2606 OID 24816)
-- Name: branch_facilities branch_facilities; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_facilities
    ADD CONSTRAINT branch_facilities FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- TOC entry 3337 (class 2606 OID 24821)
-- Name: branch_transportation branch_telephone; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT branch_telephone FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- TOC entry 3338 (class 2606 OID 24826)
-- Name: branch_transportation branch_transportation; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT branch_transportation FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- TOC entry 3339 (class 2606 OID 24831)
-- Name: details_amentities details_amentities_details; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details_amentities
    ADD CONSTRAINT details_amentities_details FOREIGN KEY (detailsid) REFERENCES public.details(detailsid) NOT VALID;


--
-- TOC entry 3341 (class 2606 OID 24836)
-- Name: hotel_branch hotel_branch_hotel; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_branch
    ADD CONSTRAINT hotel_branch_hotel FOREIGN KEY (hotelid) REFERENCES public.hotel(hotelid) NOT VALID;


--
-- TOC entry 3343 (class 2606 OID 24841)
-- Name: hotel_marketingstrategy hotel_marketingstrategy_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_marketingstrategy
    ADD CONSTRAINT hotel_marketingstrategy_normaluser FOREIGN KEY (hotelid) REFERENCES public.hotel(hotelid) NOT VALID;


--
-- TOC entry 3340 (class 2606 OID 24846)
-- Name: hotel hotel_normal_user; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel
    ADD CONSTRAINT hotel_normal_user FOREIGN KEY (userid) REFERENCES public.hotel_manager(userid) NOT VALID;


--
-- TOC entry 3344 (class 2606 OID 24851)
-- Name: hotel_technology hotel_technology_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_technology
    ADD CONSTRAINT hotel_technology_normaluser FOREIGN KEY (hotelid) REFERENCES public.hotel(hotelid) NOT VALID;


--
-- TOC entry 3347 (class 2606 OID 24856)
-- Name: normaluser_address normaluser_address_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_address
    ADD CONSTRAINT normaluser_address_normaluser FOREIGN KEY (userid) REFERENCES public.normal_user(userid) NOT VALID;


--
-- TOC entry 3348 (class 2606 OID 24861)
-- Name: normaluser_telephone normaluser_telephone_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_telephone
    ADD CONSTRAINT normaluser_telephone_normaluser FOREIGN KEY (userid) REFERENCES public.normal_user(userid) NOT VALID;


--
-- TOC entry 3349 (class 2606 OID 24866)
-- Name: room room_branch; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_branch FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- TOC entry 3332 (class 2606 OID 24871)
-- Name: admins userid_admins; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT userid_admins FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- TOC entry 3342 (class 2606 OID 24876)
-- Name: hotel_manager userid_hotel_manager; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_manager
    ADD CONSTRAINT userid_hotel_manager FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- TOC entry 3346 (class 2606 OID 24881)
-- Name: normal_user userid_normal_user; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normal_user
    ADD CONSTRAINT userid_normal_user FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


-- Completed on 2024-02-11 12:53:04 UTC

--
-- PostgreSQL database dump complete
--

