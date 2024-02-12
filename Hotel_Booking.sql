--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.1

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

    IF user_id IS NULL OR user_id NOT IN (SELECT userid FROM normal_user) THEN
        -- Raise an exception for invalid email or password
        RAISE EXCEPTION 'Invalid email or password, or user is not a normal user';
    END IF; 
    
    IF user_id NOT IN (SELECT userid FROM logs WHERE logout IS NULL) THEN
        -- Insert log entry
        INSERT INTO logs(logid, login, logout, userid)
        VALUES (COALESCE((SELECT MAX(logid) + 1 FROM logs), 1), CURRENT_TIMESTAMP, NULL, user_id)
        RETURNING user_id INTO user_id;
        -- Raise a NOTICE with the user_id for successful login
        RAISE NOTICE 'User with email % logged in successfully. UserID: %', p_user_email, user_id;
    ELSE
        -- Raise an exception for unsuccessful login
        RAISE NOTICE 'You are already logged in';
    END IF;
END;
$$;


ALTER PROCEDURE public.login_user(IN p_user_email character varying, IN p_user_password character varying) OWNER TO root;

--
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

    IF user_id IS NULL OR user_id NOT IN (SELECT userid FROM normal_user) THEN
        -- Raise an exception for invalid email or password
        RAISE EXCEPTION 'Invalid email or password, or user is not a normal user';
    END IF;

    IF user_id IN (SELECT userid FROM logs WHERE logout IS NULL) THEN
        UPDATE logs
        SET logout = CURRENT_TIMESTAMP
        WHERE userid = user_id AND logout IS NULL
        RETURNING user_id INTO user_id;
        -- Raise a NOTICE with the user_id for successful logout
        RAISE NOTICE 'User with email % logged out successfully. UserID: %', p_user_email, user_id;
    ELSE
        -- Raise an exception for unsuccessful logout
        RAISE NOTICE 'You are already logged out';
    END IF;
END;
$$;


ALTER PROCEDURE public.logout_user(IN p_user_email character varying, IN p_user_password character varying) OWNER TO root;

--
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
-- Name: user_view_all_room(character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.user_view_all_room(p_user_email character varying, p_user_password character varying) RETURNS TABLE(hotelname character varying, branchlocation character varying, telephone text, roomid integer, branchname character varying, roomdecor character varying, accessibilityfeatures character varying, roomtype character varying, roomview character varying, buildingfloor character varying, bathroom character varying, bedconfiguration character varying, services character varying, roomsize integer, wifi boolean, maxpeople integer, smoking boolean, facility character varying, measure character varying, transportation character varying, marketingstrategy character varying, technology character varying)
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
        h.HotelName,
        hb.branch_location,
      	STRING_AGG(tel.branchtelephone, ', ') OVER (PARTITION BY r.RoomID) AS telephone,
        r.RoomID,
        hb.BranchName,
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
    LEFT JOIN public.DETAILS d ON r.DetailsID = d.DetailsID
	LEFT JOIN public.Details_Amentities da ON d.DetailsID = da.DetailsID
    LEFT JOIN public.HOTEL_BRANCH hb ON r.BranchID = hb.BranchID
    LEFT JOIN public.HOTEL h ON hb.HotelID = h.HotelID
    LEFT JOIN public.BRANCH_FACILITIES bf ON r.BranchID = bf.BranchID
    LEFT JOIN public.BRANCH_SECURITYMEASURES sm ON r.BranchID = sm.BranchID
    LEFT JOIN public.BRANCH_TRANSPORTATION tr ON r.BranchID = tr.BranchID
    LEFT JOIN public.BRANCH_TELEPHONE tel ON r.BranchID = tel.BranchID
    LEFT JOIN public.HOTEL_MARKETINGSTRATEGY ms ON hb.HotelID = ms.HotelID
    LEFT JOIN public.HOTEL_TECHNOLOGY tech ON hb.HotelID = tech.HotelID
    WHERE r.Status = true
	ORDER BY h.HotelName ASC, hb.BranchName ASC, r.RoomID ASC;
END;
$$;


ALTER FUNCTION public.user_view_all_room(p_user_email character varying, p_user_password character varying) OWNER TO root;

--
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
-- Name: admins; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.admins (
    userid integer NOT NULL
);


ALTER TABLE public.admins OWNER TO root;

--
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
-- Name: branch_facilities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_facilities (
    branch_facility_id integer NOT NULL,
    branchid integer NOT NULL,
    facility character varying(100) NOT NULL
);


ALTER TABLE public.branch_facilities OWNER TO root;

--
-- Name: branch_facilities_branch_facilies_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.branch_facilities ALTER COLUMN branch_facility_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.branch_facilities_branch_facilies_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
-- Name: branch_securitymeasures; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_securitymeasures (
    branch_measure_id integer NOT NULL,
    branchid integer NOT NULL,
    measure character varying(100) NOT NULL
);


ALTER TABLE public.branch_securitymeasures OWNER TO root;

--
-- Name: branch_securitymeasures_branch_securitymeasure_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.branch_securitymeasures ALTER COLUMN branch_measure_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.branch_securitymeasures_branch_securitymeasure_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
-- Name: branch_telephone; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_telephone (
    branch_telephone_id integer NOT NULL,
    branchid integer NOT NULL,
    branchtelephone character varying(100) NOT NULL
);


ALTER TABLE public.branch_telephone OWNER TO root;

--
-- Name: branch_telephone_branch_telephone_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.branch_telephone ALTER COLUMN branch_telephone_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.branch_telephone_branch_telephone_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
-- Name: branch_transportation; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.branch_transportation (
    branch_transportation_id integer NOT NULL,
    branchid integer NOT NULL,
    transportation character varying(100) NOT NULL
);


ALTER TABLE public.branch_transportation OWNER TO root;

--
-- Name: branch_transportation_transportation_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.branch_transportation ALTER COLUMN branch_transportation_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.branch_transportation_transportation_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
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
-- Name: details_amentities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.details_amentities (
    details_amentities_id integer NOT NULL,
    detailsid integer NOT NULL,
    amentities character varying(100) NOT NULL
);


ALTER TABLE public.details_amentities OWNER TO root;

--
-- Name: details_amentities_details_amentities_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.details_amentities ALTER COLUMN details_amentities_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.details_amentities_details_amentities_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
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
-- Name: hotel_manager; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_manager (
    userid integer NOT NULL
);


ALTER TABLE public.hotel_manager OWNER TO root;

--
-- Name: hotel_marketingstrategy; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_marketingstrategy (
    hotel_strategy_id integer NOT NULL,
    hotelid integer NOT NULL,
    strategy character varying(100) NOT NULL
);


ALTER TABLE public.hotel_marketingstrategy OWNER TO root;

--
-- Name: hotel_marketingstrategy_hotel_marketingstrategy_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.hotel_marketingstrategy ALTER COLUMN hotel_strategy_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.hotel_marketingstrategy_hotel_marketingstrategy_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
-- Name: hotel_technology; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.hotel_technology (
    hotel_technology_id integer NOT NULL,
    hotelid integer NOT NULL,
    technology character varying(100) NOT NULL
);


ALTER TABLE public.hotel_technology OWNER TO root;

--
-- Name: hotel_technology_hotel_technology_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.hotel_technology ALTER COLUMN hotel_technology_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.hotel_technology_hotel_technology_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
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
-- Name: normal_user; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.normal_user (
    userid integer NOT NULL,
    birthdate date
);


ALTER TABLE public.normal_user OWNER TO root;

--
-- Name: normaluser_address; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.normaluser_address (
    normaluser_address_id integer NOT NULL,
    userid integer NOT NULL,
    useraddress character varying(100) NOT NULL
);


ALTER TABLE public.normaluser_address OWNER TO root;

--
-- Name: normaluser_address_normaluser_address_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.normaluser_address ALTER COLUMN normaluser_address_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.normaluser_address_normaluser_address_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
-- Name: normaluser_telephone; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.normaluser_telephone (
    normaluser_telephone_id integer NOT NULL,
    userid integer NOT NULL,
    usertelephone character varying(100) NOT NULL
);


ALTER TABLE public.normaluser_telephone OWNER TO root;

--
-- Name: normaluser_telephone_normaluser_telephone_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

ALTER TABLE public.normaluser_telephone ALTER COLUMN normaluser_telephone_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.normaluser_telephone_normaluser_telephone_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1
);


--
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
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.admins VALUES (1);
INSERT INTO public.admins VALUES (4);


--
-- Data for Name: all_user; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.all_user VALUES (1, 'password123', 'John Doe', 'john.doe@example.com');
INSERT INTO public.all_user VALUES (2, 'password1234', 'John Doe', 'com');
INSERT INTO public.all_user VALUES (3, 'password123', 'JohnDoe', '@example.com');
INSERT INTO public.all_user VALUES (4, 'passw1221ord123', 'JohnDoe2', 'jo132hn.doe@example.com');
INSERT INTO public.all_user VALUES (1001, 'password1', 'User 1', 'user1@example.com');
INSERT INTO public.all_user VALUES (1002, 'password2', 'User 2', 'user2@example.com');
INSERT INTO public.all_user VALUES (1003, 'password3', 'User 3', 'user3@example.com');
INSERT INTO public.all_user VALUES (1004, 'password4', 'User 4', 'user4@example.com');
INSERT INTO public.all_user VALUES (1005, 'password5', 'User 5', 'user5@example.com');
INSERT INTO public.all_user VALUES (1006, 'password6', 'User 6', 'user6@example.com');
INSERT INTO public.all_user VALUES (1007, 'password7', 'User 7', 'user7@example.com');
INSERT INTO public.all_user VALUES (1008, 'password8', 'User 8', 'user8@example.com');
INSERT INTO public.all_user VALUES (1009, 'password9', 'User 9', 'user9@example.com');
INSERT INTO public.all_user VALUES (1010, 'password10', 'User 10', 'user10@example.com');
INSERT INTO public.all_user VALUES (1011, 'password11', 'User 11', 'user11@example.com');
INSERT INTO public.all_user VALUES (1012, 'password12', 'User 12', 'user12@example.com');
INSERT INTO public.all_user VALUES (1013, 'password13', 'User 13', 'user13@example.com');
INSERT INTO public.all_user VALUES (1014, 'password14', 'User 14', 'user14@example.com');
INSERT INTO public.all_user VALUES (1015, 'password15', 'User 15', 'user15@example.com');
INSERT INTO public.all_user VALUES (1016, 'password16', 'User 16', 'user16@example.com');
INSERT INTO public.all_user VALUES (1017, 'password17', 'User 17', 'user17@example.com');
INSERT INTO public.all_user VALUES (1018, 'password18', 'User 18', 'user18@example.com');
INSERT INTO public.all_user VALUES (1019, 'password19', 'User 19', 'user19@example.com');
INSERT INTO public.all_user VALUES (1020, 'password20', 'User 20', 'user20@example.com');
INSERT INTO public.all_user VALUES (1021, 'password21', 'User 21', 'user21@example.com');
INSERT INTO public.all_user VALUES (1022, 'password22', 'User 22', 'user22@example.com');
INSERT INTO public.all_user VALUES (1023, 'password23', 'User 23', 'user23@example.com');
INSERT INTO public.all_user VALUES (1024, 'password24', 'User 24', 'user24@example.com');
INSERT INTO public.all_user VALUES (1025, 'password25', 'User 25', 'user25@example.com');


--
-- Data for Name: booking; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.booking VALUES (2, 1, 1, '3024-03-10', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1001, 1001, 1001, '2024-02-01', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1002, 1002, 1002, '2024-02-02', 'Cash', 2);
INSERT INTO public.booking VALUES (1003, 1003, 1003, '2024-02-03', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1004, 1004, 1004, '2024-02-04', 'Credit Card', 3);
INSERT INTO public.booking VALUES (1005, 1005, 1005, '2024-02-05', 'Cash', 2);
INSERT INTO public.booking VALUES (1006, 1006, 1006, '2024-02-06', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1007, 1007, 1007, '2024-02-07', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1008, 1008, 1008, '2024-02-08', 'Cash', 1);
INSERT INTO public.booking VALUES (1009, 1009, 1009, '2024-02-09', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1010, 1010, 1010, '2024-02-10', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1011, 1011, 1011, '2024-02-11', 'Cash', 3);
INSERT INTO public.booking VALUES (1012, 1012, 1012, '2024-02-12', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1013, 1013, 1013, '2024-02-13', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1014, 1014, 1014, '2024-02-14', 'Cash', 2);
INSERT INTO public.booking VALUES (1015, 1015, 1015, '2024-02-15', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1016, 1016, 1016, '2024-02-16', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1017, 1017, 1017, '2024-02-17', 'Cash', 1);
INSERT INTO public.booking VALUES (1018, 1018, 1018, '2024-02-18', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1019, 1019, 1019, '2024-02-19', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1020, 1020, 1020, '2024-02-20', 'Cash', 2);
INSERT INTO public.booking VALUES (1021, 1021, 1021, '2024-02-21', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1022, 1022, 1022, '2024-02-22', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1023, 1023, 1023, '2024-02-23', 'Cash', 1);
INSERT INTO public.booking VALUES (1024, 1001, 1001, '2024-02-24', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1025, 1002, 1002, '2024-02-25', 'Cash', 2);
INSERT INTO public.booking VALUES (1026, 1003, 1003, '2024-02-26', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1027, 1004, 1004, '2024-02-27', 'Credit Card', 3);
INSERT INTO public.booking VALUES (1028, 1005, 1005, '2024-02-28', 'Cash', 2);
INSERT INTO public.booking VALUES (1029, 1006, 1006, '2024-02-29', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1030, 1007, 1007, '2024-03-01', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1031, 1008, 1008, '2024-03-02', 'Cash', 1);
INSERT INTO public.booking VALUES (1032, 1009, 1009, '2024-03-03', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1033, 1010, 1010, '2024-03-04', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1034, 1011, 1011, '2024-03-05', 'Cash', 3);
INSERT INTO public.booking VALUES (1035, 1012, 1012, '2024-03-06', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1036, 1013, 1013, '2024-03-07', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1037, 1014, 1014, '2024-03-08', 'Cash', 2);
INSERT INTO public.booking VALUES (1038, 1015, 1015, '2024-03-09', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1039, 1016, 1016, '2024-03-10', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1040, 1017, 1017, '2024-03-11', 'Cash', 1);
INSERT INTO public.booking VALUES (1041, 1018, 1018, '2024-03-12', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1042, 1019, 1019, '2024-03-13', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1043, 1020, 1020, '2024-03-14', 'Cash', 2);
INSERT INTO public.booking VALUES (1044, 1021, 1021, '2024-03-15', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1045, 1022, 1022, '2024-03-16', 'Credit Card', 2);
INSERT INTO public.booking VALUES (1046, 1023, 1023, '2024-03-17', 'Cash', 1);
INSERT INTO public.booking VALUES (1047, 1001, 1001, '2024-03-18', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1048, 1002, 1002, '2024-03-19', 'Cash', 2);
INSERT INTO public.booking VALUES (1049, 1003, 1003, '2024-03-20', 'Credit Card', 1);
INSERT INTO public.booking VALUES (1050, 1004, 1004, '2024-03-21', 'Credit Card', 3);


--
-- Data for Name: branch_facilities; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: branch_securitymeasures; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: branch_telephone; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (0, 1, '098-234-5234');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (1, 1001, '088-234-2435');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (2, 1002, '012-345-6789');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (3, 1003, '011-234-5678');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (4, 1004, '010-987-6543');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (5, 1005, '099-876-5432');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (6, 1006, '098-765-4321');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (7, 1007, '097-654-3210');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (8, 1008, '096-543-2109');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (9, 1009, '095-432-1098');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (10, 1010, '094-321-0987');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (11, 1011, '093-210-9876');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (12, 1012, '092-109-8765');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (13, 1013, '091-098-7654');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (14, 1014, '090-987-6543');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (15, 1015, '089-876-5432');
INSERT INTO public.branch_telephone OVERRIDING SYSTEM VALUE VALUES (16, 1015, '999-876-5432');


--
-- Data for Name: branch_transportation; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: details; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.details VALUES (1, 'Modern', 'Wheelchair Accessible', 'Standard', 'City View', '5th Floor', 'Private', 'Double Bed', 'Cleaning Service', 30, true, 2, false);
INSERT INTO public.details VALUES (1001, 'Modern', 'Wheelchair Accessible', 'Standard', 'City View', '5th Floor', 'Private', 'Double Bed', 'Room Service', 300, true, 2, false);
INSERT INTO public.details VALUES (1002, 'Classic', 'Elevator Access', 'Standard', 'Ocean View', '2nd Floor', 'Private', 'Twin Beds', 'Concierge', 350, true, 2, true);
INSERT INTO public.details VALUES (1003, 'Vintage', 'Ramp Access', 'Standard', 'Mountain View', '3rd Floor', 'Shared', 'Queen Bed', 'Housekeeping', 280, true, 2, false);
INSERT INTO public.details VALUES (1004, 'Contemporary', 'Staircase Access', 'Suite', 'Lake View', '4th Floor', 'Private', 'King Bed', 'Laundry', 400, true, 4, true);
INSERT INTO public.details VALUES (1005, 'Rustic', 'No Accessibility Features', 'Suite', 'Garden View', '1st Floor', 'Private', 'Bunk Beds', 'Valet Parking', 320, true, 4, false);
INSERT INTO public.details VALUES (1006, 'Minimalist', 'Wheelchair Accessible', 'Standard', 'City View', '6th Floor', 'Private', 'Double Bed', 'Room Service', 280, true, 2, false);
INSERT INTO public.details VALUES (1007, 'Elegant', 'Elevator Access', 'Standard', 'Ocean View', '3rd Floor', 'Private', 'Twin Beds', 'Concierge', 330, true, 2, true);
INSERT INTO public.details VALUES (1008, 'Classic', 'Ramp Access', 'Standard', 'Mountain View', '4th Floor', 'Shared', 'Queen Bed', 'Housekeeping', 270, true, 2, false);
INSERT INTO public.details VALUES (1009, 'Modern', 'Staircase Access', 'Suite', 'Lake View', '5th Floor', 'Private', 'King Bed', 'Laundry', 390, true, 4, true);
INSERT INTO public.details VALUES (1010, 'Contemporary', 'No Accessibility Features', 'Suite', 'Garden View', '2nd Floor', 'Private', 'Bunk Beds', 'Valet Parking', 310, true, 4, false);
INSERT INTO public.details VALUES (1011, 'Urban', 'Elevator Access', 'Standard', 'City View', '8th Floor', 'Shared', 'Double Bed', 'Room Service', 350, true, 2, false);
INSERT INTO public.details VALUES (1012, 'Vintage', 'Wheelchair Accessible', 'Standard', 'Mountain View', '7th Floor', 'Private', 'Twin Beds', 'Concierge', 330, true, 2, true);
INSERT INTO public.details VALUES (1013, 'Minimalist', 'Elevator Access', 'Standard', 'Ocean View', '9th Floor', 'Private', 'Queen Bed', 'Housekeeping', 370, true, 2, false);
INSERT INTO public.details VALUES (1014, 'Classic', 'Ramp Access', 'Suite', 'Lake View', '3rd Floor', 'Private', 'King Bed', 'Laundry', 420, true, 4, true);
INSERT INTO public.details VALUES (1015, 'Modern', 'No Accessibility Features', 'Suite', 'Garden View', '2nd Floor', 'Private', 'Bunk Beds', 'Valet Parking', 340, true, 4, false);
INSERT INTO public.details VALUES (1016, 'Modern', 'Wheelchair Accessible', 'Standard', 'City View', '6th Floor', 'Private', 'Double Bed', 'Room Service', 300, true, 2, false);
INSERT INTO public.details VALUES (1017, 'Elegant', 'Elevator Access', 'Standard', 'Ocean View', '3rd Floor', 'Private', 'Twin Beds', 'Concierge', 330, true, 2, true);
INSERT INTO public.details VALUES (1018, 'Classic', 'Ramp Access', 'Standard', 'Mountain View', '4th Floor', 'Shared', 'Queen Bed', 'Housekeeping', 270, true, 2, false);
INSERT INTO public.details VALUES (1019, 'Modern', 'Staircase Access', 'Suite', 'Lake View', '5th Floor', 'Private', 'King Bed', 'Laundry', 390, true, 4, true);
INSERT INTO public.details VALUES (1020, 'Contemporary', 'No Accessibility Features', 'Suite', 'Garden View', '2nd Floor', 'Private', 'Bunk Beds', 'Valet Parking', 310, true, 4, false);
INSERT INTO public.details VALUES (1021, 'Contemporary', 'Staircase Access', 'Standard', 'City View', '6th Floor', 'Private', 'Double Bed', 'Room Service', 280, true, 2, false);
INSERT INTO public.details VALUES (1022, 'Vintage', 'Ramp Access', 'Standard', 'Mountain View', '4th Floor', 'Shared', 'Queen Bed', 'Housekeeping', 270, true, 2, false);
INSERT INTO public.details VALUES (1023, 'Modern', 'Wheelchair Accessible', 'Standard', 'City View', '5th Floor', 'Private', 'Double Bed', 'Room Service', 300, true, 2, false);
INSERT INTO public.details VALUES (1024, 'Classic', 'No Accessibility Features', 'Suite', 'Garden View', '1st Floor', 'Private', 'Bunk Beds', 'Valet Parking', 320, true, 4, false);
INSERT INTO public.details VALUES (1025, 'Elegant', 'Elevator Access', 'Standard', 'Ocean View', '3rd Floor', 'Private', 'Twin Beds', 'Concierge', 330, true, 2, true);


--
-- Data for Name: details_amentities; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.details_amentities OVERRIDING SYSTEM VALUE VALUES (0, 1, 'Free Wi-Fi');


--
-- Data for Name: hotel; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.hotel VALUES (1, 1, 'Sample Hotel', 'Sample Brand');
INSERT INTO public.hotel VALUES (1001, 1001, 'Grand Plaza Hotel', 'Grand Hotels Group');
INSERT INTO public.hotel VALUES (1002, 1002, 'Ocean View Resort', 'Ocean Resorts Inc.');
INSERT INTO public.hotel VALUES (1003, 1003, 'Sunset Paradise Inn', 'Sunset Hospitality Ltd.');
INSERT INTO public.hotel VALUES (1004, 1004, 'Mountain Lodge Retreat', 'Mountain Resorts & Spas');
INSERT INTO public.hotel VALUES (1005, 1005, 'Golden Sands Resort', 'Golden Resorts International');
INSERT INTO public.hotel VALUES (1006, 1001, 'City Tower Hotel', 'Urban Hospitality Group');
INSERT INTO public.hotel VALUES (1007, 1002, 'Royal Gardens Hotel', 'Royal Hospitality Management');
INSERT INTO public.hotel VALUES (1008, 1003, 'Lakeview Lodge', 'Lakefront Resorts Inc.');
INSERT INTO public.hotel VALUES (1009, 1004, 'Alpine Chalet Retreat', 'Alpine Hospitality Group');
INSERT INTO public.hotel VALUES (1010, 1005, 'Coastal Haven Resort', 'Coastal Resorts Ltd.');
INSERT INTO public.hotel VALUES (1011, 1001, 'Valley View Resort', 'Valley Resorts International');
INSERT INTO public.hotel VALUES (1012, 1002, 'Tropical Oasis Inn', 'Tropical Resorts Inc.');
INSERT INTO public.hotel VALUES (1013, 1003, 'Urban Heights Hotel', 'Urban Resorts Group');
INSERT INTO public.hotel VALUES (1014, 1004, 'Serenity Springs Resort', 'Serenity Hospitality Ltd.');
INSERT INTO public.hotel VALUES (1015, 1005, 'Skyline Plaza Hotel', 'Skyline Hospitality Group');


--
-- Data for Name: hotel_branch; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.hotel_branch VALUES (1, 1, 'Main Branch', 'City Center', 'Modern', 4, true, 'Valet Parking', 10);
INSERT INTO public.hotel_branch VALUES (1001, 1001, 'Grand Plaza - Downtown', 'City Center', 'Luxury Modern', 5, true, 'Valet', 20);
INSERT INTO public.hotel_branch VALUES (1001, 1002, 'Grand Plaza - Beachfront', 'Beachside', 'Tropical Paradise', 4, true, 'Covered', 15);
INSERT INTO public.hotel_branch VALUES (1001, 1003, 'Grand Plaza - Mountain View', 'Mountain Resort', 'Alpine Chic', 5, true, 'Open', 10);
INSERT INTO public.hotel_branch VALUES (1002, 1004, 'Ocean View - Coastal Retreat', 'Coastal Area', 'Coastal Elegance', 4, true, 'Covered', 18);
INSERT INTO public.hotel_branch VALUES (1002, 1005, 'Ocean View - Island Escape', 'Island Resort', 'Island Paradise', 5, true, 'Valet', 25);
INSERT INTO public.hotel_branch VALUES (1003, 1006, 'Sunset Paradise - Lakeside', 'Lakefront', 'Rustic Charm', 4, true, 'Open', 12);
INSERT INTO public.hotel_branch VALUES (1003, 1007, 'Sunset Paradise - Riverside', 'Riverside', 'Riverside Retreat', 4, true, 'Covered', 14);
INSERT INTO public.hotel_branch VALUES (1004, 1008, 'Mountain Lodge - Woodland', 'Woodland Area', 'Log Cabin Style', 5, true, 'Open', 15);
INSERT INTO public.hotel_branch VALUES (1004, 1009, 'Mountain Lodge - Hillside', 'Hillside Resort', 'Ski Chalet', 4, true, 'Covered', 18);
INSERT INTO public.hotel_branch VALUES (1005, 1010, 'Golden Sands - Coastal Haven', 'Coastal Area', 'Coastal Luxury', 4, true, 'Valet', 22);
INSERT INTO public.hotel_branch VALUES (1005, 1011, 'Golden Sands - Desert Oasis', 'Desert Resort', 'Desert Retreat', 4, true, 'Covered', 20);
INSERT INTO public.hotel_branch VALUES (1006, 1012, 'City Tower - Business District', 'Financial District', 'Contemporary Elegance', 4, true, 'Covered', 20);
INSERT INTO public.hotel_branch VALUES (1006, 1013, 'City Tower - Skyline View', 'Skyline Area', 'Modern Chic', 5, true, 'Valet', 25);
INSERT INTO public.hotel_branch VALUES (1007, 1014, 'Royal Gardens - Parkside', 'Park Area', 'Royal Garden Oasis', 5, true, 'Valet', 30);
INSERT INTO public.hotel_branch VALUES (1007, 1015, 'Royal Gardens - Riverfront', 'Riverfront', 'Elegant Riverside', 5, true, 'Covered', 25);
INSERT INTO public.hotel_branch VALUES (1008, 1016, 'Lakeview Lodge - Lakeside', 'Lakeside Area', 'Lakeview Retreat', 3, true, 'Open', 15);
INSERT INTO public.hotel_branch VALUES (1008, 1017, 'Lakeview Lodge - Forest Retreat', 'Forest Area', 'Tranquil Forest Hideaway', 4, true, 'Covered', 18);
INSERT INTO public.hotel_branch VALUES (1009, 1018, 'Alpine Chalet - Mountain View', 'Mountain Resort', 'Alpine Escape', 5, true, 'Open', 20);
INSERT INTO public.hotel_branch VALUES (1009, 1019, 'Alpine Chalet - Lakefront', 'Lakefront Area', 'Lakeside Chalet', 5, true, 'Covered', 22);
INSERT INTO public.hotel_branch VALUES (1010, 1020, 'Coastal Haven - Seaside Retreat', 'Seaside Area', 'Coastal Seclusion', 4, true, 'Covered', 20);
INSERT INTO public.hotel_branch VALUES (1010, 1021, 'Coastal Haven - Bayview', 'Bayfront Area', 'Bayview Escape', 5, true, 'Valet', 25);
INSERT INTO public.hotel_branch VALUES (1011, 1022, 'Valley View - Hilltop Retreat', 'Hilltop Area', 'Panoramic Valley View', 5, true, 'Open', 30);
INSERT INTO public.hotel_branch VALUES (1011, 1023, 'Valley View - Countryside', 'Countryside', 'Rural Serenity', 3, true, 'Covered', 35);
INSERT INTO public.hotel_branch VALUES (1012, 1024, 'Tropical Oasis - Beachfront', 'Beachfront', 'Tropical Beach Hideaway', 4, true, 'Covered', 20);
INSERT INTO public.hotel_branch VALUES (1012, 1025, 'Tropical Oasis - Jungle Retreat', 'Jungle Area', 'Jungle Paradise', 5, true, 'Open', 22);
INSERT INTO public.hotel_branch VALUES (1013, 1026, 'Urban Heights - Downtown', 'City Center', 'Urban Luxury', 4, true, 'Valet', 25);
INSERT INTO public.hotel_branch VALUES (1013, 1027, 'Urban Heights - Arts District', 'Arts District', 'Artistic Retreat', 5, true, 'Covered', 28);
INSERT INTO public.hotel_branch VALUES (1014, 1028, 'Serenity Springs - Lakeside', 'Lakefront Area', 'Tranquil Lakeside Sanctuary', 4, true, 'Covered', 20);
INSERT INTO public.hotel_branch VALUES (1014, 1029, 'Serenity Springs - Countryside', 'Countryside', 'Rural Escape', 3, true, 'Open', 22);
INSERT INTO public.hotel_branch VALUES (1015, 1030, 'Skyline Plaza - Downtown', 'City Center', 'Skyline Luxury', 5, true, 'Valet', 30);
INSERT INTO public.hotel_branch VALUES (1015, 1031, 'Skyline Plaza - Riverfront', 'Riverfront', 'Riverfront Retreat', 5, true, 'Covered', 35);


--
-- Data for Name: hotel_manager; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.hotel_manager VALUES (1);
INSERT INTO public.hotel_manager VALUES (1001);
INSERT INTO public.hotel_manager VALUES (1002);
INSERT INTO public.hotel_manager VALUES (1003);
INSERT INTO public.hotel_manager VALUES (1004);
INSERT INTO public.hotel_manager VALUES (1005);
INSERT INTO public.hotel_manager VALUES (1006);
INSERT INTO public.hotel_manager VALUES (1007);
INSERT INTO public.hotel_manager VALUES (1008);
INSERT INTO public.hotel_manager VALUES (1009);
INSERT INTO public.hotel_manager VALUES (1011);
INSERT INTO public.hotel_manager VALUES (1012);
INSERT INTO public.hotel_manager VALUES (1013);
INSERT INTO public.hotel_manager VALUES (1014);
INSERT INTO public.hotel_manager VALUES (1015);
INSERT INTO public.hotel_manager VALUES (1016);
INSERT INTO public.hotel_manager VALUES (1017);
INSERT INTO public.hotel_manager VALUES (1018);
INSERT INTO public.hotel_manager VALUES (1019);
INSERT INTO public.hotel_manager VALUES (1020);
INSERT INTO public.hotel_manager VALUES (1021);
INSERT INTO public.hotel_manager VALUES (1022);
INSERT INTO public.hotel_manager VALUES (1023);
INSERT INTO public.hotel_manager VALUES (1024);
INSERT INTO public.hotel_manager VALUES (1025);


--
-- Data for Name: hotel_marketingstrategy; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: hotel_technology; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Data for Name: logs; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.logs VALUES (0, 1, '2024-02-06 15:51:38.98359', '2024-02-05 16:47:08.243433');
INSERT INTO public.logs VALUES (1, 1, '2024-02-06 15:52:21.399947', '2024-02-06 15:52:14.663735');


--
-- Data for Name: normal_user; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.normal_user VALUES (1, '1990-01-01');
INSERT INTO public.normal_user VALUES (2, '2024-02-05');
INSERT INTO public.normal_user VALUES (3, '1990-01-01');
INSERT INTO public.normal_user VALUES (4, '2024-02-06');
INSERT INTO public.normal_user VALUES (1001, '1990-01-01');
INSERT INTO public.normal_user VALUES (1002, '1991-02-02');
INSERT INTO public.normal_user VALUES (1003, '1992-03-03');
INSERT INTO public.normal_user VALUES (1004, '1993-04-04');
INSERT INTO public.normal_user VALUES (1005, '1994-05-05');
INSERT INTO public.normal_user VALUES (1006, '1995-06-06');
INSERT INTO public.normal_user VALUES (1007, '1996-07-07');
INSERT INTO public.normal_user VALUES (1008, '1997-08-08');
INSERT INTO public.normal_user VALUES (1009, '1998-09-09');
INSERT INTO public.normal_user VALUES (1010, '1999-10-10');
INSERT INTO public.normal_user VALUES (1011, '1999-10-10');
INSERT INTO public.normal_user VALUES (1012, '1999-10-10');
INSERT INTO public.normal_user VALUES (1013, '1999-10-10');
INSERT INTO public.normal_user VALUES (1014, '1999-10-10');
INSERT INTO public.normal_user VALUES (1015, '1999-10-10');
INSERT INTO public.normal_user VALUES (1016, '1999-10-10');
INSERT INTO public.normal_user VALUES (1017, '2000-01-01');
INSERT INTO public.normal_user VALUES (1018, '2001-02-02');
INSERT INTO public.normal_user VALUES (1019, '2002-03-03');
INSERT INTO public.normal_user VALUES (1020, '2003-04-04');
INSERT INTO public.normal_user VALUES (1021, '2004-05-05');
INSERT INTO public.normal_user VALUES (1022, '2005-06-06');
INSERT INTO public.normal_user VALUES (1023, '2006-07-07');
INSERT INTO public.normal_user VALUES (1024, '2007-08-08');
INSERT INTO public.normal_user VALUES (1025, '2008-09-09');


--
-- Data for Name: normaluser_address; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.normaluser_address OVERRIDING SYSTEM VALUE VALUES (0, 1, '123 Main St');
INSERT INTO public.normaluser_address OVERRIDING SYSTEM VALUE VALUES (1, 1, '456 Oak St');
INSERT INTO public.normaluser_address OVERRIDING SYSTEM VALUE VALUES (2, 3, '123 Main St');
INSERT INTO public.normaluser_address OVERRIDING SYSTEM VALUE VALUES (3, 3, '456 Oak St');
INSERT INTO public.normaluser_address OVERRIDING SYSTEM VALUE VALUES (4, 4, '123 Main St');
INSERT INTO public.normaluser_address OVERRIDING SYSTEM VALUE VALUES (5, 4, '456 Oak Ave');


--
-- Data for Name: normaluser_telephone; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.normaluser_telephone OVERRIDING SYSTEM VALUE VALUES (0, 1, '555-1234');
INSERT INTO public.normaluser_telephone OVERRIDING SYSTEM VALUE VALUES (1, 1, '555-5678');
INSERT INTO public.normaluser_telephone OVERRIDING SYSTEM VALUE VALUES (2, 3, '555-1234');
INSERT INTO public.normaluser_telephone OVERRIDING SYSTEM VALUE VALUES (3, 3, '555-5678');
INSERT INTO public.normaluser_telephone OVERRIDING SYSTEM VALUE VALUES (4, 4, '555-1234');
INSERT INTO public.normaluser_telephone OVERRIDING SYSTEM VALUE VALUES (5, 4, '555-5678');


--
-- Data for Name: room; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO public.room VALUES (1, 1, 1, true, 100, 120, 150);
INSERT INTO public.room VALUES (1001, 1001, 1001, true, 150, 200, 250);
INSERT INTO public.room VALUES (1001, 1002, 1002, true, 170, 220, 270);
INSERT INTO public.room VALUES (1001, 1003, 1003, true, 160, 210, 260);
INSERT INTO public.room VALUES (1002, 1004, 1004, true, 180, 230, 280);
INSERT INTO public.room VALUES (1002, 1005, 1005, true, 140, 190, 240);
INSERT INTO public.room VALUES (1003, 1006, 1006, true, 130, 180, 230);
INSERT INTO public.room VALUES (1003, 1007, 1007, true, 120, 170, 220);
INSERT INTO public.room VALUES (1004, 1008, 1008, true, 190, 240, 290);
INSERT INTO public.room VALUES (1004, 1009, 1009, true, 200, 250, 300);
INSERT INTO public.room VALUES (1006, 1010, 1010, true, 110, 160, 210);
INSERT INTO public.room VALUES (1006, 1011, 1011, true, 100, 150, 200);
INSERT INTO public.room VALUES (1008, 1012, 1012, true, 220, 270, 320);
INSERT INTO public.room VALUES (1008, 1013, 1013, true, 210, 260, 310);
INSERT INTO public.room VALUES (1010, 1014, 1014, true, 230, 280, 330);
INSERT INTO public.room VALUES (1010, 1015, 1015, true, 240, 290, 340);
INSERT INTO public.room VALUES (1012, 1016, 1016, true, 200, 250, 300);
INSERT INTO public.room VALUES (1012, 1017, 1017, true, 210, 260, 310);
INSERT INTO public.room VALUES (1013, 1018, 1018, true, 180, 230, 280);
INSERT INTO public.room VALUES (1013, 1019, 1019, true, 190, 240, 290);
INSERT INTO public.room VALUES (1014, 1020, 1020, true, 220, 270, 320);
INSERT INTO public.room VALUES (1014, 1021, 1021, true, 230, 280, 330);
INSERT INTO public.room VALUES (1015, 1022, 1022, true, 250, 300, 350);
INSERT INTO public.room VALUES (1015, 1023, 1023, true, 260, 310, 360);


--
-- Name: branch_facilities_branch_facilies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.branch_facilities_branch_facilies_id_seq', 0, false);


--
-- Name: branch_securitymeasures_branch_securitymeasure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.branch_securitymeasures_branch_securitymeasure_id_seq', 0, false);


--
-- Name: branch_telephone_branch_telephone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.branch_telephone_branch_telephone_id_seq', 1015, true);


--
-- Name: branch_transportation_transportation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.branch_transportation_transportation_id_seq', 0, false);


--
-- Name: details_amentities_details_amentities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.details_amentities_details_amentities_id_seq', 0, true);


--
-- Name: hotel_marketingstrategy_hotel_marketingstrategy_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.hotel_marketingstrategy_hotel_marketingstrategy_seq', 0, false);


--
-- Name: hotel_technology_hotel_technology_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.hotel_technology_hotel_technology_id_seq', 0, false);


--
-- Name: normaluser_address_normaluser_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.normaluser_address_normaluser_address_id_seq', 5, true);


--
-- Name: normaluser_telephone_normaluser_telephone_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.normaluser_telephone_normaluser_telephone_id_seq', 5, true);


--
-- Name: details DETAILS_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details
    ADD CONSTRAINT "DETAILS_pkey" PRIMARY KEY (detailsid);


--
-- Name: booking NumberOfBooking; Type: CHECK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE public.booking
    ADD CONSTRAINT "NumberOfBooking" CHECK ((numberofbooking <= 3)) NOT VALID;


--
-- Name: booking NumberOfBooking2; Type: CHECK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE public.booking
    ADD CONSTRAINT "NumberOfBooking2" CHECK ((numberofbooking >= 0)) NOT VALID;


--
-- Name: room ROOM_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT "ROOM_pkey" PRIMARY KEY (branchid, roomid);


--
-- Name: room RoomID; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT "RoomID" UNIQUE (roomid);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (userid);


--
-- Name: all_user all_user_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.all_user
    ADD CONSTRAINT all_user_pkey PRIMARY KEY (userid);


--
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (bookingid);


--
-- Name: hotel_branch branch; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_branch
    ADD CONSTRAINT branch UNIQUE (branchid);


--
-- Name: branch_facilities branch_facilities_branch_facility_id_branchid_branch_facili_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_facilities
    ADD CONSTRAINT branch_facilities_branch_facility_id_branchid_branch_facili_key UNIQUE (branch_facility_id, branchid) INCLUDE (branch_facility_id, branchid);


--
-- Name: branch_facilities branch_facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_facilities
    ADD CONSTRAINT branch_facilities_pkey PRIMARY KEY (branch_facility_id) INCLUDE (branch_facility_id);


--
-- Name: branch_securitymeasures branch_measure_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_securitymeasures
    ADD CONSTRAINT branch_measure_pkey PRIMARY KEY (branch_measure_id) INCLUDE (branch_measure_id);


--
-- Name: branch_securitymeasures branch_securitymeasures_branch_measure_id_branchid_branch_m_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_securitymeasures
    ADD CONSTRAINT branch_securitymeasures_branch_measure_id_branchid_branch_m_key UNIQUE (branch_measure_id, branchid) INCLUDE (branch_measure_id, branchid);


--
-- Name: branch_telephone branch_telephone_branchid_branch_telephone_id_branchid1_bra_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_telephone
    ADD CONSTRAINT branch_telephone_branchid_branch_telephone_id_branchid1_bra_key UNIQUE (branchid, branch_telephone_id) INCLUDE (branchid, branch_telephone_id);


--
-- Name: branch_telephone branch_telephone_pk; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_telephone
    ADD CONSTRAINT branch_telephone_pk PRIMARY KEY (branch_telephone_id) INCLUDE (branch_telephone_id);


--
-- Name: branch_transportation branch_transportation_branch_transportation_id_branchid_bra_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT branch_transportation_branch_transportation_id_branchid_bra_key UNIQUE (branch_transportation_id, branchid) INCLUDE (branch_transportation_id, branchid);


--
-- Name: branch_transportation branch_transportation_pk; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT branch_transportation_pk PRIMARY KEY (branch_transportation_id) INCLUDE (branch_transportation_id);


--
-- Name: details_amentities details_amentities_details_amentities_id_detailsid_details__key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details_amentities
    ADD CONSTRAINT details_amentities_details_amentities_id_detailsid_details__key UNIQUE (details_amentities_id, detailsid) INCLUDE (details_amentities_id, detailsid);


--
-- Name: details_amentities details_amentities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details_amentities
    ADD CONSTRAINT details_amentities_pkey PRIMARY KEY (details_amentities_id) INCLUDE (details_amentities_id);


--
-- Name: hotel_branch hotel_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_branch
    ADD CONSTRAINT hotel_branch_pkey PRIMARY KEY (hotelid, branchid);


--
-- Name: hotel_manager hotel_manager_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_manager
    ADD CONSTRAINT hotel_manager_pkey PRIMARY KEY (userid);


--
-- Name: hotel_marketingstrategy hotel_marketingstrategy_hotel_strategy_id_hotelid_hotel_str_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_marketingstrategy
    ADD CONSTRAINT hotel_marketingstrategy_hotel_strategy_id_hotelid_hotel_str_key UNIQUE (hotel_strategy_id, hotelid) INCLUDE (hotel_strategy_id, hotelid);


--
-- Name: hotel_marketingstrategy hotel_marketingstrategy_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_marketingstrategy
    ADD CONSTRAINT hotel_marketingstrategy_pkey PRIMARY KEY (hotel_strategy_id) INCLUDE (hotel_strategy_id);


--
-- Name: hotel hotel_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel
    ADD CONSTRAINT hotel_pkey PRIMARY KEY (hotelid);


--
-- Name: hotel_technology hotel_technology_hotel_technology_id_hotelid_hotel_technolo_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_technology
    ADD CONSTRAINT hotel_technology_hotel_technology_id_hotelid_hotel_technolo_key UNIQUE (hotel_technology_id, hotelid) INCLUDE (hotel_technology_id, hotelid);


--
-- Name: hotel_technology hotel_technology_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_technology
    ADD CONSTRAINT hotel_technology_pkey PRIMARY KEY (hotel_technology_id) INCLUDE (hotel_technology_id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (logid);


--
-- Name: normal_user normal_user_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normal_user
    ADD CONSTRAINT normal_user_pkey PRIMARY KEY (userid);


--
-- Name: normaluser_address normaluser_address_normaluser_address_id_userid_normaluser__key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_address
    ADD CONSTRAINT normaluser_address_normaluser_address_id_userid_normaluser__key UNIQUE (normaluser_address_id, userid) INCLUDE (normaluser_address_id, userid);


--
-- Name: normaluser_address normaluser_address_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_address
    ADD CONSTRAINT normaluser_address_pkey PRIMARY KEY (normaluser_address_id) INCLUDE (normaluser_address_id);


--
-- Name: normaluser_telephone normaluser_telephone_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_telephone
    ADD CONSTRAINT normaluser_telephone_pkey PRIMARY KEY (normaluser_telephone_id) INCLUDE (normaluser_telephone_id);


--
-- Name: normaluser_telephone normaluser_telephone_userid_normaluser_telephone_id_normalu_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_telephone
    ADD CONSTRAINT normaluser_telephone_userid_normaluser_telephone_id_normalu_key UNIQUE (userid, normaluser_telephone_id) INCLUDE (normaluser_telephone_id, userid);


--
-- Name: branch_securitymeasures Branch_SecurityMeasures; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_securitymeasures
    ADD CONSTRAINT "Branch_SecurityMeasures" FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- Name: logs UserIDLogs; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT "UserIDLogs" FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- Name: booking booking_room; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_room FOREIGN KEY (roomid) REFERENCES public.room(roomid) NOT VALID;


--
-- Name: booking booking_user; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_user FOREIGN KEY (userid) REFERENCES public.normal_user(userid) NOT VALID;


--
-- Name: branch_facilities branch_facilities; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_facilities
    ADD CONSTRAINT branch_facilities FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- Name: branch_telephone branch_telephone_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_telephone
    ADD CONSTRAINT branch_telephone_fk FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- Name: branch_transportation branch_transportation_fk; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.branch_transportation
    ADD CONSTRAINT branch_transportation_fk FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- Name: room detail_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT detail_fkey FOREIGN KEY (detailsid) REFERENCES public.details(detailsid) NOT VALID;


--
-- Name: details_amentities details_amentities_details; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.details_amentities
    ADD CONSTRAINT details_amentities_details FOREIGN KEY (detailsid) REFERENCES public.details(detailsid) NOT VALID;


--
-- Name: hotel_branch hotel_branch_hotel; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_branch
    ADD CONSTRAINT hotel_branch_hotel FOREIGN KEY (hotelid) REFERENCES public.hotel(hotelid) NOT VALID;


--
-- Name: hotel_marketingstrategy hotel_marketingstrategy_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_marketingstrategy
    ADD CONSTRAINT hotel_marketingstrategy_normaluser FOREIGN KEY (hotelid) REFERENCES public.hotel(hotelid) NOT VALID;


--
-- Name: hotel hotel_normal_user; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel
    ADD CONSTRAINT hotel_normal_user FOREIGN KEY (userid) REFERENCES public.hotel_manager(userid) NOT VALID;


--
-- Name: hotel_technology hotel_technology_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_technology
    ADD CONSTRAINT hotel_technology_normaluser FOREIGN KEY (hotelid) REFERENCES public.hotel(hotelid) NOT VALID;


--
-- Name: normaluser_address normaluser_address_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_address
    ADD CONSTRAINT normaluser_address_normaluser FOREIGN KEY (userid) REFERENCES public.normal_user(userid) NOT VALID;


--
-- Name: normaluser_telephone normaluser_telephone_normaluser; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normaluser_telephone
    ADD CONSTRAINT normaluser_telephone_normaluser FOREIGN KEY (userid) REFERENCES public.normal_user(userid) NOT VALID;


--
-- Name: room room_branch; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.room
    ADD CONSTRAINT room_branch FOREIGN KEY (branchid) REFERENCES public.hotel_branch(branchid) NOT VALID;


--
-- Name: admins userid_admins; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT userid_admins FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- Name: hotel_manager userid_hotel_manager; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.hotel_manager
    ADD CONSTRAINT userid_hotel_manager FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- Name: normal_user userid_normal_user; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.normal_user
    ADD CONSTRAINT userid_normal_user FOREIGN KEY (userid) REFERENCES public.all_user(userid) NOT VALID;


--
-- PostgreSQL database dump complete
--

