CREATE OR REPLACE FUNCTION user_view_his_booking(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100)
)
RETURNS TABLE (
    BookingID INTEGER,
    UserID INTEGER,
    CheckInDate DATE,
    PayType VARCHAR(100),
    NumberOfBooking INTEGER,
    RoomID INTEGER,
    HotelID INTEGER,
    HotelName VARCHAR(100),
    BranchID INTEGER,
    BranchName VARCHAR(100),
    BranchLocation VARCHAR(100),
    DecorAndTheme VARCHAR(100),
    RatingReviews INTEGER,
    ParkingAvailability BOOLEAN,
    ParkingTypeParking VARCHAR(100),
    ParkingCostParking INTEGER,
    RoomDecor VARCHAR(100),
    AccessibilityFeatures VARCHAR(100),
    RoomType VARCHAR(100),
    RoomView VARCHAR(100),
    BuildingFloor VARCHAR(100),
    Bathroom VARCHAR(100),
    BedConfiguration VARCHAR(100),
    Services VARCHAR(100),
    RoomSize INTEGER,
    WiFi BOOLEAN,
    MaxPeople INTEGER,
    Smoking BOOLEAN,
    Facility VARCHAR(100),
    Measure VARCHAR(100),
    Transportation VARCHAR(100),
    MarketingStrategy VARCHAR(100),
    Technology VARCHAR(100)
)
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

SELECT * FROM user_view_his_booking('john.doe@example.com', 'password123');
