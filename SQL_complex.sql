-- หาว่า MANAGER แต่ละคนมีจำนวนโรงแรมที่ MANAGE จำนวนกี่โรงแรม

SELECT HOTEL_MANAGER.UserID, ALL_USER.UserName, COUNT(HOTEL_BRANCH.BranchID) AS ManagedBranches
FROM HOTEL_MANAGER
JOIN HOTEL ON HOTEL_MANAGER.UserID = HOTEL.UserID
LEFT JOIN HOTEL_BRANCH ON HOTEL.HotelID = HOTEL_BRANCH.HotelID
JOIN ALL_USER ON HOTEL_MANAGER.UserID = ALL_USER.UserID
GROUP BY HOTEL_MANAGER.UserID,ALL_USER.UserName
ORDER BY ManagedBranches DESC;


-- top 10 hotels with an average rating of at least 4.5,
-- categorizing them by revenue level based on booking amounts and counting the number of unique customers per hotel
SELECT 
    "hotel"."hotelname", 
    AVG("hotel_branch"."rating_reviews") AS "averagerating", 
    SUM("room"."pricenormal" * "booking"."numberofbooking") AS "totalrevenue",
    COUNT(DISTINCT "booking"."userid") AS "uniquecustomers",
    CASE 
        WHEN SUM("room"."pricenormal" * "booking"."numberofbooking") > 10000 THEN 'High Revenue'
        WHEN SUM("room"."pricenormal" * "booking"."numberofbooking") > 5000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS "revenuecategory"
FROM 
    "hotel"
JOIN 
    "hotel_branch" ON "hotel"."hotelid" = "hotel_branch"."hotelid"
JOIN 
    "room" ON "hotel_branch"."branchid" = "room"."branchid"
JOIN 
    "booking" ON "room"."roomid" = "booking"."roomid"
GROUP BY 
    "hotel"."hotelname"
HAVING 
    AVG("hotel_branch"."rating_reviews") >= 4.5 
ORDER BY 
    "averagerating" DESC, "totalrevenue" DESC
LIMIT 10;

