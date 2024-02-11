-- หาว่า MANAGER แต่ละคนมีจำนวนโรงแรมที่ MANAGE จำนวนกี่โรงแรม

SELECT HOTEL_MANAGER.UserID, ALL_USER.UserName, COUNT(HOTEL_BRANCH.BranchID) AS ManagedBranches
FROM HOTEL_MANAGER
JOIN HOTEL ON HOTEL_MANAGER.UserID = HOTEL.UserID
LEFT JOIN HOTEL_BRANCH ON HOTEL.HotelID = HOTEL_BRANCH.HotelID
JOIN ALL_USER ON HOTEL_MANAGER.UserID = ALL_USER.UserID
GROUP BY HOTEL_MANAGER.UserID,ALL_USER.UserName
ORDER BY ManagedBranches DESC;


-- top 10 hotels with an average rating of at least 4.5,

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
