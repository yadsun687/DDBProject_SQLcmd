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