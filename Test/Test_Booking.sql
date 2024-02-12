DO $$
DECLARE
    user_id INTEGER;
BEGIN
    CALL public.register_all_user('user45116', 'Bob Jaohnson', 'bob.jaaaohnson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Oak St'], ARRAY['555-9012']);
    CALL public.login_user('bob.jaaaohnson@example.com', 'user45116');

    -- Retrieve the user ID
    SELECT UserID INTO user_id FROM public.ALL_USER WHERE UserEmail = 'bob.jaaaohnson@example.com';

    -- Attempt to insert the user into hotel_manager
    BEGIN
        INSERT INTO public.hotel_manager(userid) VALUES (user_id);
        RAISE NOTICE 'User inserted into hotel_manager';
    EXCEPTION
        WHEN unique_violation THEN
            -- User already exists in hotel_manager
            RAISE NOTICE 'User already exists in hotel_manager';
    END;
END;
$$;

-- Test case 1: Successful booking with different user, room, and hotel information
DO $$
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL public.register_all_user('user123', 'Alice Smith', 'alice.smith@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['456 Elm St'], ARRAY['555-5678']);
    CALL public.login_user('alice.smith@example.com', 'user123');

    -- Insert hotel and branch with different information
    PERFORM public.insert_hotel(63631, user_id, 'Grand Hotel', 'Grand Brand');
    PERFORM public.insert_hotel_branch(63631, 143145, 'Grand Branch', 'Central Location', 'Luxurious Theme', 4, TRUE, 'Valet Parking', 20);
    PERFORM public.insert_room(143145, 232445, 1, TRUE, 100, 120, 150);
    
    -- Retrieve a valid room ID (assuming room ID 2 exists and is available)
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 232445;
    
    -- Attempt to book the room for 3 nights starting from the next day
    BEGIN
        CALL public.insert_booking_with_user_and_room('alice.smith@example.com', 'user123', room_id, CURRENT_DATE + 1, 'Credit Card', 3);
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
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL public.register_all_user('user456', 'Bob Johnson', 'bob.johnson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Oak St'], ARRAY['555-9012']);
    CALL public.login_user('bob.johnson@example.com', 'user456');

     -- Insert hotel and branch with different information
    PERFORM public.insert_hotel(341423, user_id, 'Cozy Inn', 'Cozy Brand');
    PERFORM public.insert_hotel_branch(341423, 1312345, 'Cozy Branch', 'Rural Location', 'Rustic Theme', 3, TRUE, 'Free Parking', 0);
    PERFORM public.insert_room(1312345, 1234555, 1, TRUE, 100, 120, 150);
    
    -- Retrieve a valid room ID (assuming room ID 3 exists and is available)
    SELECT RoomID INTO room_id FROM public.ROOM WHERE RoomID = 1234555;
    
    -- Attempt to book the room for 3 nights starting from the next day (outside the allowed range)
    BEGIN
        CALL public.insert_booking_with_user_and_room(
            user_email := 'bob.johnson@example.com',
            user_password := 'user456',
            room_id := room_id,
            check_in_date := CURRENT_DATE - 3,
            payment_type := 'Credit Card',
            number_of_nights := 3
        );
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
    CALL public.register_all_user('user789', 'Eva Martinez', 'eva.martinez@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['101 Pine St'], ARRAY['555-3456']);
    CALL public.login_user('eva.martinez@example.com', 'user789');
    
    -- Attempt to book an invalid room (room ID 999, assuming it doesn't exist)
    BEGIN
        CALL public.insert_booking_with_user_and_room('eva.martinez@example.com', 'user789', 9999999995433311, CURRENT_DATE + 2, 'Credit Card', 3);
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
    CALL public.register_all_user('user234', 'Ethan Johnson', 'ethan.johnson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['123 Maple St'], ARRAY['555-1234']);
    CALL public.login_user('ethan.johnson@example.com', 'user234');
    
    -- Insert hotel and branch with different information
    PERFORM public.insert_hotel(535246, user_id, 'Mountain Lodge', 'Mountain Brand');
    PERFORM public.insert_hotel_branch(535246, 741345, 'Mountain Branch', 'Scenic Location', 'Rustic Theme', 4, TRUE, 'Free Parking', 0);
    PERFORM public.insert_room(741345, 61415, 1, TRUE, 100, 120, 150);
    
    -- Attempt to book the room at the specified hotel for 2 nights starting from the next day
    BEGIN
        CALL public.insert_booking_with_user_and_room('ethan.johnson@example.com', 'user234', 61415, CURRENT_DATE + 1, 'Credit Card', 2);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 4: Booking hotel up to 3 nights - FAILED';
            RETURN;
    END;
    
    -- Check if the booking was successful
    RAISE NOTICE 'Test case 4: Booking hotel up to 3 nights - PASS';
END;
$$;

-- Test case 5: Cant Booking with more than 3 nights
DO $$
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL public.register_all_user('user456', 'Liam Martinez', 'liam.martinez@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Pine St'], ARRAY['555-9012']);
    CALL public.login_user('liam.martinez@example.com', 'user456');
    
    -- Insert hotel and branch with different information
    PERFORM public.insert_hotel(731451, user_id, 'Seaside Resort', 'Seaside Brand');
    PERFORM public.insert_hotel_branch(731451, 142145, 'Seaside Branch', 'Coastal Location', 'Tropical Theme', 4, TRUE, 'Beach Parking', 25);
    PERFORM public.insert_room(142145, 54156, 1, TRUE, 100, 120, 150);
        
    -- Attempt to book the room at the specified hotel for 4 nights starting from the next day
    BEGIN
        CALL public.insert_booking_with_user_and_room('liam.martinez@example.com', 'user456', 54156, CURRENT_DATE + 1, 'Credit Card', 4);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 5: Cant Booking with more than 3 nights - PASS';
            RETURN;
    END;
    
    -- Check if the booking failed due to more than 3 nights
    RAISE NOTICE 'Test case 5: Cant Booking with more than 3 nights - FAILED';
END;
$$;

-- Test case 6: Cant Book Room That Already Booked
DO $$
DECLARE
    user_id INTEGER;
    room_id INTEGER;
BEGIN
    -- Ensure the user is registered and logged in
    CALL public.register_all_user('user678', 'Mia Wilson', 'mia.wilson@example.com', ARRAY['NORMAL'], CURRENT_DATE, ARRAY['789 Maple St'], ARRAY['555-7890']);
    CALL public.login_user('mia.wilson@example.com', 'user678');
    
    -- Insert hotel and branch with different information
    PERFORM public.insert_hotel(156264, user_id, 'Lakeside Lodge', 'Lakeside Brand');
    PERFORM public.insert_hotel_branch(156264, 786548, 'Lakeside Branch', 'Lakefront Location', 'Nature Theme', 4, TRUE, 'Lake Parking', 0);
    PERFORM public.insert_room(786548, 96521, 1, TRUE, 100, 120, 150);
    
    -- Attempt to book the room at the specified hotel for 2 nights starting from the next day
    BEGIN
        CALL public.insert_booking_with_user_and_room('mia.wilson@example.com', 'user678', 96521, CURRENT_DATE + 1, 'Credit Card', 2);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 6: Cant Book Room That Already Booked - FAILED (First booking failed)';
            RETURN;
    END;
    
    -- Attempt to book the same room again
    BEGIN
        CALL public.insert_booking_with_user_and_room('mia.wilson@example.com', 'user678', 96521, CURRENT_DATE + 1, 'Credit Card', 2);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Test case 6: Cant Book Room That Already Booked - PASS';
            RETURN;
    END;
    
    -- If the second booking succeeds, it indicates incorrect behavior
    RAISE NOTICE 'Test case 6: Cant Book Room That Already Bookede - FAILED (Second booking failed)';
END;
$$;
