CREATE OR REPLACE FUNCTION user_view_all_room(
    p_user_email VARCHAR(100),
    p_user_password VARCHAR(100)
)
RETURNS TABLE (
    HotelName VARCHAR(100),
    BranchLocation VARCHAR(100),
    Telephone TEXT,
    RoomID INTEGER,
    BranchName VARCHAR(100),
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

CALL login_user('john.doe@example.com', 'password123');
SELECT * FROM user_view_all_room('john.doe@example.com', 'password123');