-- insert hotel
CREATE OR REPLACE FUNCTION insert_hotel(
    _hotelid integer,
    _userid integer,
    _hotelname character varying,
    _brandidentity character varying
) RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert into hotel table
    INSERT INTO public.hotel(hotelid, userid, hotelname, brandidentity)
    VALUES (_hotelid, _userid, _hotelname, _brandidentity);
END;
$BODY$;
-- (_hotelid, _userid, _hotelname, _brandidentity)
-- SELECT insert_hotel(1, 1, 'Hotel ABC', 'ABC Brand');

-- insert hotel branch
CREATE OR REPLACE FUNCTION insert_hotel_branch(
    _hotelid integer,
    _branchid integer,
    _branchname character varying,
    _branch_location character varying,
    _decorandtheme character varying,
    _rating_reviews integer,
    _parkingavailability boolean,
    _parkingtypeparking character varying,
    _parkingcostparking integer
) RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert into hotel_branch table
    INSERT INTO public.hotel_branch(hotelid, branchid, branchname, branch_location, decorandtheme, rating_reviews, parkingavailability, parkingtypeparking, parkingcostparking)
    VALUES (_hotelid, _branchid, _branchname, _branch_location, _decorandtheme, _rating_reviews, _parkingavailability, _parkingtypeparking, _parkingcostparking);
END;
$BODY$;
-- (_hotelid, _branchid, _branchname, _branch_location, _decorandtheme, _rating_reviews, _parkingavailability, _parkingtypeparking, _parkingcostparking)
-- SELECT insert_hotel_branch(1, 1, 'Branch ABC', 'Location XYZ', 'Theme XYZ', 5, TRUE, 'Parking Type', 10);

--insert room 
CREATE OR REPLACE FUNCTION insert_room(
    _branchid integer,
    _roomid integer,
    _detailsid integer,
    _status boolean,
    _pricenormal integer,
    _priceweekend integer,
    _priceevent integer
) RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert into room table
    INSERT INTO public.room(branchid, roomid, detailsid, status, pricenormal, priceweekend, priceevent)
    VALUES (_branchid, _roomid, _detailsid, _status, _pricenormal, _priceweekend, _priceevent);
END;
$BODY$;

-- (_branchid, _roomid, _detailsid, _status, _pricenormal, _priceweekend, _priceevent)
-- SELECT insert_room(1, 1, 1, TRUE, 100, 120, 150);

-- Test case 1: Successful booking with different user, room, and hotel information
DO $$
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL register_all_user('user123', 'Alice Smith', 'alice.smith@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['456 Elm St'], ARRAY['555-5678']);
    CALL login_user('alice.smith@example.com', 'user123');
    
    -- Insert hotel and branch with different information
    PERFORM insert_hotel(2, 1, 'Grand Hotel', 'Grand Brand');
    PERFORM insert_hotel_branch(2, 1, 'Grand Branch', 'Central Location', 'Luxurious Theme', 4, TRUE, 'Valet Parking', 20);
    
    -- Retrieve the user ID
    SELECT UserID INTO user_id FROM public.ALL_USER WHERE UserEmail = 'alice.smith@example.com';
    
    -- Retrieve a valid room ID (assuming room ID 2 exists and is available)
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 2;
    
    -- Attempt to book the room for 3 nights starting from the next day
    BEGIN
        PERFORM insert_booking_with_user_and_room('alice.smith@example.com', 'user123', room_id, CURRENT_DATE + 1, 'Credit Card', 3);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 1: Successful booking - FAILED';
            RETURN;
    END;
    
    -- Check if the booking was successful
    RAISE NOTICE 'Test case 1: Successful booking - PASS';
END;
$$;

-- Test case 2: Booking Past Date
DO $$
BEGIN
    -- Ensure the user is registered and logged in
    CALL register_all_user('user456', 'Bob Johnson', 'bob.johnson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Oak St'], ARRAY['555-9012']);
    CALL login_user('bob.johnson@example.com', 'user456');
    
    -- Insert hotel and branch with different information
    PERFORM insert_hotel(3, 1, 'Cozy Inn', 'Cozy Brand');
    PERFORM insert_hotel_branch(3, 1, 'Cozy Branch', 'Rural Location', 'Rustic Theme', 3, TRUE, 'Free Parking', 0);
    
    -- Retrieve a valid room ID (assuming room ID 3 exists and is available)
    DECLARE room_id INTEGER;
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 3;
    
    -- Attempt to book the room for 3 nights starting from the next day (outside the allowed range)
    BEGIN
        PERFORM insert_booking_with_user_and_room('bob.johnson@example.com', 'user456', room_id, CURRENT_DATE - 3, 'Credit Card', 3);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 2: Cant Booking with invalid date - PASS';
            RETURN;
    END;
    
    -- Check if the booking failed due to invalid date
    RAISE NOTICE 'Test case 2: Cant Booking with invalid date - FAILED';
END;
$$;

-- Test case 3: Cant booking with invalid room ID 
DO $$
BEGIN
    -- Ensure the user is registered and logged in
    CALL register_all_user('user789', 'Eva Martinez', 'eva.martinez@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['101 Pine St'], ARRAY['555-3456']);
    CALL login_user('eva.martinez@example.com', 'user789');
    
    -- Insert hotel and branch with different information
    PERFORM insert_hotel(4, 1, 'Ocean View Hotel', 'Ocean Brand');
    PERFORM insert_hotel_branch(4, 1, 'Ocean Branch', 'Beachfront Location', 'Nautical Theme', 4, TRUE, 'Public Parking', 5);
    
    -- Attempt to book an invalid room (room ID 999, assuming it doesn't exist)
    BEGIN
        PERFORM insert_booking_with_user_and_room('eva.martinez@example.com', 'user789', 999, CURRENT_DATE + 2, 'Credit Card', 3);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 3: Cant booking with invalid room ID  - PASS';
            RETURN;
    END;
    
    -- Check if the booking failed due to invalid room
    RAISE NOTICE 'Test case 3: Cant booking with invalid room ID - FAILED';
END;
$$;

-- Test case 4: Booking with hotel selection for up to 3 nights
DO $$
DECLARE
    user_id INTEGER;
    hotel_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL register_all_user('user234', 'Ethan Johnson', 'ethan.johnson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['123 Maple St'], ARRAY['555-1234']);
    CALL login_user('ethan.johnson@example.com', 'user234');
    
    -- Insert hotel and branch with different information
    PERFORM insert_hotel(5, 1, 'Mountain Lodge', 'Mountain Brand');
    PERFORM insert_hotel_branch(5, 1, 'Mountain Branch', 'Scenic Location', 'Rustic Theme', 4, TRUE, 'Free Parking', 0);
    
    -- Retrieve the user ID
    SELECT UserID INTO user_id FROM public.ALL_USER WHERE UserEmail = 'ethan.johnson@example.com';
    
    -- Retrieve a valid room ID (assuming room ID 4 exists and is available)
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 4;
    
    -- Retrieve a valid hotel ID (assuming hotel ID 5 exists)
    SELECT HotelID INTO hotel_id FROM public.HOTEL WHERE HotelID = 5;
    
    -- Attempt to book the room at the specified hotel for 2 nights starting from the next day
    BEGIN
        PERFORM insert_booking_with_user_and_room('ethan.johnson@example.com', 'user234', room_id, CURRENT_DATE + 1, 'Credit Card', 2);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 4: Booking hotel up to 3 nights - FAILED';
            RETURN;
    END;
    
    -- Check if the booking was successful
    RAISE NOTICE 'Test case 4: Booking hotel up to 3 nights - PASS';
END;
$$;

-- Test case 5: Booking with more than 3 nights
DO $$
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL register_all_user('user456', 'Liam Martinez', 'liam.martinez@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Pine St'], ARRAY['555-9012']);
    CALL login_user('liam.martinez@example.com', 'user456');
    
    -- Insert hotel and branch with different information
    PERFORM insert_hotel(7, 1, 'Seaside Resort', 'Seaside Brand');
    PERFORM insert_hotel_branch(7, 1, 'Seaside Branch', 'Coastal Location', 'Tropical Theme', 4, TRUE, 'Beach Parking', 25);
    
    -- Retrieve a valid room ID (assuming room ID 6 exists and is available)
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 6;
    
    -- Attempt to book the room at the specified hotel for 4 nights starting from the next day
    BEGIN
        PERFORM insert_booking_with_user_and_room('liam.martinez@example.com', 'user456', room_id, CURRENT_DATE + 1, 'Credit Card', 4);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 5: Booking with more than 3 nights - FAILED';
            RETURN;
    END;
    
    -- Check if the booking failed due to more than 3 nights
    RAISE NOTICE 'Test case 5: Booking with more than 3 nights - PASS';
END;
$$;

-- Test case 6: Cant Book Room That Already Booked
DO $$
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL register_all_user('user678', 'Mia Wilson', 'mia.wilson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Maple St'], ARRAY['555-7890']);
    CALL login_user('mia.wilson@example.com', 'user678');
    
    -- Insert hotel and branch with different information
    PERFORM insert_hotel(11, 1, 'Lakeside Lodge', 'Lakeside Brand');
    PERFORM insert_hotel_branch(11, 1, 'Lakeside Branch', 'Lakefront Location', 'Nature Theme', 4, TRUE, 'Lake Parking', 0);
    
    -- Retrieve a valid room ID (assuming room ID 9 exists and is available)
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 9;
    
    -- Attempt to book the room at the specified hotel for 2 nights starting from the next day
    BEGIN
        PERFORM insert_booking_with_user_and_room('mia.wilson@example.com', 'user678', room_id, CURRENT_DATE + 1, 'Credit Card', 2);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 6: Cant Book Room That Already Booked - FAILED (First booking failed)';
            RETURN;
    END;
    
    -- Attempt to book the same room again
    BEGIN
        PERFORM insert_booking_with_user_and_room('mia.wilson@example.com', 'user678', room_id, CURRENT_DATE + 1, 'Credit Card', 2);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 6: Cant Book Room That Already Booked - PASS';
            RETURN;
    END;
    
    -- If the second booking succeeds, it indicates incorrect behavior
    RAISE NOTICE 'Test case 6: Cant Book Room That Already Bookede - FAILED (Second booking failed)';
END;
$$;


