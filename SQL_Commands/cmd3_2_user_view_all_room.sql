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