SELECT "HOTEL_BRANCH"."BranchName", SUM("ROOM"."PriceNormal" * "BOOKING"."NumberOfBooking") AS "TotalRevenue"
FROM "HOTEL_BRANCH"
JOIN "ROOM" ON "HOTEL_BRANCH"."BranchID" = "ROOM"."BranchID(ROOM)"
JOIN "BOOKING" ON "ROOM"."RoomID" = "BOOKING"."RoomID(BOOKING)"
GROUP BY "HOTEL_BRANCH"."BranchName";


SELECT "HOTEL"."HotelName", AVG("HOTEL_BRANCH"."Rating/Reviews") AS "AverageRating",
       SUM("ROOM"."PriceNormal" * "BOOKING"."NumberOfBooking") AS "TotalRevenue"
FROM "HOTEL"
JOIN "HOTEL_BRANCH" ON "HOTEL"."HotelID" = "HOTEL_BRANCH"."HotelID(HOTEL_BRANCH)"
JOIN "ROOM" ON "HOTEL_BRANCH"."BranchID" = "ROOM"."BranchID(ROOM)"
JOIN "BOOKING" ON "ROOM"."RoomID" = "BOOKING"."RoomID(BOOKING)"
GROUP BY "HOTEL"."HotelName"
ORDER BY "AverageRating" DESC, "TotalRevenue" DESC
LIMIT 5;

SELECT AGE("NORMAL_USER"."BirthDate") AS "AgeGroup", COUNT(*) AS "UserCount"
FROM "NORMAL_USER"
GROUP BY "AgeGroup"
ORDER BY "AgeGroup";

SELECT "HOTEL_MANAGER"."UserID(HOTEL_MANAGER)", "ALL_USER"."UserName", COUNT("HOTEL_BRANCH"."BranchID") AS "ManagedBranches"
FROM "HOTEL_MANAGER"
JOIN "HOTEL" ON "HOTEL_MANAGER"."UserID(HOTEL_MANAGER)" = "HOTEL"."UserID(HOTEL_MANAGER)"
LEFT JOIN "HOTEL_BRANCH" ON "HOTEL"."HotelID" = "HOTEL_BRANCH"."HotelID(HOTEL_BRANCH)"
JOIN "ALL_USER" ON "HOTEL_MANAGER"."UserID(HOTEL_MANAGER)" = "ALL_USER"."UserID"
GROUP BY "HOTEL_MANAGER"."UserID(HOTEL_MANAGER)", "ALL_USER"."UserName"
ORDER BY "ManagedBranches" DESC;


/*top 10 hotels with an average rating of at least 4.5,
categorizing them by revenue level based on booking amounts and counting the number of unique customers per hotel*/
SELECT 
    "HOTEL"."HotelName", 
    AVG("HOTEL_BRANCH"."Rating/Reviews") AS "AverageRating", 
    SUM("ROOM"."PriceNormal" * "BOOKING"."NumberOfBooking") AS "TotalRevenue",
    COUNT(DISTINCT "CUSTOMER"."CustomerID") AS "UniqueCustomers",
    CASE 
        WHEN "TotalRevenue" > 10000 THEN 'High Revenue'
        WHEN "TotalRevenue" > 5000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS "RevenueCategory"
FROM 
    "HOTEL"
JOIN 
    "HOTEL_BRANCH" ON "HOTEL"."HotelID" = "HOTEL_BRANCH"."HotelID(HOTEL_BRANCH)"
JOIN 
    "ROOM" ON "HOTEL_BRANCH"."BranchID" = "ROOM"."BranchID(ROOM)"
JOIN 
    "BOOKING" ON "ROOM"."RoomID" = "BOOKING"."RoomID(BOOKING)"
JOIN 
    "CUSTOMER" ON "BOOKING"."CustomerID(BOOKING)" = "CUSTOMER"."CustomerID"
GROUP BY 
    "HOTEL"."HotelName"
HAVING 
    "AverageRating" >= 4.5
ORDER BY 
    "AverageRating" DESC, "TotalRevenue" DESC
LIMIT 10;
