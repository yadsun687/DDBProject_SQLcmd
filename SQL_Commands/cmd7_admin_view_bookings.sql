CREATE OR REPLACE FUNCTION admins_view_all_bookings(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100)
)
RETURNS TABLE (
    bookingid INTEGER,
    userid INTEGER,
    checkindate DATE,
    paytype VARCHAR(100),
    numberofbooking INTEGER,
    roomid INTEGER,
    hotelid INTEGER,
    hotelname VARCHAR(100),
    branchid INTEGER,
    branchname VARCHAR(100),
    branch_location VARCHAR(100),
    decorandtheme VARCHAR(100),
    rating_reviews INTEGER,
    parkingavailability BOOLEAN,
    parkingtypeparking VARCHAR(100),
    parkingcostparking INTEGER,
    roomdecor VARCHAR(100),
    accessibilityfeatures VARCHAR(100),
    roomtype VARCHAR(100),
    roomview VARCHAR(100),
    buildingfloor VARCHAR(100), -- Adjusted type to VARCHAR(100)
    bathroom VARCHAR(100),
    bedconfiguration VARCHAR(100),
    services VARCHAR(100),
    roomsize INTEGER,
    wifi BOOLEAN,
    maxpeople INTEGER,
    smoking BOOLEAN,
    facility VARCHAR(100),
    measure VARCHAR(100),
    transportation VARCHAR(100),
    marketingstrategy VARCHAR(100),
    technology VARCHAR(100)
)
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
        public.hotel_branch hb ON r.branchid = hb.branchid
    JOIN 
        public.hotel h ON hb.hotelid = h.hotelid
    LEFT JOIN 
        public.details_amentities da ON d.detailsid = da.detailsid
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

--show result
SELECT * FROM public.admins_view_all_bookings('john.doe@example.com' , 'password123') ORDER BY bookingid ASC;