CREATE OR REPLACE FUNCTION admin_view_bookings()
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
    SELECT *
    FROM view_bookings;
END;
$$;