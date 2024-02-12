-- top 5 hotels with an average rating of at least 4,
-- categorizing them by revenue level based on booking amounts and counting the number of unique customers per hotel
SELECT 
    "hotel"."hotelname", 
    ROUND(AVG("hotel_branch"."rating_reviews"), 2) AS "averagerating", 
    SUM("room"."pricenormal" * "booking"."numberofbooking") AS "totalrevenue",
    COUNT(DISTINCT "booking"."userid") AS "uniquecustomers",
    CASE 
        WHEN SUM("room"."pricenormal" * "booking"."numberofbooking") > 4000 THEN 'High Revenue'
        WHEN SUM("room"."pricenormal" * "booking"."numberofbooking") > 1500 THEN 'Medium Revenue'
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
    AVG("hotel_branch"."rating_reviews") >= 4
ORDER BY 
    "averagerating" DESC, "totalrevenue" DESC
LIMIT 5;
