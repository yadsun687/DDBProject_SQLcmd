CREATE
OR REPLACE VIEW view_bookings AS
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
FROM
  public."BOOKING" b
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
  LEFT JOIN public."Hotel_Technology" tech ON hb."HotelID(HOTEL_BRANCH)" = tech."HotelID(Hotel_Technology)";