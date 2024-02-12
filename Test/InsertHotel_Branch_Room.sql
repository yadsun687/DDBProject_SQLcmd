-- insert hotel
CREATE OR REPLACE FUNCTION insert_hotel(
    _hotelid integer,
    _userid integer,
    _hotelname character varying,
    _brandidentity character varying
) RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert into hotel table
    INSERT INTO public.hotel(hotelid, userid, hotelname, brandidentity)
    VALUES (_hotelid, _userid, _hotelname, _brandidentity);
END;
$BODY$;
-- (_hotelid, _userid, _hotelname, _brandidentity)
-- SELECT insert_hotel(1, 1, 'Hotel ABC', 'ABC Brand');

-- insert hotel branch
CREATE OR REPLACE FUNCTION insert_hotel_branch(
    _hotelid integer,
    _branchid integer,
    _branchname character varying,
    _branch_location character varying,
    _decorandtheme character varying,
    _rating_reviews integer,
    _parkingavailability boolean,
    _parkingtypeparking character varying,
    _parkingcostparking integer
) RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert into hotel_branch table
    INSERT INTO public.hotel_branch(hotelid, branchid, branchname, branch_location, decorandtheme, rating_reviews, parkingavailability, parkingtypeparking, parkingcostparking)
    VALUES (_hotelid, _branchid, _branchname, _branch_location, _decorandtheme, _rating_reviews, _parkingavailability, _parkingtypeparking, _parkingcostparking);
END;
$BODY$;
-- (_hotelid, _branchid, _branchname, _branch_location, _decorandtheme, _rating_reviews, _parkingavailability, _parkingtypeparking, _parkingcostparking)
-- SELECT insert_hotel_branch(1, 1, 'Branch ABC', 'Location XYZ', 'Theme XYZ', 5, TRUE, 'Parking Type', 10);

--insert room 
CREATE OR REPLACE FUNCTION insert_room(
    _branchid integer,
    _roomid integer,
    _detailsid integer,
    _status boolean,
    _pricenormal integer,
    _priceweekend integer,
    _priceevent integer
) RETURNS void
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Insert into room table
    INSERT INTO public.room(branchid, roomid, detailsid, status, pricenormal, priceweekend, priceevent)
    VALUES (_branchid, _roomid, _detailsid, _status, _pricenormal, _priceweekend, _priceevent);
END;
$BODY$;

-- (_branchid, _roomid, _detailsid, _status, _pricenormal, _priceweekend, _priceevent)
-- SELECT insert_room(1, 1, 1, TRUE, 100, 120, 150);
